# 知识持久化到 Anchor Spec

## Why

当前会话积累了大量关于 Trae 源码的深度知识（代码定位、架构关系、踩过的坑、做过的决策），这些知识只存在于会话记忆中，会话结束后会丢失。需要将这些知识写入 Anchor shared/ 模块，让未来的 AI 会话可以继承。

## What Changes

- 更新 `shared/discoveries.md` — 补充深度源码分析发现的关键代码位置和架构关系
- 更新 `shared/decisions.md` — 补充补丁崩溃修复、check_fingerprint 修复等技术决策
- 更新 `shared/status.md` — 更新当前补丁状态、待处理项、已知问题
- 更新 `shared/context.md` — 补充架构文档索引和关键位置索引

## Impact

- Affected files: `shared/discoveries.md`, `shared/decisions.md`, `shared/status.md`, `shared/context.md`

## ADDED Requirements

### Requirement: 知识持久化

将会话中的关键知识按 _registry.md 格式写入对应的 shared/ 模块，确保未来 AI 会话可以无缝继承。

#### Scenario: 未来 AI 读取 discoveries.md
- **WHEN** 未来 AI 需要定位某个代码功能
- **THEN** 可以在 discoveries.md 中找到精确的偏移位置和架构关系

#### Scenario: 未来 AI 读取 decisions.md
- **WHEN** 未来 AI 需要理解某个技术决策
- **THEN** 可以在 decisions.md 中找到决策原因和否决方案
