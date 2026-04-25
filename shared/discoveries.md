---
module: discoveries
description: 源码发现和代码定位（核心资产）
read_priority: P2
read_when: 需要查代码时
write_when: 发现关键信息时
format: registry
---

# 源码探索经验

> **这是本项目最有价值的文件。** 所有 Trae 内部代码位置、枚举值、架构关系都在这里。
> 未来 AI 同事：改补丁前先搜这里，90% 的概率前人已经分析过。

## [2026-04-23 01:00] 白屏根因对比诊断 — 6cfb3de (v7) vs 当前版 ⭐⭐⭐

**问题**: 当前版本补丁导致 AI 聊天界面消失（白屏）。commit `6cfb3de` 是最后一个确认有正常界面的版本。

### 对比方法
- 提取 6cfb3de 的 definitions.json（13 个补丁，UTF-16 编码）
- 备份当前白屏版 definitions.json（14 个补丁）
- Node.js 脚本逐补丁对比 find_original / replace_with / fingerprint

### 对比结果

| 变更类型 | 补丁 ID | 详情 | 风险 |
|---------|---------|------|------|
| **+1 新增** | `auto-continue-l2-event` | 在文件末尾 IIFE 注入 setInterval(3000) 轮询器，读取 window.__traeSvc 并调用 sendChatMessage | **🔴 CRITICAL** |
| **~1 修改** | `auto-continue-thinking` | v7(1266c, 纯 if(V&&J) 内部逻辑) → v9(611c, 在 if(V&&J)**前**添加 D/b 变量访问 + window.__traeSvc 捕获) | **🟠 HIGH → CRITICAL** |
| -0 删除 | 无 | — | — |

### 根因分析

#### 原因 1 [CRITICAL]: auto-continue-l2-event 新增补丁

```
注入位置: 文件末尾 `,apis:FW}})(),l})()`
替换为:   `,apis:FW}})();(function(){setInterval(...)});l})()`
```

**为什么导致白屏**:
1. 这个补丁在 IIFE 的闭合位置注入代码
2. 如果注入破坏了闭包结构（括号不匹配、作用域泄漏等）→ 整个模块无法正确初始化
3. React 依赖此模块 → 模块崩溃 → React 无法挂载 → **聊天界面空白**
4. **关键**: 此补丁在 6cfb3de 中**完全不存在**

#### 原因 2 [HIGH→CRITICAL]: auto-continue-thinking v7→v9 修改

```javascript
// v7 (安全): 纯内部逻辑，不改变组件结构
if(V&&J){
    let e=M.localize("continue",{},"Continue");
    // ... queueMicrotask + resumeChat + fallback ...
    return sX().createElement(Cr.Alert,{...})
}

// v9 (危险): 在 if(V&&J) 外部添加代码
if(typeof D!=='undefined'&&D&&typeof b!=='undefined'&&b){   // ← 新增！
    if(!window.__traeSvc){window.__traeSvc={D:D,b:b,M:M}}      // ← 新增！
}else{window.__traeSvc.D=D;...}                               // ← 新增！
if(V&&J){...}  // 原有逻辑不变
```

**为什么危险**:
1. 在 React 组件的 render 函数中、在条件渲染之前添加了副作用代码
2. 访问 D 和 b 变量——这些是闭包内的局部变量，在某些渲染路径下可能未定义
3. 与原因 1 协同：v9 设置 `window.__traeSvc`，而 l2-event 读取它。如果设置时机/内容错误 → l2-event 的轮询器可能触发异常操作

### 为什么 node --check 没有捕获到

**语法检查 ≠ 运行时安全**:
- `node --check` 只检查 JavaScript 语法是否合法
- 它**不检查**:
  - 变量在运行时是否存在（D/b 可能 undefined）
  - 闭包作用域是否正确（IIFE 注入可能破坏 scope chain）
  - React 组件是否能正常渲染（需要实际 DOM 环境）
- 这是白屏问题的核心教训：**语法通过不代表不会崩溃**

### 预防措施（给未来 AI）

1. **新增补丁 = 高风险操作** — 必须在干净目标上测试，不能在已有其他修改的目标上叠加
2. **修改现有补丁的 replace_with 结构** = 同样高风险 — 特别是改变代码位置（如从 if 内部移到外部）的修改
3. **两个互相依赖的新补丁同时上线** = 最高风险 — 应该分步验证
4. **白屏发生时的标准诊断流程**:
   ```
   a. git log --oneline patches/definitions.json 找到最后一个工作版本
   b. git diff <working> <last-good>:patches/definitions.json > diff.txt
   c. 关注: 新增补丁? replace_with 结构变化? 注入位置变化?
   d. 回滚到工作版本的 definitions.json + 干净目标文件
   e. apply-patches + node --check + 重启 Trae 验证
   ```
module: discoveries
description: 源码发现和代码定位（核心资产）
read_priority: P2
read_when: 需要查代码时
write_when: 发现关键信息时
format: registry
---

# 源码探索经验

> **这是本项目最有价值的文件。** 所有 Trae 内部代码位置、枚举值、架构关系都在这里。
> 未来 AI 同事：改补丁前先搜这里，90% 的概率前人已经分析过。

---

## 架构总览

### 三层架构分层法则

```
┌───────────────────────────────────────┐
│ L1 UI 层 (React 组件)   ~8640000      │ ❌ 切走窗口后冻结！
│ RunCommandCard: ey useMemo, useEffect  │ 只适合纯视觉修改
├───────────────────────────────────────┤
│ L2 服务层 (PlanItemStreamParser) ~750万│ ✅ 始终活跃
│ provideUserResponse: 主动确认调用      │ 最可靠补丁注入点
├───────────────────────────────────────┤
│ L3 数据层 (DG.parse)     ~7318521     │ ✅ 始终活跃
│ auto_confirm 标志: 从源头改变行为      │ 不受 React 时序影响
└───────────────────────────────────────┘
```

**黄金规则**: 能从 L3 解决的绝不从 L1 改。L2 是安全区。Trae 更新主要影响 L1。

### L1 冻结原则（2026-04-22 验证 ⭐最重要）

```
Chromium 后台标签页:
  requestAnimationFrame 停止
    → React Scheduler 暂停 → memo() 不重渲染
      → render 函数体内的补丁代码不执行
```

**证据**: v7 日志三阶段 — 聚焦时 auto-continue 正常触发 → 切走后完全无响应 → 切回后延迟触发。
**解释了**: auto-continue-thinking 为什么需要 6 次迭代（v3→v7）才在聚焦窗口下成功。
**设计原则**: 需要实时响应的补丁必须放在 L2 或 L3。L1 仅适用于纯展示性修改。

### 确认系统双层架构

**Layer 1**: PlanItemStreamParser（~7502574）— `confirm_status==="unconfirmed"` → `provideUserResponse`
**Layer 2**: RunCommandCard（~8069620）— `getRunCommandCardBranch()` 根据 BlockLevel + AutoRunMode 决定 UI 分支
**关键**: 两层完全独立，只补一层另一层仍会弹窗。服务层不受 React 冻结影响。

---

## 关键代码位置

### PlanItemStreamParser — SSE 流解析器

**位置**: ~7502500 | **层级**: 服务层（不依赖 React）
**作用**: 解析服务端 SSE 流返回的 planItem，命令确认流程的核心入口
**4 个调用点**:
1. ~7502574: knowledge 分支 — `confirm_status==="unconfirmed" && toolName!=="response_to_user"`
2. ~7503319: else 分支 — `toolName!=="response_to_user" && confirm_status!=="confirmed"`
3. ~8635000+: egR 组件用户手动点击确认
4. ~8635000+: egR 组件用户手动点击拒绝

**成功后**: provideUserResponse → 服务端执行 → 手动同步 confirm_status="confirmed" → Store 更新 → React re-render
**失败后**: .catch(e=>{...}) → confirm_status 保持 "unconfirmed"

### getRunCommandCardBranch — UI 分支逻辑

**位置**: ~8069620 | **签名**: `getRunCommandCardBranch({ run_mode_version, autoRunMode, blockLevel, hasBlacklist })`

| AutoRunMode | BlockLevel | hasBlacklist | 返回值 | 行为 |
|-------------|-----------|-------------|--------|------|
| WHITELIST | RedList | - | V2_Sandbox_RedList | 弹窗 |
| WHITELIST | Sandbox* | false | V2_Sandbox_* | 弹窗 |
| WHITELIST | default | - | **Default** | **自动执行 ✅** |
| ALWAYS_RUN | RedList | - | V2_Manual_RedList | 弹窗 |
| ALWAYS_RUN | (其他) | false | **Default** | **自动执行 ✅** |
| default(Ask) | RedList | - | V2_Manual_RedList | 弹窗 |
| default(Ask) | (其他) | false | V2_Manual | 弹窗 |

**关键**: 只有 `P8.Default` 才是真正的自动执行。即使 ALWAYS_RUN + RedList 仍然弹窗。

### provideUserResponse 完整调用链

**API**: `this._taskService.provideUserResponse({task_id, type:"tool_confirm", toolcall_id, tool_name, decision:"confirm"|"reject"})`
**注意**: 没有 SSE 事件确认服务端收到。调用后必须手动同步本地 confirm_info.confirm_status。

### ew.confirm() 是日志打点，不是执行函数！

**位置**: ~8635000+ (egR 组件内)
**发现**: `ew.confirm(true)` 只是 telemetry 打点，不触发业务逻辑。
**真正执行函数**: `eE(Ck.Confirmed)` — 触发状态更新和命令执行。

### J 变量和 efh 列表 — 错误恢复的两条路径

**J 变量** (~8696378): 控制是否显示"继续"按钮
```javascript
J = !![kg.MODEL_OUTPUT_TOO_LONG, kg.TASK_TURN_EXCEEDED_ERROR,
       kg.LLM_STOP_DUP_TOOL_CALL, kg.LLM_STOP_CONTENT_LOOP].includes(_)
// J=true → Alert + "继续"按钮 → 可自动续接
// J=false → 只显示错误消息 → 对话终止
```

**efh 列表** (~8695303 / 现在是 efg): 控制是否可自动恢复（resumeChat）
- 包含网络/服务错误码（SERVER_CRASH, CONNECTION_ERROR 等）
- 补丁新增: TASK_TURN_EXCEEDED_ERROR, LLM_STOP_CONTENT_LOOP, DEFAULT
- ec 回调: `if("v3"===p && e.includes(_)) D.resumeChat()`

**两条恢复路径**:
1. **resumeChat 路径** (ec 回调): 错误在 efh 中 + agentProcess==="v3" → D.resumeChat()
2. **sendChatMessage 路径** (fallback): 发送 "Continue" 文本 → 新一轮对话

### stopStreaming() 覆盖 status — "沉默杀手"

**问题**: D7.Error 设置 status=Warning → stopStreaming() **覆盖为 Canceled** → guard clause `if(!n||!q||et)` 中 q=false → 组件不渲染 → if(V&&J) 永远不执行
**修复 (guard-clause-bypass)**: `if(!n||!q||et)` → `if(!n||(!q&&!J)||et)` — J=true 时放行

### 暂停按钮状态机

**暂停图标 = 消息已发送 + AI 正在生成**（不是 bug！）
- 按钮 `ei` 组件 (~2796260): 单一组件处理 send + stop，通过 `sendingState` prop 切换图标
- 3-way icon switch: Spinning(Sending) → ⏹ stop-circle(Running) → ↑ ArrowUp(WaitingInput)
- `setRunningStatusMap(sessionId, Io.Running)` 只在 `onSendChatMessageStart()` 中调用
- resumeChat 和 sendChatMessage 都走同一路径 → 暂停图标无法区分

---

## 枚举值

### 错误码枚举

**位置**: ~54000 / ~7161400

| 常量 | 值 | 含义 | 处理方式 |
|------|-----|------|---------|
| TASK_TURN_EXCEEDED_ERROR | 4000002 | 思考次数上限 | J数组→自动续接 |
| LLM_STOP_DUP_TOOL_CALL | 4000009 | 重复工具调用循环 | J数组→自动续接 |
| LLM_STOP_CONTENT_LOOP | 4000012 | 内容循环 | J数组+efh列表 |
| MODEL_OUTPUT_TOO_LONG | — | 输出过长 | J数组 |
| DEFAULT | 2000000 | 默认错误（二次覆盖元凶） | 加入J+efh防御 |

### BlockLevel 枚举

**位置**: ~8069382

| 值 | 含义 |
|----|------|
| `"redlist"` | 危险命令（Remove-Item 等） |
| `"blacklist"` | 企业策略禁止 |
| `"sandbox_execute_failure"` | 沙箱执行失败 |
| `"sandbox_to_recovery"` | 沙箱恢复 |
| `"sandbox_unavailable"` | 沙箱不可用 |

### AutoRunMode 枚举

**位置**: ~8069382 (ee 对象)

| 值 | 含义 |
|----|------|
| `"auto"` | Auto |
| `"manual"` | Manual |
| `"allowlist"` | Allowlist |
| `"in_sandbox"` | InSandbox |
| `"out_sandbox"` | OutSandbox |

### ConfirmMode 枚举

**位置**: ~8069382 (ei 对象) — 用户可见设置

| 值 | 含义 |
|----|------|
| `"alwaysAsk"` | 每次都问 |
| `"whitelist"` | 白名单内自动 |
| `"blacklist"` | 黑名单外自动 |
| `"alwaysRun"` | 全自动 |

**设置 Key**: `AI.toolcall.confirmMode` (~7438613)

### ToolCallName 完整枚举（80+ 工具）

**位置**: `ee` 枚举（~7076154-7079682）

**需要用户交互（禁止自动确认）**: `response_to_user`, `AskUserQuestion`, `NotifyUser`, `ExitPlanMode`

**命令执行类**: `RunCommand`, `run_mcp`, `check_command_status`

**文件操作类**: `Read`, `Write`, `Edit`, `MultiEdit`, `Glob`, `Grep`, `LS`, `SearchReplace`, `SearchCodebase`, `view_file`, `view_files`, `view_folder`, `write_to_file`, `edit_file_search_replace`, `create_file`, `delete_file`, `file_search`, `show_diff`, `show_diff_fc`

**浏览器操作类**: `browser_*`（20+个）

**搜索/索引类**: `search_by_*`, `TodoWrite`, `todo_write`, `web_search`, `WebSearch`

**任务/代理类**: `Task*`, `Team*`, `agent_finish`, `finish`, `Skill`, `CompactFake`

**其他**: `deploy_to_remote`, `stripe_*`, `supabase_*`, `manage_core_memory`, `*_shallow_memento*`, `OpenPreview*`, `open_folder`, `init_env`, `image_ocr`

### confirm_info 数据结构

```javascript
confirm_info = {
  confirm_status: "unconfirmed" | "confirmed" | "canceled" | "skipped",
  auto_confirm: true | false,          // knowledge 背景任务为 true
  hit_red_list: ["Remove-Item", ...],
  hit_blacklist: [...],
  block_level: "redlist" | "blacklist" | "sandbox_not_block_command" | ...,
  run_mode: "auto" | "manual" | "allowlist" | ...,
  now_run_mode: "in_sandbox" | "out_sandbox" | ...
}
```
**生命周期**: 服务端 SSE → DG.parse(~7318521) → PlanItemStreamParser(~7502500) → Store(~3211326) → React(~8635000)

### RunningStatus 枚举

**位置**: ~46816

| 值 | 图标 | 含义 |
|----|------|------|
| WaitingInput | ↑ ArrowUp | 空闲 |
| Running | ⏹ stop-circle | AI正在生成 |
| Sending | 🔄 Spinning | 消息已等待首token |
| Pending | — | 等待中 |
| Disabled | — | 禁用 |

---

## 17 个 Alert 渲染点完整列表

**位置**: ~8700000-8930000 | **组件**: ErrorMessageWithActions

| # | 位置 | 错误码 | 类型 | 已覆盖? |
|---|------|--------|------|---------|
| 1 | ~8700219 | ENTERPRISE_QUOTA_CONFIG_INVALID | warning | ❌ |
| 2 | ~8701000 | MODEL_PREMIUM_EXHAUSTED | warning | ❌ |
| 3 | ~8701454 | PAYMENT_METHOD_INVALID | warning | ❌ |
| 4 | ~8701681 | INTERNAL_USAGE_LIMIT | warning | ❌ |
| 5 | ~8702300 | if(V&&J) 可继续错误 | warning | ✅ |
| 6 | ~8702410 | RISK_REQUEST_V2 | error/warning | ❌ |
| 7 | ~8703141 | CONTENT_SECURITY_BLOCKED | warning | ❌ |
| 8 | ~8703913 | FREE_ACTIVITY_QUOTA_EXHAUSTED | warning | ❌ |
| 9 | ~8704548 | CAN_NOT_USE_SOLO_AGENT | warning | ❌ |
| 10 | ~8705020 | CLAUDE_MODEL_FORBIDDEN | error | ❌ |
| 11 | ~8705534 | REPO_LEVEL_MODEL_UNAVAILABLE | warning | ❌ |
| 12 | ~8705889 | FIREWALL_BLOCKED | error | ❌ |
| 13 | ~8706759 | EXTERNAL_LLM_REQUEST_FAILED | error | ❌ |
| 14 | ~8707685 | PREMIUM_USAGE_LIMIT | error | ❌ |
| 15 | ~8708073 | STANDARD_MODE_USAGE_LIMIT | error | ❌ |
| 16 | ~8708463 | INVALID_TOOL_CALL | error | ❌ |
| 17 | ~8709130 | TOOL_CALL_RETRY_LIMIT | error | ❌ |

---

## 重要教训（精简版）

### resumeChat vs sendChatMessage

`D.resumeChat()` = 服务端级别恢复（✅ 正确）。`D.sendChatMessage({message:"Continue"})` = 创建新轮次（❌ 服务端不识别为续接 → 空响应 → Cancel）。

### queueMicrotask 替代 setTimeout

React render path 中的 `setTimeout(fn, 500)` 有三大缺陷：重复定时器、闭包捕获过期值、cleanup 竞速（stopStreaming 在 10-50ms 后清理 session，远早于 500ms）。用 `queueMicrotask(fn)` 替代 — 当前渲染微任务完成后立即执行。

### v7-debug 日志三大发现

1. **queueMicrotask 确实触发了**（推翻 v5 的 cleanup 杀死假设）
2. **resumeChat 是 no-op** — 被调用但不抛异常也完全无效（v3-v6 全部基于错误假设）
3. **React 重渲染风暴** — if(V&J) 在 <1 秒内被进入 10+ 次，每次触发新的 resumeChat

### 必须用箭头函数

`.catch(e=>{...})` 而非 `.catch(function(e){...})`。后者严格模式下 this=undefined → TypeError → React 组件树崩溃 → 聊天窗口消失。（v5 历史教训）

### find_original 匹配失败诊断

fuzzy match 成功 + exact match 失败 = 微小差异（可能仅 2 字符互换如 `}` 和 `)`）。必须逐字符对比。find_original 必须同步于当前文件状态（上次应用后的内容），而非最初原始代码。

### Trae 更新注意事项

terser/webpack 重新打包导致变量重命名（非确定性！）：`efh`→`efg`, `P8`→`P7`。不能硬编码变量名。文件大小也可能变化（10.73MB→10.24MB）。

### 脏备份残留

回滚到包含旧版补丁的备份后，apply-patches 只**追加**不删除旧代码。结果：多个 provideUserResponse 调用（有过滤+无过滤混合）。修复：使用干净备份。

---

# 🔍 知识索引

## 表 1: 函数/API

| API | 行为 | 关键点 |
|-----|------|--------|
| `PlanItemStreamParser._handlePlanItem()` | SSE解析核心入口 | 最可靠补丁注入点，切窗口不冻住 |
| `provideUserResponse()` | 主动确认工具调用 | 无单独SSE确认事件，需手动同步status |
| `DG.parse()` | 数据解析层~7318521 | L3最底层拦截，不受React影响 |
| `getRunCommandCardBranch()` | 三元组UI分支决策 | P8只控制按钮样式不控制弹窗 |
| `D.resumeChat()` | 服务端恢复对话 | 循环检测后可能no-op，需fallback |
| `D.sendChatMessage()` | 创建新消息轮次 | 续接场景禁用，仅作fallback |
| `ew.confirm()` | **仅为telemetry打点** | 真正执行是 eE(Ck.Confirmed) |
| `stopStreaming()` | 覆盖status为Canceled | "沉默杀手"，破坏上游Warning状态 |
| `queueMicrotask(fn)` | 微任务调度 | 替代render-path中的setTimeout |

## 表 2: 错误码/现象

| 错误码/现象 | 处理 | 涉及补丁 |
|-------------|------|---------|
| LLM_STOP_DUP_TOOL_CALL (4000009) | J数组→if(V&J)→resumeChat/fallback | bypass-loop-detection |
| LLM_STOP_CONTENT_LOOP (4000012) | 同上+efh列表 | bypass-loop-detection v4 |
| TASK_TURN_EXCEEDED_ERROR (4000002) | J数组→自动续接 | bypass-loop-detection |
| DEFAULT (2000000) | 加入J数组和efh列表防御二次覆盖 | bypass-loop-detection v4 |
| L1 冻结（切走窗口无效） | 用L2/L3补丁替代L1 | v8架构迁移 |
| 聊天界面消失/白屏 | definitions.json不一致+语法错误 | 四层防护架构 |
| resumeChat no-op | 先尝试→监控→fallback三段式 | v8 L2 poller |

## 表 3: 当前补丁状态

| 补丁 | 版本 | 所在层 | 状态 |
|------|------|--------|------|
| auto-confirm-commands | v4 | L2 | ✅ |
| service-layer-runcommand-confirm | v8 | L2 | ✅ |
| data-source-auto-confirm | v3 | L3 | ✅ |
| guard-clause-bypass | v1 | L1 | ✅ |
| **auto-continue-thinking** | **v9** | **L1+L2** | ⚠️ **测试中** |
| auto-continue-thinking | **v7** | **L1** | ✅ **已回滚** |
| efh-resume-list | v3 | L1 | ✅ |
| bypass-loop-detection | v4 | L1 | ✅ |
| bypass-runcommandcard-redlist | v2 | L1 | ⚠️ 仅改样式 |

---

## [2026-04-23 00:45] v8 架构缺陷根因 — "切换窗口后失效"的真正原因 ⭐⭐⭐

**这是本项目最重要的发现之一。** 解释了为什么 auto-continue 从 v3 到 v8 迭代了 6 次，每次都"解决"了但又复发。

### v8 的依赖链（有缺陷的设计）

```
L1 (if(V&&J), React render 内):
  └─ 检测到错误 → 设置 window.__traeSvc = {D, b, M, sid, mid}

L2 (setInterval(3000), 文件末尾 IIFE):
  └─ 读取 window.__traeSvc → 如果存在 → sendChatMessage
```

### 后台窗口场景下的执行流程（v8 失效的完整证据链）

```
1. 用户切到别的窗口
2. Chromium 停止后台标签页的 requestAnimationFrame
3. React Scheduler 暂停 → memo() 不重渲染
4. if(V&&J) **不执行**（它在 React render path 内）
5. window.__traeSvc **从未被设置** ← 关键！
6. L2 轮询器运行（✅ setInterval 不受 rAF 影响）
7. var svc = window.__traeSvc → **undefined**
8. if(!svc) return → **退出，什么都不做**
9. 结果：和 v3-v7 完全一样失效！
```

### 为什么之前没发现

1. **测试时总盯着窗口** — 前台时 L1 正常执行 → __traeSvc 被设置 → L2 也工作 → 误以为 L2 独立有效
2. **v8 的 L2 确实能运行** — setInterval 不受影响，但拿到的是 undefined → 静默失败无报错
3. **焦点在"换触发方式"上** — queueMicrotask → setTimeout → setInterval，一直在改"何时触发"，没意识到问题是"拿不到服务引用"

### v9 解决方案：早捕获 (Early Capture)

**核心改变**: 将 `window.__traeSvc` 捕获从 `if(V&&J)` **内部**移到**外部**。

```javascript
// v8 (有缺陷): 只在错误检测时捕获
if(V&&J){
    if(!window.__traeSvc){window.__traeSvc={D:D,b:b,M:M}}  // ← 后台时不执行!
    ...
}

// v9 (修复): 每次渲染都无条件捕获
if(typeof D!=='undefined'&&D&&typeof b!=='undefined'&&b){
    if(!window.__traeSvc){window.__traeSvc={D:D,b:b,M:M}}  // ← 只要组件渲染就执行!
}else{window.__traeSvc.D=D;...}  // 更新引用（防止 stale）
if(V&&J){...}  // 错误处理逻辑不变
}
```

### v9 的保证

| 场景 | v8 | v9 |
|------|-----|-----|
| 前台触发错误 | ✅ L1执行→__traeSvc设置→L2可用 | ✅ 同上 |
| **后台首次触发错误** | ❌ __traeSvc从未设置→L2空转 | ✅ 前台已设置→L2读取可用 |
| 切走后再切回 | ✅ 但可能重复 | ✅ __taeAC守卫防重复 |
| 组件首次渲染 | 不捕获 | ✅ **立即捕获** |

**关键洞察**: 用户只要看到聊天界面（组件至少渲染一次），`window.__traeSvc` 就被设置了。之后无论是否切走窗口，L2 都能使用。

### 教训：标与本

- **标**: 换触发方式（queueMicrotask→setTimeout→setInterval）— 改了 6 次
- **本**: 服务引用在 React 闭包内，后台无法访问 — **v9 才真正解决**

未来遇到类似问题，先问："这个变量/函数的作用域是什么？在后台能访问到吗？"

## [2026-04-23 02:00] 模块级服务发现 + ast-grep 废弃 ⭐

### PowerShell 子串搜索发现的新模块级服务

在废弃 ast-grep 的对比测试中，PowerShell 子串搜索发现了两个之前未记录的模块级服务引用：

| 服务 | 偏移量 | 说明 |
|------|--------|------|
| `_aiAgentChatService` | **~7500589** | AI Agent 聊天服务，有 `resumeChat` 方法！这是 `D.resumeChat()` 的真正底层实现 |
| `_sessionServiceV2` | **~7776387** | 会话服务 v2，可能有 `getCurrentSession` 等方法 |

**重要**: 这两个服务都在 React 组件闭包**外部**（PlanItemStreamParser 类或模块级），可能不受 L1 冻结影响！需要进一步探索其完整 API。

### 搜索方式决策：ast-grep → PowerShell 子串搜索

详见 [decisions.md](decisions.md) 中 `[2026-04-23 02:00]` 条目。核心结论：

```
ast-grep (sg): 2/5 命中率，函数调用模式全军覆没
PowerShell:   7/7 命中率，还额外发现 2 个未知服务
结论:         永远用 $c.IndexOf("keyword") 搜索
```

---

## [2026-04-23 03:00] "切窗口就失效"全景根因研究 ⭐⭐⭐

### 一、Chromium 后台标签页行为（精确实测）

| Web API | 后台行为 | 对本项目影响 |
|---------|----------|-------------|
| **requestAnimationFrame** | **完全停止** | React 时间片计算降级 |
| **requestIdleCallback** | **完全停止** | 不影响（项目未使用） |
| **setTimeout/setInterval** | **节流到最小1秒** | v8 的 setInterval(3000) 实际变成 ~3s（不受影响，因为 >1s） |
| **MessageChannel** | **完全正常** ✅ | React Scheduler 主调度通道！ |
| **Promise/microtask** | **完全正常** ✅ | queueMicrotask 正常执行 |
| **postMessage (window)** | **完全正常** ✅ | 跨窗口通信可用 |
| **fetch/WebSocket/SSE** | **完全正常** ✅ | 数据接收层不受影响 |
| **Web Worker** | **完全正常** ✅ | 独立线程 |

**关键洞察**: SSE 数据到达 → onmessage 回调触发 → 回调内代码同步执行 → 微任务正常 → **数据层(L3)和服务层(L2)在后台完全工作**。

### 二、React 18 Scheduler 在后台的行为

```
调度链路:
  MessageChannel.postMesage() → onmessage → performWorkUntilDeadline()
    ↓ (不受后台影响 ✅)
  shouldYieldToHost():
    deadline = rAF timestamp (停止 ❌) → fallback setTimeout(100ms → 节流到1s ⚠️)
    ↓
  结论: Scheduler 工作但变慢，不会完全暂停
```

**对 L1 补丁的影响**:
- `setState()` → 正常入队 ✅
- 组件 render 函数中的 `if(V&&J){...}` → **会执行但时序不可预测** ⚠️
- `useEffect` → 会执行但可能延迟 ⚠️
- `memo()` 浅比较 → 正常工作 ✅

### 三、Trae 源码架构突破性发现 🔥🔥🔥

#### 发现 1：全局 DI 容器 `uj.getInstance()`

```
位置: ~6275751 (模块级变量)
类型: 全局单例 DI 容器（类似 InversifyJS）
用法:
  uj.getInstance().resolve(TOKEN)  → 解析服务实例
  uj.getInstance().provide(TOKEN, instance) → 注册服务
快捷方式: hX() = () => uj.getInstance()
```

**这是解决 L1 冻结问题的关键钥匙！**

#### 发现 2：`_sessionServiceV2` — 模块级会话服务（DI token = BR）

```
DI Token: BR (Symbol 或唯一标识符)
注入方式: uX(BR) 装饰器注入到 G6/HT/etJ 等类
获取方式: uj.getInstance().resolve(BR)

方法清单:
  .sendChatMessage({sessionId, message, parsedQuery, multiMedia})  ← 发消息
  .resumeChat({messageId, sessionId})                              ← 续接思考！
  .stopChat(sessionId)                                             ← 停止对话
```

**所有13处使用都在模块级（非React闭包），包括：**
- @7776405: session管理类中 sendChatMessage
- @7789264: session管理类中 resumeChat（用于知识库续接）
- @7839175: workspace facade 中 sendMessage
- @8144926-8146411: KnowledgesTaskService 中 stopChat + resumeChat

#### 发现 3：`_aiAgentChatService` — AI Agent 聊天服务（DI token = Di）

```
DI Token: Di
注入方式: uX(Di) 装饰器注入到 zb/Bs/BP/G6/etz 等类
获取方式: uj.getInstance().resolve(Di)

方法清单:
  .resumeChat({message_id})           ← 底层续接API
  .chat(t, i, r)                      ← 发起新对话
  .appendChat({...})                  ← 追加消息
  .cancel({session_id, user_message_id})
  .getSessions / getSessionMessages / createSession ...
```

**关键发现 @7540953**: `_aiAgentChatService.resumeChat()` 在 SideChatStreamService 中被调用（模块级）。

#### 发现 4：F3/sendToAgentBackground 函数 — 已有的蓝图！

```javascript
// @7610443 — 模块级函数，不在 React 闭包内
async function F3(e, t) {
    let i = uj.getInstance();              // ← 获取 DI 容器
    let r = i.resolve(bY);                 // ← 解析 logger
    
    let {
        sessionService: n,
        agentService: o,
        docsetService: a,
        sessionServiceV2: s,               // ← BR token!
        commandService: l,
        // ...
    } = FX(i);                             // ← 从容器解构服务
    
    // 使用 window 事件监听取消操作
    window.addEventListener(t.cancelEventKey, () => {
        s.stopChat(f.sessionId);            // ← 直接调用模块级服务！
    });
}
```

**这个函数证明了：从模块级通过 DI 容器获取服务并直接调用其方法是 Trae 自己的标准模式。**

#### 发现 5：PlanItemStreamParser 精确位置

```
日志标记: "[PlanItemStreamParser]" @7508858
所在类: Bs 类（~7530948 注入了 _aiAgentChatService）
可访问的服务:
  this._logService     — 日志
  this._taskService    — 任务服务（有 provideUserResponse）
  this.storeService    — Store 服务
运行环境: SSE 回调内（L2 层，不受 React 冻结影响）
```

### 四、完整根因链条（最终版）

```
用户切换窗口
  → Chromium 停止 rAF
    → React Scheduler 时间片精度降级 (5ms → 1s)
      → L1 组件 render 执行延迟/不确定
        → if(V&&J) 条件判断时机错乱
          → D.resumeChat() 未被调用
            → 自动续接失效

但与此同时：
  SSE 数据继续到达 ✅ (不受影响)
  PlanItemStreamParser 继续解析 ✅ (不受影响)
  _sessionServiceV2 存在于模块级 ✅ (不受影响)
  uj.getInstance().resolve(BR) 可随时调用 ✅ (不受影响)
  
结论: 问题不是"后台不能执行代码"，而是"L1补丁放在了错误的位置"
```

### 五、解决方向评估

| 方向 | 描述 | 可行性 | 复杂度 | 安全性 | 兼容性 | 推荐度 |
|------|------|--------|--------|--------|--------|--------|
| **A. L2 服务层补丁** | 在 PlanItemStreamParser 中用 DI 容器获取 sessionServiceV2 | **极高** | **极低** | **极高** | 中高 | ⭐⭐⭐ **首选** |
| B. Zustand Store 直接触发 | 从 store 触发 action | 中 | 高 | 中 | 低 | ❌ |
| C. Web Worker | Worker 内轮询检测 | 极低 | 极高 | 高 | 低 | ❌ |
| D. visibilitychange 事件 | 切回窗口时触发续接 | 中 | 低 | 高 | 高 | ⭐ 备选 |
| E. startTransition | 标记为低优先级更新 | 低 | 低 | 中 | 中 | ❌ |
| F. postMessage 自定义事件 | L1→L2 事件桥接 | 低 | 中 | 高 | 中 | ❌ |
| **G. DI 容器解析 (新)** | uj.getInstance().resolve(BR) + resumeChat/sendChatMessage | **极高** | **极低** | **极高** | 中高 | ⭐⭐⭐ **=A** |

**Direction A/G（合二为一）的具体方案**:

```javascript
// 在 PlanItemStreamParser 的 confirm_status 检查或 error handler 中:
if (需要自动续接的条件) {
    try {
        let svc = uj.getInstance().resolve(BR);  // 获取 sessionServiceV2
        await svc.resumeChat({
            messageId: lastMessageId,
            sessionId: this.currentSessionId || t.sessionId
        });
        this._logService("[auto-continue-bg] resumed via DI container");
    } catch(err) {
        this._logService.warn("[auto-continue-bg] DI resolve failed:", err);
    }
}
```

**优势**:
1. 运行在 L2（SSE 回调）— 完全不受 React 冻结影响 ✅
2. 使用 Trae 自身的 DI 系统 — 与现有代码模式一致 ✅
3. 无 IIFE 注入 — 不会导致白屏 ✅
4. 无 window 变量 hack — 干净整洁 ✅
5. 代码量极少（3-5行）— find_original 长度不变 ✅

**风险**:
1. DI token `BR` 可能随 Trae 更新而改名（中等风险，可通过搜索 `_sessionServiceV2` 定位新 token）
2. `resumeChat` 参数格式可能变化（低风险，与现有调用保持一致即可）
3. 需要确认 PlanItemStreamParser 内能访问到 sessionId/messageId

---

## [2026-04-23 03:20] v10 实施过程中的关键发现 ⭐⭐

### 发现 1：错误码是数字枚举，不是字符串！

```
枚举变量: kg (模块级)
格式: kg.XXX = 数字值
e.code 返回数字，不是字符串

关键错误码数值:
  kg.TASK_TURN_EXCEEDED_ERROR  = 4000002  (思考次数上限)
  kg.LLM_STOP_DUP_TOOL_CALL    = 4000009  (循环检测-重复工具调用)
  kg.LLM_STOP_CONTENT_LOOP     = 4000012  (循环检测-内容循环)
  kg.DEFAULT                   = 2000000  (未知错误兜底)
  kg.MODEL_OUTPUT_TOO_LONG     = 987      (输出过长)
  kg.PREMIUM_MODE_USAGE_LIMIT  = 4008     (高级模式用量限制)
  kg.MODEL_PREMIUM_QUOTA_DRAINED = 977    (高级模型配额耗尽)
  kg.CLAUDE_MODEL_FORBIDDEN    = 4113     (Claude模型禁止)
  kg.INVALID_TOOL_CALL         = 4027     (无效工具调用)
```

**教训**: 之前 spec 中写的 `["MODEL_PREMIUM_EXHAUSTED","CLAUDE_MODEL_FORBIDDEN",...]` 字符串白名单完全错误！`MODEL_PREMIUM_EXHAUSTED` 在源码中根本不存在。必须用数字值。

### [2026-04-23 04:00] v10 测试失败根因 — SSE 事件的两条路径 ⭐⭐⭐

**这是本项目最重要的架构发现之一！**

```
SSE 流数据到达后，有两条完全不同的处理路径:

路径1: 正常消息事件 (onMessage) ← 思考上限走这里！
  SSE data → onMessage(e, t) → Br.register(Ot.Error, zF)
  → ErrorStreamParser(zU).parse(e, t)  ← e.code = 业务错误码(4000002等)
  → handleSteamingResult(e, t)
  → handleSideChat(e, t) → storeService.updateMessage()
  → React re-render → if(V&&J) → L1 续接

路径2: 连接断开 (_onError) ← v10补丁错误地放在这里！
  SSE connection error → _onError(e, t, i)
  → e.code = 1006 (CONNECTION_ERROR)
  → 不含业务错误码！
  → 只是日志记录 + 流停止处理
```

**实测证据**（日志 vscode-app-1776888145215.log）:
- 行3336: `_onError @ index.js:3861` — 确认被调用
- 但 `[ChatStreamService] _onError sessionId` 日志没出现 → `1006!==e.code` 为 false → **e.code = 1006**
- `[v10-bg]` 日志也没出现 → 补丁代码在 `1006!==e.code` 之后，被跳过

**关键教训**:
1. **`_onError` 只处理 SSE 连接级别的错误**（网络断开、超时等），不处理业务错误码
2. **业务错误码（思考上限、循环检测等）通过 SSE 正常消息流传递**，走 `onMessage → Ot.Error → parse` 路径
3. **L2 补丁必须放在 `parse` 方法中**，不是 `_onError` 中
4. **`check_fingerprint` 冲突**: 旧补丁和新补丁共用 `[v10-bg]` 指纹，导致 apply-patches 误判为已应用

**修正**: v10 L2 补丁从 `_onError`(Bs类@7528742) 移到 `parse`(zU类@7513080)

### ErrorStreamParser (zU) 类完整结构

```
位置: @7513080 (parse方法)
DI token: zF = Symbol.for("IErrorStreamParser")
继承: zU extends DV

方法:
  parse(e, t) — 解析错误事件，e.code=业务错误码
  handleSteamingResult(e, t) — 分发到 Inline/Side 处理
  handleSideChat(e, t) — 更新 Store 消息
  handleInlineError(e, t) — Inline 聊天错误处理

DI 注入:
  this._aiChatRequestErrorService (uX(D5))
  this._logService (uX(bY))
  this.chatStreamFrontResponseReporter
  this.storeService
  this._inlineChatStore

注意: zU 类没有 this._aiAgentChatService!
需要通过 uj.getInstance().resolve(Di) 获取

### [2026-04-23 05:00] v10 第二次测试失败 — 思考上限错误不走 SSE 路径！⭐⭐⭐

**这是本项目最关键的架构发现——推翻了之前所有 L2 补丁位置的假设！**

#### 完整错误传播链路（从日志 vscode-app-1776902776348.log 确认）

```
时序图 (用户全程切走窗口):

T1: AI 开始回复 (前台)
  → teaEventChatShown + teaEventChatShownWhenFirstToken
  → handleSteamingResult (SSE正常消息)

T2: 用户切走窗口 (后台)
  → (AI 继续思考，SSE 数据继续到达...)

T3: 思考次数达到上限 (后台!)
  → workbench.desktop.main.js:38  ERR exceeded maximum number of turns
    → GZt.create() 在主进程中创建错误对象
    → YTr.drain/enqueueData/emit (主进程事件总线)
    → POST mcs.zijieapi.com... ERR_CONNECTION_RESET (网络断开!)

T4: 渲染进程收到通知 (后台)
  → teaEventChatFail ×2 (@7199-7200) ← 思考上限的真正入口!
  → _onError @ index.js:3861 (@7202) ← SSE连接断开(e.code=1006)
  → [v10-bg] 没有出现! ← parse方法没被调用或e.code不匹配

T5: 用户切回窗口
  → React Scheduler 恢复正常
  → Store 状态更新触发 re-render
  → if(V&&J) 条件满足
  → [v7] triggering auto-continue (@7420) ← L1续接触发!
```

#### 核心发现：两条完全独立的错误路径

**路径 A: 思考上限错误（我们关心的）**
```
主进程 GZt.create("exceeded maximum number of turns")
  → 主进程 YTr 事件总线
    → teaEventChatFail 事件 (渲染进程)
      → 更新 Store/State
        → React re-render (切回窗口后才执行!)
          → if(V&&J) → L1续接
```
**特点**: 不经过 SSE 的 Ot.Error 事件! 不经过 ErrorStreamParser.parse()!
`_onError` 只是巧合地在同一时间被 SSE 连接断开触发的!

**路径 B: SSE 连接断开错误（之前误判为路径A）**
```
Chromium 后台节流 → SSE 连接断开 (ERR_CONNECTION_RESET, e.code=1006)
  → Bs._onError(e, !0, u)
    → BP.onError(e, true, i)
      → 1006!==e.code → false → 跳过 teaEventChatFail
      → t && eventHandlerFactory.handle(Ot.Error, e, r) ← 这里才调用parse()
        → ErrorStreamParser.parse(e, t) ← 但 e.code=1006不在白名单!
```

#### BP.onError 的关键代码 (@7542473, @7546037)

```javascript
onError(e, t, i) {
  let {context: r} = i;
  // 只有 e.code != 1006 时才上报
  1006 !== e.code && this.chatStreamBizReporter.teaEventChatFail(e, r),
  // 有 code 时处理通用错误
  e.code && this._aiChatRequestErrorService.handleCommonError(e.code, e.data),
  // ★★★ 只在 t=true 时才分发到 eventHandlerFactory!
  t && this.eventHandlerFactory.handle(Ot.Error, e, r),   // @7542473
  // ...
}
```

**结论**: `eventHandlerFactory.handle(Ot.Error)` → `ErrorStreamParser.parse()` 只在 `t=true` 且 `e.code != 1006` 时才会被有意义地调用。而思考上限错误根本不经过这条路！

#### 为什么 L1 补丁在后台不工作

L1 补丁 (`if(V&&J)`) 在 React render 函数中:
1. 思考上限错误到达 → teaEventChatFail → Store 更新 ✅ (后台可执行)
2. React setState 入队 ✅ (后台可执行)
3. **但 React re-render 在后台被延迟/不确定** ⚠️ (Scheduler 时间片降级到1s)
4. **if(V&&J) 判断时机不可预测** ⚠️
5. 切回窗口 → React 立即 re-render → if(V&&J) 满足 → L1续接 ✅

#### 最终结论

**L2 补丁无法拦截"思考上限"错误，因为这个错误不经过任何 L2 层的代码路径。**

它从主进程直接通过 IPC/事件机制到达渲染进程的 Store/State 层，然后依赖 React re-render 触发 UI 更新。

可行的方案只剩:
1. **Direction D: visibilitychange 事件** — 切回窗口时立即检查+续接(简单可靠)
2. **Store 订阅/中间件** — 拦截 Store 中 thinking status 变化(复杂但真正的后台执行)
3. **主进程补丁** — 修改 workbench.desktop.main.js(不在本项目范围内)
```

### 发现 2：`class Bs` = ChatStreamService（不是 PlanItemStreamParser！）

```
位置: @7524723
完整名: class Bs extends bV.Disposable
实际功能: ChatStreamService — SSE 流的核心管理类

关键方法:
  chatStream(e)           — 发起聊天流 (@7524723)
  createStream(e)         — 创建流，含 resumeChat 蓝图 (@7540700)
  _onError(e,t,i)         — SSE 错误回调 (@7528742) ← v10 补丁位置
  _onMessage(e,t)         — SSE 消息回调
  _onCancel(e)            — SSE 取消回调
  _onComplete(e)          — SSE 完成回调
  _onStreamingStop(e)     — 流停止统一处理
  _stopStreaming(e)       — 停止流（取消请求）

DI 注入的服务:
  this._aiAgentChatService  (DI token=Di) — AI聊天服务，有 resumeChat()
  this._logService          — 日志服务
  this.storeService         — Store 服务
  this._taskService         — 任务服务
  this.eventHandlerFactory  — 事件处理器工厂
```

### 发现 3：`createStream` 中已有 resumeChat 蓝图

```javascript
// @7540933 — Bs 类中已有的续接逻辑
async createStream(e){
  let{requestObject:t,chatType:i,agentMessage:r,aiClient:n,terminalInfo:o}=e;
  return "resume"===i
    ? await this._aiAgentChatService.resumeChat({...t,message_id:r.agentMessageId})
    : await this._aiAgentChatService.chat(t,n,o)
}
```

**意义**: `this._aiAgentChatService.resumeChat({message_id: xxx})` 是 Trae 自己的续接调用模式。v10 补丁直接复用此模式，无需 `uj.getInstance().resolve()`。

### 发现 4：`_onError` 回调参数结构

```
_onError(e, t, i):
  e = 错误对象 {code: number, data: any, message: string}
  t = boolean (是否为 SSE 流错误，true=流错误, false=其他错误)
  i = stream context {sessionId, agentMessageId, context, ...}

调用处 (@7526672):
  this._onError(e, !0, u)  — SSE 流错误
  this._onError(e, !1, u)  — catch 中的异常

i.agentMessageId 可用性: ✅ 确认存在（Bs 类中22处使用）
fallback: i.context?.agentMessageId
```

### 发现 5：`kg` 枚举在 Bs 类中不可直接访问

```
Bs 类区域 (7520000-7560000) 中 kg. 的使用次数: 0
但同文件其他位置有使用（如 @7513091: e.code===kg.MODEL_RESPONSE_TIMEOUT_ERROR）

结论: kg 是模块级变量，理论上可在 Bs 类中访问
但为了补丁安全性，v10 使用数字字面量而非 kg.XXX 引用
好处: 不依赖 kg 变量名，Trae 更新后更稳定
```

### 发现 6：v10 最终方案 — 无需 DI 容器 resolve

研究阶段推荐的 `uj.getInstance().resolve(BR)` 方案在实际实施中被简化：
- Bs 类已经通过 DI 注入了 `this._aiAgentChatService`
- 直接用 `this._aiAgentChatService.resumeChat()` 即可
- 无需额外的 `uj.getInstance().resolve()` 调用
- 更简洁、更安全、更符合 Trae 自身代码模式

### [2026-04-23 08:35] v11 根因确认: React Scheduler 后台冻结 + store.subscribe 解决方案 ⭐⭐⭐

**问题**: v7/v10 auto-continu 在后台窗口不触发，切回后才执行。

**根因**: `if(V&&J)` 代码位于 **sX().memo() (React.memo) 子组件的 render body** 中 (offset 8709284)，依赖 React Scheduler 调度 re-render。后台 tab 中 React 将渲染节流到 ~1s 或完全不执行。

**完整数据流**:
```
主进程 GZt.create("exceeded max turns") → IPC → Zustand Store更新(currentSession.messages[last].exception={code:4000002})
  → store.subscribe() 回调 ✅ 立即执行
  → React useStore → scheduleReRender ❌ 后台冻结
        → sX().memo() → if(V&J) ❌ 不执行
```

**组件结构** (offset ~8709284):
- 父组件: D=uB(BR)=_sessionServiceV2, G=N.useStore(e=>e.currentSession)
- sX().memo(Jj): JP.Sz选择器提取 status/exception/agentMessageId/sessionId
- **`_` (错误码) = (JP.Sz(Jj,e=>e.exception)||efp).code** — 来自消息对象的exception字段!
- V=G?.messages?[last]?.agentMessageId===o, J=!![TASK_TURN_EXCEEDED_ERROR,...].includes(_)

**三个成功案例对比**:
| 补丁 | 层 | 位置 | 为什么能后台工作 |
|------|-----|------|----------------|
| 命令确认 | L2 | PlanItemStreamParser._onMessage | SSE回调，不受React影响 |
| DG.parse | L3 | DG.parse() | 数据修改层，React前拦截 |
| 沙箱useMemo | L1 | useMemo同步计算 | 同步执行路径 |
| v7/v10 | L1 | sX().memo() render body | ❌ React Scheduler冻结 |

**解决方案 v11**: store.subscribe() 模块级监听
- 注入点: offset ~7588590 (async function FR() 末尾, subscribe #8 旁边)
- 模式: 完全绕过React, 用Zustand MessageChannel通知
- 变量: n=store(从e.resolve(xC)), uj=DI容器, BR=_sessionServiceV2 DI token
- 参考: subscribe #8 已有 `n.subscribe((e,t)=>{...currentSession.messages.length...})` 先例

**关键代码位置**:
- subscribe #8: offset 7588518, `n.subscribe((e,t)=>{((e.currentSession?.messages?.length??0)!==(t.currentSession?.messages?.length??0)||e.currentSessionId!==t.currentSessionId)&&a()})`
- v11注入: offset 7588639, find_original以 `d!==t.currentSessionId)&&a()})}async function FP(e)` 结尾
- sX().memo(): offset ~8707000, 包含全部JP.Sz选择器和V/J计算
- efc函数: offset 8701488, 返回{hub,errorInfo,chatConfirmPopUp} from commercial activity config

### [2026-04-23 09:00] v11.1 Bug修复 — Zustand subscribe 参数顺序反了 ⭐⭐

**症状**: v11 注入成功(node --check通过, fingerprint存在), 但 `[v11-bg]` 日志完全不出现。

**根因**: Zustand `store.subscribe((state, prevState) => {})` 的参数顺序理解错误。
- 第1个参数 `_p` = state = **NEW/CURRENT** 状态 (包含新错误消息)
- 第2个参数 `_c` = prevState = **OLD/PREV** 状态 (无错误)

**Bug代码**:
```javascript
// 错误: _m取了prevState, _o取了currentState
var _m=_c?.currentSession?.messages||[],  // OLD messages
    _o=_p?.currentSession?.messages||[];   // NEW messages  
if(_m.length<=_o.length)return;  // 只在消息减少时触发! 完全反了!
```

**修复后**:
```javascript
// 正确: _m取currentState(新), _o取prevState(旧)
var _m=_p?.currentSession?.messages||[],  // NEW messages (有新错误)
    _o=_c?.currentSession?.messages||[];   // OLD messages
if(_m.length<=_o.length)return;  // 无新消息时跳过 ✅
// 用 _m[last] 检查新消息的错误码 ✅
// sessionId 从 _p.currentSession 获取 ✅
```

**次要发现**: "store.subscribe installed" 日志未出现 — FR() 在启动早期执行，可能在日志捕获前完成。这不影响功能(subscribe已安装), 只是调试日志缺失。

**经验教训**: 写 subscribe 回调时必须明确标注 `(curr, prev)` 参数含义!

### [2026-04-23 10:00] v11.2 诊断结果 — Zustand 浅比较 + 属性变异 ⭐⭐⭐

**诊断日志决定性证据** (vscode-app-1776921117541.log):
```
[v11-diag] CALLBACK FIRED! {"p_msgs":1,"c_msgs":0}     ← store.subscribe 回调在后台确实触发了!
[v11-diag] lastNew msg: 69e9a0b1
[v11-diag]   exception: undefined                        ← 🔴 但 exception 是 undefined!
[v11-diag]   status: completed                            ← 状态是 completed
[v11-diag] checking error code: undefined whitelist: -1   ← code=undefined, 不在白名单
[v11-diag] SKIP: code not in whitelist                   ← 跳过!
```

**时间线**:
```
行29766: v11-diag → status=completed, exception=undefined → SKIP
行29767: exceeded maximum number of turns (主进程报错!)
行29915: [v7] triggering auto-continue ← 用户切回窗口后触发!
```

**根因**: 思考上限错误通过**修改已有消息对象的属性**(mutation)写入Store:
```
① 流结束: messages=[{status:"completed", exception:undefined}]
   → 数组引用变化 → subscribe ✅ 触发 → v11看到exception=undefined → SKIP ✗

② 错误到达: messages[0].exception = {code:4000002}  ← 属性变异!
   → 数组引用不变! Zustand浅比较认为"无变化" → subscribe ❌ 不再通知!

③ 用户切回: React直接读Store当前值 → exception.code=4000002 → J=true → v7✅
```

**v7的J从哪来的?**:
- J = !![TASK_TURN_EXCEEDED_ERROR,...].includes(_)
- _ = (JP.Sz(Jj,e=>e.exception)||efp).code
- 当React re-render时直接读Store最新值(不是subscribe回调), 此时exception已填充
- 所以J=true, V=true → if(V&J)触发resumeChat

**修复方案(v11.3)**: setInterval轮询替代store.subscribe
- 每2秒调用 n.getState().currentSession?.messages[last]?.exception?.code
- 同步读取Store最新状态, 不依赖Zustand通知机制
- 与沙箱问题(useMemo)同款模式: 后台同步读取有效

### [2026-04-23 11:00] v11.4 MessageChannel轮询 — 绕过Chromium后台节流 ⭐⭐⭐

**v11.3(setInterval)测试结果** (vscode-app-1776927977865.log):
- [v11-bg] POLL detected error 4000002 ✅ 检测到了!
- 但 v11 和 v7 只差3行日志 → 说明都是在切回窗口后才触发
- **根因: Chromium 后台 tab 将 setInterval 节流到可能1分钟+**
- 我们的2000ms间隔在后台被严重延迟

**修复方案(v11.4)**: MessageChannel + setTimeout 组合
- MessageChannel.postMessage 基于 IPC 机制, **不受后台节流影响**
- 这与 Zustand 内部使用的通知机制完全相同
- 架构:
  ```
  IIFE启动 → _mc.port2.postMessage("") → port1.onmessage → _v11poll()
                                                    ↓
                                             检测 n.getState() 错误码
                                                    ↓
                                        成功? → clearInterval等效(不再_sched) → resumeChat
                                        失败? → _sched() → 新MC → setTimeout(2000) → postMessage → 循环
  ```

**注入技术要点**:
- 位置: async function FR() 末尾 (offset ~7588639), 在 subscribe #8 和 FP() 之间
- 花括号平衡: 原始 `})}` = close-subscribe + close-FR, 替换为 `}); }` + MC代码
- 必须用模板字面量(String.raw)避免引号冲突
- fingerprint: [v11.4-bg] MC installed

**完整失败→成功演进链**:
v11.0 store.subscribe → 参数顺序反了(不触发)
v11.2 diagnostic版   → 发现exception=undefined(Zustand浅比较)
v11.3 setInterval    → 检测到但时机不对(后台节流)
v11.4 MessageChannel → 待验证 ✨

### [2026-04-23 12:00] v11.5 模块级注入 — 解决FR()不执行导致零输出 ⭐⭐

**v11.4测试结果** (vscode-app-1776936667064.log):
- [v11.4-bg] 完全零输出 — 连 "MC installed" 都没有
- 代码验证: 文件中 ✅ 存在, node --check ✅ 通过
- **根因推断**: async function FR() 内部卡在 await o() 未执行到我们的代码
  FR()结构: if(FL)return → resolve DI → await o() [可能挂起] → subscribe#8 → [v11代码]
  如果 o() (isPastChatsEnabled检查) 在后台/特定条件下永远不resolve, 后续代码全不会执行

**v11.5修复**: 将MC轮询从FR()内部移至模块级
- 注入位置: async function FR() 定义之前 (offset ~7588017)
- 执行时机: 模块加载时立即执行IIFE (不等任何async函数)
- Store获取: uj.getInstance().resolve(xC).getState() (与FR()内相同DI方式)
- 完全消除对FR()/await o()/FL守卫的依赖

**完整演进链更新**:
v11.0 store.subscribe(参数反了) → 不触发
v11.2 diagnostic(30次回调) → 发现exception=undefined(属性变异)
v11.3 setInterval(检测到了!) → 但与v7同时触发(后台节流)
v11.4 MessageChannel(FR()内) → 零输出(FR没执行完)
v11.5 MessageChannel(模块级) → 待测试 ✨✨

### [2026-04-23 13:00] v11.6 挂钩subscribe #8 — 彻底解决执行位置问题 ⭐⭐⭐

**v11.5零输出的真正根因** (花括号平衡分析):
- 文件起始到v11.5位置: Open=71595, Close=71604, **Delta=-9**
- **v11.5在函数内部9层深度!** 不是真正的模块级!
- 上下文: ...async function FD(){...}let FO=null,FL=!1;; [IIFE定义但外层函数未调用]
- 这也解释了v11.4(FR()内)零输出: FR()卡在await o()

**关键教训**: 在压缩JS中找"模块级"注入点极其困难
- 不能靠视觉判断代码是否在顶层函数内
- 必须用花括号/圆括号计数验证实际嵌套深度
- async function FR(){ 前面的代码可能在完全不同的作用域链中

**v11.6最终方案**: 挂钩到已证明有效的subscribe #8回调
- 位置: n.subscribe((e,t)=>{...}) 回调体末尾 (offset ~7588518)
- 为什么这次应该能工作:
  1. subscribe #8 是Trae原始代码(非我们添加的)
  2. v11.2诊断证明它在后台触发30次回调 ✅
  3. 我们只是在已执行的回调中追加逻辑
  4. 不需要找新的执行位置/不依赖FR()/模块加载时机

**完整演进链(终版)**:
v11.0 store.subscribe(独立新subscribe,参数反了) → 不触发
v11.2 diagnostic(30次回调✅,exception=undefined) → 发现属性变异
v11.3 setInterval(检测到4000002✅, 但与v7同时触发) → 后台节流
v11.4 MC轮询(FR()内) → 零输出(FR未执行完)
v11.5 MC轮询("模块级") → 零输出(实际在函数内9层深)
v11.6 挂钩sub#8(追加到已证明的回调) → 检测到但延迟253行(~30秒,依赖其他状态变化触发)
```

### [2026-04-23 14:00] v12 变异源头追踪 — TaskAgentMessageParser.parse() ⭐⭐⭐⭐⭐

**这是本项目的突破性发现 — 回答了"前面几次是怎么解决的？"**

#### 核心问题回顾

用户提问: "奇怪了, 那前面几次我们是怎么解决的呢? '沙箱问题', '自动确认命令'等等"

**答案: 成功补丁都在数据管道的活跃通道上拦截新数据，而思考上限错误通过属性变异静默写入，没有通知通道。**

#### 成功案例 vs 失败案例 — 根本差异

| 补丁 | 层 | 数据到达方式 | 为什么能后台工作 |
|------|-----|------------|----------------|
| 命令确认 | L2 PlanItemStreamParser | SSE **回调主动推送** confirm_status | 回调不受React冻结 |
| DG.parse | L3 DG.parse() | 解析函数**同步处理**原始响应 | React前拦截 |
| 沙箱useMemo | L1 useMemo | React render**同步计算** | render时立即执行 |
| v7/v10/v11 | L1 sX().memo() render body | **属性变异**(无通知) | ❌ React Scheduler冻结 |

#### 🔥🔥🔥 变异源头找到了！全局唯一的 `.exception=` 赋值

**位置**: `TaskAgentMessageParser.parse()` @ offset **7615777**
**模式**: `h.exception={code:t,message:i.message,data:e.error.data}`
**唯一性**: 全文件仅此1处 `.exception={` 赋值!

#### 完整调用链 (从服务端到Store)

```
服务端返回含 error 的 task-type agent message (SSE data)
  ↓
asyncConvertAgentMessageToAssistantChatMessage(e)  ← 消息路由 (@7618345)
  switch(e.message_type):
    case xa.Task:
      TaskAgentMessageParser.parse(e, t)           ← 🎯 v12 注入点! L2数据层!
        e = 原始服务端响应 {error:{code:4000002,...}, content, ...}
        t = ParserContext {sessionId, sceneLocation, ...}
        
        h = {
          ...i,                                      // base message
          content: r,                                // parsed content
          role: bZ.Assistant,
          userMessageId: e.reply_to_message_id,
          agentTaskContent: {...},
          // ... other fields
        };
        
        if (e.error) {
          let t = e.error.code;                      // ← 错误码 (shadowed!)
          i = this.aiChatRequestErrorService.getErrorInfo(t, {...});
          h.status = "warn" === i.level ? bQ.Warning : bQ.Error;
          h.exception = {code:t, message:i.message, data:e.error.data};  ← 🎯 唯一变异点!
        }
        return h;                                    // ← 返回含exception的消息对象
      ↓
    handleHistoryResult(e, h)                        // 后处理
  ↓
ErrorStreamParser.handleSideChat(h, context)         // 分发
  context.agentMessageId 
    ? storeService.updateMessage(sessionId, agentMessageId, h)  // 写入Store!
    : storeService.updateLastMessage(sessionId, h)
  ↓
Zustand Store 更新 → React re-render → if(V&&J) → v7 L1续接
```

#### 为什么这个位置能工作（与成功案例同款模式）

1. **L2 数据层**: 在消息解析管道中，不在 React render 内
2. **SSE 回调链路触发**: parse() 由 SSE onMessage → eventHandlerFactory.handle(Ot.Error/Error?) 调用
3. **同步执行**: parse() 是同步函数，不依赖 async/await
4. **错误码直接可用**: `t` (shadowed) = `e.error.code` 精确的错误码数字
5. **queueMicrotask 延迟**: resumeChat 通过 queueMicrotask 延迟到 store update 完成后执行

#### v12 设计：检测 + 延迟执行

```javascript
// 在 h.exception={...} 之后注入:
if(t===4000002||t===4000009||t===4000012||t===987){
  var _n=Date.now();
  if(!window.__traeAC12||_n-window.__traeAC12>5000){
    window.__traeAC12=_n;
    console.log("[v12-bg]",t);
    queueMicrotask(function(){
      // 此时 Store 已更新完成, 可以读取 agentMessageId
      var _s=uj.getInstance().resolve(xC).getState(),
          _cs=_s.currentSession,
          _m=_cs?.messages;
      if(_m&&_m.length){
        var _last=_m[_m.length-1];
        if(_last?.agentMessageId&&_cs?.sessionId){
          uj.getInstance().resolve(BR).resumeChat({
            messageId:_last.agentMessageId,
            sessionId:_cs.sessionId
          });
          console.log("[v12-bg] OK")
        }
      }
    })
  }
}
```

**queueMicrotask 的作用**: parse()返回后→handleHistoryResult()→handleSideChat()→updateMessage()→Store更新, 全部在当前同步执行栈中完成。queueMicrotask 将 resumeChat 推到下一个微任务队列, 确保 Store 中已有完整的消息(含agentMessageId)。

#### TaskAgentMessageParser 类结构

```
位置: ~7614800-7619000 区域
DI 注入:
  this.aiChatRequestErrorService   (注意: 无下划线前缀!)
  this.agentService
  this.logService
  this.storageFacade
  this.feeUsageParser
  this.notificationParser
  this.planItemParser
  
方法:
  parse(e, t)                          ← 🎯 v12 注入点
  handleHistoryResult(e, t)            // 后处理
  parseTaskContent(e)                  // 任务内容解析
  parseProposal(e)                     // 提案解析
```

**与 Bs(ChatStreamService) 的区别**: Bs 用 `this._aiChatRequestErrorService`(有下划线), TaskAgentMessageParser 用 `this.aiChatRequestErrorService`(无下划线)。这是两个不同的类实例!

#### teaEventChatFail 调用链完整映射

从日志已知 teaEventChatFail 在 index.js:3861 被调用。完整路径:
1. **定义**: @7458678 — `teaEventChatFail(e,t,i)` 方法体, 参数: errorObj, userMsgId, session
2. **调用点1**: @7505837 — `this._codeCompEventService.teaEventChatFail(t.userMessageId, i, e)`
3. **调用点2**: @7505954 — 类似 #1
4. **调用点3**: @7542473 — Bs.onError: `this.chatStreamBizReporter.teaEventChatFail(e,r)`
5. **调用点4**: @7546037 — 另一个 onError 方法类似 #3

**handleCommonError** (@7300455): 定义在 `_aiChatRequestErrorService` 中, 处理特殊错误码(ABNORMAL_ACCOUNT_LOGOUT等), 被 Bs.onError 调用。

#### 关键变量可用性 (v12 注入点)

| 变量 | 类型 | 来源 | 可用性 |
|------|------|------|--------|
| t (shadowed) | number | let t=e.error.code | ✅ 错误码 4000002/4000009/4000012/987 |
| h | object | 构建中的消息对象 | ✅ 含 exception 字段 |
| e | object | 原始SSE响应数据 | ✅ e.reply_to_message_id 等 |
| uj | DI container | 模块级全局 | ✅ 始终可用 |
| BR | DI token | 模块级常量 | ✅ _sessionServiceV2 |
| xC | DI token | 模块级常量 | ✅ Zustand store |
| agentMessageId | string | ❌ 不在此作用域 | ⚠️ 通过 queueMicrotask + Store 读取 |
| sessionId | string | t.sessionId (被shadow!) | ⚠️ 同上, 通过 Store 读取 |

**注意**: parse()的第2个参数名也是 `t`, 在 if(e.error) 内部被 `let t=e.error.code` 遮蔽(shadow)。所以不能用 `t.sessionId` 获取 sessionId, 必须通过 Store 读取。

### [2026-04-23 14:30] v12 测试失败 — TaskAgentMessageParser.parse() 不被调用! ⭐⭐⭐⭐

**测试日志** (vscode-app-1776957837393.log):
```
行7278: ERR exceeded maximum number of turns     ← 错误发生
行7345: teaEventChatFail ×2                      ← 67行后!
   ... (无 handleSideChat, 无 updateMessage, 无 .exception 相关日志) ...
行7428: [Debug] currentSession                   ← 某状态变化
行7429: [v11.6-bg] sub#8 error 4000002            ← 84行后(还是v11.6!)
行7431: [v7] triggering auto-continue
```

**关键证据**: `[v12-bg]` 完全零输出！TaskAgentMessageParser.parse() 根本没被思考上限错误调用！

#### 全文件 exception 写入模式穷举搜索

搜索了所有可能的写入模式:
| 模式 | 出现次数 | 位置 | 是否为思考上限路径? |
|------|---------|------|-------------------|
| `.exception=` (直接赋值) | **1** | @7615778 TaskAgentMessageParser.parse() | ❌ 不走这条路 |
| `exception:` (对象字面量) | **3** | @7513727 ErrorStreamParser.parse(), @7881275, @8707548 | ❌ parse()也不被调用 |
| `setErrorInfo` / `setException` / `withError` | **0** | — | N/A |
| immer `produce()` 中写 exception | **0** | — | N/A |
| `updateMessage(` 带 exception | 间接(通过展开) | 多处 | 可能,但updateMessage的参数来自外部 |

#### 🔴 根本结论：exception 不在 index.js 中通过任何显式赋值写入！

**真正的变异机制**（推断）:
```
主进程 workbench.desktop.main.js:
  GZt.create("exceeded maximum number of turns")
    → 构造完整消息对象 {...message, exception: {code: 4000002, ...}}
      → IPC (postMessage/bridge) → 渲染进程
        → 某处接收 IPC 消息
          → storeService.updateMessage(sessionId, msgId, ipcMessage)  // exception 已在对象中!
            → setCurrentSession({...session, messages: [...]})
              → Store 更新完成
                → teaEventChatFail(e, t, {code: 4000002, ...})  // 上报统计
```

**exception 是在主进程中构造好的，随 IPC 消息一起到达渲染进程。index.js 只是"转发"整个消息对象到 Store，不单独操作 exception 字段。**

### [2026-04-23 14:45] v13 方案 — hook teaEventChatFail + queueMicrotask 轮询 ⭐⭐⭐⭐⭐

**核心洞察**: 既然无法拦截变异源头（在主进程/index.js外），那就hook**最早的已知触发点**。

#### 为什么选 teaEventChatFail?

1. **时机最早**: 日志显示错误发生后仅 67 行就触发了（vs v11.6 的 253 行 / ~30 秒）
2. **携带错误码**: 第 3 参数 `i` = `{code: 4000002, message: "...", level: "..."}`
3. **后台可执行**: 从日志确认它在后台 tab 中正常执行
4. **定义清晰**: offset 7458679, 签名稳定

```javascript
// teaEventChatFail 定义 (@7458679):
teaEventChatFail(e, t, i){
    // e = turnId?, t = userMessageId?
    // i = {code: 4000002, message: "exceeded...", level: "error"}
    let r = this.getAssistantMessageReportParamsByTurnId(e, t);
    this._teaService.event(i4.CodeCompStep.fail, {
        ...r,
        error_code: i.code,       // ← 我们要的就是这个!
        error_message: i.message,
        error_level: i.level,
        ...
    })
}
```

#### v13 设计

```
teaEventChatFail 触发
  ↓
检测 i.code ∈ [4000002, 4000009, 4000012, 987] ?
  ↓ Yes
启动 queueMicrotask 轮询循环 (最多3秒/约100次)
  ↓ 每次 microtask:
读取 uj.getInstance().resolve(xC).getState().currentSession.messages[last]
  ↓
messages[last].exception?.code 匹配?
  ↓ Yes (Store已更新!)
uj.getInstance().resolve(BR).resumeChat({messageId, sessionId})
console.log("[v13-bg] OK") ✅
  ↓ No 且未超时
继续 _poll13() (下一个 queueMicrotask)
  ↓ 超时
console.log("[v13-bg] timeout")
```

**queueMicrotask vs setInterval 优势**:
- queueMicrotask 基于 Promise microtask queue，**不受 Chromium 后台节流影响**
- 每次事件循环迭代至少执行一次 microtask
- 比 MessageChannel 更简单（不需要 port1/port2）

#### 注入详情

- **位置**: teaEventChatFail 方法体开头, `{` 之后, `let r=...` 之前
- **find_original**: `teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)`
- **fingerprint**: `[v13-bg]` at offset ~7458876
- **可用变量**: `i`(错误码), `uj`(DI容器), `BR`(sessionServiceV2 token), `xC`(store token)
- **不可用变量**: `agentMessageId`, `sessionId` — 通过 queueMicrotask 内读取 Store 获取

### [2026-04-23 15:00] v13 测试结果 — 后台触发成功但 Store 轮询超时! ⭐⭐⭐⭐⭐

**测试日志** (vscode-app-1776960852907.log) — **历史性突破!**
```
行7121: [v13-bg] teaEventChatFail 4000002    ← 🎉🎉🎉 在后台触发了!!!
行7122: [v13-bg] timeout                    ← 轮询3秒超时(Store中没有exception!)
行7123: ERR exceeded maximum number of turns  ← 错误在v13之后才发生?!
行7190: teaEventChatFail @ index.js:3861     ← Trae原始的(第二次调用)
行7309: [v11.6-bg] sub#8 error 4000002       ← 切回窗口后
行7311: [v7] triggering auto-continue
```

#### 三个关键发现

**发现 1: teaEventChatFail 被调用两次!**

| 调用 | 行号 | 来源 | i.code | Store 状态 | 我们的处理 |
|------|------|------|--------|-----------|-----------|
| 第 1 次 | 7121 | workbench.desktop.main.js:619 (console.log位置) | 4000002 ✅ | **空**(未更新) | 触发hook → qMT轮询 → **timeout** |
| 第 2 次 | 7190 | index.js:3861 (方法定义位置) | ? | 已更新 | ❌ 被5秒冷却**跳过** |

- 第 1 次是"预上报"(telemetry)，在 GZt.create() **之前**就携带了 code=4000002
- 第 2 次是真正的 thinking limit 错误处理
- **我们的 5 秒冷却窗口阻塞了第 2 次！**

**发现 2: Store 在后台 tab 中不更新!**

v13 的 queueMicrotask 轮询在后台运行了 3 秒（~100 次 microtask），每次读取 Store 都得到 `messages[last].exception = undefined`。
用户切回窗口后，v11.6 立刻（84 行日志内）就读到了 exception.code=4000002。

**结论**: `storeService.updateMessage()` / `setCurrentSession()` 在后台 tab 中被**延迟/阻塞**，只有切回窗口后才执行。这不是 Chromium 定时器节流问题（qMT 不受影响），而是 **Trae 自身的某个机制**（可能是 SSE 断开后数据流中断，或 async handler 等待前台条件）。

**发现 3: v13 证明了 teaEventChatFail 是可行的 hook 点**

✅ teaEventChatFail 在后台正常执行
✅ 第 3 参数 `i` 包含正确的错误码
✅ 注入的代码不崩溃、不影响原有逻辑
❌ 但不能在同一个调用中完成续接（Store 还没数据）

### [2026-04-23 15:15] v14 Hybrid 方案 — 标志 + visibilitychange ⭐⭐⭐⭐⭐

**核心思路**: 既然"检测"和"执行"必须分开（因为 Store 延迟更新），那就:
1. **后台检测**: teaEventChatFail 触发时设标志 `window.__traeBGError = {code, time}`
2. **前台执行**: visibilitychange → visible 时检查标志 + 读 Store → resumeChat

这比纯 visibilitychange 方案好的地方:
- **纯 VC 方案**: 不知道发生了什么错误，需要扫描所有消息猜测
- **Hybrid 方案**: **确切知道**发生了可恢复错误（标志告诉你），只需等 Store 可读

#### v14 架构

```
后台 (用户切走窗口):
  AI 思考达到上限
    ↓ 主进程 GZt.create()
    ↓ IPC / 事件
  teaEventChatFail(e, t, {code:4000002,...})  ← 第1次(预上报)
    ↓ 我们的注入代码:
  window.__traeBGError = {code:4000002, time:Date.now()}
  console.log("[v14-bg] FLAG SET", 4000002)
    ↓ (Store 此时还没有 exception!)

  ... 用户切回窗口 ...

前台 (visibilitychange → visible):
  document.visibilitychange 事件触发
    ↓ 我们的监听器:
  window.__traeBGError 存在? 且 < 30秒前? → YES
  window.__traeBGError = null (清除标志)
  读取 Store → messages[last].exception.code = 4000002 ✅ (Store已更新!)
  uj.getInstance().resolve(BR).resumeChat({messageId, sessionId})
  console.log("[v14-bg] OK")
```

#### 与之前所有版本的对比

| 版本 | 检测方式 | 续接时机 | 后台能工作? |
|------|---------|---------|-----------|
| v7 L1 | React render body | render 时 | ❌ Scheduler冻结 |
| v10 L2 | ErrorStreamParser.parse() | parse 时 | ❌ 不走此路径 |
| v11.0-11.5 | subscribe/polling/MC | 检测到时 | ❌ 无通知/节流/位置错 |
| v11.6 | subscribe #8 回调 | 其他状态变化触发 | ⚠️ 延迟~30秒 |
| v12 | TaskAgentMessageParser.parse() | 变异点 | ❌ 零输出(不走此路径) |
| **v13** | **teaEventChatFail 参数** | qMT轮询Store | ⚠️ **触发成功但Store无数据** |
| **v14** | **teaEventChatFail 设标志** | **visibilitychange→visible** | **✅ 最优解** |

#### 注入详情 (两处)

**PART1 — teaEventChatFail flag (@7458679)**:
- find_original: `teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)`
- 注入: 方法体 `{` 之后，仅设置 `window.__traeBGError` 标志 + console.log
- 无冷却、无轮询、无 resumeChat — **极简**

**PART2 — visibilitychange listener (文件末尾)**:
- 追加到文件末尾（模块级 IIFE 外）
- `if(!window.__traeVC14)` 防重复注册
- 检查 `document.visibilityState === "visible"` + `window.__traeBGError`
- 30 秒过期时间（防止旧标志误触发）
- 读取 Store 获取 agentMessageId + sessionId → resumeChat

### [2026-04-23 15:45] v14 测试结果 — FLAG 成功但 visibilitychange 不触发! ⭐⭐⭐⭐

**测试日志** (vscode-app-1776995748083.log):
```
行7009: [v14-bg] FLAG SET 4000002    ← ✅ 后台标志设置成功!
行7010: ERR exceeded maximum number of turns
行7077: teaEventChatFail @ index.js:3861
   ... (用户切回窗口) ...
行7371: [v7] triggering auto-continue     ← v7 触发了
```

**关键发现**: `[v14-bg] VISIBLE` 和 `[v14-bg] OK` 完全没出现！

visibilitychange 监听器可能失败的原因:
1. **注入位置在 webpack IIFE 内部** — 文件末尾的代码可能仍在 `(function(){...})()` 内部，导致作用域问题（`uj`/`BR`/`xC` 未定义）
2. **`document` 对象在代码执行时不可用** — Trae 的 index.js 可能在 DOM ready 前加载
3. **Electron/VSCode 特殊行为** — visibilitychange 事件可能不按预期触发

**结论**: 文件末尾追加代码的方式在 Trae 的 webpack bundle 环境中不可靠。需要使用**已证明有效的内部 hook 点**。

### [2026-04-23 16:00] v15 Hybrid v2 — flag + 独立 store.subscribe watcher ⭐⭐⭐⭐⭐

**核心改进**: 不用 visibilitychange（不可靠），改用在 **subscribe #8 之前注入独立的 store.subscribe() watcher**

#### 为什么这个方案应该工作

| 组件 | 证明来源 | 可靠性 |
|------|---------|--------|
| teaEventChatFail 后台执行 | v13 日志 `[v13-bg] teaEventChatFail 4000002` | ✅ 已验证 |
| i.code 携带正确错误码 | 同上, code=4000002 | ✅ 已验证 |
| store.subscribe 在切回窗口后触发 | v11.6 日志 sub#8 在切回后 84 行内触发 | ✅ 已验证 |
| Store 切回后包含 exception | v11.6 读到 exception.code=4000002 | ✅ 已验证 |
| 独立 subscribe 不影响原有逻辑 | 纯追加, 不修改任何现有代码 | ✅ 设计保证 |

#### v15 架构 (最终版)

```
后台 (用户切走窗口):
  AI 思考达到上限 → 主进程 GZt.create()
    → IPC / 某事件机制
  teaEventChatFail(e, t, {code:4000002,...})   ← 第1次(预上报)
    ↓ 我们的 PART1 注入:
  window.__traeBGError = {code:4000002, time:Date.now()}
  console.log("[v15-bg] FLAG", 4000002)
    ↓ (Store 此时还没有 exception! 后台不更新)

  ... 用户切回窗口 ...

前台 (Store 更新, subscribe 触发):
  Store.setCurrentSession({...messages: [{...,exception:{code:4000002}}]})
    ↓ Zustand 触发所有订阅者:
  
  【我们的 watcher】store.subscribe(function(e){...})     ← PART2 新增!
    ↓ 检查:
  window.__traeBGError 存在? 且 <30秒? → YES ✅
  e.currentSession.messages[last].exception.code 匹配? → YES ✅
  window.__traeBGError = null (清除标志)
  sessionServiceV2.resumeChat({messageId, sessionId})
  console.log("[v15-bg] OK", 4000002)                    ← 🎯
  
  【原有 sub#8】n.subscribe((e,t)=>{...})               ← 原有代码不变
    ↓ (也会触发, 但我们的 watcher 已经处理了)

  【v7 L1】if(V&&J) render body                        ← 保底, 如果上面都失败了
```

#### 注入详情 (两处, 都在 IIFE 内部, 变量可访问)

**PART1 — teaEventChatFail flag (@7458876)**:
```
原始: teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)
替换: teaEventChatFail(e,t,i){;try{if(i&&i.code&&[4000002,...].indexOf(i.code)>=0){
        window.__traeBGError={code:i.code,time:Date.now()};
        console.log("[v15-bg] FLAG",i.code)}}catch(_e){}}let r=this...
```

**PART2 — 独立 store watcher (@7588682)** — 在原有 `a(),n.subscribe((e,t)` 之前插入:
```
原始: a(),n.subscribe((e,t)=>{((...condition...)&&a())})
替换: 
  uj.getInstance().resolve(xC).subscribe(function(e){
    try{
      var _f=window.__traeBGError;
      if(_f&&_f.code){
        var _now=Date.now();
        if(_now-_f.time<30000){
          var _m=e.currentSession?.messages;
          if(_m&&_m.length){
            var _l=_m[_m.length-1];
            if([4000002,...].indexOf(_l?.exception?.code)>=0 && _l?.agentMessageId && e.currentSession?.sessionId){
              window.__traeBGError=null;
              uj.getInstance().resolve(BR).resumeChat({messageId:_l.agentMessageId,sessionId:e.currentSession.sessionId});
              console.log("[v15-bg] OK",_f.code)
            }
          }
        }
      }
    }catch(_e){}
  });
  a(),n.subscribe((e,t)=>{((...condition...)&&a())})   // 原有代码不变!
```

#### 与所有之前版本的完整对比

| 版本 | 检测方式 | 续接时机 | 后台检测? | Store可用? | 结果 |
|------|---------|---------|----------|-----------|------|
| v7 L1 | React render body | render 时 | ❌ 冻结 | ✅ | 仅前台 |
| v10 L2 | ErrorStreamParser.parse() | parse 时 | ❌ 不走此路径 | N/A | 零输出 |
| v11.0-11.5 | subscribe/polling/MC | 各异 | ❌ 各原因 | ⚠️ | 失败 |
| v11.6 | sub#8 回调内读Store | 其他状态变化触发 | ⚠️ 被动 | ✅ 切回后 | 延迟~30秒 |
| v12 | TaskAgentMessageParser.parse() | 变异点 | ❌ 不调用 | N/A | 零输出 |
| **v13** | **teaEventChatFail 参数** | **qMT轮询Store** | **✅ 触发!** | **❌ 后台空** | timeout |
| **v14** | **teaEventChatFail 设标志** | **visibilitychange** | **✅ FLAG成功!** | **❌ VC不触发** | VISIBLE缺失 |
| **v17** | **teaEventChatFail 设标志** | **独立sub watcher** | ✅ 应该触发 |
| **v17 final** | **teaEventChatFail + context参数直接resume** | **qMT轮询fallback** | **⚠️ 调用成功但效果延迟!** |

### [2026-04-23 18:30] v17 Final v3 测试 — 历史性突破与遗留问题 ⭐⭐⭐⭐⭐

**测试日志** (vscode-app-1777045914222.log):
```
行5986: [v17-bg] 4000002 sid aid           ← ✅ 后台触发!
行5987: [v17-bg] OK-resume                  ← ✅ resumeChat调用成功(无异常!)
行5988: [v17-bg] OK-resumed 14 new msgs     ← 🎉 qMT检测到Store消息增加!
行5989: ERR exceeded maximum number of turns ← ⚠️ 紧接着又出现错误!
   ... (无[v7]触发! v17处理了) ...
```

#### 三个正面发现

1. **`[v17-bg] RESUMING` 在后台触发** — teaEventChatFail 后台执行已验证 6 次以上
2. **`resumeChat()` 不抛异常** — 调用成功返回
3. **Store 消息数确实增加了** — 从初始值增加到 +14 (qMT 轮询检测到)
4. **`[v7]` 未触发** — v17 完全接管了，不需要 v7 保底

#### 用户反馈的关键问题

> "不，他在我切回窗口时才开始自动发'继续', 没切回去之前一直都是触发上限被中断的状态"

**即：resumeChat 被调用了，Store 也更新了，但视觉上对话没有继续。**

#### 根因分析 (待进一步验证)

**假设 A: resumeChat 触发了新轮次，新轮次也超限**
- 行 5988 检测到 14 new msgs（可能是 resume 触发的内部消息）
- 行 5989 紧接着出现第二个 `ERR exceeded`
- 说明续接后的回复也达到了思考上限
- 但我们的冷却窗口阻止了第二次自动续接
- 用户切回窗口后手动或 v7 的后续逻辑才真正打破循环

**假设 B: resumeChat 内部操作被延迟到窗口可见**
- resumeChat 可能通过 IPC 到主进程
- 主进程在后台时排队处理渲染进程请求
- 切回窗口后排队消息被批量处理
- 那 14 new msgs 是窗口恢复时的批量更新

**假设 C: 14 new msgs 是虚假检测**
- t.messages (从 context 参数获取) 可能和 Store.messages 不是同一引用
- 后台时 context 的 messages 数组可能是旧的快照
- 切回窗口后 Store 才更新，此时 qMT 读到的是新的 Store（不是 context 的）

**最可能的根因**: 结合 v13 的发现（Store 后台不更新）+ 本次发现（resumeChat 不报错但无视觉效果），**假设 B 或 C 最可能** —— resumeChat 的实际网络发送/处理在后台被某种机制阻塞。

### [2026-04-23 18:45] v18 方向思考 — 绕过 resumeChat 阻塞

既然 `resumeChat()` / `sendChatMessage()` 在后台的**实际效果被阻塞**，需要找到完全不同的路径：

#### 已排除的方案
| 方案 | 为什么不行 |
|------|-----------|
| React L1 render body (v7/v10) | Scheduler 冻结 |
| store.subscribe 新建 (v11.0-11.5) | 无通知/节流 |
| TaskAgentMessageParser.parse() (v12) | 不走此路径 |
| qMT 轮询等待 Store (v13) | Store 后台空 |
| visibilitychange 监听器 (v14) | 注入位置不可靠 |
| 独立 subscribe watcher (v15) | 未注册(depth=2) |
| sub#8 内部追加 (v16) | 需等切回窗口 |
| resumeChat 直接调用 (v17) | **调用成功但效果阻塞!** |

#### 待探索的方向

1. **DOM 操作模拟点击**: 找到"继续"按钮的 DOM 元素，在 visibilitychange 时 click()
   - 优点: 绕过所有 API 层面的限制
   - 缺点: 需要定位按钮元素; 可能仍受 React 合成事件影响
   
2. **主进程侧拦截**: 修改 workbench.desktop.main.js 中 GZt.create() 的行为
   - 优点: 完全绕过渲染进程所有限制
   - 缺点: 需要修改另一个文件; 主进程代码可能更复杂

3. **防止错误显示而非恢复**: 修改 exception 对象使其不被识别为可恢复错误
   - 让 UI 不显示错误提示和继续按钮
   - 但这不能真正"续接"对话

4. **多次重试循环**: v17 已经触发了 resumeChat，只是效果延迟。如果在冷却窗口过期后再次尝试呢？
   - 问题: 如果根本原因是后台阻塞，重试也没用 **✅ 切回后有** | **待测试** |

## [2026-04-25 18:00] DI 容器系统完整映射 ⭐⭐⭐⭐⭐

> 本发现是 Trae AI 模块 DI 系统的完整逆向工程。所有偏移量基于当前版本的 index.js。
> 搜索模板可用于 Trae 更新后重新定位。

---

### 1. DI 核心架构

| 组件 | 混淆名 | 类型 | 偏移量 | 说明 | 搜索模板 |
|------|--------|------|--------|------|----------|
| DI Container | `uj` | class | 6268469 | 单例容器，`uj.getInstance()` | `class uj` |
| 注入装饰器 | `uX` | decorator | — | `@inject(TOKEN)` 等价物 | `uX(` (101次) |
| 注册装饰器 | `uJ` | decorator | — | `@singleton({identifier:TOKEN})` | `uJ({identifier:` (51次) |
| React Hook | `uB` | hook | 6270579 | `useInject(TOKEN)` 等价物 | `uB=(hX=` |
| 容器快捷方式 | `hX` | ()=>uj | 6270579 | `hX=()=>uj.getInstance()` | `hX=()=>uj.getInstance()` |
| 依赖注册表 | `uP` | class | — | `uj.getDependencyRegistry()` | `new uP` |
| VS Code 服务标识 | `S2` | object | — | 包含 IEditorService, IFileService 等 | `S2.IEditorService` |

**容器类定义** (@6268469):
```javascript
class uj {
  static getInstance() { return uj.instance || (uj.instance = new uj), uj.instance }
  constructor() { this.initialized = !1, this.bindings = new Map, this.singletons = new Map }
  getDependencyRegistry() { return this._dependencyRegistry || (this._dependencyRegistry = new uP), this._dependencyRegistry }
  initialize(e) { !this.initialized && (this.externalCreateDecorator = e?.nativeIDECreateDecorator, ...) }
  resolve(token) { ... }  // 从容器获取服务实例
  provide(token, impl) { ... }  // 注册服务实现
  isInitialized() { ... }
  hasIdentifier(token) { ... }
}
```

**React Hook 定义** (@6270579):
```javascript
uB = (hX = () => uj.getInstance(), function(e) {
  let t = useContext(uL),  // MockServiceContext
  i = useMemo(() => i => {
    if (!t.isEmpty && t.mockServices.get(e)) return () => {};
    let n = hX();
    if (n.isInitialized()) return () => {};
    // ... polling until initialized
  }, [e, t]),
  n = useSyncExternalStore(i, r);
  if (t.mockServices.get(e)) return t.mockServices.get(e);
  let i = hX();
  return i.isInitialized() ? i.resolve(e) : null;
}, [e, t])
```

---

### 2. DI Token 注册表

#### 2a. Symbol.for() 全局 Token（跨模块共享，⭐⭐⭐⭐⭐ 稳定）

| Token 变量 | Symbol.for 值 | 偏移量 | 服务描述 | 搜索模板 |
|-----------|---------------|--------|----------|----------|
| `bY` | `"aiAgent.ILogService"` | 6473533 | 日志服务 | `Symbol.for("aiAgent.ILogService")` |
| `Ei` | `"aiAgent.ICredentialFacade"` | 7015771 | 凭证门面 | `Symbol.for("aiAgent.ICredentialFacade")` |
| `Eh` | `"aiAgent.IStorageFacade"` | 7018237 | 存储门面 | `Symbol.for("aiAgent.IStorageFacade")` |
| `ED` | `"aiAgent.IEnvironmentFacade"` | 7027572 | 环境门面 | `Symbol.for("aiAgent.IEnvironmentFacade")` |
| `E$` | `"aiAgent.IFastApplyFacade"` | 7031258 | 快速应用门面 | `Symbol.for("aiAgent.IFastApplyFacade")` |
| `Au` | `"aiAgent.IFileFacade"` | 7042224 | 文件门面 | `Symbol.for("aiAgent.IFileFacade")` |
| `AM` | `"IUtilFacade"` | 7056752 | 工具门面 | `Symbol.for("IUtilFacade")` |
| `Cv` | `"aiAgent.II18nService"` | 7075754 | 国际化服务 | `Symbol.for("aiAgent.II18nService")` |
| `xL` | `"IWorkspaceFacade"` | 7097709 | 工作区门面 | `Symbol.for("IWorkspaceFacade")` |
| `xJ` | `"IEditorFacade"` | ~7126296 | 编辑器门面 | `Symbol.for("IEditorFacade")` |
| `Mr` | `"aiAgent.ISlardarFacade"` | ~7134171 | Slardar 监控门面 | `Symbol.for("aiAgent.ISlardarFacade")` |
| `Ma` | `"ITeaFacade"` | ~7134895 | Tea 上报门面 | `Symbol.for("ITeaFacade")` |
| `Mc` | `"aiAgent.IFpsRecordFacade"` | ~7135785 | FPS 记录门面 | `Symbol.for("aiAgent.IFpsRecordFacade")` |
| `M0` | `"aiAgent.ISessionService"` | 7150072 | **会话服务（核心）** | `Symbol.for("aiAgent.ISessionService")` |
| `M5` | `"aiAgent.IAiClientManagerService"` | ~7152097 | AI 客户端管理 | `Symbol.for("aiAgent.IAiClientManagerService")` |
| `kv` | `"IModelService"` | 7177093 | 模型服务 | `Symbol.for("IModelService")` |
| `kb` | `"IModelStorageService"` | ~7177093 | 模型存储服务 | `Symbol.for("IModelStorageService")` |
| `kA` | `"aiAgent.IProductService"` | ~7179610 | 产品服务 | `Symbol.for("aiAgent.IProductService")` |
| `Mz` | `"aiAgent.IContextKeyFacade"` | ~7145449 | 上下文键门面 | `Symbol.for("aiAgent.IContextKeyFacade")` |
| `B3` | `"aiAgent.IPastChatExporter"` | 7566970 | 历史聊天导出 | `Symbol.for("aiAgent.IPastChatExporter")` |
| `jN` | `"IPlanService"` | 7450318 | 计划服务 | `Symbol.for("IPlanService")` |
| `Oe` | `"INotificationStreamParser"` | ~7322410 | 通知流解析器 | `Symbol.for("INotificationStreamParser")` |
| `zS` | `"ITextMessageChatStreamParser"` | ~7497479 | 文本消息流解析器 | `Symbol.for("ITextMessageChatStreamParser")` |
| `zz` | `"IErrorStreamParser"` | ~7508572 | 错误流解析器 | `Symbol.for("IErrorStreamParser")` |
| `zJ` | `"IUserMessageStreamParser"` | ~7515007 | 用户消息流解析器 | `Symbol.for("IUserMessageStreamParser")` |
| `z2` | `"ITokenUsageStreamParser"` | ~7516765 | Token 用量流解析器 | `Symbol.for("ITokenUsageStreamParser")` |
| `z3` | `"IContextTokenUsageStreamParser"` | ~7517392 | 上下文 Token 流解析器 | `Symbol.for("IContextTokenUsageStreamParser")` |
| `z8` | `"ISessionTitleMessageStreamParser"` | ~7518028 | 会话标题流解析器 | `Symbol.for("ISessionTitleMessageStreamParser")` |
| `TL` | `"aiChat.ICustomRulesService"` | ~7244804 | 自定义规则服务 | `Symbol.for("aiChat.ICustomRulesService")` |
| `kd` | `"aiChat.IAIChatRequestErrorService"` | ~7155260 | AI 请求错误服务 | `Symbol.for("aiChat.IAIChatRequestErrorService")` |
| — | `"ai.IDocsetService"` | 3546087 | 文档集服务 | `Symbol.for("ai.IDocsetService")` |
| `xI` | `"IEditorFacade"` (alt) | ~7126296 | 编辑器门面(变体) | `Symbol.for("IEditorFacade")` |
| `k5` | `"IModeStorageService"` | ~7189229 | 模式存储服务 | `Symbol.for("IModeStorageService")` |
| `BB` | (租户配置) | ~7591333 | 租户配置服务 | `resolve(BB)` |

#### 2b. Symbol() 局部 Token（模块内，⭐⭐⭐⭐ 稳定）

| Token 变量 | Symbol 值 | 偏移量 | 服务描述 | 搜索模板 |
|-----------|-----------|--------|----------|----------|
| `xC` | `"ISessionStore"` | ~7087490 | **会话存储（核心 Zustand）** | `Symbol("ISessionStore")` |
| `D5` | `"IAgentService"` | 7321280 | Agent 服务 | `Symbol("IAgentService")` |
| `D3` | `"IFeeUsageParser"` | 7321280 | 费用解析器 | `Symbol("IFeeUsageParser")` |
| `BO` | `"ISessionServiceV2"` | 7545196 | 会话服务 V2 | `Symbol("ISessionServiceV2")` |
| `k1` | `"IModelStore"` | 7186457 | 模型存储（Zustand） | `Symbol("IModelStore")` |
| `IN` | `"ISessionRelationStoreInternal"` | ~7203850 | 会话关系存储 | `Symbol("ISessionRelationStoreInternal")` |
| `DV` | `"IUserMessageContextParser"` | ~7314000 | 用户消息上下文解析器 | `Symbol("IUserMessageContextParser")` |
| `DQ` | `"IMetadataParser"` | ~7314000 | 元数据解析器 | `Symbol("IMetadataParser")` |
| `za` | `"IFeeUsageStreamParser"` | ~7482422 | 费用流解析器 | `Symbol("IFeeUsageStreamParser")` |
| `zL` | `"IPlanItemStreamParser"` | ~7503299 | **计划项流解析器** | `Symbol("IPlanItemStreamParser")` |
| `zW` | `"IDoneStreamParser"` | ~7511057 | 完成流解析器 | `Symbol("IDoneStreamParser")` |
| `zV` | `"IQueueingStreamParser"` | ~7512721 | 排队流解析器 | `Symbol("IQueueingStreamParser")` |
| `I2` | `"IInlineSessionStore"` | ~7221939 | 内联会话存储 | `Symbol("IInlineSessionStore")` |
| `I6` | `"IMarkdownContextMenuStore"` | ~7223077 | Markdown 上下文菜单 | `Symbol("IMarkdownContextMenuStore")` |
| `I7` | `"IProjectStore"` | ~7224039 | 项目存储 | `Symbol("IProjectStore")` |
| `To` | `"IChatTurnImageMenuStore"` | ~7224870 | 聊天图片菜单存储 | `Symbol("IChatTurnImageMenuStore")` |
| `TG` | `"IAgentExtensionStore"` | ~7248275 | Agent 扩展存储 | `Symbol("IAgentExtensionStore")` |
| `T8` | `"ILintErrorAutoFixStore"` | ~7256181 | Lint 自动修复存储 | `Symbol("ILintErrorAutoFixStore")` |
| `Na` | `"ISkillStore"` | ~7258315 | 技能存储 | `Symbol("ISkillStore")` |
| `Nc` | `"IEntitlementStore"` | ~7259427 | 权限存储 | `Symbol("IEntitlementStore")` |
| `Ci` | (会话服务标识) | ~7152097 | 会话服务（同 M0?） | `uJ({identifier:Ci})` |

#### 2c. 未解析 Token 变量（⭐⭐⭐ 需进一步搜索）

| Token 变量 | 用途推断 | resolve 调用偏移 | 搜索模板 |
|-----------|---------|-----------------|----------|
| `Di` | ChatService (resumeChat) | 7508810 | `resolve(Di)` |
| `BB` | 租户配置服务 | 7591333 | `resolve(BB)` |
| `BX` | 文件差异提供者 | 7601575 | `resolve(BX)` |
| `FE` | 知识库服务 | 7599324 | `resolve(FE)` |
| `etN` | 知识库特性开关 | 7599324 | `resolve(etN)` |
| `etr` | DSL Agent 服务 | 10470403 | `resolve(etr)` |
| `Wg` | 会话 Todo 服务 | 10469891 | `resolve(Wg)` |
| `Dy` | 快速应用存储 | 7306295 | `resolve(Dy)` |
| `eYH` | 用量限制服务 | 10465352 | `resolve(eYH)` |
| `Jp` | 网络数据服务 | 10469447 | `resolve(Jp)` |
| `ee4` | AI 代码贡献服务 | 10470055 | `resolve(ee4)` |
| `M$` | 凭证存储 | ~7149840 | `resolve(M$)` |
| `N7` | (forkSession 中使用) | 10475553 | `resolve(N7)` |
| `B9` | (上传图片中使用) | 7578056 | `resolve(B9)` |
| `ks` | AI 客户端服务变体 | ~7155260 | `uJ({identifier:ks})` |
| `kS` | 动态配置存储 | ~7177763 | `uJ({identifier:kS})` |
| `Ix` | 会话关系服务 | ~7203823 | `uJ({identifier:Ix})` |

---

### 3. ⚠️ 重要纠正：BR 和 FX 不是 DI Token

**`BR`** = `s(72103)` = Node.js `path` 模块导入（@7551518）
- `BR.relative()`, `BR.basename()` — 文件路径操作
- 在 auto-continue 补丁中 `uj.getInstance().resolve(BR)` 是把 path 模块当作服务来 resolve，这是**错误的用法**（应该是 resolve 其他 token）
- **之前 discoveries.md 中将 BR 标记为 _sessionServiceV2 的 DI token 是错误的！**

**`FX`** = `findTargetAgent` 辅助函数（@7604449），**不是** DI 解构模式
- `async function FX(e,t,i,r,n=!1,o)` — 按名称或 ID 查找 Agent
- 在 sendToAgentBackground 中被调用：`await FX(o,r,t?.agentName,t?.agentId)`
- 之前假设 `FX(i)` 是从容器解构服务是**错误的**！

---

### 4. uj.getInstance().resolve() 调用完整表（45 次 DI 专用）

| # | 偏移量 | Token | 服务 | 上下文 |
|---|--------|-------|------|--------|
| 1 | 7137173 | `Cv` | II18nService | 历史列表图片占位符 |
| 2 | 7306295 | `Dy` | FastApplyStore | 检查脏状态 |
| 3 | 7306625 | `M0` | ISessionService | 获取当前会话 |
| 4 | 7452910 | `BR` | ⚠️ path 模块 | auto-continue resumeChat |
| 5 | 7508810 | `Di` | ChatService | auto-continue resumeChat |
| 6 | 7583273 | `M0` | ISessionService | 创建新会话 |
| 7 | 7583427 | `M0` | ISessionService | 确认处理待定差异 |
| 8 | 7584554 | `M0` | ISessionService | 获取运行状态 |
| 9 | 7585043 | `Au` | IFileFacade | 检查文件存在 |
| 10 | 7585588 | `M0` | ISessionService | 获取当前会话 |
| 11 | 7589023 | `Cv` | II18nService | 本地化 "Ready to build!" |
| 12 | 7590109 | `jN` | IPlanService | 切换计划模式 |
| 13 | 7590208 | `M0` | ISessionService | 切换历史列表可见 |
| 14 | 7590888 | `M0` | ISessionService | 获取工作状态提示 |
| 15 | 7590979 | `M0` | ISessionService | 删除会话 |
| 16 | 7591104 | `kv` | IModelService | 刷新模型存储 |
| 17 | 7591229 | `kv` | IModelService | 初始化操作 |
| 18 | 7591333 | `BB` | TenantConfig | 获取租户用户配置 |
| 19 | 7591798 | `M0` | ISessionService | 设置促销卡片标志 |
| 20 | 7591982 | `xC`,`D5` | ISessionStore,IAgentService | 使用内置 Agent |
| 21 | 7592370 | `xC` | ISessionStore | 按 worktree 路径获取会话标题 |
| 22 | 7592511 | `S2.IStorageService` | VS Code 存储 | 重置聊天反馈 |
| 23 | 7592768 | `S2.IStorageService` | VS Code 存储 | 重置满意度反馈 |
| 24 | 7592943 | `S2.IStorageService` | VS Code 存储 | 重置解决反馈 |
| 25 | 7593118 | `S2.IStorageService` | VS Code 存储 | 重置聊天反馈轮次 |
| 26 | 7599006 | `WQ.IDocsetService` | 文档集服务 | 调试获取企业文档集 |
| 27 | 7599215 | `B3` | IPastChatExporter | 导出当前聊天到文件 |
| 28 | 7599324 | `etN`,`FE` | 知识库服务 | 初始化知识库 |
| 29 | 7601575 | `BX` | FileDiffProvider | 获取文件差异提供者 |
| 30 | 9799554 | `D5` | IAgentService | 获取 Agent 面板数据 |
| 31 | 9799757 | `D5` | IAgentService | 获取 Agent 面板数据 |
| 32 | 9799992 | `S2.IICubeAgentService` | VS Code Agent 服务 | 保存 Agent 面板数据 |
| 33 | 9836993 | `S2.IICubeAgentService` | VS Code Agent 服务 | 获取 Agent 面板数据 |
| 34 | 10466533 | (动态) | 注册适配器 | getRegisteredAdapter |
| 35 | 10467510 | `S2.IViewsService` | VS Code 视图服务 | 打开视图容器 |
| 36 | 10469314 | `eYH` | UsageLimit | 打开用量限制弹窗 |
| 37 | 10469447 | `Jp` | NetworkData | 获取网络数据 |
| 38 | 10469573 | `ED` | IEnvironmentFacade | 更新 Python 环境 |
| 39 | 10469706 | `M0` | ISessionService | 更新 worktree |
| 40 | 10469891 | `Wg` | SessionTodo | 接受会话 Todo |
| 41 | 10470055 | `ee4` | AICodeContribution | 报告 AI 代码贡献 |
| 42 | 10470403 | `etr` | DSLAgent | 启动全局日志流 |
| 43 | 10470537 | `etr` | DSLAgent | 停止全局日志流 |
| 44 | 10470666 | `etr`,`S2.IWebviewWorkbenchService`,`S2.IFileService`,`Au` | DSL 编辑器 | 打开 DSL 编辑器 |
| 45 | 10473463 | `BO` | ISessionServiceV2 | 停止聊天会话 |

**uj.getInstance().provide()** 仅 1 次 (@10466462):
```javascript
registerAdapter: function(e, t) { uj.getInstance().provide(e, t) }
```

---

### 5. 服务注册（uJ 装饰器，51 个服务类）

每个 `uJ({identifier:TOKEN})` 将一个类注册为 DI 单例服务：

| # | 偏移量 | Token | 类名(混淆) | 服务描述 |
|---|--------|-------|-----------|----------|
| 1 | 7017457 | `Ei` | `Er` | CredentialFacade |
| 2 | 7024823 | `Eh` | `E_` | StorageFacade |
| 3 | 7030377 | `ED` | `ER` | EnvironmentFacade |
| 4 | 7040640 | `E$` | `EJ` | FastApplyFacade |
| 5 | 7051496 | `Au` | `Ad` | FileFacade |
| 6 | 7058236 | `AM` | `Ak` | UtilFacade |
| 7 | 7097170 | `xC` | `xI` | SessionStore (Zustand) |
| 8 | 7097709 | `xL` | `xR` | WorkspaceFacade |
| 9 | 7121088 | `xU` | `xW` | FileCommandFacade |
| 10 | 7126296 | `xq` | `xK` | TerminalFacade |
| 11 | 7128698 | `xJ` | `x0` | EditorFacade |
| 12 | 7132284 | `x3` | `x6` | OutlineFacade |
| 13 | 7134171 | `Me` | `Mt` | ChatPane |
| 14 | 7134895 | `Mr` | `Mn` | SlardarFacade |
| 15 | 7135785 | `Ma` | `Ms` | TeaFacade |
| 16 | 7136260 | `Mc` | `Mu` | FpsRecordFacade |
| 17 | 7141119 | `Mb` | `Mw` | PaneComposite 服务 |
| 18 | 7141929 | `MA` | `MC` | Telemetry 服务 |
| 19 | 7143044 | `MT` | `MN` | Theme 服务 |
| 20 | 7145449 | `MR` | `MP` | DynamicConfig 服务 |
| 21 | 7145912 | `Mz` | `MB` | ContextKeyFacade |
| 22 | 7148272 | `MY` | `MV` | Keybinding 服务 |
| 23 | 7148876 | `bY` | `MQ` | **LogService** |
| 24 | 7149840 | `M$` | `MX` | CredentialStore |
| 25 | 7152097 | `Ci` | `M4` | SessionService |
| 26 | 7153584 | `M5` | `M7` | AiClientManagerService |
| 27 | 7155260 | `ks` | `ku` | AI 客户端变体 |
| 28 | 7177763 | `kS` | `kE` | DynamicConfigStore |
| 29 | 7179610 | `kA` | `kM` | ProductService |
| 30 | 7189229 | `k1` | `k2` | ModelStore (Zustand) |
| 31 | 7190440 | `Ie` | `Ii` | SoloGuide 服务 |
| 32 | 7203823 | `Ix` | `IM` | SessionRelation 服务 |
| 33 | 7217424 | `IN` | `ID` | SessionRelationStore (Zustand) |
| 34 | 7220298 | `IZ` | `IQ` | Storage 相关 |
| 35 | 7221939 | `I$` | `IX` | Input 相关 |
| 36 | 7223077 | `I2` | `I4` | InlineSessionStore |
| 37 | 7224039 | `I6` | `I8` | MarkdownContextMenuStore |
| 38 | 7224870 | `I7` | `Ti` | ProjectStore |
| 39 | 7225729 | `To` | `Ta` | ChatTurnImageMenuStore |
| 40 | 7228600 | `Td` | `Th` | Storage 相关 |
| 41 | 7229095 | `Tm` | `Tm` | Tea+Log 组合服务 |
| 42 | 7244804 | `TM` | `TD` | Tea+Log 组合服务 |
| 43 | 7248275 | `Tz` | `TB` | Env 相关 |
| 44 | 7249310 | `TG` | `TH` | AgentExtensionStore |
| 45 | 7251505 | `TQ` | `Tq` | 某服务 |
| 46 | 7256181 | `T5` | `T3` | Entitlement 相关 |
| 47 | 7256739 | `T8` | `T9` | LintErrorAutoFixStore |
| 48 | 7258315 | `Nr` | `Nn` | RulesMode 服务 |
| 49 | 7259427 | `Na` | `Ns` | SkillStore |
| 50 | 7260182 | `Nc` | `Nu` | EntitlementStore |

---

### 6. DI 依赖图（核心服务注入关系）

```
uj (DI Container Singleton)
├── uX (inject) ─── 101 次装饰器调用
├── uJ (register) ── 51 次服务注册
├── uB (useInject) ── React Hook，内部用 hX
└── hX (()=>uj.getInstance()) ── 容器快捷方式

关键服务依赖链:
xR (WorkspaceFacade)
  ← uX(S2.IClipboardService, IFileService, IEditorService, ICodeEditorService,
       ITextModelService, IOutlineModelService, IWorkspaceContextService,
       ITextFileService, ILanguageService, IEditorService, ICodeEditorService,
       IPathService, IModelService, IICubeAITeaService, IEnvironmentService,
       IAiChatApiService, AM, xC, ED)

xW (FileCommandFacade)
  ← uX(S2.IClipboardService, IFileService, IEditorService, ICodeEditorService,
       ITextFileService, IBulkEditService, IFileDialogService,
       IWorkspaceContextService, ICommandService)

xK (TerminalFacade)
  ← uX(S2.IEditorService, IEditorGroupsService, IICubeSoloModeManagerService,
       ITerminalEditorService, ICommandService, IFileService, ITerminalService,
       ITerminalGroupService, IPathService, IOpenerService)

x0 (EditorFacade)
  ← uX(S2.ICodeEditorService, ITextFileService, IPathService)

x6 (OutlineFacade)
  ← uX(S2.IModelService, ILanguageService, IPathService)

xI (SessionStore) ← uX(xC) [自引用? 或其他服务]
MQ (LogService) ← uX(AM) [UtilFacade]
M4 (SessionService) ← uX(Ci) [同 M0?]
MX (CredentialStore) ← uX(M$)
k2 (ModelStore) ← uX(k1) [自引用?]
ID (SessionRelationStore) ← uX(Ix, ...)
```

---

### 7. 对补丁开发的关键影响

1. **服务层 > UI 层原则验证**: DI resolve 调用集中在 7583273-7601575 区间（FF 对象，API 层）和 10463462-10478629 区间（命令注册层）。这些是**服务层代码**，不受 React 冻结影响。

2. **auto-continue 补丁中的 Token 问题**:
   - `uj.getInstance().resolve(BR)` @7452910 — BR 是 path 模块，不是 DI token！
   - `uj.getInstance().resolve(Di)` @7508810 — Di 是 ChatService，调用 `.resumeChat()`
   - **建议**: auto-continue 应该 resolve `M0` (ISessionService) 或 `BO` (ISessionServiceV2) 而非 BR

3. **容器初始化时序**: `hX()` 返回容器后先检查 `isInitialized()`，未初始化时轮询等待。这意味着在 React 组件外使用 `uj.getInstance().resolve()` 需确保容器已初始化。

4. **Zustand Store 与 DI 的关系**: `xC` (ISessionStore), `k1` (IModelStore), `IN` (ISessionRelationStore) 都是 Zustand store，通过 DI 注册但用 `uB(token)` 在 React 中注入，用 `.getState()` 在服务层访问。

5. **搜索模板稳定性**: `Symbol.for("...")` 字符串是**最稳定的搜索锚点**，跨版本不变。`uX(`, `uJ({identifier:` 等混淆名每次构建可能变化。

---

## [2026-04-25 18:30] SSE 流管道完整拓扑 ⭐⭐⭐⭐⭐

> SSE 流是 Trae AI 聊天的核心数据管道。本节完整映射了从服务端到 UI 的所有路径。

### 1. SSE 事件枚举 (D7)

**注意**: 变量名 `D7` 随 webpack 构建变化。稳定搜索锚点是 `Symbol.for("IPlanItemStreamParser")` 等注册 token。

| 事件类型 | 枚举值 | 说明 | Parser 类 | DI Token |
|---------|--------|------|-----------|----------|
| Metadata | `"metadata"` | 元数据 | DQ (MetadataParser) | `Symbol("IMetadataParser")` |
| UserMessage | `"userMessage"` | 用户消息 | DV (UserMessageContextParser) | `Symbol("IUserMessageContextParser")` |
| Notification | `"notification"` | 通知 | — | `Symbol.for("INotificationStreamParser")` |
| TextMessage | `"textMessage"` | 文本消息 | — | `Symbol.for("ITextMessageChatStreamParser")` |
| PlanItem | `"planItem"` | 计划项/工具调用 | zL (PlanItemStreamParser) | `Symbol("IPlanItemStreamParser")` |
| Error | `"error"` | 错误 | zU (ErrorStreamParser) | `Symbol.for("IErrorStreamParser")` |
| UserMessageStream | `"userMessageStream"` | 用户消息流 | zJ | `Symbol.for("IUserMessageStreamParser")` |
| TokenUsage | `"tokenUsage"` | Token 用量 | z2 | `Symbol.for("ITokenUsageStreamParser")` |
| ContextTokenUsage | `"contextTokenUsage"` | 上下文 Token | z3 | `Symbol.for("IContextTokenUsageStreamParser")` |
| FeeUsage | `"feeUsage"` | 费用 | za | `Symbol("IFeeUsageStreamParser")` |
| SessionTitle | `"sessionTitle"` | 会话标题 | z8 | `Symbol.for("ISessionTitleMessageStreamParser")` |
| Done | `"done"` | 完成 | zW | `Symbol("IDoneStreamParser")` |
| Queueing | `"queueing"` | 排队 | zV | `Symbol("IQueueingStreamParser")` |

### 2. EventHandlerFactory (Bt) — 中央调度器

```
位置: ~7300000 区域
模式: handle(event, payload, context) → parse(event, payload, context) → handleSteamingResult(result, context)
```

每个事件类型注册一个 Parser，handle() 调用 Parser.parse() 然后分发结果。

### 3. ChatStreamService 层级

```
Bo (ChatStreamService 基类, Template Method 模式)
├── Bv (SideChatStreamService) — 侧边栏聊天，完整事件分发
└── BE (InlineChatStreamService) — 内联聊天，简化版
```

**关键**: `Bs` 不是 ChatStreamService！`Bs` 是 ChatParserContext（数据类）。

### 4. SSE 流生命周期

```
SSE 连接建立
  → onMetadata → MetadataParser.parse()
  → onMessage → EventHandlerFactory.handle(eventType, payload, context)
    → Parser.parse() → handleSteamingResult() → handleSideChat()/handleInlineError()
      → storeService.updateMessage() → Zustand Store → React re-render
  → onError(e, t, i) → 仅 t=true 时分发到 ErrorStreamParser
  → onComplete → DoneParser.parse()
  → onCancel → 清理
```

### 5. 15 个 Parser 类完整列表

| Parser | 混淆名 | 偏移量 | DI Token | 处理事件 |
|--------|--------|--------|----------|---------|
| MetadataParser | DQ | ~7314000 | IMetadataParser | Metadata |
| UserMessageContextParser | DV | ~7314000 | IUserMessageContextParser | UserMessage |
| NotificationStreamParser | — | ~7322410 | INotificationStreamParser | Notification |
| TextMessageChatStreamParser | — | ~7497479 | ITextMessageChatStreamParser | TextMessage |
| PlanItemStreamParser | — | ~7503299 | IPlanItemStreamParser | PlanItem |
| ErrorStreamParser | zU | ~7508572 | IErrorStreamParser | Error |
| UserMessageStreamParser | zJ | ~7515007 | IUserMessageStreamParser | UserMessageStream |
| TokenUsageStreamParser | z2 | ~7516765 | ITokenUsageStreamParser | TokenUsage |
| ContextTokenUsageStreamParser | z3 | ~7517392 | IContextTokenUsageStreamParser | ContextTokenUsage |
| FeeUsageStreamParser | za | ~7482422 | IFeeUsageStreamParser | FeeUsage |
| SessionTitleMessageStreamParser | z8 | ~7518028 | ISessionTitleMessageStreamParser | SessionTitle |
| DoneStreamParser | zW | ~7511057 | IDoneStreamParser | Done |
| QueueingStreamParser | zV | ~7512721 | IQueueingStreamParser | Queueing |
| TaskAgentMessageParser | — | ~7614800 | (非 SSE 管道) | (IPC 消息) |
| DZ/Dq (预解析器) | DZ, Dq | ~7300000 | — | 预处理 |

**关键发现**: TaskAgentMessageParser 不在 SSE 管道中！它处理 IPC 来源的消息，这就是 v12 补丁零输出的原因。

### 6. 错误分发的关键条件

```javascript
// Bo.onError(e, t, i):
// t=true → SSE 流错误 → eventHandlerFactory.handle(D7.Error, e, r) → ErrorStreamParser
// t=false → 其他异常 → 仅日志记录
// 思考上限错误不经过此路径！
```

### 7. 搜索模板

| 目标 | 搜索关键词 | 稳定性 |
|------|-----------|--------|
| SSE 事件枚举 | `Symbol.for("IPlanItemStreamParser")` | ⭐⭐⭐⭐⭐ |
| EventHandlerFactory | `eventHandlerFactory` | ⭐⭐⭐ |
| ChatStreamService | `class Bo` | ⭐⭐ |
| ErrorStreamParser | `Symbol.for("IErrorStreamParser")` | ⭐⭐⭐⭐⭐ |
| PlanItemStreamParser | `Symbol("IPlanItemStreamParser")` | ⭐⭐⭐⭐ |

---

## [2026-04-25 18:45] Zustand Store 架构完整映射 ⭐⭐⭐⭐⭐

> Store 是 Trae AI 聊天的状态中枢。本节完整映射了所有 Store 操作。

### 1. Store 实例

| Store | DI Token | 混淆名 | 偏移量 | 说明 |
|-------|----------|--------|--------|------|
| SessionStore | `xC` = Symbol("ISessionStore") | xI | ~7087490 | 主聊天会话存储 |
| InlineSessionStore | `I2` = Symbol("IInlineSessionStore") | I4 | ~7221939 | 内联聊天会话存储 |
| ModelStore | `k1` = Symbol("IModelStore") | k2 | ~7186457 | 模型配置存储 |
| SessionRelationStore | `IN` = Symbol("ISessionRelationStoreInternal") | ID | ~7203850 | 会话关系存储 |
| ProjectStore | `I7` | Ti | ~7224039 | 项目存储 |
| AgentExtensionStore | `TG` | TH | ~7248275 | Agent 扩展存储 |
| SkillStore | `Na` | Ns | ~7258315 | 技能存储 |
| EntitlementStore | `Nc` | Nu | ~7259427 | 权限存储 |

### 2. 两种 currentSession 模式

**SessionStore (主聊天)**:
- `currentSession` 是**计算属性**: 从 `sessions[]` + `currentSessionId` 派生
- `updateMessage()` 操作 `sessions[]` 数组
- `updateLastMessage()` 操作 `sessions[]` 数组

**InlineSessionStore (内联聊天)**:
- `currentSession` 是**直接字段**
- `updateMessage()` 和 `updateLastMessage()` 都调用 `setCurrentSession({...i, messages:[...]})`

**影响**: 补丁目标不同，策略不同。

### 3. setCurrentSession 调用点

| 偏移量 | 上下文 | Store |
|--------|--------|-------|
| ~7087490 | Store 定义 | SessionStore |
| ~7221939 | Store 定义 | InlineSessionStore |
| ~7584046 | subscribe #8 回调 | SessionStore |
| ~7605848 | runningStatusMap subscribe | SessionStore |

### 4. 关键 subscribe 调用

| 偏移量 | 监听内容 | 用途 |
|--------|---------|------|
| ~7584046 | `currentSession.messages.length` + `currentSessionId` | 更新全局上下文 |
| ~7605848 | `runningStatusMap` | 解析 waitForResponseComplete promise |
| ~7588518 | subscribe #8 (已有) | 消息数量变化检测 |

### 5. 无 Immer

代码库使用**展开运算符**进行不可变更新，不使用 Immer 的 `produce()`。
- `setCurrentSession({...i, messages:[...]})` — 标准展开
- 这简化了补丁设计——不需要担心 draft proxy

### 6. Store-React 连接

```javascript
// uB(token) — React Hook 注入 Store
// 等价于: const store = useSyncExternalStore(subscribe, getSnapshot)
// 返回: store 实例，可调用 .getState() / .subscribe() / .setState()
```

### 7. confirm_info 流经 PlanItemStreamParser

```
SSE PlanItem 事件 → PlanItemStreamParser._handlePlanItem() (~7504035)
  → 检查 confirm_info.confirm_status
  → 调用 provideUserResponse() (自动确认补丁)
  → 更新 confirm_info.confirm_status = "confirmed"
  → storeService.updateMessage() → Store 更新 → React re-render
```

### 8. 搜索模板

| 目标 | 搜索关键词 | 稳定性 |
|------|-----------|--------|
| SessionStore | `Symbol("ISessionStore")` | ⭐⭐⭐⭐ |
| InlineSessionStore | `Symbol("IInlineSessionStore")` | ⭐⭐⭐⭐ |
| setCurrentSession | `setCurrentSession` | ⭐⭐⭐ |
| subscribe | `.subscribe(` | ⭐⭐⭐ |
| getState | `.getState()` | ⭐⭐⭐ |
| useStore | `N.useStore` | ⭐⭐ |

## [2026-04-25 19:15] 错误处理系统完整映射 ⭐⭐⭐⭐⭐

> 错误系统是 Trae AI 聊天的"免疫系统"。本节完整映射了所有错误码、传播路径和恢复策略。

### 1. 错误码枚举 (kg) 完整列表

#### LLM/Agent 错误 (4000xxx 范围)

| 错误码 | 枚举名 | 含义 | 分类 |
|--------|--------|------|------|
| 4000002 | TASK_TURN_EXCEEDED_ERROR | 思考轮次超限 | 可续接 |
| 4000009 | LLM_STOP_DUP_TOOL_CALL | 重复工具调用 | 可续接 |
| 4000012 | LLM_STOP_CONTENT_LOOP | 内容循环检测 | 可续接 |
| 4008 | (未命名) | 工具调用错误 | 可恢复 |
| 4027 | (未命名) | 请求被拒绝 | 可恢复 |
| 4113 | (未命名) | 模型限制 | 不可恢复 |

#### 网络/服务错误 (efh 列表, 14 个)

| 错误码 | 含义 | 分类 |
|--------|------|------|
| SERVER_CRASH | 服务器崩溃 | 可恢复(resumeChat) |
| (13个其他网络错误) | 连接超时/重置等 | 可恢复(resumeChat) |

#### 特殊错误码

| 错误码 | 枚举名 | 含义 | 分类 |
|--------|--------|------|------|
| 987 | MODEL_OUTPUT_TOO_LONG | 输出过长 | 不可恢复 |
| 977 | (未命名) | 上下文过长 | 不可恢复 |
| 2000000 | DEFAULT | 默认错误 | 视情况 |

### 2. 错误传播路径

```
PATH A: 主进程 IPC (思考上限等)
  服务端 → Electron 主进程 → YTr.emit() → IPC → TaskAgentMessageParser.parse() @7615777
    → 写入 exception={code:t, ...} → Store 更新 → React 渲染

PATH B: SSE 流错误 (连接断开等)
  服务端 → SSE Error 事件 → ChatStreamService._onError(e,t,i) @7528742
    → eventHandlerFactory.handle(D7.Error, ...) → ErrorStreamParser.parse() @7508572
      → getErrorInfoWithError(e) → Store 更新 → React 渲染

PATH C: 通用错误 (账户/权限等)
  服务端 → Bs.onError → handleCommonError() @7300455
    → _aiChatRequestErrorService 处理 → 可能弹窗/重定向
```

**关键**: 思考上限错误走 PATH A，不经过 SSE ErrorStreamParser！

### 3. 错误码→消息映射

- `getErrorInfoWithError(e)` @7513080 — ErrorStreamParser 中使用
- `getErrorInfo(t, {...})` @7615777 — TaskAgentMessageParser 中使用
- 两者都映射数字码 → `{level, message}`，level 决定 bQ.Warning vs bQ.Error

### 4. stopStreaming — "沉默杀手"

```
位置: ~7538139
行为: 将 bQ.Warning 覆盖为 bQ.Canceled
影响: if(V&&J) 守卫条件中 J 检查 status===Warning，被覆盖后守卫失败
修复: guard-clause-bypass 补丁
```

### 5. agentProcess "v3"

```
只有 agentProcess==="v3" 的会话才支持 resumeChat()
其他版本回退到 retryChatByUserMessageId()（可能丢失上下文）
```

### 6. 搜索模板

| 目标 | 搜索关键词 | 稳定性 |
|------|-----------|--------|
| 错误码枚举 | `4000002` | ⭐⭐⭐⭐⭐ |
| ErrorStreamParser | `Symbol.for("IErrorStreamParser")` | ⭐⭐⭐⭐⭐ |
| TaskAgentMessageParser | `Symbol("ITaskAgentMessageParser")` | ⭐⭐⭐⭐ |
| handleCommonError | `handleCommonError` | ⭐⭐⭐ |
| stopStreaming | `_stopStreaming` | ⭐⭐ |
| resumeChat | `resumeChat` | ⭐⭐⭐ |

## [2026-04-25 19:30] React 组件层级完整映射 ⭐⭐⭐⭐⭐

> React 组件是 Trae AI 聊天的 UI 表现层。本节完整映射了组件树、Store 连接和冻结行为。

### 1. 三层架构 (核心设计原则)

```
L1 UI 层 (React 组件) ~8000000+     → 后台标签页冻结！
L2 服务层 (SSE 解析器) ~7500000     → 始终活跃
L3 数据层 (DG.parse)    ~7318521     → 始终活跃
```

### 2. 组件树

```
AMD Module Entry
├── L3 数据层
│   ├── DG.parse() @7318521
│   └── data-source-auto-confirm 补丁 @7323241
├── L2 服务层
│   ├── EventHandlerFactory (Bt) @~7300000
│   │   ├── PlanItemStreamParser @7502500 [自动确认补丁]
│   │   ├── ErrorStreamParser @7508572
│   │   └── (13 个 Parser)
│   ├── ChatStreamService (Bo) @~7520000
│   │   ├── SideChatStreamService (Bv)
│   │   └── InlineChatStreamService (BE)
│   ├── teaEventChatFail() @7458679 [最早错误信号]
│   └── sendToAgentBackground (F3) @7610443
├── L1 UI 层 → 后台冻结！
│   ├── egR (RunCommandCard) @8635000
│   │   ├── confirm_info 解构 @8637300
│   │   ├── ey useMemo (有效确认状态) @8636941
│   │   ├── _ useMemo (需要确认弹窗) @8629200
│   │   ├── 自动确认 useEffect @8640019
│   │   ├── ew.confirm() [仅遥测！] @~8635000+
│   │   └── eE(Ck.Confirmed) [真正执行] @~8635000+
│   ├── sX().memo(Jj) @~8709284 [自动续接宿主]
│   │   ├── JP.Sz 选择器 (status/exception/agentMessageId/sessionId)
│   │   ├── V = 最后一条助手消息匹配
│   │   ├── J = 可续接错误标志 @8696378
│   │   ├── if(V&&J) 分支 @8702300 [自动续接补丁]
│   │   ├── ec useCallback (重试/续接) @8697580
│   │   ├── ed useCallback ("继续"按钮) @8697620
│   │   └── efh 可恢复错误列表 @8695303
│   └── ErrorMessageWithActions @8700000-8930000
│       └── 17+ Alert 渲染点
├── DI 容器 (uj) @6268469
│   ├── uX(token) 注入装饰器 (101 次)
│   ├── uJ({identifier:token}) 注册装饰器 (51 服务)
│   └── uB(token) React Hook useInject @6270579
└── Zustand Stores (8 个)
    ├── SessionStore (xC) @~7087490
    ├── InlineSessionStore (I2) @~7221939
    └── (6 个其他 Store)
```

### 3. 17+ Alert 渲染点

| # | 偏移量 | 错误码/条件 | 类型 | 有按钮? |
|---|--------|-----------|------|--------|
| 1 | ~8700219 | ENTERPRISE_QUOTA_CONFIG_INVALID | warning | No |
| 2 | ~8701000 | MODEL_PREMIUM_EXHAUSTED | warning | No |
| 3 | ~8701454 | PAYMENT_METHOD_INVALID | warning | No |
| 4 | ~8701681 | INTERNAL_USAGE_LIMIT | warning | No |
| 5 | ~8702300 | **if(V&&J) 可恢复错误** | **warning** | **Yes** |
| 6 | ~8702410 | RISK_REQUEST_V2 | error/warning | No |
| 7 | ~8703141 | CONTENT_SECURITY_BLOCKED | warning | No |
| 8 | ~8703913 | FREE_ACTIVITY_QUOTA_EXHAUSTED | warning | No |
| 9 | ~8704548 | CAN_NOT_USE_SOLO_AGENT | warning | No |
| 10 | ~8705020 | CLAUDE_MODEL_FORBIDDEN | error | No |
| 11 | ~8705534 | REPO_LEVEL_MODEL_UNAVAILABLE | warning | No |
| 12 | ~8705889 | FIREWALL_BLOCKED | error | No |
| 13 | ~8706759 | EXTERNAL_LLM_REQUEST_FAILED | error | Yes |
| 14 | ~8707685 | PREMIUM_USAGE_LIMIT | error | No |
| 15 | ~8708073 | STANDARD_MODE_USAGE_LIMIT | error | No |
| 16 | ~8708463 | INVALID_TOOL_CALL | error | No |
| 17 | ~8709130 | TOOL_CALL_RETRY_LIMIT | error | Yes |

### 4. 冻结行为

| 组件 | 层 | 后台行为 |
|------|---|---------|
| sX().memo(Jj) | L1 | 冻结 — React Scheduler 停止重渲染 |
| egR (RunCommandCard) | L1 | 冻结 — useEffect/useMemo 暂停 |
| PlanItemStreamParser | L2 | 活跃 — SSE 回调运行 |
| teaEventChatFail | L2 | 活跃 — 遥测触发 |
| store.subscribe | L2/L3 | 部分活跃 — 回调触发但浅比较遗漏 |

### 5. 搜索模板

| 目标 | 搜索关键词 | 稳定性 |
|------|-----------|--------|
| RunCommandCard | `getRunCommandCardBranch` | ⭐⭐⭐ |
| 自动续接宿主 | `if(V&&J)` → 向上追溯到 `sX().memo(` | ⭐ |
| efh 列表 | `kg.SERVER_CRASH` | ⭐⭐⭐ |
| 确认状态 | `"unconfirmed"` | ⭐⭐⭐⭐ |
| BlockLevel 枚举 | `"redlist"` | ⭐⭐⭐⭐ |

## [2026-04-25 19:45] 事件总线与遥测系统完整映射 ⭐⭐⭐⭐⭐

> 事件系统是 Trae AI 聊天的"神经系统"。本节完整映射了所有事件通道和遥测机制。

### 1. TEA 遥测事件

| 方法名 | 偏移量 | 用途 | 稳定性 |
|--------|--------|------|--------|
| teaEventChatFail | ~7458679 | 报告聊天失败(最早错误信号) | ⭐⭐⭐⭐ |
| teaEventChatShown | (推断) | 报告聊天显示 | ⭐⭐⭐ |
| teaEventChatRetry | (推断) | 报告聊天重试 | ⭐⭐⭐ |

**DI Token**: `Ma` = `Symbol.for("ITeaFacade")` @~7135785

### 2. SSE 事件总线 (EventHandlerFactory)

```
EventHandlerFactory (Bt) @~7300000
  handle(eventType, payload, context) → Parser.parse() → handleSteamingResult()
  
13 个事件类型注册:
  Metadata → DQ.parse()
  PlanItem → PlanItemStreamParser._handlePlanItem()  ← 补丁 hook 点
  Error → ErrorStreamParser.parse()                  ← 补丁 hook 点
  Done → zW.parse()
  ... (完整列表见 SSE 拓扑节)
```

### 3. Zustand Store 订阅

| # | 偏移量 | 监听内容 | 用途 |
|---|--------|---------|------|
| 1 | ~7584046 | currentSession.messages.length + currentSessionId | 更新全局上下文 |
| 2 | ~7588518 | subscribe #8 | 消息数量变化检测 |
| 3 | ~7605848 | runningStatusMap | 解析 waitForResponseComplete |

### 4. DOM 事件监听

| # | 偏移量 | 事件 | 目标 | 用途 |
|---|--------|------|------|------|
| 1 | ~7610443 | cancelEventKey (动态) | window | 取消聊天流 |
| 2 | (补丁注入) | visibilitychange | document | 窗口焦点恢复 |

### 5. 无 Node.js EventEmitter

代码库**不使用** `.on()`/`.emit()` 模式。使用自定义 EventHandlerFactory 的 `handle()`/`register()` 方法。

### 6. 补丁 Hook 点可行性评估

| Hook 点 | 偏移量 | 稳定性 | 可访问性 | 后台可用 | 信息量 | 综合 |
|---------|--------|--------|---------|---------|--------|------|
| **teaEventChatFail** | ~7458679 | 4 | 5 | **5** | 4 | **4.5** |
| **PlanItemStreamParser** | ~7502500 | 5 | 4 | **5** | 5 | **4.75** |
| **ErrorStreamParser** | ~7508572 | 5 | 3 | **5** | 4 | **4.25** |
| DI resolve | 任意 | 5 | 3 | **5** | 3 | **4.0** |
| store.subscribe | ~7588518 | 3 | 4 | 3 | 3 | **3.25** |
| if(V&&J) Alert | ~8702300 | 2 | 5 | **1** | 5 | **3.25** |

**Top 3 推荐 Hook 点**:
1. PlanItemStreamParser._handlePlanItem — 命令确认最佳点
2. teaEventChatFail — 后台错误检测最佳点
3. DI Container resolve — 服务访问最佳点

### 7. 搜索模板

| 目标 | 搜索关键词 | 稳定性 |
|------|-----------|--------|
| TEA 服务 | `Symbol.for("ITeaFacade")` | ⭐⭐⭐⭐⭐ |
| teaEventChatFail | `teaEventChatFail` | ⭐⭐⭐⭐ |
| EventHandlerFactory | `eventHandlerFactory.handle(` | ⭐⭐⭐ |
| visibilitychange | `visibilitychange` | ⭐⭐⭐⭐⭐ |
| MessageChannel | `MessageChannel` | ⭐⭐⭐⭐⭐ |

## [2026-04-25 20:15] IPC 进程间通信完整映射 ⭐⭐⭐⭐⭐

> IPC 是 Trae 多进程架构的通信骨干。本节完整映射了所有通信通道。

### 1. 三层 IPC 架构

```
Server → SSE Stream → Main Process (YTr Event Bus) → Renderer Process (Parsers)
Renderer → VS Code Commands → Extension Host (ShellExec Service)
Extension Host → EventEmitters → Renderer (Output/Status Updates)
```

### 2. Shell 执行命令 (icube.shellExec.*)

| 命令 ID | 用途 |
|---------|------|
| `icube.shellExec.initShell` | 初始化登录 Shell 快照 |
| `icube.shellExec.runCommand` | 执行命令 |
| `icube.shellExec.checkStatus` | 检查命令状态 |
| `icube.shellExec.killCommand` | 终止运行中命令 |
| `icube.shellExec.getRunningCommands` | 获取 Agent 运行中命令 |
| `icube.shellExec.getAllRunningCommands` | 获取所有运行中命令 |
| `icube.shellExec.getTerminalHistory` | 获取终端历史 |
| `icube.shellExec.getCommandOutput` | 获取命令输出 |
| `icube.shellExec.getCommandIdByToolCallId` | toolCallId → commandId 映射 |

### 3. 主进程事件总线 (workbench.desktop.main.js)

| 类 | 方法 | 用途 |
|----|------|------|
| YTr | `.emit()` | 发射事件到流 |
| YTr | `.enqueueData()` | 入队流数据 |
| YTr | `.drain()` | 排队数据到客户端 |
| GZt | `.create()` | 创建错误对象 (如 "exceeded maximum number of turns") |

### 4. 取消机制 (cancelEventKey)

```
位置: ~7610443 (F3/sendToAgentBackground)
模式: window.addEventListener(t.cancelEventKey, () => { s.stopChat(f.sessionId) })
```

### 5. 关键发现: 无 ipcRenderer

index.js **不使用** Electron 的 `ipcRenderer` API。所有主进程通信通过:
1. VS Code 命令系统 (`vscode.commands.executeCommand`)
2. SSE 流 (服务端→渲染进程数据)
3. DI 容器服务方法 (渲染进程内部通信)
4. `window.addEventListener` 动态键 (取消事件)

### 6. 搜索模板

| 目标 | 搜索关键词 | 稳定性 |
|------|-----------|--------|
| Shell 执行 | `icube.shellExec.` | ⭐⭐⭐⭐⭐ |
| 取消事件 | `cancelEventKey` | ⭐⭐⭐⭐ |
| 错误工厂 | `GZt.create` | ⭐⭐ |
| 事件总线 | `YTr.drain` | ⭐⭐ |

## [2026-04-25 20:30] 设置系统完整映射 ⭐⭐⭐⭐⭐

> 设置系统控制着 Trae AI 的行为边界。本节完整映射了所有设置键和监听机制。

### 1. AI 工具调用设置

| 设置键 | 类型 | 默认值 | 偏移量 | 用途 |
|--------|------|--------|--------|------|
| `AI.toolcall.confirmMode` | string | `"alwaysAsk"` | ~7438613 | 确认模式 |
| `AI.toolcall.v2.command.mode` | string | — | ~7438600 | 命令执行模式 |
| `AI.toolcall.v2.command.allowList` | array | — | ~7438600 | 允许列表 |
| `AI.toolcall.v2.command.denyList` | array | — | ~7438600 | 拒绝列表 |

### 2. 聊天工具设置

| 设置键 | 类型 | 用途 |
|--------|------|------|
| `chat.tools.terminal.autoApprove` | boolean | 终端命令自动批准 |
| `chat.tools.terminal.ignoreDefaultAutoApproveRules` | boolean | 忽略默认自动批准规则 |
| `chat.tools.edits.autoApproveEdits` | boolean | 编辑操作自动批准 |

### 3. 全局设置

| 设置键 | 类型 | 用途 |
|--------|------|------|
| `GlobalAutoApprove` | boolean | 全局自动批准 (YOLO 模式) |

### 4. ConfirmMode 枚举 (偏移 ~8069382)

| 枚举值 | 字符串 | 行为 |
|--------|--------|------|
| ALWAYS_ASK | `"alwaysAsk"` | 每次命令需确认 |
| WHITELIST | `"whitelist"` | 白名单内自动执行 |
| BLACKLIST | `"blacklist"` | 非黑名单自动执行 |
| ALWAYS_RUN | `"alwaysRun"` | 全部自动执行 (RedList 仍弹窗!) |

### 5. 关键发现: 无 onDidChangeConfiguration

index.js 中**没有** `onDidChangeConfiguration` 监听器。设置在服务构造时读取，变更需服务重新初始化。

### 6. 搜索模板

| 目标 | 搜索关键词 | 稳定性 |
|------|-----------|--------|
| 确认模式 | `AI.toolcall.confirmMode` | ⭐⭐⭐⭐⭐ |
| 命令设置 | `AI.toolcall.v2.command.` | ⭐⭐⭐⭐⭐ |
| 聊天工具 | `chat.tools.` | ⭐⭐⭐⭐⭐ |
| YOLO 模式 | `GlobalAutoApprove` | ⭐⭐⭐⭐ |
| ConfirmMode 值 | `"alwaysAsk"` | ⭐⭐⭐⭐⭐ |

## [2026-04-25 20:45] 沙箱与命令执行管道完整映射 ⭐⭐⭐⭐⭐

> 沙箱系统是 Trae AI 的安全防线。本节完整映射了命令执行管道和安全规则。

### 1. BlockLevel 枚举 (偏移 ~8069382)

| 枚举值 | 字符串 | 含义 | 需确认? |
|--------|--------|------|---------|
| RedList | `"redlist"` | 危险命令 | 始终弹窗 |
| Blacklist | `"blacklist"` | 企业策略阻止 | 始终弹窗 |
| SandboxNotBlockCommand | `"sandbox_not_block_command"` | 无法在沙箱运行 | 视模式 |
| SandboxExecuteFailure | `"sandbox_execute_failure"` | 沙箱执行失败 | 视模式 |
| SandboxToRecovery | `"sandbox_to_recovery"` | 沙箱需恢复 | 视模式 |
| SandboxUnavailable | `"sandbox_unavailable"` | 沙箱不可用 | 视模式 |

### 2. AutoRunMode 枚举

| 枚举值 | 字符串 | 含义 |
|--------|--------|------|
| Auto | `"auto"` | 自动模式 |
| Manual | `"manual"` | 手动确认 |
| Allowlist | `"allowlist"` | 白名单模式 |
| InSandbox | `"in_sandbox"` | 沙箱内运行 |
| OutSandbox | `"out_sandbox"` | 沙箱外运行 |

### 3. getRunCommandCardBranch 决策矩阵

```
WHITELIST 模式:
  + RedList → V2_Sandbox_RedList (弹窗)
  + 其他 → P8.Default (自动执行)

ALWAYS_RUN 模式:
  + RedList → V2_Manual_RedList (弹窗!) ← 即使 ALWAYS_RUN + RedList 仍弹窗!
  + 其他 → P8.Default (自动执行)

默认 (Ask/Blacklist):
  + RedList → V2_Manual_RedList (弹窗)
  + 其他 → V2_Manual (弹窗)
```

**关键**: 只有 `P8.Default` = 真正自动执行。即使 `ALWAYS_RUN + RedList` 仍弹窗。

### 4. 命令执行管道

```
AI 生成 tool_call → SSE PlanItem 事件 → DG.parse() @7318521
  → PlanItemStreamParser._handlePlanItem() @7502500
    → provideUserResponse({decision:"confirm"}) [自动确认补丁]
    → 服务器接收决策 → icube.shellExec.runCommand
      → ExtHostShellExecService.runCommand()
        → ShellExecutor.spawn*Command()
          → child_process 执行
            → 输出捕获 → 状态快照 → SSE 回传结果
```

### 5. SAFE_RM 沙箱安全规则

| 环境变量 | 用途 |
|----------|------|
| `SAFE_RM_ALLOWED_PATH` | 允许删除/修改的路径白名单 |
| `SAFE_RM_DENIED_PATH` | 禁止操作的路径黑名单 |
| `SAFE_RM_SCRIPT_DIR` | safe_rm 脚本目录 |
| `SAFE_RM_AUTO_ADD_TEMP` | 自动添加临时目录到白名单 |

拦截的命令: Remove-Item, Move-Item, Copy-Item, Out-File, Set-Content (PowerShell)
拦截的命令: del, erase, rd, rmdir (CMD)

### 6. provideUserResponse 调用点

| # | 位置 | 调用者 | 决策 |
|---|--------|--------|------|
| 1 | ~7502574 | PlanItemStreamParser (知识分支) | `"confirm"` |
| 2 | ~7503319 | PlanItemStreamParser (其他分支) | `"confirm"` |
| 3 | ~8635000+ | egR 组件 (用户确认) | `"confirm"` |
| 4 | ~8635000+ | egR 组件 (用户拒绝) | `"reject"` |

### 7. 搜索模板

| 目标 | 搜索关键词 | 稳定性 |
|------|-----------|--------|
| BlockLevel | `"redlist"` | ⭐⭐⭐⭐⭐ |
| AutoRunMode | `"allowlist"` | ⭐⭐⭐⭐⭐ |
| ConfirmMode | `"alwaysAsk"` | ⭐⭐⭐⭐⭐ |
| 决策函数 | `getRunCommandCardBranch` | ⭐⭐⭐ |
| 确认 API | `provideUserResponse` | ⭐⭐⭐⭐ |
| 确认类型 | `"tool_confirm"` | ⭐⭐⭐⭐⭐ |
| SAFE_RM | `SAFE_RM_ALLOWED_PATH` | ⭐⭐⭐⭐⭐ |

## [2026-04-25 21:00] MCP/工具调用系统完整映射 ⭐⭐⭐⭐⭐

> MCP/工具调用系统是 Trae AI 的能力扩展层。本节完整映射了工具调用生命周期。

### 1. ToolCallName 枚举 (80+ 工具, 偏移 ~41400/~7076154)

#### 命令执行类

| 枚举值 | 字符串 | 用途 |
|--------|--------|------|
| RunCommand | `"run_command"` | Shell 命令执行 |
| MCPCall | `"run_mcp"` | MCP 工具调用 |
| check_command_status | `"check_command_status"` | 检查命令状态 |

#### 文件操作类

| 枚举值 | 字符串 | 用途 |
|--------|--------|------|
| Read | `"Read"` | 读取文件 |
| Write | `"Write"` | 写入文件 |
| Edit | `"Edit"` | 编辑文件 |
| MultiEdit | `"MultiEdit"` | 多处编辑 |
| Glob | `"Glob"` | Glob 模式搜索 |
| Grep | `"Grep"` | Grep 搜索 |
| LS | `"LS"` | 列出目录 |
| SearchReplace | `"SearchReplace"` | 搜索替换 |
| SearchCodebase | `"SearchCodebase"` | 代码库搜索 |

#### 用户交互类 (排除自动确认)

| 枚举值 | 字符串 | 用途 |
|--------|--------|------|
| response_to_user | `"response_to_user"` | 询问用户 |
| AskUserQuestion | `"AskUserQuestion"` | 提问用户 |
| NotifyUser | `"NotifyUser"` | 通知用户 |
| ExitPlanMode | `"ExitPlanMode"` | 退出计划模式 |

#### 浏览器操作类 (20+ 工具)
- `browser_*` 系列 (navigate, click, screenshot 等)

### 2. 工具调用生命周期

```
1. 发起: AI 模型生成 tool_call (tool_name, tool_input, toolcall_id)
2. 传输: SSE "planItem" 事件 + confirm_info
3. 解析: DG.parse() @7318521 → 结构化对象
4. 处理: PlanItemStreamParser._handlePlanItem() @7502500
   → 检查 confirm_status → provideUserResponse()
5. 决策: getRunCommandCardBranch() @8069620 → UI 分支
6. 执行: 服务器 → icube.shellExec.runCommand → child_process
7. 结果: 命令输出 → SSE 回传 → 聊天显示
8. 完成: DoneStreamParser.parse() → 标记轮次完成
```

### 3. confirm_info 数据结构

```javascript
confirm_info = {
    confirm_status: "unconfirmed" | "confirmed" | "canceled" | "skipped",
    auto_confirm: true | false,
    hit_red_list: ["Remove-Item", ...],
    hit_blacklist: [...],
    block_level: "redlist" | "blacklist" | "sandbox_*",
    run_mode: "auto" | "manual" | "allowlist" | "in_sandbox" | "out_sandbox",
    now_run_mode: "in_sandbox" | "out_sandbox" | ...
}
```

### 4. MCP 集成

MCP 工具调用 (`run_mcp`) 与 `run_command` 共享相同的确认管道。自动确认补丁覆盖 MCP 调用，因为它们确认所有 `toolName !== "response_to_user"` 的调用。

### 5. 搜索模板

| 目标 | 搜索关键词 | 稳定性 |
|------|-----------|--------|
| MCP 调用 | `"run_mcp"` | ⭐⭐⭐⭐⭐ |
| 工具枚举 | `"ToolCallName"` | ⭐⭐ |
| 确认信息 | `"confirm_info"` | ⭐⭐⭐⭐ |
| 确认状态 | `"unconfirmed"` | ⭐⭐⭐⭐⭐ |
| 工具确认 | `"tool_confirm"` | ⭐⭐⭐⭐⭐ |

---

# 偏移量索引与交叉引用

> 以下索引按域、偏移量范围和功能组织，方便快速定位代码。

## 按探索域索引

### [DI] 依赖注入

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~6268469 | DI 容器类 (uj) | ⭐⭐ |
| ~6270579 | uB useInject Hook + hX 快捷方式 | ⭐⭐ |
| ~6473533 | bY = Symbol.for("aiAgent.ILogService") | ⭐⭐⭐⭐⭐ |
| ~7015771 | Ei = Symbol.for("aiAgent.ICredentialFacade") | ⭐⭐⭐⭐⭐ |
| ~7087490 | xC = Symbol("ISessionStore") | ⭐⭐⭐⭐ |
| ~7097170 | SessionStore 注册 | ⭐⭐⭐⭐ |
| ~7135785 | Ma = Symbol.for("ITeaFacade") | ⭐⭐⭐⭐⭐ |
| ~7150072 | M0 = Symbol.for("aiAgent.ISessionService") | ⭐⭐⭐⭐⭐ |
| ~7152097 | SessionService 注册 (Ci) | ⭐⭐⭐⭐ |
| ~7186457 | k1 = Symbol("IModelStore") | ⭐⭐⭐⭐ |
| ~7203850 | IN = Symbol("ISessionRelationStoreInternal") | ⭐⭐⭐⭐ |
| ~7221939 | I2 = Symbol("IInlineSessionStore") | ⭐⭐⭐⭐ |
| ~7224039 | I7 ProjectStore | ⭐⭐⭐ |
| ~7248275 | TG AgentExtensionStore | ⭐⭐⭐ |
| ~7258315 | Na SkillStore | ⭐⭐⭐ |
| ~7259427 | Nc EntitlementStore | ⭐⭐⭐ |
| ~7545196 | BO = Symbol("ISessionServiceV2") | ⭐⭐⭐⭐ |

### [SSE] 流管道

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~7300000 | EventHandlerFactory (Bt) | ⭐⭐⭐ |
| ~7314000 | MetadataParser (DQ) + UserMessageContextParser (DV) | ⭐⭐⭐⭐ |
| ~7318521 | DG.parse() 服务端响应解析器 | ⭐⭐⭐⭐ |
| ~7322410 | NotificationStreamParser | ⭐⭐⭐⭐⭐ |
| ~7323241 | data-source-auto-confirm 补丁位置 | ⭐⭐⭐ |
| ~7482422 | FeeUsageStreamParser (za) | ⭐⭐⭐⭐ |
| ~7497479 | TextMessageChatStreamParser | ⭐⭐⭐⭐⭐ |
| ~7502500 | PlanItemStreamParser._handlePlanItem() | ⭐⭐⭐⭐ |
| ~7503299 | PlanItemStreamParser DI Token | ⭐⭐⭐⭐ |
| ~7508572 | ErrorStreamParser (zU) | ⭐⭐⭐⭐⭐ |
| ~7511057 | DoneStreamParser (zW) | ⭐⭐⭐⭐ |
| ~7512721 | QueueingStreamParser (zV) | ⭐⭐⭐⭐ |
| ~7513080 | getErrorInfoWithError(e) | ⭐⭐⭐ |
| ~7513727 | SSE path exception 写入点 | ⭐⭐ |
| ~7515007 | UserMessageStreamParser (zJ) | ⭐⭐⭐⭐⭐ |
| ~7516765 | TokenUsageStreamParser (z2) | ⭐⭐⭐⭐⭐ |
| ~7517392 | ContextTokenUsageStreamParser (z3) | ⭐⭐⭐⭐⭐ |
| ~7518028 | SessionTitleMessageStreamParser (z8) | ⭐⭐⭐⭐⭐ |
| ~7524723 | Bs class (ChatParserContext) | ⭐⭐ |
| ~7528742 | _onError(e,t,i) | ⭐⭐ |
| ~7533176 | _onStreamingStop → WaitingInput | ⭐⭐ |
| ~7538139 | stopStreaming — "沉默杀手" | ⭐⭐ |
| ~7540700 | createStream() + resumeChat 蓝图 | ⭐⭐⭐ |
| ~7540953 | _aiAgentChatService.resumeChat() | ⭐⭐⭐ |
| ~7610443 | F3/sendToAgentBackground (DI 蓝图) | ⭐⭐⭐ |
| ~7614717 | ResumeChat 服务端方法调用 | ⭐⭐⭐ |
| ~7615777 | TaskAgentMessageParser.parse() — IPC exception 写入 | ⭐⭐⭐⭐ |

### [Store] 状态架构

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~3211326 | needConfirm Zustand store | ⭐⭐⭐ |
| ~7584046 | subscribe #1 (消息数+会话ID) | ⭐⭐⭐ |
| ~7588518 | subscribe #8 (消息数变化) | ⭐⭐⭐ |
| ~7605848 | runningStatusMap subscribe | ⭐⭐⭐ |

### [Error] 错误系统

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~54000 | kg 错误码枚举 (第一段) | ⭐⭐⭐ |
| ~54269 | LLM_STOP_DUP_TOOL_CALL=4000009 | ⭐⭐⭐⭐⭐ |
| ~54415 | TASK_TURN_EXCEEDED_ERROR=4000002 | ⭐⭐⭐⭐⭐ |
| ~7161400 | kg 错误码枚举 (第二段) | ⭐⭐⭐ |
| ~7161547 | LLM_STOP_CONTENT_LOOP=4000012 | ⭐⭐⭐⭐⭐ |
| ~7169408 | 错误码→消息映射 | ⭐⭐⭐ |
| ~7300455 | handleCommonError() | ⭐⭐⭐ |
| ~7458679 | teaEventChatFail() | ⭐⭐⭐⭐ |
| ~8695303 | efh 可恢复错误列表 | ⭐⭐⭐ |
| ~8696378 | J 变量 (可续接错误标志) | ⭐⭐ |

### [React] UI 层

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~2796260 | Pause/Send 按钮 (ei) | ⭐⭐ |
| ~8069382 | BlockLevel/AutoRunMode/ConfirmMode 枚举 | ⭐⭐⭐⭐⭐ |
| ~8069620 | getRunCommandCardBranch() | ⭐⭐⭐ |
| ~8070328 | bypass-runcommandcard-redlist 补丁 | ⭐⭐ |
| ~8629200 | UI 确认状态检查 | ⭐⭐ |
| ~8635000 | egR (RunCommandCard) 组件 | ⭐⭐ |
| ~8636941 | ey useMemo (有效确认状态) | ⭐⭐ |
| ~8637300 | confirm_info 解构 | ⭐⭐ |
| ~8640019 | 自动确认 useEffect | ⭐⭐ |
| ~8697580 | ec callback (retry/resume) | ⭐⭐ |
| ~8697620 | ed callback ("继续"按钮) | ⭐⭐ |
| ~8700000 | ErrorMessageWithActions 开始 | ⭐⭐ |
| ~8702300 | if(V&&J) Alert 分支 | ⭐ |
| ~8709284 | sX().memo(Jj) 组件 | ⭐ |
| ~8930000 | ErrorMessageWithActions 结束 | ⭐ |
| ~9910446 | DEFAULT 错误组件 | ⭐⭐ |

### [IPC] 进程间通信

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~7610443 | cancelEventKey (window.addEventListener) | ⭐⭐⭐⭐ |

### [Setting] 设置系统

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~7438613 | AI.toolcall.confirmMode | ⭐⭐⭐⭐⭐ |
| ~7438600 | AI.toolcall.v2.command.* | ⭐⭐⭐⭐⭐ |

### [Sandbox] 沙箱

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~8069382 | BlockLevel/AutoRunMode/ConfirmMode 枚举定义 | ⭐⭐⭐⭐⭐ |
| ~8069620 | getRunCommandCardBranch() 决策函数 | ⭐⭐⭐ |
| ~7502574 | provideUserResponse (知识分支) | ⭐⭐⭐⭐ |
| ~7503319 | provideUserResponse (其他分支) | ⭐⭐⭐⭐ |

### [MCP] 工具调用

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~41400 | ToolCallName 枚举 (第一段) | ⭐⭐ |
| ~7076154 | ToolCallName 枚举 (第二段) | ⭐⭐ |

## 按偏移量范围索引

### 0-1M (枚举 + 工具定义)

| 偏移量 | 域 | 内容 |
|--------|-----|------|
| ~41400 | MCP | ToolCallName 枚举 |
| ~44403 | React | Ck.Unconfirmed="unconfirmed" |
| ~46816 | Store | RunningStatus 枚举 (Io) |
| ~47202 | Error | ChatTurnStatus 枚举 (bQ) |
| ~54000 | Error | kg 错误码枚举 (第一段) |

### 1M-5M (UI 组件)

| 偏移量 | 域 | 内容 |
|--------|-----|------|
| ~2665348 | React | AI.NEED_CONFIRM 枚举 |
| ~2796260 | React | Pause/Send 按钮 |
| ~3211326 | Store | needConfirm 状态 |

### 5M-8M (核心服务层 — 最密集区域)

| 偏移量 | 域 | 内容 |
|--------|-----|------|
| ~6268469 | DI | DI 容器类 (uj) |
| ~6270579 | DI | uB useInject Hook |
| ~6473533 | DI | bY LogService Token |
| ~7015771 | DI | Ei CredentialFacade Token |
| ~7076154 | MCP | ToolCallName 枚举 (第二段) |
| ~7087490 | DI/Store | xC SessionStore Token |
| ~7135785 | DI | Ma TeaFacade Token |
| ~7150072 | DI | M0 SessionService Token |
| ~7161400 | Error | kg 错误码枚举 (第二段) |
| ~7186457 | DI/Store | k1 ModelStore Token |
| ~7221939 | DI/Store | I2 InlineSessionStore Token |
| ~7300000 | SSE | EventHandlerFactory (Bt) |
| ~7318521 | SSE | DG.parse() |
| ~7438613 | Setting | AI.toolcall.confirmMode |
| ~7458679 | Error | teaEventChatFail() |
| ~7502500 | SSE | PlanItemStreamParser._handlePlanItem() |
| ~7508572 | SSE | ErrorStreamParser (zU) |
| ~7524723 | SSE | Bs class (ChatParserContext) |
| ~7545196 | DI | BO SessionServiceV2 Token |
| ~7584046 | Store | subscribe #1 |
| ~7588518 | Store | subscribe #8 |
| ~7605848 | Store | runningStatusMap subscribe |
| ~7610443 | IPC | F3/sendToAgentBackground |
| ~7615777 | Error | TaskAgentMessageParser.parse() |

### 8M-10M (UI 层)

| 偏移量 | 域 | 内容 |
|--------|-----|------|
| ~8069382 | Sandbox | BlockLevel/AutoRunMode/ConfirmMode 枚举 |
| ~8069620 | Sandbox | getRunCommandCardBranch() |
| ~8635000 | React | egR (RunCommandCard) |
| ~8695303 | Error | efh 可恢复错误列表 |
| ~8696378 | Error | J 变量 (可续接错误标志) |
| ~8700000 | React | ErrorMessageWithActions |
| ~8702300 | React | if(V&&J) 分支 |
| ~8709284 | React | sX().memo(Jj) 组件 |

## 按功能索引

### 自动确认 (Auto-Confirm)

| 偏移量 | 内容 | 层 |
|--------|------|-----|
| ~7323241 | data-source-auto-confirm 补丁 | L3 |
| ~7502500 | PlanItemStreamParser._handlePlanItem() | L2 |
| ~7502574 | knowledge 分支 provideUserResponse | L2 |
| ~7503319 | else 分支 provideUserResponse | L2 |
| ~8069620 | getRunCommandCardBranch() | L1 |
| ~8070328 | bypass-runcommandcard-redlist 补丁 | L1 |
| ~8635000 | egR (RunCommandCard) | L1 |
| ~8640019 | 自动确认 useEffect | L1 |

### 自动续接 (Auto-Continue)

| 偏移量 | 内容 | 层 |
|--------|------|-----|
| ~7458679 | teaEventChatFail() | L2 |
| ~7538139 | stopStreaming — "沉默杀手" | L2 |
| ~7540953 | _aiAgentChatService.resumeChat() | L2 |
| ~7588518 | subscribe #8 | L2 |
| ~8695303 | efh 可恢复错误列表 | L1 |
| ~8696378 | J 变量 | L1 |
| ~8702300 | if(V&&J) 分支 | L1 |

### 沙箱/命令执行

| 偏移量 | 内容 | 层 |
|--------|------|-----|
| ~8069382 | BlockLevel/AutoRunMode/ConfirmMode 枚举 | L1 |
| ~8069620 | getRunCommandCardBranch() | L1 |
| ~7502574 | provideUserResponse (知识分支) | L2 |
| ~7503319 | provideUserResponse (其他分支) | L2 |

### 错误处理

| 偏移量 | 内容 | 层 |
|--------|------|-----|
| ~54000 | kg 错误码枚举 | 枚举 |
| ~7161400 | kg 错误码枚举 (第二段) | 枚举 |
| ~7300455 | handleCommonError() | L2 |
| ~7458679 | teaEventChatFail() | L2 |
| ~7508572 | ErrorStreamParser (zU) | L2 |
| ~7513080 | getErrorInfoWithError(e) | L2 |
| ~7528742 | _onError(e,t,i) | L2 |
| ~7615777 | TaskAgentMessageParser.parse() | L2 |

### 设置/配置

| 偏移量 | 内容 | 层 |
|--------|------|-----|
| ~7438613 | AI.toolcall.confirmMode | 配置 |
| ~7438600 | AI.toolcall.v2.command.* | 配置 |
