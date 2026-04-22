# 修复 rollback.ps1 参数 Bug + 用户体验优化 Spec

## Why

rollback.ps1 的帮助文档写 `--list`/`--date`，但 PowerShell 参数实际是 `-List`/`-Date`（单横杠），导致用户按文档使用会失败。另外日期参数需要手动输入完整时间戳（如 `20260419-214638`），非常不友好。

## What Changes

- 修复参数名：统一为 PowerShell 标准单横杠 `-List`/`-Date`
- **新增交互式选择模式**：不带参数运行时，列出可用 backup 让用户选择（而不是默认选最新的）
- 新增 `-Latest` 快捷参数：恢复到最新 backup

## Impact

- Affected files: scripts/rollback.ps1

## ADDED Requirements

### Requirement: 交互式 Backup 选择

当用户不带 `-Date` 参数运行 rollback.ps1 时，系统 SHALL 列出所有可用 backup 并让用户通过数字选择，而不是默认恢复最新的。

#### Scenario: 无参数运行 → 交互选择
- **WHEN** 用户运行 `.\rollback.ps1`
- **THEN** 列出所有 backup（带编号），提示用户输入编号选择

#### Scenario: -Latest 快捷恢复
- **WHEN** 用户运行 `.\rollback.ps1 -Latest`
- **THEN** 直接恢复最新 backup（不交互）

#### Scenario: -Date 部分匹配
- **WHEN** 用户运行 `.\rollback.ps1 -Date 19`
- **THEN** 匹配包含 "19" 的 backup（模糊匹配，不需要完整时间戳）
