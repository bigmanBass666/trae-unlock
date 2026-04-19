# Checklist: Anchor 闭环性审计与进化

## 设计原则持久化

- [x] _registry.md 包含"设计原则"章节
  - [x] 去品牌化原则（含违反后果）
  - [x] 集中定义原则（含违反后果）
  - [x] 历史不改原则（含违反后果）
  - [x] AGENTS.md 只做路由原则（含违反后果）
  - [x] 牵一发动全身原则（含违反后果）

---

## 规则融入 Anchor

- [x] rules/core.yaml 引用 shared/ 模块而非分散文档
  - [x] rule-001 引导读取 shared/_registry.md
  - [x] rule-002 引导写入 shared/ 对应模块
  - [x] rule-003 引导写入 shared/discoveries.md
  - [x] rule-004 引用 shared/_registry.md 的写入格式

- [x] rules/anchor.yaml 已创建
  - [x] rule-016 去品牌化规则
  - [x] rule-017 AGENTS.md 解耦规则
  - [x] rule-018 历史不改规则
  - [x] rule-019 集中定义规则

- [x] shared/rules.md 已重新生成
  - [x] 包含新增的 anchor 类别规则（rule-016~019）
  - [x] core 类别规则引用 shared/ 模块

---

## 闭环验证

- [x] 新 AI 会话读取路径无知识断点
  - [x] AGENTS.md → _registry.md（设计原则 ✅ + 改名指引 ✅ + 模块管理 ✅）
  - [x] 规则引擎输出与 Anchor 系统一致（不矛盾）

- [x] AI 改进系统时能从系统自身获取约束
  - [x] 想加品牌名 → 设计原则 #1 + rule-016 阻止
  - [x] 想改 AGENTS.md → 设计原则 #4 + rule-017 阻止
  - [x] 想改系统名 → 改名指引 + rule-019 引导

---

## 最终验收

- [x] **操作闭环**: AI 知道怎么用 Anchor 系统
- [x] **维护闭环**: AI 知道怎么维护 Anchor 系统（改名、增删模块）
- [x] **进化闭环**: AI 知道 Anchor 的设计约束，不会违反原则性决策
- [x] **零回归**: 原有功能不受影响
