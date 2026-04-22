# Tasks: 动态模块化通信系统

## 核心思路

解决"牵一发动全身"问题：引入注册表机制，让模块增删改只动一个地方，AGENTS.md 永远不需要因模块变化而修改。

---

## Phase 1: 创建注册表

- [x] **Task 1.1**: 创建 `shared/_registry.md` 模块注册表
  - [x] 1.1.1 编写注册表头部说明
  - [x] 1.1.2 创建模块元数据表（5 个现有模块：context/status/discoveries/decisions/rules）
  - [x] 1.1.3 集中定义写入格式约定（从各文件中提取统一格式）
  - [x] 1.1.4 添加模块管理说明（新增/删除/修改优先级的操作步骤）
  - **验证标准**: ✅ 注册表包含完整的模块列表和格式约定

---

## Phase 2: 为现有模块添加自描述头部

- [x] **Task 2.1**: 为 5 个 shared/*.md 文件添加自描述元数据块
  - [x] 2.1.1 `shared/context.md` — 添加 module: context, read_priority: P0
  - [x] 2.1.2 `shared/status.md` — 添加 module: status, read_priority: P1
  - [x] 2.1.3 `shared/discoveries.md` — 添加 module: discoveries, read_priority: P2
  - [x] 2.1.4 `shared/decisions.md` — 添加 module: decisions, read_priority: P2
  - [x] 2.1.5 `shared/rules.md` — 添加 module: rules, read_priority: P2
  - **验证标准**: ✅ 每个文件开头有 `---` 包裹的元数据块

- [x] **Task 2.2**: 替换各文件中的分散格式说明
  - [x] 2.2.1 将每个文件的"📝 写入格式"章节替换为引用 `_registry.md` 的简短提示
  - **验证标准**: ✅ 格式约定只存在于 _registry.md，各文件只引用不重复

---

## Phase 3: 简化 AGENTS.md

- [x] **Task 3.1**: 移除 AGENTS.md 中的硬编码文件列表
  - [x] 3.1.1 将 5 个文件的逐行列表替换为"读取 shared/_registry.md"
  - [x] 3.1.2 确保总行数仍然 < 60 行（实际 34 行）
  - **验证标准**: ✅ AGENTS.md 不包含任何具体的 shared/ 文件名（除 _registry.md 外）

- [x] **Task 3.2**: 验证 AGENTS.md 与模块完全解耦
  - [x] 3.2.1 确认 AGENTS.md 中不出现 context.md/status.md/discoveries.md/decisions.md/rules.md
  - **验证标准**: ✅ AGENTS.md 只指向 _registry.md，不硬编码任何模块

---

## Phase 4: 验证动态性

- [x] **Task 4.1**: 测试新增模块流程
  - [x] 4.1.1 创建测试模块 `shared/test-module.md`（含自描述头部）
  - [x] 4.1.2 在 `_registry.md` 添加一行
  - [x] 4.1.3 确认 AGENTS.md 无需修改
  - [x] 4.1.4 清理测试模块
  - **验证标准**: ✅ 新增模块只需 2 步，AGENTS.md 不变

- [x] **Task 4.2**: 测试删除模块流程
  - [x] 4.2.1 模拟删除一个模块（从 _registry.md 移除一行）
  - [x] 4.2.2 确认 AGENTS.md 无需修改
  - [x] 4.2.3 恢复 _registry.md
  - **验证标准**: ✅ 删除模块只需 2 步，AGENTS.md 不变

- [x] **Task 4.3**: 测试修改优先级流程
  - [x] 4.3.1 修改 _registry.md 中某模块的优先级
  - [x] 4.3.2 确认只需改 _registry.md 一处
  - [x] 4.3.3 恢复原始优先级
  - **验证标准**: ✅ 修改优先级只需改 1 个文件 1 行

---

# Task Dependencies

```
Phase 1 (注册表) ✅
    ↓
Phase 2 (自描述头部) ✅ ← 依赖注册表中的格式约定
    ↓
Phase 3 (AGENTS.md 简化) ✅ ← 依赖注册表已创建
    ↓
Phase 4 (验证动态性) ✅ ← 依赖所有前置完成
```

---

# 实现总结

## ✅ 全部任务已完成！

### 核心成果

1. **注册表机制**: `shared/_registry.md` 集中管理所有模块元数据
2. **自描述模块**: 每个 shared/*.md 文件头部包含元数据块
3. **AGENTS.md 解耦**: AGENTS.md 不硬编码任何模块文件名，只指向 _registry.md
4. **集中格式约定**: 写入格式只存在于 _registry.md，改一处全局生效
5. **动态性验证**: 新增/删除/修改模块均不需要改 AGENTS.md

### 动态性对比

| 操作 | 旧系统 | 新系统 |
|------|--------|--------|
| 新增模块 | 改 AGENTS.md + 创建文件 | 创建文件 + _registry.md 加一行 |
| 删除模块 | 改 AGENTS.md + 删文件 | 删文件 + _registry.md 删一行 |
| 修改优先级 | 改 AGENTS.md | 改 _registry.md |
| 修改写入格式 | 改 N 个文件 | 改 _registry.md 1 处 |
| AGENTS.md 是否需要改 | ✅ 是 | ❌ 否 |
