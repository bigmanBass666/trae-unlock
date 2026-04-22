# 提升 P2 模块写入率 Spec

## Why

跨 3 个工作会话（#7、#9、#10）的测试数据显示，P2 模块（discoveries.md、decisions.md）的写入率为 0/3。每次都需要 COO 手动补充。根因是写入触发条件在 rules.md（P2 按需读取）中，Agent 不一定读到；且触发条件（"发现关键信息时"、"做出重要决策时"）过于主观，Agent 不自评其工作为"关键"或"重要"。

## What Changes

- 在 `_registry.md` 中添加"会话结束检查清单"，作为 P0 必读内容的一部分，显式提醒 Agent 检查 P2 写入
- 更新会话日志格式，增加"P2 写入"字段，使 Agent 在写日志时被迫回顾是否需要写入 discoveries/decisions
- 将 rule-002 的第 5 条操作步骤从"会话结束前 → 在 status.md 会话日志区域追加本次会话日志"扩展为包含 P2 检查的完整流程

## Impact

- Affected files: `shared/_registry.md`, `rules/core.yaml`
- Affected specs: 无破坏性变更，仅增强现有规则
- Affected agents: 所有未来会话将看到更明确的 P2 写入提示

## ADDED Requirements

### Requirement: 会话结束检查清单

系统 SHALL 在 _registry.md 中提供会话结束检查清单，作为 P0 必读内容的一部分。

#### Scenario: Agent 完成工作准备结束会话
- **WHEN** Agent 完成工作并准备写会话日志
- **THEN** Agent 必须按检查清单逐项检查：是否需要写入 discoveries.md、decisions.md
- **AND** 在会话日志中记录 P2 写入情况

### Requirement: 会话日志增加 P2 写入字段

系统 SHALL 在会话日志格式中增加"P2 写入"字段。

#### Scenario: Agent 写会话日志
- **WHEN** Agent 在 status.md 中追加会话日志
- **THEN** 日志必须包含"P2 写入"字段，列出本次写入的 P2 模块（或"无"）
- **AND** 如果未写入 discoveries.md 但有发现，应说明原因

## MODIFIED Requirements

### Requirement: rule-002 操作后写入 Anchor 共享模块

扩展 rule-002 的第 5 条操作步骤，增加 P2 检查环节：

原：
5. 会话结束前 → 在 status.md 会话日志区域追加本次会话日志（操作/观察/问题/建议）

新：
5. 会话结束前 → 执行检查清单：①有发现？→ discoveries.md ②有决策？→ decisions.md ③写会话日志（含 P2 写入字段）→ status.md
