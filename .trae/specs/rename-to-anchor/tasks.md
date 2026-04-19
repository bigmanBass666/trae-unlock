# Tasks: Anchor 命名统一

## 核心思路

将 19 个文件中的 48 处旧系统名称替换为 "Anchor" 及其衍生名称。按优先级分批执行。

---

## Phase 1: 核心文件（AI 每次必读）

- [ ] **Task 1.1**: 更新 AGENTS.md（2 处）
  - "跨会话通信声明" → "Anchor 声明"
  - "跨会话共享知识库" → "Anchor 共享知识库"

- [ ] **Task 1.2**: 更新 shared/ 目录文件（9 处）
  - shared/_registry.md: "跨会话共享知识库" → "Anchor 共享知识库"
  - shared/context.md: 3 处
  - shared/status.md: 3 处
  - shared/discoveries.md: 1 处
  - shared/decisions.md: 1 处

---

## Phase 2: 项目文档（人类和 AI 都参考）

- [ ] **Task 2.1**: 更新 README.md（3 处）
  - "动态规则系统" → "Anchor 规则子系统"

- [ ] **Task 2.2**: 更新 docs/dynamic-rules-system.md（4 处）
  - 标题和正文中的旧命名

- [ ] **Task 2.3**: 更新 progress.txt（5 处）
  - 历史记录中的系统名称

---

## Phase 3: Spec 文件（历史记录，优先级低）

- [ ] **Task 3.1**: 更新 .trae/specs/ 下的 6 个 spec 文件（24 处）
  - cross-session-communication/ (3 文件, 12 处)
  - modular-communication-system/ (3 文件, 6 处)
  - dynamic-agent-rules-system/ (3 文件, 6 处)
  - ai-reference-doc/ (1 处)

---

# Task Dependencies

```
Phase 1 (核心文件) ← 优先级最高
    ↓
Phase 2 (项目文档) ← 可与 Phase 1 并行
    ↓
Phase 3 (Spec 文件) ← 优先级最低
```
