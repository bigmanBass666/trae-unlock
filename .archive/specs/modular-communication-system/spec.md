# 动态模块化通信系统 Spec

## Why

当前跨会话通信系统存在"牵一发动全身"的维护性问题：
1. **AGENTS.md 硬编码了 shared/ 文件列表** — 新增/删除模块必须改 AGENTS.md
2. **写入格式约定分散在每个文件中** — 改格式要改 N 个文件
3. **模块没有自描述能力** — 元数据（优先级、读写时机）硬编码在 AGENTS.md 而非模块自身
4. **没有模块注册/发现机制** — AI 不知道有哪些模块可用

需要让系统具备：增删模块只动一个地方、模块自包含自描述、AGENTS.md 永远不需要因为模块变化而修改。

## What Changes

### 核心设计：注册表 + 自描述模块

```
旧架构（硬编码）:
  AGENTS.md → 硬编码列出 5 个 shared/ 文件 → AI 逐个读取

新架构（动态注册）:
  AGENTS.md → 只指向 _registry.md（注册表）
  _registry.md → 动态列出所有模块 + 元数据
  每个 shared/*.md → 自描述（头部包含自身元数据）
```

### 具体变更

#### 1. 新增 `shared/_registry.md` — 模块注册表
- 集中列出所有 shared/ 模块的元数据
- AI 读取 AGENTS.md → 读取 _registry.md → 按需选择模块
- 新增模块只需：创建文件 + 在 _registry.md 加一行
- 删除模块只需：删文件 + 从 _registry.md 移除一行
- **AGENTS.md 永远不需要改**

#### 2. 每个 shared/*.md 增加自描述头部
- 每个文件开头有统一的 YAML front matter 风格元数据块
- 包含：模块名、描述、读取优先级、写入时机、格式约定
- AI 读到文件就知道这个文件是什么、什么时候该读、什么时候该写

#### 3. 集中写入格式约定到 _registry.md
- 不再在每个文件中重复格式说明
- _registry.md 定义统一的写入格式规范
- 各模块只需引用"遵循 _registry.md 中的格式约定"

#### 4. AGENTS.md 简化 — 只指向注册表
- 移除硬编码的文件列表
- 只保留：跨会话意识声明 + 元认知洞察 + "读取 shared/_registry.md"
- 模块增删完全不影响 AGENTS.md

### **BREAKING Changes**
- ⚠️ AGENTS.md 中的文件列表被移除，改为指向 _registry.md
- ⚠️ shared/*.md 文件头部新增自描述元数据块

## Impact

- Affected files: AGENTS.md (简化), shared/*.md (增加元数据头), 新增 shared/_registry.md
- Affected specs: cross-session-communication (模块发现机制变更)

## ADDED Requirements

### Requirement: 模块注册表 (_registry.md)

系统 SHALL 提供 `shared/_registry.md` 作为模块注册表，具备以下特性：

1. **集中注册**：列出所有 shared/ 模块的元数据
2. **动态发现**：AI 通过读取注册表了解有哪些模块可用
3. **单点维护**：增删模块只需修改注册表 + 创建/删除文件
4. **AGENTS.md 解耦**：AGENTS.md 不再硬编码文件列表

注册表格式：

```markdown
# 跨会话共享知识库 — 模块注册表

## 读取顺序

| 优先级 | 模块 | 描述 | 读取时机 | 写入时机 |
|--------|------|------|---------|---------|
| P0 必读 | context.md | 项目核心上下文 | 每个新会话 | 项目重大变更时 |
| P1 推荐 | status.md | 当前状态和待办 | 每个新会话 | 每次会话结束时 |
| P2 按需 | discoveries.md | 重要发现 | 需要相关知识时 | 发现关键信息时 |
| P2 按需 | decisions.md | 技术决策 | 需要理解决策时 | 做出重要决策时 |
| P2 按需 | rules.md | 协作规则 | 需要了解规则时 | 修改 rules/*.yaml 后 |

## 写入格式约定

追加新条目时，使用以下格式：

### [YYYY-MM-DD HH:mm] 简短标题
**关键字**: 值
详细描述...
---

## 模块管理

- **新增模块**: 创建 `shared/新模块.md`（含自描述头部） + 在本表添加一行
- **删除模块**: 删除文件 + 从本表移除对应行
- **修改优先级**: 只改本表中的优先级列
```

#### Scenario: 新增模块
- **WHEN** 需要新增一个 `shared/learnings.md` 模块
- **THEN** 只需：1) 创建 `shared/learnings.md`（含自描述头部） 2) 在 `_registry.md` 添加一行
- **AND** AGENTS.md 无需任何修改
- **AND** 下一个会话的 AI 通过读取 _registry.md 自动发现新模块

#### Scenario: 删除模块
- **WHEN** 需要移除 `shared/rules.md` 模块
- **THEN** 只需：1) 删除 `shared/rules.md` 2) 从 `_registry.md` 移除对应行
- **AND** AGENTS.md 无需任何修改

#### Scenario: 调整模块优先级
- **WHEN** 需要将 `decisions.md` 从 P2 提升到 P1
- **THEN** 只需修改 `_registry.md` 中的优先级列
- **AND** 不需要修改任何其他文件

### Requirement: 模块自描述头部

每个 shared/*.md 文件 SHALL 在开头包含自描述元数据块：

```markdown
---
module: context
description: 项目核心上下文
read_priority: P0
read_when: 每个新会话
write_when: 项目重大变更时
format: registry
---

# 项目核心上下文
...
```

元数据字段说明：
- `module`: 模块标识符（与文件名一致，不含 .md）
- `description`: 一句话描述模块用途
- `read_priority`: P0(必读) / P1(推荐) / P2(按需)
- `read_when`: 什么时候应该读取
- `write_when`: 什么时候应该写入
- `format`: 写入格式来源（`registry` 表示遵循 _registry.md 的格式约定）

#### Scenario: AI 读取任意 shared/ 文件
- **WHEN** AI 读取 `shared/discoveries.md`
- **THEN** 从文件头部立刻知道：这是什么模块、什么时候该读、什么时候该写
- **AND** 不需要去 AGENTS.md 或其他地方查找这个文件的用途

### Requirement: AGENTS.md 与模块解耦

AGENTS.md SHALL 不再硬编码 shared/ 文件列表，改为：

```markdown
**在开始任何工作之前，你必须先读取跨会话共享知识库：**
→ 读取 `shared/_registry.md` 了解所有可用模块
→ 按 P0 → P1 → P2 优先级读取所需模块
```

#### Scenario: AGENTS.md 因模块变化而修改
- **WHEN** 新增、删除或修改 shared/ 模块
- **THEN** AGENTS.md 不需要任何修改
- **AND** 只有 `shared/_registry.md` 和模块文件本身需要变更

### Requirement: 集中格式约定

写入格式约定 SHALL 集中定义在 `shared/_registry.md` 中，而非分散在每个文件中。

- 各 shared/*.md 文件的"写入格式"章节替换为：`> 写入格式遵循 shared/_registry.md 中的约定`
- 修改格式只需改 _registry.md 一个地方

#### Scenario: 修改写入格式
- **WHEN** 需要调整所有 shared/ 文件的写入格式
- **THEN** 只需修改 `shared/_registry.md` 中的"写入格式约定"章节
- **AND** 不需要逐个修改 5+ 个文件

## MODIFIED Requirements

### Requirement: AGENTS.md 引导方式

**原设计**：AGENTS.md 硬编码列出 5 个 shared/ 文件（context/decisions/discoveries/status/rules）
**修改后**：AGENTS.md 只指向 `shared/_registry.md`，由注册表动态列出所有模块

### Requirement: shared/ 文件格式

**原设计**：每个 shared/ 文件开头包含完整的"写入格式"说明
**修改后**：每个 shared/ 文件开头包含自描述元数据块 + 引用 _registry.md 的格式约定

## REMOVED Requirements

### Requirement: AGENTS.md 硬编码文件列表

**原因**：硬编码导致"牵一发动全身"——新增模块必须改 AGENTS.md
**迁移**：文件列表迁移到 `shared/_registry.md`，AGENTS.md 只指向注册表
