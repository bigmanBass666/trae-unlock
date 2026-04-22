# 修复 AskUserQuestion 自动确认 Bug Spec

## Why

AskUserQuestion 再次被自动确认（返回 null），原因是目标文件中存在旧版 `service-layer-confirm-status-update` 补丁的残留代码——一个未过滤的 `provideUserResponse` 调用（偏移 ~7503943），使用 `.catch(function(e){this._logService...})` 且没有 `response_to_user` 黑名单过滤。

## What Changes

- 手动删除偏移 ~7503943 处的残留未过滤 `provideUserResponse` 调用
- 验证删除后只剩 2 个过滤过的 `provideUserResponse` 调用（knowledge 分支 + else 分支）

## Impact

- Affected files: 目标文件 `ai-modules-chat/dist/index.js`

## 根因分析

回滚到 20260419-003102 备份时，该备份已包含旧版 `service-layer-confirm-status-update` 补丁代码。apply-patches.ps1 的 `service-layer-runcommand-confirm` v6 补丁在旧代码后面**追加**了新代码，但没有删除旧的未过滤调用。结果：

1. **v6 过滤调用**（有 `response_to_user` 黑名单）: ✅ 正确
2. **旧版未过滤调用**（无黑名单）: ❌ 导致 AskUserQuestion 被自动确认

这和之前遇到的问题完全一样——双重 `provideUserResponse` 调用，一个过滤一个未过滤。
