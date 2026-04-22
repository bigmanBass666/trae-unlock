# Tasks: Anchor 命名集中化

## 核心思路

将系统名从"散布式"改为"集中式"：系统名只在 AGENTS.md 和 _registry.md 中定义，其他文件去品牌化或保持历史原名。

---

## Phase 1: shared/*.md 去品牌化

- [x] **Task 1.1**: 移除 shared/*.md 描述行中的系统品牌名
  - [x] context.md: `> Anchor 共享知识库 — 每个新会话 AI 必读的项目核心信息` → `> 每个新会话 AI 必读的项目核心信息`
  - [x] status.md: `> Anchor 共享知识库 — 每次会话结束时更新，下一个会话读取` → `> 每次会话结束时更新，下一个会话读取`
  - [x] discoveries.md: `> Anchor 共享知识库 — 关键代码位置、架构关系、枚举值等` → `> 关键代码位置、架构关系、枚举值等`
  - [x] decisions.md: `> Anchor 共享知识库 — 记录"为什么选择 X 而不是 Y"` → `> 记录"为什么选择 X 而不是 Y"`

- [x] **Task 1.2**: 移除 shared/*.md 内容中的系统品牌名
  - [x] context.md 目录树: `# Anchor 共享知识库` → `# 跨会话共享模块`
  - [x] status.md 表格: `Anchor 规则子系统` → `规则子系统`
  - [x] status.md 表格: `Anchor 共享知识库` → `共享知识库`

---

## Phase 2: _registry.md 增加系统元数据

- [x] **Task 2.1**: 在 _registry.md 注册表标题下方增加系统名称标注
  - 在标题行后增加 `> 系统名称: Anchor` 行

---

## Phase 3: 完成人类文档改名

- [x] **Task 3.1**: 完成 docs/dynamic-rules-system.md 剩余改名
  - 标题: `# 动态规则系统使用指南` → `# Anchor 规则子系统使用指南`
  - 通知块: `跨会话通信声明` → `Anchor 声明`

- [x] **Task 3.2**: 完成 progress.txt 剩余改名
  - 回退了 2 处不当改名（历史条目恢复原名）
  - 2026-04-20 新条目中的 "Anchor" 保留（当前名称）

---

## Phase 4: 历史文件处理

- [x] **Task 4.1**: 确认 .trae/specs/ 下文件保持原名不变
  - 所有历史 spec 文件保持创建时的原始名称

- [x] **Task 4.2**: 确认 progress.txt 中已改名的部分是否需要回退
  - 已回退 2 处不当改名
  - 2026-04-19 的 "动态规则系统上线" 恢复原名
  - "shared/ 跨会话共享知识库" 恢复原名

---

## Phase 5: 验证集中化效果

- [x] **Task 5.1**: 搜索确认系统名只在 2 个文件中硬编码
  - shared/_registry.md: 2 处 "Anchor"（标题 + 系统名称标注）✅
  - AGENTS.md: 2 处 "Anchor"（声明 + 知识库引用）✅
  - shared/context.md: 0 处 ✅
  - shared/status.md: 0 处 ✅
  - shared/discoveries.md: 0 处 ✅
  - shared/decisions.md: 0 处 ✅

- [x] **Task 5.2**: 模拟未来改名场景
  - 假设系统名从 "Anchor" 改为 "NewName"
  - 只需修改 AGENTS.md（2处）+ _registry.md（2处）= 共 4 处
  - shared/*.md 不需要任何修改

---

# Task Dependencies

```
Phase 1 (去品牌化) ✅
    ↓
Phase 2 (元数据) ✅
    ↓
Phase 3 (人类文档) ✅
    ↓
Phase 4 (历史文件) ✅
    ↓
Phase 5 (验证) ✅
```
