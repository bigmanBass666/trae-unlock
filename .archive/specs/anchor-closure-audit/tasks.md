# Tasks: Anchor 闭环性审计与进化

## 核心思路

修复闭环缺口，让 Anchor 系统自身包含维护自身所需的所有知识。本轮聚焦高优先级：规则融入 Anchor + 设计原则持久化。

---

## Phase 1: 设计原则持久化

- [x] **Task 1.1**: 在 _registry.md 中增加"设计原则"章节
  - 记录 5 条核心设计原则（含描述、理由、违反后果）
  - 去品牌化、集中定义、历史不改、AGENTS.md 只做路由、牵一发动全身

---

## Phase 2: 规则系统融入 Anchor

- [x] **Task 2.1**: 更新 rules/core.yaml — 对齐 Anchor shared/ 系统
  - rule-001 → 引导读取 shared/_registry.md → 按 P0/P1/P2 读取
  - rule-002 → 引导写入 shared/ 对应模块
  - rule-003 → 引导写入 shared/discoveries.md
  - rule-004 → 引用 shared/_registry.md 的写入格式约定

- [x] **Task 2.2**: 新增 rules/anchor.yaml — Anchor 系统维护规则
  - rule-016: 去品牌化规则
  - rule-017: AGENTS.md 解耦规则
  - rule-018: 历史不改规则
  - rule-019: 集中定义规则

- [x] **Task 2.3**: 重新生成 shared/rules.md
  - 修复规则引擎：添加 anchor 类别到 $categoryTitles 和 $categoryOrder
  - 重新生成：19 条规则，5 个类别（core/anchor/workflow/git/safety）

---

## Phase 3: 验证闭环效果

- [x] **Task 3.1**: 模拟新 AI 会话读取路径
  - AGENTS.md → _registry.md（设计原则 + 改名指引 + 模块管理）→ shared/*.md ✅
  - 规则引擎输出与 Anchor 系统一致（不矛盾）✅

- [x] **Task 3.2**: 模拟 AI 改进 Anchor 系统的场景
  - 想加品牌名 → 设计原则 #1 + rule-016 阻止 ✅
  - 想改 AGENTS.md → 设计原则 #4 + rule-017 阻止 ✅
  - 想改系统名 → 改名指引 + rule-019 引导 ✅

---

# Task Dependencies

```
Phase 1 (设计原则) ✅
    ↓
Phase 2 (规则融入) ✅
    ↓
Phase 3 (验证) ✅
```
