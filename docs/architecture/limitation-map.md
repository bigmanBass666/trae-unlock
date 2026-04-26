---
domain: architecture
sub_domain: limitations
focus: Trae AI 聊天模块中所有可被补丁修改的限制点——错误码枚举（56个）、Alert 渲染点、BlockLevel 判定、ToolCallName 分类和 efh 可恢复错误列表
dependencies: [command-confirm-system.md, commercial-permission-domain.md]
consumers: Developer, Reviewer
created: 2026-04-26
updated: 2026-04-26
format: reference
---

# 限制点地图

> Trae AI 聊天模块中所有可被补丁修改的限制点

> last_verified: 2026-04-26 | 兼容版本: Trae v3.3.x (10490721 chars)

## 1. 概述

本文档列出 Trae AI 聊天模块中所有已发现的限制点，包括确认弹窗、错误阻断、UI 限制等。每个限制点标注了位置、类型、触发条件、当前补丁覆盖状态和推荐解锁方案。

## 2. 错误码枚举完整列表

### 核心错误码 (kg, ~54000 / ~7161400, 共56个)

| 错误码 | 枚举名 | 触发场景 | 可继续(J) | 可恢复(efh) | 补丁覆盖 |
|--------|--------|---------|----------|------------|---------|
| 4000002 | TASK_TURN_EXCEEDED_ERROR | 思考轮次超限 | ✅ 原始 | ✅ 补丁后 | ✅ efh-resume-list |
| 4000003 | LLM_INVALID_JSON | JSON 解析失败 | ❌ | ❌ | ❌ |
| 4000004 | LLM_INVALID_JSON_START | JSON 起始无效 | ❌ | ❌ | ❌ |
| 4000005 | LLM_QUEUING | 排队中 | ❌ | ❌ | ❌ |
| 4000009 | LLM_STOP_DUP_TOOL_CALL | 重复工具调用循环 | ✅ 补丁后 | ❌ | ✅ bypass-loop-detection |
| 4000010 | LLM_TASK_PROMPT_TOKEN_EXCEED_LIMIT | Prompt token 超限 | ❌ | ❌ | ❌ |
| 4000012 | LLM_STOP_CONTENT_LOOP | 内容循环 | ✅ 补丁后 | ❌ | ✅ bypass-loop-detection |
| 700 | FIREWALL_BLOCKED | 防火墙拦截 | ❌ | ❌ | ❌ |
| 4008 | PREMIUM_MODE_USAGE_LIMIT | 高级模式使用限制 | ❌ | ❌ | ❌ |
| 4009 | STANDARD_MODE_USAGE_LIMIT | 标准模式使用限制 | ❌ | ❌ | ❌ |

### 网络/服务错误 (efh 列表, ~8695303)

| 枚举名 | 触发场景 | 可恢复(efh) | 补丁覆盖 |
|--------|---------|------------|---------|
| SERVER_CRASH | 服务端崩溃 | ✅ | ❌ |
| CONNECTION_ERROR | 连接错误 | ✅ | ❌ |
| NETWORK_ERROR | 网络错误 | ✅ | ❌ |
| NETWORK_ERROR_INTERNAL | 内部网络错误 | ✅ | ❌ |
| CLIENT_NETWORK_ERROR | 客户端网络错误 | ✅ | ❌ |
| NETWORK_CHANGED | 网络切换 | ✅ | ❌ |
| NETWORK_DISCONNECTED | 网络断开 | ✅ | ❌ |
| CLIENT_NETWORK_ERROR_INTERNAL | 客户端内部网络错误 | ✅ | ❌ |
| REQUEST_TIMEOUT_ERROR | 请求超时 | ✅ | ❌ |
| REQUEST_TIMEOUT_ERROR_INTERNAL | 内部请求超时 | ✅ | ❌ |
| MODEL_RESPONSE_TIMEOUT_ERROR | 模型响应超时 | ✅ | ❌ |
| MODEL_RESPONSE_FAILED_ERROR | 模型响应失败 | ✅ | ❌ |
| MODEL_AUTO_SELECTION_FAILED | 模型自动选择失败 | ✅ | ❌ |
| MODEL_FAIL | 模型失败 | ✅ | ❌ |

### Alert 渲染点 (~8700000-8930000)

| # | 位置 | 错误码/名称 | 类型 | 中文提示(推断) | 补丁覆盖 |
|---|------|------------|------|--------------|---------|
| 1 | ~8700219 | ENTERPRISE_QUOTA_CONFIG_INVALID | warning | 企业配额配置无效 | ❌ |
| 2 | ~8701000 | MODEL_PREMIUM_EXHAUSTED | warning | 高级模型额度已用尽 | ❌ |
| 3 | ~8701454 | PAYMENT_METHOD_INVALID | warning | 支付方式无效 | ❌ |
| 4 | ~8701681 | INTERNAL_USAGE_LIMIT | warning | 内部使用限制 | ❌ |
| 5 | ~8702300 | if(V&&J) 可继续错误 | warning | (动态消息) | ✅ auto-continue-thinking |
| 6 | ~8702410 | RISK_REQUEST_V2 | error/warning | 风险请求 | ❌ |
| 7 | ~8703141 | CONTENT_SECURITY_BLOCKED | warning | 内容安全拦截 | ❌ |
| 8 | ~8703913 | FREE_ACTIVITY_QUOTA_EXHAUSTED | warning | 免费活动额度已用尽 | ❌ |
| 9 | ~8704548 | CAN_NOT_USE_SOLO_AGENT | warning | 无法使用 Solo Agent | ❌ |
| 10 | ~8705020 | CLAUDE_MODEL_FORBIDDEN | error | Claude 模型被禁止 | ❌ |
| 11 | ~8705534 | REPO_LEVEL_MODEL_UNAVAILABLE | warning | 仓库级模型不可用 | ❌ |
| 12 | ~8705889 | FIREWALL_BLOCKED (700) | error | 防火墙拦截 | ❌ |
| 13 | ~8706759 | EXTERNAL_LLM_REQUEST_FAILED | error | 外部 LLM 请求失败 | ❌ |
| 14 | ~8707685 | PREMIUM_USAGE_LIMIT | error | 高级使用限制 | ❌ |
| 15 | ~8708073 | STANDARD_MODE_USAGE_LIMIT (4009) | error | 标准模式使用限制 | ❌ |
| 16 | ~8708463 | INVALID_TOOL_CALL | error | 无效工具调用 | ❌ |
| 17 | ~8709130 | TOOL_CALL_RETRY_LIMIT | error | 工具调用重试上限 | ❌ |
| 18 | ~8707858 | PREMIUM_MODE_USAGE_LIMIT (4008) | 配额限制 | 高级模式配额限制 | ❌ |
| 19 | ~8707858 | STANDARD_MODE_USAGE_LIMIT (4009) | 配额限制 | 标准模式配额限制 | ❌ |

> **配额限制标志**: ee=!![kg.PREMIUM_MODE_USAGE_LIMIT,kg.STANDARD_MODE_USAGE_LIMIT].includes(_) @8707858

## 3. BlockLevel 限制点

### BlockLevel 枚举 (~8069382)

| 枚举值 | 字符串值 | 含义 | 补丁覆盖 |
|--------|---------|------|---------|
| RedList | `"redlist"` | 红名单：危险命令 | ⚠️ 部分覆盖 |
| Blacklist | `"blacklist"` | 黑名单：企业策略禁止 | ❌ 未覆盖 |
| SandboxNotBlockCommand | `"sandbox_not_block_command"` | 沙箱非阻塞命令 | ⚠️ DISABLED (bypass-whitelist-sandbox-blocks) |
| SandboxExecuteFailure | `"sandbox_execute_failure"` | 沙箱执行失败 | ⚠️ DISABLED (bypass-whitelist-sandbox-blocks) |
| SandboxToRecovery | `"sandbox_to_recovery"` | 沙箱需要恢复 | ⚠️ DISABLED (bypass-whitelist-sandbox-blocks) |
| SandboxUnavailable | `"sandbox_unavailable"` | 沙箱服务不可用 | ⚠️ DISABLED (bypass-whitelist-sandbox-blocks) |

### getRunCommandCardBranch 分支覆盖

| AutoRunMode | BlockLevel | 返回值 | 是否弹窗 | 补丁覆盖 |
|-------------|-----------|--------|---------|---------|
| WHITELIST | 任何 | Default (补丁后) | ❌ 不弹窗 | ✅ bypass-runcommandcard-redlist v2 |
| ALWAYS_RUN | RedList | V2_Manual_RedList | ✅ 弹窗 | ✅ bypass-runcommandcard-redlist v2 |
| ALWAYS_RUN | (其他+无黑名单) | Default | ❌ 不弹窗 | ✅ bypass-runcommandcard-redlist v2 |
| default(Ask) | RedList | V2_Manual_RedList | ✅ 弹窗 | ✅ bypass-runcommandcard-redlist v2 |
| default(Ask) | (其他) | V2_Manual | ✅ 弹窗 | ✅ bypass-runcommandcard-redlist v2 |

## 4. ToolCallName 与确认逻辑

### ToolCallName 枚举 (~41400, 共38个)

| 枚举值 | 字符串值 | 类型 | 确认逻辑 | 补丁覆盖 |
|--------|---------|------|---------|---------|
| RunCommand | `"run_command"` | 命令执行 | 需确认(受BlockLevel) | ✅ 自动确认 |
| ResponseToUser | `"response_to_user"` | 用户问答 | 需用户选择 | ✅ 黑名单排除 |
| CreateFile | `"create_file"` | 文件操作 | 需确认 | ✅ 自动确认 |
| WriteToFile | `"write_to_file"` | 文件操作 | 需确认 | ✅ 自动确认 |
| EditFileSearchReplace | `"edit_file_search_replace"` | 文件操作 | 需确认 | ✅ 自动确认 |
| DeleteFile | `"delete_file"` | 文件操作 | 需确认 | ✅ 自动确认 |
| OpenFolder | `"open_folder"` | 文件操作 | 需确认 | ✅ 自动确认 |
| ViewFile | `"view_file"` | 查看 | 需确认 | ✅ 自动确认 |
| WebSearch | `"web_search"` | 搜索 | 需确认 | ✅ 自动确认 |
| MCPCall | `"run_mcp"` | MCP 调用 | 需确认 | ✅ 自动确认 |
| Finish | `"finish"` | 完成 | 不需确认 | N/A |
| TodoWrite | `"todo_write"` | Todo | 需确认 | ✅ 自动确认 |

> **说明**: 当前黑名单策略只排除 `response_to_user`，其余所有 toolName 默认自动确认。完整枚举共 38 个 ToolCallName (@40836)。

## 5. ConfirmMode 与设置

### ConfirmMode 设置 (已移除枚举，现为设置键)

> **注意**: ConfirmMode 枚举 (ei) 在当前版本中已移除。确认模式现在通过 `AI.toolcall.confirmMode` 设置键 (@7438613) 控制，不再有独立枚举类型。搜索锚点应以 BlockLevel 和 AutoRunMode 为主。

| 枚举值 | 字符串值 | 含义 | 默认行为 |
|--------|---------|------|---------|
| ALWAYS_ASK | `"alwaysAsk"` | 每次都问 | 几乎全部弹窗 |
| WHITELIST | `"whitelist"` | 白名单内自动 | WHITELIST 模式判定 |
| BLACKLIST | `"blacklist"` | 黑名单外自动 | 类似 ALWAYS_ASK |
| ALWAYS_RUN | `"alwaysRun"` | 全自动 | 仅 RedList 弹窗 |

### 设置 Key

| 设置 ID | 位置 | 说明 |
|---------|------|------|
| `AI.toolcall.confirmMode` | ~7438613 | 用户确认模式设置 |
| `command.mode` | ~7438600 | 命令执行模式 |
| `command.allowList` | ~7438600 | 允许的命令列表 |
| `command.denyList` | ~7438600 | 禁止的命令列表 |

## 6. 推荐解锁方案

### 高优先级（影响日常使用）

| 限制点 | 推荐方案 | 难度 |
|--------|---------|------|
| ALWAYS_RUN + RedList 弹窗 | 修改 getRunCommandCardBranch 让 ALWAYS_RUN 模式 RedList 也返回 Default | 中 |
| default(Ask) 模式弹窗 | 修改 getRunCommandCardBranch 让所有模式都返回 Default | 中 |
| MODEL_PREMIUM_EXHAUSTED | 加入 J 变量使其成为可继续错误 | 低 |
| CLAUDE_MODEL_FORBIDDEN | 加入 J 变量使其成为可继续错误 | 低 |

### 中优先级（偶尔遇到）

| 限制点 | 推荐方案 | 难度 |
|--------|---------|------|
| INVALID_TOOL_CALL | 加入 J 变量使其成为可继续错误 | 低 |
| TOOL_CALL_RETRY_LIMIT | 加入 J 变量使其成为可继续错误 | 低 |
| LLM_INVALID_JSON | 加入 efh 列表使其可恢复 | 低 |
| LLM_TASK_PROMPT_TOKEN_EXCEED_LIMIT | 加入 J 变量使其成为可继续错误 | 低 |

### 低优先级（企业/付费相关）

| 限制点 | 推荐方案 | 难度 |
|--------|---------|------|
| ENTERPRISE_QUOTA_CONFIG_INVALID | 可能无法绕过（服务端限制） | 高 |
| PAYMENT_METHOD_INVALID | 可能无法绕过（服务端限制） | 高 |
| FIREWALL_BLOCKED | 可能无法绕过（网络层限制） | 高 |
| CONTENT_SECURITY_BLOCKED | 可能无法绕过（服务端审核） | 高 |

## 7. 枚举速查

### ConfirmStatus / UserConfirmStatusEnum (Ck, ~44416)

| 枚举值 | 字符串值 |
|--------|---------|
| Unconfirmed | `"unconfirmed"` |
| Confirmed | `"confirmed"` |
| Canceled | `"canceled"` |
| Skipped | `"skipped"` |

### AutoRunMode (ee, ~8069382)

| 枚举值 | 字符串值 |
|--------|---------|
| Auto | `"auto"` |
| Manual | `"manual"` |
| Allowlist | `"allowlist"` |
| InSandbox | `"in_sandbox"` |
| OutSandbox | `"out_sandbox"` |

### StreamStopType (j9, ~7479332)

| 枚举值 | 字符串值 |
|--------|---------|
| Cancel | `"Cancel"` |
| Error | `"Error"` |
| Complete | `"Complete"` |

### 用户身份枚举 (bJ, ~6479431)

| 枚举值 | 字符串值 | 含义 |
|--------|---------|------|
| Free | 0 | 免费用户 |
| Pro | 1 | Pro 付费用户 |
| ProPlus | 2 | ProPlus 付费用户 |
| Ultra | 3 | Ultra 付费用户 |
| Trial | 4 | 试用用户 |
| Lite | 5 | Lite 用户 |
| Express | 100 | Express 用户 |

### P0 新发现枚举

| 枚举 | 偏移量 | 内容 | 重要性 |
|------|--------|------|--------|
| ContactType | @55561 | 30+ 配额状态枚举（含免费/付费/试用等细分状态） | ⭐⭐⭐⭐⭐ |
| ChatError | @54993 | 聊天错误码枚举（kg 枚举的补充/替代） | ⭐⭐⭐⭐ |
| API endpoints config | @5870417 | API 端点配置（服务端接口地址映射） | ⭐⭐⭐⭐ |
