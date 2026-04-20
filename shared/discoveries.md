---
module: discoveries
description: 重要发现和代码定位
read_priority: P2
read_when: 需要相关知识时
write_when: 发现关键信息时
format: registry
---

# 重要发现

> 关键代码位置、架构关系、枚举值等

> 📝 写入格式遵循 `shared/_registry.md` 中的约定

### [2026-04-18 10:00] PlanItemStreamParser SSE 流解析器

**位置**: ~7502500
**层级**: 服务层（不依赖 React）
**作用**: 解析服务端 SSE 流返回的 planItem，是命令确认流程的核心入口。`_handlePlanItem()` 方法检测 `confirm_status==="unconfirmed"` 后可调用 `provideUserResponse` 自动确认。切窗口不冻住，是最可靠的补丁注入点。

---

### [2026-04-19 15:00] 30 个 Alert 弹窗渲染点

**位置**: ~8700000-8930000
**组件**: ErrorMessageWithActions
**发现**: 扫描发现 30 个 Alert 弹窗渲染点，其中只有 1 个被补丁覆盖（if(V&&J) 可继续错误分支）。其余 29 个尚未处理，是未来扩展的潜在目标。

---

### [2026-04-19 12:00] 错误码枚举

**位置**: ~54000（第一处）/ ~7161400（第二处）
**关键值**:
- `TASK_TURN_EXCEEDED_ERROR = 4000002` — 思考次数上限
- `LLM_STOP_DUP_TOOL_CALL = 4000009` — 重复工具调用循环
- `LLM_STOP_CONTENT_LOOP = 4000012` — 内容循环
- `MODEL_OUTPUT_TOO_LONG` — 输出过长
- 待处理: MODEL_PREMIUM_EXHAUSTED、CLAUDE_MODEL_FORBIDDEN、INVALID_TOOL_CALL

---

### [2026-04-18 15:00] BlockLevel 枚举

**位置**: ~8069382
**枚举值**:
- `RedList = "redlist"` — 危险命令（Remove-Item 等）
- `Blacklist = "blacklist"` — 企业策略禁止
- `SandboxExecuteFailure = "sandbox_execute_failure"` — 沙箱执行失败
- `SandboxToRecovery = "sandbox_to_recovery"` — 沙箱恢复
- `SandboxUnavailable = "sandbox_unavailable"` — 沙箱不可用

---

### [2026-04-19 10:00] ToolCallName 枚举

**位置**: ~41400
**关键值**:
- `RunCommand = "run_command"` — 命令执行（需自动确认）
- `ResponseToUser = "response_to_user"` — 用户问答（不应自动确认）
- 其他 30+ 种工具类型（文件操作/搜索/MCP 等）

---

### [2026-04-18 18:00] 确认系统双层架构

**Layer 1**: PlanItemStreamParser（服务层，~7502574）— 检测 `confirm_status==="unconfirmed"` → `provideUserResponse`
**Layer 2**: RunCommandCard（UI 层，~8069620）— `getRunCommandCardBranch()` 根据 BlockLevel + AutoRunMode 决定 UI 分支
**关键**: 两层完全独立，只补一层另一层仍会弹窗。服务层补丁不受 React 冻结影响，UI 层补丁切窗口后失效。

---

### [2026-04-20 15:00] 闭环是分形的

**发现者**: 用户洞察
**性质**: 元认知发现
**内容**: "闭环"这一概念本身没有范围边界。我们解决了项目级闭环（同一项目跨会话通信），但无意中硬编码了闭环的边界——默认闭环只在项目内。实际上闭环是分形的：
- 会话级闭环（AI 自身记忆）
- 项目级闭环（Anchor shared/ 系统）
- 跨项目级闭环（项目 A 的 AI 学习项目 B 的模式）
- 更高级别闭环（？）

**启示**: 不要硬编码闭环的范围和边界。今天解决项目级，明天可能需要跨项目级。设计时应保持闭环机制的可扩展性，而非假设闭环只在当前层级。

---

### [2026-04-20 16:00] getRunCommandCardBranch 完整分支逻辑

**位置**: ~8069620
**函数签名**: `getRunCommandCardBranch({ run_mode_version, autoRunMode, blockLevel, hasBlacklist })`
**核心逻辑**: v2 模式下，根据 AutoRunMode + BlockLevel + hasBlacklist 三元组决定返回值

**交互矩阵**:
| AutoRunMode | BlockLevel | hasBlacklist | 返回值 | 行为 |
|-------------|-----------|-------------|--------|------|
| WHITELIST | RedList | - | V2_Sandbox_RedList | 弹窗 |
| WHITELIST | Sandbox* | false | V2_Sandbox_* | 弹窗 |
| WHITELIST | Sandbox* | true | V2_Sandbox_*_RedList | 弹窗 |
| WHITELIST | default | - | **Default** | **自动执行** |
| ALWAYS_RUN | RedList | - | V2_Manual_RedList | 弹窗 |
| ALWAYS_RUN | (任何) | true | V2_Manual_RedList | 弹窗 |
| ALWAYS_RUN | (其他) | false | **Default** | **自动执行** |
| default(Ask) | RedList | - | V2_Manual_RedList | 弹窗 |
| default(Ask) | (任何) | true | V2_Manual_RedList | 弹窗 |
| default(Ask) | (其他) | false | V2_Manual | 弹窗 |

**关键**: 只有 `P8.Default` 才是真正的自动执行。即使 ALWAYS_RUN + RedList 仍然弹窗。

---

### [2026-04-20 16:10] provideUserResponse 完整调用链

**API 签名**: `this._taskService.provideUserResponse({task_id, type:"tool_confirm", toolcall_id, tool_name, decision:"confirm"|"reject"})`
**所属服务**: _taskService (TaskService)

**4 个调用点**:
1. ~7502574: PlanItemStreamParser knowledge 分支 — `confirm_status==="unconfirmed" && toolName!=="response_to_user"`
2. ~7503319: PlanItemStreamParser else 分支 — `toolName!=="response_to_user" && confirm_status!=="confirmed"`
3. ~8635000+: egR 组件用户手动点击确认 — decision="confirm"
4. ~8635000+: egR 组件用户手动点击拒绝 — decision="reject"

**成功后处理链**: provideUserResponse → 服务端执行命令 → 本地同步 confirm_status="confirmed" → Zustand Store 更新 → React re-render
**失败后处理链**: .catch(e=>{this._logService.warn(...)}) → confirm_status 保持 "unconfirmed" → UI 继续显示"等待操作"

**关键**: 没有单独的 SSE 事件确认服务端收到响应。调用后必须手动同步本地 confirm_info.confirm_status。

---

### [2026-04-20 16:20] J 变量和 efh 列表 — 错误恢复的两条路径

**J 变量** (~8696378): 控制是否显示"继续"按钮
- `J=!![kg.MODEL_OUTPUT_TOO_LONG, kg.TASK_TURN_EXCEEDED_ERROR, kg.LLM_STOP_DUP_TOOL_CALL, kg.LLM_STOP_CONTENT_LOOP].includes(_)`
- J=true → Alert + "继续"按钮 → 可自动续接
- J=false → 只显示错误消息 → 对话终止

**efh 列表** (~8695303): 控制是否可自动恢复（resumeChat）
- 包含 14 个网络/服务错误码（SERVER_CRASH, CONNECTION_ERROR, MODEL_FAIL 等）
- 补丁后新增: TASK_TURN_EXCEEDED_ERROR
- ec 回调: `if("v3"===p && e.includes(_)) D.resumeChat()` — v3 进程 + 错误在 efh 中 → 自动恢复

**两条恢复路径**:
1. **resumeChat 路径** (ec 回调): 错误在 efh 列表中 + agentProcess==="v3" → 自动调用 D.resumeChat()
2. **sendChatMessage 路径** (ed 回调): 发送 "Continue" 文本作为新消息 → 开始新一轮对话

---

### [2026-04-20 16:30] AutoRunMode 和 ConfirmMode 枚举

**AutoRunMode** (ee, ~8069382):
- Auto="auto", Manual="manual", Allowlist="allowlist", InSandbox="in_sandbox", OutSandbox="out_sandbox"

**ConfirmMode** (ei, ~8069382) — 用户设置:
- ALWAYS_ASK="alwaysAsk" — 每次都问
- WHITELIST="whitelist" — 白名单内自动
- BLACKLIST="blacklist" — 黑名单外自动
- ALWAYS_RUN="alwaysRun" — 全自动

**设置 Key**: `AI.toolcall.confirmMode` (~7438613)

**关系**: ConfirmMode 是用户可见的设置选项，AutoRunMode 是服务端返回的运行模式。getRunCommandCardBranch 根据 AutoRunMode 分发，而 ConfirmMode 决定用户选择哪种 AutoRunMode。

---

### [2026-04-20 16:40] confirm_info 完整数据结构

**位置**: 服务端 SSE 流返回，嵌套在 planItem 中

```javascript
confirm_info = {
  confirm_status: "unconfirmed" | "confirmed" | "canceled" | "skipped",
  auto_confirm: true | false,          // knowledge 背景任务为 true
  hit_red_list: ["Remove-Item", ...],  // 命中的危险命令列表
  hit_blacklist: [...],                // 命中的企业黑名单
  block_level: "redlist" | "blacklist" | "sandbox_not_block_command" |
               "sandbox_execute_failure" | "sandbox_to_recovery" | "sandbox_unavailable",
  run_mode: "auto" | "manual" | "allowlist" | "in_sandbox" | "out_sandbox",
  now_run_mode: "in_sandbox" | "out_sandbox" | ...
}
```

**生命周期**: 服务端 SSE → DG.parse(~7318521) → PlanItemStreamParser(~7502500) → Zustand Store(~3211326) → React 组件(~8635000)

**状态转换**: unconfirmed → confirmed (用户/自动确认) | canceled (用户取消) | skipped (跳过)

---

### [2026-04-20 16:50] 17 个 Alert 渲染点完整列表

**位置**: ~8700000-8930000 (ErrorMessageWithActions 组件)
**已覆盖**: 仅 #5 (if(V&&J) 可继续错误分支) — auto-continue-thinking 补丁

| # | 位置 | 错误码/名称 | 类型 | 补丁覆盖 |
|---|------|------------|------|---------|
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

**推荐解锁**: 将错误码加入 J 变量使其成为可继续错误（低难度），或加入 efh 列表使其可自动恢复

---

### [2026-04-20 17:20] ew.confirm() 是日志打点而非执行函数

**位置**: ~8635000+ (egR 组件内)
**发现**: RunCommandCard 组件中，用户点击"确认"按钮时调用了 `ew.confirm(true)`，直觉上以为这是触发命令执行的函数。实际上 `ew.confirm()` **只是 telemetry/日志打点函数**，不触发任何业务逻辑。

**真正的执行函数**: `eE(Ck.Confirmed)` — 这才是触发状态更新和命令执行的核心函数。

**自动确认 effect** (~8640019) 中也调用了 `ew.confirm(!0)`：
```javascript
useEffect(() => {
  !e && er === Ck.Unconfirmed && en && ew.confirm(!0)
}, [e, en, ew.confirm])
```
这里 `ew.confirm(true)` 也只是打点，真正让命令执行的是 React 状态更新触发的 re-render（ey 变为 Confirmed → 组件不再显示弹窗 → 后续流程继续）。

**启示**: 在压缩代码中，函数名被混淆后无法从名字判断功能。必须追踪调用链才能确定函数的真实作用。这个发现让我们在 v1-v4 版本的补丁中走了弯路——试图在 React 层修改 ew.confirm 的行为，而真正需要修改的是服务层的 provideUserResponse 调用。

---

### [2026-04-20 19:30] 脏备份残留代码导致 AskUserQuestion 被自动确认

**位置**: ~7503942 (service-layer-runcommand-confirm 补丁区域)
**发现**: 回滚到脏备份(20260419-003102)后，apply-patches 只**追加**了 v6 代码，没有删除旧版 service-layer-confirm-status-update 的残留代码。导致 3 个 provideUserResponse 调用（2个有过滤+1个无过滤），无过滤的调用使 AskUserQuestion 被自动确认，返回 null。
**特征**: 残留代码使用 `.catch(function(e){this._logService...})`（非箭头函数），而非 v6 的箭头函数格式
**修复**: 删除 313 字符残留代码，创建干净备份(20260420-072436)
**启示**: 回滚到包含旧版补丁的备份后，重新 apply-patches 不会清理旧代码——它只做追加。未来回滚应使用干净备份

---

### [2026-04-20 20:30] Trae 更新导致 ey useMemo 逻辑变化

**位置**: ~8636971 (RunCommandCard 组件)
**发现**: Trae 更新后 `ey` useMemo 的逻辑从 `er===Unconfirmed?Confirmed:en?Confirmed:...` 变为 `en?Confirmed:e&&er===Unconfirmed?Canceled:er`。旧版 Unconfirmed 直接返回 Confirmed（自动确认），新版必须 auto_confirm=true 才能确认
**相关发现**: 所有 P8 枚举值（Default, V1_*, V2_*）都有 buttons 定义，没有"无弹窗"值。bypass-runcommandcard-redlist 改变 P8 返回值只影响按钮样式，不影响是否显示弹窗
**根因修复**: data-source-auto-confirm 在数据解析层（~7318521）设置 auto_confirm=true，让 ey 的 en=true → 直接返回 Confirmed
**启示**: 控制弹窗的是 auto_confirm 标志 + confirm_status 状态，不是 P8 值。数据源层修改是最可靠的方案——不受 React 组件渲染时序影响

---

### [2026-04-20 20:10] 完整 toolName 枚举与分类

**位置**: `ee` 枚举（偏移 ~7076154-7079682）
**发现**: 源码中定义了 80+ 个 toolName，通过 `ee.XXX="toolName"` 形式定义。完整分类如下：
- **需要用户交互（禁止自动确认）**: `response_to_user`, `AskUserQuestion`, `NotifyUser`, `ExitPlanMode`
- **命令执行类**: `RunCommand`, `run_mcp`, `check_command_status`
- **文件操作类**: `Read`, `Write`, `Edit`, `MultiEdit`, `Glob`, `Grep`, `LS`, `SearchReplace`, `SearchCodebase`, `view_file`, `view_files`, `view_folder`, `write_to_file`, `edit_file_search_replace`, `create_file`, `delete_file`, `file_search`, `show_diff`, `show_diff_fc`
- **浏览器操作类**: `browser_*`（20+个）
- **搜索/索引类**: `search_by_*`, `TodoWrite`, `todo_write`, `web_search`, `WebSearch`
- **任务/代理类**: `Task*`, `Team*`, `agent_finish`, `finish`, `Skill`, `CompactFake`
- **预览/环境类**: `OpenPreview*`, `open_folder`, `init_env`, `image_ocr`, `get_preview_console_logs`, `get_llm_config`
- **外部服务类**: `deploy_to_remote`, `stripe_*`, `supabase_*`, `edit_product_document_*`, `write_to_product_document`
- **记忆/内部类**: `manage_core_memory`, `*_shallow_memento*`, `create_requirement`
**启示**: 黑名单必须基于完整枚举设计，不能只凭经验添加。`SendMessage` 暂不加入黑名单（走不同确认流程）

---

### [2026-04-20 19:50] 黑名单不完整导致 AskUserQuestion 被自动确认

**位置**: ~7503319 (service-layer-runcommand-confirm else 分支)
**发现**: service-layer-runcommand-confirm v6 的 else 分支只过滤了 `response_to_user`，但 AskUserQuestion 的 toolName 是 `"AskUserQuestion"` 不是 `"response_to_user"`，所以 else 分支会自动确认 AskUserQuestion，导致 AskUserQuestion 返回 null
**根因**: 黑名单设计时只考虑了 response_to_user 一种需要排除的工具，没有考虑其他需要用户交互的工具（如 AskUserQuestion）
**修复**: v7 将黑名单从 `e?.toolName!=="response_to_user"` 扩展为 `e?.toolName!=="response_to_user"&&e?.toolName!=="AskUserQuestion"`
**启示**: 黑名单不能只过滤已知的排除项，需要考虑所有需要用户交互的工具类型

---

### [2026-04-20 20:40] 三层架构分层法则 — 补丁修改的黄金规则

**位置**: 全局架构（跨多个偏移区域）
**发现**: Trae 的命令确认系统分为三层，每层的能力和限制完全不同：

```
┌─────────────────────────────────────────┐
│  L1 UI 层 (React 组件)  ~8640000        │  改这里 = 治标不治本
│  - RunCommandCard: ey useMemo, useEffect │
│  - P8 枚举: 只控制按钮样式，不控制弹窗   │
│  - 所有15个P8值都有buttons定义，无"无弹窗"值
├─────────────────────────────────────────┤
│  L2 服务层 (PlanItemStreamParser) ~750万 │  改这里 = 直接告诉服务端已确认
│  - provideUserResponse: 主动确认调用     │
│  - confirm_status: 状态管理              │
│  - 黑名单过滤: 控制哪些工具不被自动确认    │
├─────────────────────────────────────────┤
│  L3 数据层 (DG.parse)     ~7318521       │  改这里 = 从源头改变数据流
│  - auto_confirm 标志: 让UI层以为用户同意了│
│  - 最底层拦截，所有下游组件都能看到       │
│  - 不受React渲染时序影响，不受ey逻辑变化影响
└─────────────────────────────────────────┘
```

**各层补丁效果验证**:
| 补丁 | 所在层 | 预期 | 实际 |
|------|--------|------|------|
| bypass-runcommandcard-redlist v2 | L1 UI | 不弹窗 | ❌ 只改按钮样式 |
| force-auto-confirm | L1 UI | 自动确认 | ❌ 条件依赖auto_confirm |
| sync-force-confirm | L1 UI | 同步确认 | ❌ Trae更新后失效 |
| auto-confirm-commands / service-layer-runcommand-confirm | L2 服务 | 自动确认 | ✅ 有效 |
| data-source-auto-confirm | L3 数据 | 全局auto_confirm=true | ✅✅ 最可靠 |

**黄金规则**:
1. **能从L3解决的，绝不从L1改** — UI层是"症状"，数据层是"病因"
2. **L2是安全区** — provideUserResponse直接和服务端通信，不受UI渲染时序影响
3. **L1只适合做辅助修改** — 如bypass-loop-detection改J变量、efh-resume-list改恢复列表
4. **黑名单必须在L2维护** — L3设置auto_confirm后，L2的黑名单是唯一能阻止不需要的工具被确认的防线
5. **Trae更新主要影响L1** — React组件逻辑经常变，数据解析层相对稳定
