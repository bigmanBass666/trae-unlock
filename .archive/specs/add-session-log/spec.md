# Anchor 会话日志机制 Spec

## Why

跨会话通知存在阀门：用户需要手动复制聊天记录才能让另一个会话了解发生了什么。Anchor 解决了持久化问题，但没解决通知问题。需要在 shared/ 中增加会话日志，让 AI 重读文件即可理解全貌，用户只需说 "sync"。

## What Changes

- status.md 增加"会话日志"区域
- _registry.md 写入格式约定增加会话日志格式
- rules/core.yaml rule-002 增加"写会话日志"动作
- 重新生成 shared/rules.md

## ADDED Requirements

### Requirement: 会话日志

每个 AI 会话在结束前 SHALL 在 status.md 的"会话日志"区域追加一条日志，记录本次会话做了什么、观察到什么、发现了什么问题。

#### Scenario: 会话结束时
- **WHEN** AI 会话即将结束
- **THEN** 在 status.md 末尾追加会话日志
- **AND** 日志包含：操作、观察、问题、建议

#### Scenario: 用户说 "sync"
- **WHEN** 用户在新会话中说 "sync"
- **THEN** AI 重读 shared/ 所有模块
- **AND** 从会话日志了解其他会话做了什么
