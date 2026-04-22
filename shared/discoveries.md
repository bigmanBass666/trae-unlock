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
| **auto-continue-thinking** | **v8** | **L1+L2** | ⚠️ 测试中 |
| auto-continue-l2-event | v1 | L2 | ⚠️ 测试中 |
| efh-resume-list | v3 | L1 | ✅ |
| bypass-loop-detection | v4 | L1 | ✅ |
| bypass-runcommandcard-redlist | v2 | L1 | ⚠️ 仅改样式 |
