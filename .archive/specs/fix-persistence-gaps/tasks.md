# Tasks

- [x] Task 1: 更新 context.md 关键位置速查表
  - [x] 1.1 更新 auto-continue-thinking 偏移: ~8702342 → ~8706660, 版本 v4 → v5
  - [x] 1.2 更新 efh-resume-list 版本: v2 → v3
  - [x] 1.3 更新 J 变量版本: v3 → v4（bypass-loop-detection）
  - [x] 1.4 新增 guard-clause-bypass 条目 (~8706067)
  - [x] 1.5 确认其他偏移值是否仍正确 → 新增 7 个条目（ec/ed/stopStreaming/D7.Error/JV/DEFAULT组件）

- [x] Task 2: 升级 rules.md 为 P1 + AGENTS.md 强化引用
  - [x] 2.1 在 _registry.md 中将 rules.md 从 P2 改为 P1（"每个新会话（**强制**)"）
  - [x] 2.2 AGENTS.md 已包含完整的规则引用和方法论索引

- [x] Task 3: 向 decisions.md 追加缺失的技术决策
  - [x] 3.1 追加 "为什么 auto-continue-thinking 从 ed()→ec()→直调 D.resumeChat()" (v3→v5 演进)
  - [x] 3.2 追加 "为什么新增 guard-clause-bypass 补丁而非修改现有补丁"
  - [x] 3.3 追加 "为什么 v5 选择三重加固 (DEFAULT+500ms+retry)"
  - [x] 3.4 追加 "为什么 bypass-loop-detection 要加入 kg.DEFAULT"

- [x] Task 4: AGENTS.md 增加方法论快速索引
  - [x] 4.1 增加集中方法论索引表：搜索类(4) + 补丁开发类(5) + 元认知类(3) = 12 条
  - [x] 4.2 增加 5 个会话的效率数据参考表

- [x] Task 5: 验证 + 强制复盘
  - [x] 5.1 模拟新会话读取流程验证通过 — 所有关键经验可获取 ✅
  - [x] 5.2 执行复盘四步（rule-009 + rule-013 强制）✅

# Task Dependencies
- [Task 1], [Task 2], [Task 3], [Task 4] 并行执行
- [Task 5] 依赖全部前序任务
