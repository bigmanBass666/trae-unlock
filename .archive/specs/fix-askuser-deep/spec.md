# 深度排查 AskUserQuestion 自动确认 Spec

## Why

删除残留的未过滤 provideUserResponse 调用后，AskUserQuestion 仍然被自动确认（返回空值）。说明除了已知的残留代码外，还有其他自动确认路径在起作用。需要全面排查所有可能的确认路径。

## What Changes

- 全面搜索目标文件中所有与 AskUserQuestion 相关的自动确认代码路径
- 检查 `auto_confirm` 标志、`confirm_status` 状态变更、`provideUserResponse` 调用
- 检查 `bypass-runcommandcard-redlist v2` 返回 P8.Default 后是否导致 UI 层自动确认
- 检查 `auto-confirm-commands v3` 的 `s` 变量（knowledge 过滤条件）对 AskUserQuestion 的判断
- 检查 `service-layer-runcommand-confirm v6` 的 `confirm_status` 守卫是否被绕过

## Impact

- Affected files: 目标文件 `ai-modules-chat/dist/index.js`
- Affected patches: auto-confirm-commands, service-layer-runcommand-confirm, bypass-runcommandcard-redlist

## 根因假设

### 假设 1: bypass-runcommandcard-redlist v2 返回 P8.Default 导致 UI 层自动确认
- P8.Default 意味着"自动执行，不弹窗"
- 但 UI 层可能对 P8.Default 有额外的自动确认逻辑
- RunCommandCard 组件在收到 P8.Default 后可能自动调用 confirm

### 假设 2: auto-confirm-commands v3 的 `s` 变量对 AskUserQuestion 为 true
- `s` 是 knowledge 过滤条件，如果 AskUserQuestion 匹配了 knowledge 条件，则会被自动确认
- 虽然 `e?.toolName!=="response_to_user"` 过滤了 response_to_user，但 AskUserQuestion 的 toolName 不是 response_to_user

### 假设 3: service-layer-runcommand-confirm v6 的 else 分支对 AskUserQuestion 生效
- else 分支没有 `s` (knowledge) 过滤，只检查 toolName 和 confirm_status
- AskUserQuestion 的 toolName 不是 response_to_user，所以不会被黑名单过滤
- confirm_status 守卫可能被绕过（如果第一次调用后状态未及时更新）

### 假设 4: 存在其他未知的自动确认路径
- 可能有其他代码路径在处理 confirm 流程

## ADDED Requirements

### Requirement: AskUserQuestion 不应被自动确认
系统 SHALL 确保当 toolName 为 AskUserQuestion 时，不自动调用 provideUserResponse。

#### Scenario: AI 调用 AskUserQuestion
- **WHEN** AI 调用 AskUserQuestion 工具
- **THEN** 用户应看到选项弹窗并手动选择
- **AND** 不应自动调用 provideUserResponse 确认
