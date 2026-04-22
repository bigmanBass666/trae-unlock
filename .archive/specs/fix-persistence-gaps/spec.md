# 修复跨会话知识持久化缺陷 Spec

## Why

审计发现共享知识库存在 3 个缺陷，导致新会话 AI 无法完整继承所有复盘成果：
1. context.md 关键位置速查表过时（偏移值是旧版）
2. rules.md 被 _registry 标记为 P2 按需，新会话可能跳过不读
3. decisions.md 缺少近期关键技术决策（v4/v5 方案选择）

**用户需求**: 随便开一个新会话，里面的 AI 必须能共享所有经验。

## What Changes

- 更新 context.md 关键位置速查表为当前版本
- 将 rules.md 从 P2 升级为 P1（或确保 AGENTS.md 强制引用）
- 向 decisions.md 追加缺失的技术决策
- 在 AGENTS.md 中增加方法论快速索引（让新 AI 不必读完所有文件就能找到关键方法论）

## Impact

- Affected code: 无代码修改，仅文档更新
- Affected specs: 无

## ADDED Requirements

### Requirement: context.md 位置速查表必须与当前补丁版本同步

#### Scenario: 新会话 AI 按 context.md 找到正确的代码位置
- **WHEN** 新会话 AI 读取 context.md 的"关键位置速查表"
- **THEN** 所有偏移值必须与当前 definitions.json 中的 offset_hint 一致
- **AND** 补丁版本号必须正确（如 auto-continue-thinking v5 而非 v4）

### Requirement: rules.md 必须被新会话 AI 读取

#### Scenario: 新会话启动时自动加载所有规则
- **WHEN** 新会话 AI 按 _registry.md 读取模块
- **THEN** rules.md 应被标记为 P1 推荐读取（而非 P2）
- **OR** AGENTS.md 应包含明确的"必须阅读 rules.md 全文"指令

### Requirement: decisions.md 必须包含所有重大技术决策

#### Scenario: 新会话 AI 了解为什么当前方案是这样设计的
- **WHEN** 新会话 AI 读取 decisions.md
- **THEN** 以下决策必须有记录：
  - 为什么 auto-continue-thinking 从 ed() 改为 ec() 再改为直调 D.resumeChat()
  - 为什么新增 guard-clause-bypass 补丁
  - 为什么 v5 选择三重加固（DEFAULT入J + 500ms + 嵌套retry）
  - 为什么 bypass-loop-detection 要加入 kg.DEFAULT

## MODIFIED Requirements

### Requirement: AGENTS.md 方法论索引

当前 AGENTS.md 引用了部分方法论名称但缺少完整索引。应增加一个集中的方法论快速查找区。
