# Trae 更新后补丁恢复与 NotifyUser 自动确认修复

## Why

Trae 刚刚更新，所有之前应用的补丁可能已失效。同时需要修复 `data-source-auto-confirm v2` 中 NotifyUser 被错误加入黑名单的问题。

## What Changes

- 重新扫描 Trae 更新后的目标文件（~10.73MB）
- 确认哪些补丁仍然存在，哪些需要重新应用
- 修复 `data-source-auto-confirm v3`：NotifyUser 从黑名单移除
- 更新 `patches/definitions.json` 补丁定义
- 更新 `shared/discoveries.md` 知识库

## Impact

- Affected specs: 补丁系统、spec 模式自动确认、AskUserQuestion 自动确认
- Affected code: `ai-modules-chat/dist/index.js` (10.73MB)

## ADDED Requirements

### Requirement: Trae 更新后补丁恢复流程
The system SHALL 提供完整的补丁恢复流程，在 Trae 更新后快速重新应用所有补丁。

#### Scenario: 补丁状态检查
- **WHEN** Trae 更新后
- **THEN** 自动检查所有补丁状态并报告哪些需要重新应用

### Requirement: NotifyUser 自动确认（v3）
The system SHALL 对 NotifyUser 工具自动确认（spec 模式弹窗），但不对 AskUserQuestion 和 ExitPlanMode 自动确认。

#### Scenario: spec 模式自动确认
- **WHEN** AI 创建 spec 文档并触发 NotifyUser 工具
- **THEN** 弹窗显示但自动确认，无需用户手动点击
- **AND** AskUserQuestion 仍然显示选项让用户选择

### Requirement: 黑名单设计原则
The system SHALL 只在黑名单中保留需要用户交互的工具。

| 工具 | 是否自动确认 | 原因 |
|------|-------------|------|
| NotifyUser | ✅ 是 | spec 模式确认弹窗，应该自动确认 |
| AskUserQuestion | ❌ 否 | 需要用户选择答案 |
| ExitPlanMode | ❌ 否 | 需要用户确认退出 |
| response_to_user | ❌ 否 | 用户问答，不应自动确认 |
