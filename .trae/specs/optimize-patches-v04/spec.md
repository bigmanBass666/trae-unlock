# 补丁优化 + 稳定版标记 Spec

## Why

基于源码架构深度分析，发现当前补丁存在优化空间：1) `bypass-runcommandcard-redlist` 应重新启用以消除所有模式弹窗竞态；2) `auto-continue-thinking` 应改用箭头函数保持一致性；3) 需要标记当前稳定版以便随时回滚。

## What Changes

- 标记 git tag v0.4 作为当前稳定版
- 重新启用 `bypass-runcommandcard-redlist`（替代 `bypass-whitelist-sandbox-blocks`，覆盖所有模式）
- 禁用 `bypass-whitelist-sandbox-blocks`（被 `bypass-runcommandcard-redlist` 完全包含）
- `auto-continue-thinking` 改用箭头函数
- 应用补丁并验证

## Impact

- Affected files: `patches/definitions.json`, 目标文件 `ai-modules-chat/dist/index.js`
- **BREAKING**: `bypass-whitelist-sandbox-blocks` 将被禁用，由 `bypass-runcommandcard-redlist` 替代

## ADDED Requirements

### Requirement: 稳定版标记

每次重大变更前 SHALL 标记 git tag，以便随时回滚。

#### Scenario: 补丁应用失败
- **WHEN** 新补丁导致聊天窗口崩溃
- **THEN** 可以通过 `git checkout v0.4` 回滚到稳定版

### Requirement: 全模式弹窗消除

`bypass-runcommandcard-redlist` 让所有 AutoRunMode 都返回 P8.Default，消除 UI 层弹窗竞态。

#### Scenario: ALWAYS_RUN + RedList
- **WHEN** 用户设置 ALWAYS_RUN 模式且命令命中红名单
- **THEN** 不弹窗，直接自动执行

#### Scenario: default(Ask) 模式
- **WHEN** 用户设置 ALWAYS_ASK 或 BLACKLIST 模式
- **THEN** 不弹窗，直接自动执行

## MODIFIED Requirements

### Requirement: auto-continue-thinking 补丁

setTimeout 回调改用箭头函数，与补丁安全规范保持一致。

## REMOVED Requirements

### Requirement: bypass-whitelist-sandbox-blocks

**Reason**: 被 `bypass-runcommandcard-redlist` 完全包含。`bypass-whitelist-sandbox-blocks` 只处理 WHITELIST 模式，而 `bypass-runcommandcard-redlist` 处理所有模式（WHITELIST + ALWAYS_RUN + default）。
**Migration**: 禁用 `bypass-whitelist-sandbox-blocks`，启用 `bypass-runcommandcard-redlist`。
