# 修复 AskUserQuestion 被自动确认 Bug Spec

## Why

AskUserQuestion 提问被自动确认提交（用户收到空回答），黑名单过滤没起作用。根因：`service-layer-confirm-status-update` 补丁的旧版本残留了第二个无过滤的 `provideUserResponse` 调用。

## What Changes

- 删除第二个无过滤的 `provideUserResponse` 调用（~7503802）
- 确保 `service-layer-confirm-status-update` 补丁的 `find_original` 匹配的是第一个（有过滤的）调用

## Impact

- Affected code: ai-modules-chat/dist/index.js ~7503802

## 根因分析

```
补丁应用顺序:
1. service-layer-runcommand-confirm (v4) → 添加了有黑名单过滤的 provideUserResponse ✅
2. service-layer-confirm-status-update (v3) → 匹配的是旧版 find_original（无过滤版本）
   → 在旧代码位置又加了一个无过滤的 provideUserResponse ❌

结果: 两个 provideUserResponse 调用:
  第一个: (e?.toolName!=="response_to_user") && provideUserResponse(...)  ← 有过滤
  第二个: (e?.toolName||e?.id||e?.toolCallId) && provideUserResponse(...) ← 无过滤！

AskUserQuestion 的 toolName="response_to_user":
  第一个: "response_to_user" !== "response_to_user" → false → 跳过 ✅
  第二个: "response_to_user" 存在 → true → 调用 provideUserResponse ❌ ← BUG!
```

## ADDED Requirements

### Requirement: 删除无过滤的 provideUserResponse 调用

系统 SHALL 只保留一个有黑名单过滤的 `provideUserResponse` 调用，删除第二个无过滤的调用。
