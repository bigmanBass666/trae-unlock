---
module: diagnosis-playbook
description: 故障排查手册和场景化操作流程
read_priority: P2
read_when: 出现问题时需要诊断
write_when: 发现新的故障模式时
format: reference
sync_with:
  - shared/discoveries.md (数据来源)
last_reviewed: 2026-04-26
---

# 🏥 Trae Unlock 诊断操作手册

> 使用场景：遇到补丁失效、界面异常、功能不工作时打开此文件。
> 核心原则：先查已有知识（rule-014），再动手调查。
> 配合工具：`diagnose-patch-health.ps1`（一键健康检查）、`discoveries.md`（🔍知识索引）

---

## 场景 A: 聊天界面消失 / 白屏 / 崩溃

**症状**: 重启 Trae 后 AI 聊天窗口不存在或空白

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| A1 | 运行 `powershell scripts/diagnose-patch-health.ps1` | 健康评分 + 8 项检查 |
| A2 | 如果评分 < 30 (CRITICAL) | → backups/ 有备份？→ 手动恢复 → apply-patches |
| A3 | 如果评分 30-70 (DEGRADED) | → 部分补丁失败 → apply-patches 重新应用 |
| A4 | 如果语法错误 | → auto-heal.ps1 自动修复 |
| A5 | **查 discoveries 🔍索引 "崩溃"/"消失"/"白屏"/"crash"** | ← rule-014 强制步骤 |

**已知根因链**（来自 discoveries.md [2026-04-22 11:00]）:

| # | 根因 | 触发条件 | 防御层 |
|---|------|---------|--------|
| 1 | **definitions.json 版本不一致** | SearchReplace 直接写目标文件但没同步更新 fingerprint | L0 `node --check` 写入前验证 |
| 2 | **缺少语法验证安全网** | apply-patches WriteAllText 前不做语法检查，一个括号错误毁掉整个 10MB 文件 | L0 + L1 自动备份 |
| 3 | **Trae 更新导致 minifier 变量重命名** | terser/webpack 重新打包，短变量名随机变化（如 efh→efg, P8→P7） | L3 diagnose-patch-health 定期检查 |

**崩溃模式总结**:
```
Trae 更新(变量重命名) → 部分补丁失效 → 残留+新代码混合
    ↓
某次操作触发不完整的重新应用（fingerprint 不一致导致误判）
    ↓
apply-patches 写入含语法错误的 10MB 文件（无验证！）
    ↓
React 无法加载 index.js → 聊天界面消失
```

**快速修复路径**: `backups/clean-*.ext` → 复制回目标文件 → `apply-patches.ps1`

---

## 场景 B: auto-continue-thinking 不工作（循环检测后无法续接）

**症状**: 黄色警告出现但不自动续接，或手动点"继续"没反应

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| B1 | 打开 DevTools Console (F12) | 准备收集日志 |
| B2 | 触发循环检测（让 AI 做重复任务） | 产生 `[v7]` 日志 |
| B3 | 查控制台 `[v7]` 日志 | 确认触发点和失败位置 |
| B4 | **查 discoveries 🔍索引 "resumeChat"/"ec()"/"queueMicrotask"/"v7-debug"** | ← rule-014 强制步骤 |
| B5 | 对比日志与已知发现 | 定位是新问题还是已知问题 |

**已知发现**（来自 discoveries.md [2026-04-22 14:30] v7-debug 日志）:

#### 发现 1: queueMicrotask 确实触发了 ✅

```
[v7-auto] if(V&&J) ENTERED, o=69e85c... h=69e85c...
[v7-auto] queueMicrotask FIRED, o&&h=true, calling resumeChat...
[v7-auto] resumeChat RETURNED (may be async)
```
→ 调度时机不是问题。v3-v5 的 setTimeout 问题已被 queueMicrotask 解决。

#### 发现 2: resumeChat 是 no-op ⚠️ 核心问题

```
resumeChat RETURNED (may be async)   ← 没报错
... (之后没有任何新消息出现)          ← 但也没有任何效果!
ERR repeated tool call RunCommand 5 times ← 真正的错误码
```
→ **resumeChat 被调用但完全无效**。这是 v3-v6 全部失败的统一解释——不是调度问题，而是 API 本身在循环检测后的 session 状态下不可用。

#### 发现 3: React 重渲染风暴

```
if(V&&J) ENTERED    ← 第 1 次
if(V&&J) ENTERED x2 ← 第 2-3 次
if(V&&J) ENTERED x2 ← 第 5-6 次
... (约 50 行日志内进入 10+ 次)
```
→ 每次 render 都触发新的 `queueMicrotask → D.resumeChat()`，形成正反馈循环。需要防重复守卫（v7 已加 `__traeAC` timestamp flag + 5 秒 cooldown）。

#### 发现 4: ec() 条件链复杂

来自 discoveries.md [2026-04-21 19:00] 和 [2026-04-21 12:00]:
- `"v3"===p && efg.includes(_)` 双重条件 → agentProcess 必须是 v3 且错误码在 efg 列表中
- 手动点击"继续"按钮走不同代码路径（可能绕过部分条件）
- **暂停按钮 = sendingState=Running = 消息已发送**（[2026-04-22 02:00]，不是错误信号）

**快速决策树**:
```
看到 [v7-auto] 日志？
  ├─ 没有 → queueMicrotask 没触发 → 回到 v6 问题（guard clause 拦截?）
  ├─ 有一次 → resumeChat 被调 → 等 2 秒看是否有新消息
  │   ├─ 有新消息 → ✅ 成功！
  │   └─ 无新消息 → resumeChat is no-op → 需要 fallback 方案
  ├─ 有多次(x10+) → 渲染风暴 → 检查 __traeAC 防重复守卫是否生效
  └─ [v7-manual] 出现？→ 手动点了继续 → 看 ec() 条件哪个不满足
       ├─ !a||!h → agentMessageId 或 sessionId 为空
       ├─ "v3"!==p → agentProcess 不是 v3
       └─ !efg.includes(_) → 错误码不在恢复列表中
```

---

## 场景 C: Trae 更新后补丁全部丢失

**症状**: 重启后发现之前的功能都不工作了

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| C1 | `powershell scripts/diagnose-patch-health.ps1` | 确认补丁状态 |
| C2 | 大部分 FAIL/RESUAL? | → Trae 更新还原了目标文件 |
| C3 | `powershell scripts/apply-patches.ps1` | 重新应用全部补丁 |
| C4 | 有 fuzzy match 失败? | → minifier 变量重命名 → 更新 find_original → 重新 apply |
| C5 | **查 discoveries 🔍索引 "更新"/"变量重命名"/"efh→efg"/"P8→P7"** | ← rule-014 强制步骤 |
| C6 | 全部通过? | ✅ 完成。运行 `snapshot.ps1` 备份 |

**已知变化记录**（来自 discoveries.md [2026-04-20 21:00] 和 [2026-04-22 11:00]）:

| 时间 | 变化类型 | 具体变化 |
|------|---------|---------|
| 2026-04-20 | Trae 大更新 | 目标文件 ~87MB → ~10.73MB，所有偏移变化 10-15% |
| 2026-04-22 | Trae 小更新 | ~10.73MB → 10.24MB (-4.9%)，变量重命名 |

**常见变量名变化**（terser 每次打包随机生成，不可硬编码）:

| 旧变量 | 新变量 | 影响 |
|--------|--------|------|
| `efh` | `efg` | efh-resume-list 补丁的 find_original 失效 |
| `P8` | `P7` | bypass-runcommandcard-redlist 补丁失效 |
| 其他短变量 | 随机变化 | 取决于 terser 的符号表分配 |

**诊断关键指标**:
- 目标文件大小变化 > 1% → 很可能是 Trae 更新
- `diagnose-patch-health.ps1` 报告多个 FAIL → 确认是批量失效而非单个补丁问题
- fuzzy match 成功但 exact match 失败 → 微小差异（参考 [2026-04-22 14:00] 字节级诊断方法论）

---

## 场景 D: 命令确认弹窗未自动消除

**症状**: 执行命令时弹出确认对话框需要手动点击

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| D1 | **查 discoveries 🔍索引 "confirm"/"弹窗"/"auto-confirm"/"provideUserResponse"** | ← rule-014 强制步骤 |
| D2 | 是 knowledge 类命令（后台任务）？ | → data-source-auto-confirm (L3 数据层) 应该处理 |
| D3 | 是 Shell/PowerShell 高风险命令？ | → service-layer-runcommand-confirm (L2 服务层) 应该处理 |
| D4 | 是普通工具命令？ | → auto-confirm-commands (L2 服务层) 应该处理 |
| D5 | 都没生效？ | → verify.ps1 检查指纹 → 可能 find_original 不匹配 |
| D6 | 弹窗样式变了但还在？ | → bypass-runcommandcard-redlist 只改按钮样式，不影响是否显示弹窗 |

**已知架构**（来自 discoveries.md [2026-04-20 20:40] 三层架构分层法则）:

```
┌──────────────────────────────────────────┐
│  L1 UI 层 (React 组件)     ~8640000      │  改这里 = 治标不治本
│  - RunCommandCard: ey useMemo            │
│  - P8 枚举: 只控制按钮样式，不控制弹窗    │
├──────────────────────────────────────────┤
│  L2 服务层 (PlanItemStreamParser) ~750万  │  改这里 = 直接告诉服务端已确认
│  - provideUserResponse: 主动确认调用      │
│  - 黑名单过滤: 控制哪些工具不被自动确认    │
├──────────────────────────────────────────┤
│  L3 数据层 (DG.parse)      ~7318521      │  改这里 = 从源头改变数据流
│  - auto_confirm 标志: 最底层拦截         │
│  - 不受 React 渲染时序影响               │
└──────────────────────────────────────────┘
```

**黄金规则**: 能从 L3 解决的绝不从 L1 改。UI 层是"症状"，数据层是"病因"。

**已知黑名单**（来自 discoveries.md [2026-04-20 19:50]）:
- ✅ 已排除: `response_to_user`, `AskUserQuestion`
- ❌ 不应排除: `NotifyUser`（spec 模式确认弹窗应该自动确认）

**常见误判**:
- `ew.confirm()` 是日志打点函数，不是执行函数（[2026-04-20 17:20]）
- 所有 P8 枚举值都有 buttons 定义，没有"无弹窗"值（[2026-04-20 20:30]）

---

## 场景 E: 其他异常（通用流程）

**症状**: 不确定属于哪类问题

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| E1 | `powershell scripts/diagnose-patch-health.ps1` | 获取健康评分和 8 项检查详情 |
| E2 | **查 discoveries 🔍索引** — 从错误信息/现象中提取关键词搜索 | ← rule-014 强制步骤 |
| E3 | 找到相关发现？ | → 基于已知信息构建假设（rule-011 假设优先搜索法） |
| E4 | 没找到？ | → 新问题 → 创建 spec 调查（此时才是从零开始） |
| E5 | 排查时遵循「推理→搜索→验证三步法」 | 先列假设再搜索，避免广撒网（rule-010） |
| E6 | 修复后 | → `powershell scripts/snapshot.ps1` → 备份 + git commit |

**rule-011 假设优先搜索法**（来自 discoveries.md [2026-04-23] 方法论索引）:
```
遇到问题时，先花 2 分钟列出 2-4 个可能的根因假设
  每个假设对应一个关键验证点（1 个搜索命令就能确认/排除）
  按"排除成本从低到高"的顺序验证
  一旦某个假设被验证为真，立即停止搜索
  禁止"广撒网式搜索"——没有明确目标的搜索是时间黑洞
```

**discoveries.md 热门搜索关键词速查**:

| 现象 | 搜索关键词 | 对应发现 |
|------|-----------|---------|
| 补丁找不到/模糊匹配失败 | "find_original", "fuzzy", "字节级" | [2026-04-22 14:00] 字节级诊断方法论 |
| 函数调了但没效果 | "no-op", "resumeChat", "沉默杀手" | [2026-04-22 14:30] v7-debug, [2026-04-22 01:00] setTimeout 缺陷 |
| UI 先正确后变错误 | "二次错误覆盖", "DEFAULT", "2000000" | [2026-04-21 23:00] 黄色警告 = 正常工作 |
| React 组件反复渲染 | "渲染风暴", "重渲染", "if(V&&J)" | [2026-04-22 14:30] 发现 3 |
| 中间层回调不按预期工作 | "中间层陷阱", "ec()", "条件判断" | [2026-04-21 19:00], AGENTS.md rule-012 |
| 状态被莫名覆盖 | "覆盖者", "stopStreaming", "Canceled" | [2026-04-21 21:00] Guard Clause 根因 |
| 弹窗/确认相关 | "confirm", "provideUserResponse", "三层架构" | [2026-04-20 16:20], [2026-04-20 20:40] |
| 错误码不明 | "错误码枚举", "4000009", "4000012" | [2026-04-19 12:00] |
| 变量名/偏移变化 | "变量重命名", "efh→efg", "P8→P7" | [2026-04-22 11:00] 崩溃三根因链 |
| 效率低下/重复劳动 | "知识孤岛", "重复调查", "搜索优先" | [2026-04-22 15:00], [2026-04-21 14:00] |

---

## 场景 F: 前台正常 / 后台失效（L1 冻结问题）

**症状**: 补丁在盯着窗口时正常工作，切换到别的聊天或最小化后失效，切回来后又恢复

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| F1 | **查 discoveries 🔍索引 "冻结"/"L1"/"后台"/"切走"/"render"** | ← rule-014 强制步骤 |
| F2 | 确认补丁所在层级？ | → L1? → 这是预期行为。见下方「分层速查表」 |
| F3 | 补丁需要实时响应？ | → 是 → 必须迁移到 L2 或 L3 |
| F4 | 补丁只是视觉修改？ | → 否 → L1 冻结可接受，切回后自动恢复 |

**根因机制**（已验证, discoveries.md [2026-04-22 16:00]）:

```
Chromium 后台标签页:
  rAF 暂停 → React Scheduler 暂停 → memo() 不重渲染 → render 函数不执行
  结果: L1 补丁代码在后台完全静默，切回后延迟触发
```

**8 个补丁分层速查表**:

| 补丁 | 层级 | 后台行为 | 如果出问题 |
|------|------|---------|-----------|
| service-layer-runcommand-confirm | L2 | ✅ 正常 | 不是冻结问题，查其他原因 |
| data-source-auto-confirm | L3 | ✅ 正常 | 同上 |
| auto-confirm-commands | L2 | ✅ 正常 | 同上 |
| **auto-continue-thinking** | **L1** | **❌ 冻结** | **预期行为！v7 已加 fallback 缓解** |
| guard-clause-bypass | L1 | ❌ 冻结 | 预期行为，首次渲染时生效即可 |
| bypass-loop-detection | L1 | ⚠️ 定义存在 | J数组值在内存中，但读取它的 if(V&&J) 在L1 |
| efh-resume-list | L1 | ⚠️ 同上 | efg列表值在内存中 |
| bypass-runcommandcard-redlist | L1 | ⚠️ 同上 | P7枚举在编译时确定 |

**决策树**:
```
补丁在前台正常、后台失效？
  ├─ 是 L2/L3 补丁？→ 不是冻结问题 → 按 Scene E 排查
  └─ 是 L1 补丁？
      ├─ 需要实时响应？（如 auto-continue）
      │   └─ 考虑迁移到 L2（事件监听）或 L3（store 订阅）
      └─ 只是展示修改？（如按钮样式、Alert 文字）
          └─ ✅ 冻结可接受，用户切回时自动恢复
```

---

## 🔧 工具速查

| 工具 | 命令 | 用途 |
|------|------|------|
| 健康检查 | `scripts/diagnose-patch-health.ps1` | 一键 100 分制诊断，8 项逐项检查 |
| 应用补丁 | `scripts/apply-patches.ps1` | 全部补丁重新应用（自动备份） |
| 自愈修复 | `scripts/auto-heal.ps1` | 自动检测 + 修复（自动备份 + 提交） |
| 一键快照 | `scripts/snapshot.ps1` | backup + git commit 一体化 |
| 补丁验证 | `scripts/verify.ps1` | 指纹匹配验证每个补丁状态 |
| 子串搜索 | `$c=[IO.File]::ReadAllText($path); $c.IndexOf("keyword")` | 压缩文件精确搜索（唯一可靠方式） |
| 文本搜索 | `scripts/tools/search-target.ps1 -Pattern "关键词"` | 项目内文本搜索 |
| 语法检查 | `node --check target.js` | 写入前验证 JS 语法正确性 |

---

## 📋 诊断前自检清单

在开始任何诊断工作前，确认以下事项：

```
□ 是否已运行 diagnose-patch-health.ps1 获取基线状态？
□ 是否已搜索 discoveries.md 相关关键词？（rule-014）
□ 是否已列出 2-4 个根因假设？（rule-011）
□ backups/ 目录是否有可用的干净备份？
□ 当前会话的修改是否会与其他 AI 会话冲突？
```
