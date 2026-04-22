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
