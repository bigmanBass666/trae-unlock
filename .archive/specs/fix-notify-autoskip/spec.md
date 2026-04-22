# Fix NotifyUser 自动确认修复

## Why

`data-source-auto-confirm v2` 错误地将 NotifyUser 加入黑名单，导致 spec 模式确认弹窗不会被自动确认。

## What Changes
- 从 `data-source-auto-confirm` 黑名单中移除 `CS.NotifyUser`
- 撤销 UI 层错误补丁（NotifyUserCard 完全隐藏）
- 恢复 NotifyUserCard 的原始渲染逻辑

## 工具分类
| 工具 | 是否自动确认 | 原因 |
|------|-------------|------|
| NotifyUser | ✅ 是 | spec 模式确认弹窗，应该自动确认 |
| AskUserQuestion | ❌ 否 | 需要用户选择答案 |
| ExitPlanMode | ❌ 否 | 需要用户确认退出 |

## Impact
- Affected patch: `data-source-auto-confirm` (v2 → v3)
- Affected tool: NotifyUser (不再被黑名单拦截)
