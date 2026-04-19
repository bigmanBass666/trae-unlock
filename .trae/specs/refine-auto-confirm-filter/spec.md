# 精准化自动确认过滤 Spec

## Why

当前 `auto-confirm-commands` 和 `service-layer-runcommand-confirm` 两个补丁会自动确认**所有** `confirm_status === "unconfirmed"` 的 planItem，包括 AI 向用户提问的 AskUserQuestionCard 类型。这导致用户无法看到或回答 AI 的问题，所有选项都被自动"确认"了。

需要让自动化更精准：只自动确认**命令执行类**工具调用（RunCommandCard），跳过**用户问答类**（AskUserQuestionCard）。

## What Changes

- **修改 `service-layer-runcommand-confirm` 补丁**: 增加 `toolName` 过滤条件，只确认命令执行类工具
- **修改 `auto-confirm-commands` 补丁**: 增加相同的过滤条件
- **新增白名单/黑名单机制**: 可配置哪些 toolName 需要自动确认，哪些需要跳过

## Impact

- Affected specs: 无（独立功能）
- Affected code:
  - `ai-modules-chat/dist/index.js` ~7503400 (service-layer 补丁)
  - `ai-modules-chat/dist/index.js` ~7502900 (knowledges 补丁)

## ADDED Requirements

### Requirement: 精准化自动确认过滤

系统 SHALL 只对**命令执行类**工具调用进行自动确认，**不跳过用户问答类**交互。

#### Scenario: RunCommandCard 自动确认成功
- **WHEN** 服务端返回 `confirm_info.confirm_status === "unconfirmed"` 且 `toolName` 为命令执行类（如 `run_command`, `shell_exec` 等）
- **THEN** 系统自动调用 `provideUserResponse({decision: "confirm"})`

#### Scenario: AskUserQuestionCard 不被自动确认
- **WHEN** 服务端返回 `confirm_info.confirm_status === "unconfirmed"` 且 `toolName` 为用户问答类（如 `ask_user_question` 等）
- **THEN** 系统不调用 `provideUserResponse`，保留 UI 让用户手动选择

#### Scenario: 未知 toolName 的安全处理
- **WHEN** `toolName` 无法识别或为空
- **THEN** 默认不自动确认（保守策略），显示 UI 等待用户操作

## MODIFIED Requirements

### Requirement: service-layer-runcommand-confirm 补丁

修改后的补丁 SHALL 在调用 `provideUserResponse` 前**检查 `e?.toolName` 是否在允许列表中**：

```javascript
// 原始逻辑 (过于宽泛):
(e?.toolName||e?.id||e?.toolCallId) && provideUserResponse(...)

// 新逻辑 (精准过滤):
(e?.toolName||e?.id||e?.toolCallId) && 
isAutoConfirmTool(e?.toolName) && 
provideUserResponse(...)
```

其中 `isAutoConfirmTool(toolName)` 函数判断：
- ✅ 允许: `run_command`, `shell_exec`, `execute_command` 等命令执行类
- ❌ 跳过: `ask_user_question`, `user_input` 等用户交互类
- ⚠️ 默认: 不确定时**不自动确认**

### Requirement: auto-confirm-commands 补丁

同理，knowledges 背景任务补丁也需增加相同的 `toolName` 过滤。

## 技术调研待确认项

1. **AskUserQuestion 的 `toolName` 具体值是什么？** — 需要在运行时日志确认
2. **RunCommandCard 的 `toolName` 具体值是什么？** — 可能是 `run_command` 或 `shell_exec`
3. **是否存在其他需要自动确认/跳过的工具类型？** — 需要完整枚举
