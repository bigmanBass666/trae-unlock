# 测试 Spec 模式确认弹框

## Why

验证 `bypass-runcommandcard-redlist v2` 是否正常工作，spec 模式下执行命令时不应弹出确认框。

## What Changes

- 测试在 spec 模式下执行命令（触发需要确认的命令）时是否仍有弹窗
- 验证黑名单机制是否有效

## 测试方法

使用 `powershell -Command "Write-Host test"` 这样的简单命令，测试是否会触发确认弹窗。
