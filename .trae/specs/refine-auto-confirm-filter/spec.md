# 精准化自动确认过滤 Spec (v2 - 黑名单模式)

## Why

当前使用白名单模式（只允许 run\_command 自动确认）太保守，导致大量正常工具操作也需要手动确认。用户明确要求：**只排除 AskUserQuestionCard，其他全部默认确认**。

## What Changes

* **策略变更**: 白名单 → 黑名单模式

  * 旧: `(e?.toolName==="run_command")` → 只允许 run\_command

  * 新: `(e?.toolName!=="response_to_user")` → 排除 response\_to\_user，其余全过

* **影响补丁**: service-layer-runcommand-confirm, service-layer-confirm-status-update, auto-confirm-commands

## Impact

* Affected code: ai-modules-chat/dist/index.js \~7502574, \~7503319, \~7503400

## MODIFIED Requirements

### Requirement: 自动确认过滤策略 (v2: 黑名单模式)

系统 SHALL 使用**黑名单模式**进行自动确认过滤：

```javascript
// v2 黑名单模式: 只排除明确的用户交互类，其余全部默认确认
(e?.toolName||e?.id||e?.toolCallId) && 
(e?.toolName !== "response_to_user") &&   // ← 唯一排除项
provideUserResponse(...)
```

#### Scenario: RunCommandCard → 自动确认 ✅

* **WHEN** toolName = "run\_command"

* **THEN** `"run_command" !== "response_to_user"` → true → 自动确认

#### Scenario: AskUserQuestionCard → 不自动确认 ❌

* **WHEN** toolName = "response\_to\_user"

* **THEN** `"response_to_user" !== "response_to_user"` → false → 跳过，显示 UI

#### Scenario: 其他工具 (create\_file, web\_search 等) → 默认确认 ✅

* **WHEN** toolName = 其他任意值

* **THEN** 不在黑名单中 → 自动确认

## ADDED: 主动性扫描计划

### 目标

不再被动等用户报 bug，而是系统性找出 Trae 中**所有可能触发确认弹窗/中断对话的限制点**。

### 扫描范围

1. 所有 `confirm_status === "unconfirmed"` 的处理路径
2. 所有 `Alert` / 弹窗渲染逻辑
3. 所有 `block_level` 相关的分支判断
4. 所有 `auto_confirm === false` 的场景
5. SSE 流中可能导致 UI 卡住的状态更新遗漏
6. 错误码处理中缺少"可恢复"标记的情况

