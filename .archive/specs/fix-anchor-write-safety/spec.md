# Anchor 写入安全补丁 Spec

## Why

Anchor 测试暴露了一个关键漏洞：AI 会话重写了 status.md 而非追加，导致原有内容可能丢失。_registry.md 的写入格式约定没有明确"追加而非重写"的规则。同时 safety.yaml 中 rule-012 仍引用旧文档路径，与 Anchor 系统矛盾。

## What Changes

- _registry.md 写入格式约定增加"追加而非重写"规则
- rules/anchor.yaml 新增 rule-020 防止重写
- rules/safety.yaml rule-012 对齐 Anchor 系统
- 重新生成 shared/rules.md

## ADDED Requirements

### Requirement: 追加而非重写

shared/*.md 模块 SHALL 使用追加方式写入新条目，不得重写整个文件。重写会导致其他会话写入的条目丢失。

#### Scenario: AI 向 shared/status.md 写入
- **WHEN** AI 完成工作后更新 status.md
- **THEN** 在文件末尾追加新条目
- **AND** 不删除或覆盖已有条目

## MODIFIED Requirements

### Requirement: rule-012 对齐 Anchor

**原内容**: "修改前必须阅读核心文档（README.md、source-architecture.md、progress.txt）"
**修改后**: "修改前必须通过 Anchor 系统获取项目上下文（shared/_registry.md → P0/P1 模块）"
