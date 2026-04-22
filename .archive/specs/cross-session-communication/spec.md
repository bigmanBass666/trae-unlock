# 跨会话通信系统 Spec

## Why

**核心问题不是"AI 不守规则"，而是"AI 没有跨会话意识"**。

AI 默认假设自己一直在当前会话中，不会考虑：
- 用户会在将来开启新会话
- 当前会话的发现/决策需要传递给未来的会话
- 不同会话之间需要共享状态和知识

一旦 AI 有了跨会话通信能力，规则遵守只是其中一个应用场景。更重要的是：**任何 AI 想让其他 AI 知道的信息，都可以通过这个通信系统持久化**——包括但不限于规则、重要发现、项目状态、待办事项、技术决策等。

**关键洞察**：`AGENTS.md` 是 Trae IDE 中 AI 每次回复都会读取的特殊文件。这个特性使它成为跨会话通信的天然入口/路由器。这个洞察本身也应该写在 AGENTS.md 开头，让每个未来想设计跨会话系统的 AI 都能意识到这一点。

## What Changes

### 核心重构：从"规则引擎"到"通信系统"

```
旧设计（规则引擎）:
  AGENTS.md → rules-engine.ps1 → rules/*.yaml → 输出规则

新设计（通信系统）:
  AGENTS.md (路由器 + 跨会话意识声明)
       ↓ 引导 AI 读取
  shared/ (跨会话共享知识库)
  ├── context.md      — 项目上下文（AI 必读）
  ├── decisions.md    — 技术决策记录
  ├── discoveries.md  — 重要发现和代码定位
  ├── status.md       — 当前状态和待办
  └── rules.md        — 协作规则（从 rules/*.yaml 生成）
```

### 具体变更

#### 1. **重构 AGENTS.md** — 加入跨会话意识声明
- 在文件最开头声明"AGENTS.md 会被 AI 每次回复时读取"这个关键特性
- 声明"用户会开启多个会话"这个事实
- 将 AGENTS.md 定位为"跨会话通信入口"而非"规则路由器"
- 引导 AI 读取 `shared/` 目录获取完整上下文

#### 2. **新增 `shared/` 跨会话共享知识库**
- `shared/context.md` — 项目核心上下文（替代原来分散在 README/progress/source-architecture 中的必读信息）
- `shared/decisions.md` — 技术决策记录（为什么选择 X 而不是 Y）
- `shared/discoveries.md` — 重要发现（代码位置、架构关系、枚举值等）
- `shared/status.md` — 当前状态和待办事项
- `shared/rules.md` — 协作规则（由 rules-engine.ps1 从 rules/*.yaml 生成，保持动态性）

#### 3. **保留 rules/ 和 rules-engine.ps1** — 规则作为通信内容的一种
- 规则系统不废弃，而是降级为通信系统的一个子模块
- `shared/rules.md` 由引擎自动生成，AI 也可以直接编辑其他 shared/ 文件

#### 4. **AI 写入机制** — 让 AI 能主动向 shared/ 写入信息
- AI 在工作过程中发现重要信息时，直接写入 `shared/discoveries.md`
- AI 做出技术决策时，记录到 `shared/decisions.md`
- AI 完成工作后，更新 `shared/status.md`
- 写入格式约定：时间戳 + 会话标识 + 内容

### **BREAKING Changes**
- ⚠️ AGENTS.md 从"规则路由器"重新定位为"跨会话通信入口"
- ⚠️ AI 的职责从"遵守规则"扩展为"维护跨会话通信"

## Impact

- Affected specs: `dynamic-agent-rules-system` (规则系统降级为通信子系统)
- Affected code: AGENTS.md (重构), 新增 shared/ 目录
- Affected docs: docs/dynamic-rules-system.md (需更新定位说明)

## ADDED Requirements

### Requirement: 跨会话意识声明

AGENTS.md 的最开头 SHALL 包含一段"跨会话意识声明"，让每个读取此文件的 AI 立刻意识到：

1. **AGENTS.md 的特殊性**：这个文件会被 AI 每次回复时自动读取，是跨会话通信的天然入口
2. **多会话事实**：用户会在不同时间开启多个 AI 会话，当前会话不是唯一的
3. **通信责任**：当前会话的 AI 有责任将重要信息持久化到 shared/ 目录，以便未来会话读取
4. **这个洞察的传承**：上述关于 AGENTS.md 特性的洞察，应该写在本文件中，让未来想设计跨会话系统的 AI 也能意识到这一点

#### Scenario: 新会话 AI 读取 AGENTS.md
- **WHEN** AI 开始新的对话会话
- **AND** 自动读取 AGENTS.md
- **THEN** 立刻意识到"用户会开启多个会话"
- **AND** 知道自己有责任将重要信息写入 shared/ 目录
- **AND** 知道应该先读取 shared/ 目录获取前序会话留下的信息

### Requirement: 跨会话共享知识库 (shared/)

系统 SHALL 提供 `shared/` 目录作为跨会话共享知识库，包含以下文件：

| 文件 | 用途 | 写入时机 | 读者 |
|------|------|---------|------|
| `context.md` | 项目核心上下文 | 项目初始化/重大变更时 | 每个新会话必读 |
| `decisions.md` | 技术决策记录 | 做出重要决策时 | 需要理解决策背景的会话 |
| `discoveries.md` | 重要发现 | 发现关键代码/架构时 | 需要相关知识的会话 |
| `status.md` | 当前状态和待办 | 每次会话结束时 | 下一个会话 |
| `rules.md` | 协作规则 | 修改 rules/*.yaml 后 | 每个会话 |

#### Scenario: AI 在工作中发现重要信息
- **WHEN** AI 发现了关键代码位置、架构关系、枚举值等重要信息
- **THEN** AI 应将该信息追加到 `shared/discoveries.md`
- **AND** 使用格式：`### [YYYY-MM-DD HH:mm] 会话摘要\n发现内容`

#### Scenario: AI 完成工作后
- **WHEN** AI 完成了当前会话的工作
- **THEN** AI 应更新 `shared/status.md` 记录当前状态
- **AND** 包括：完成了什么、还有什么待做、遇到什么问题

#### Scenario: 新会话 AI 启动
- **WHEN** 新会话的 AI 读取 AGENTS.md
- **THEN** 被引导读取 `shared/context.md`（必读）
- **AND** 可选读取 `shared/status.md`（了解当前进度）
- **AND** 可选读取 `shared/discoveries.md`（按需查阅）

### Requirement: AI 写入格式约定

AI 向 shared/ 目录写入信息时 SHALL 遵循统一格式：

```markdown
### [2026-04-20 14:30] 补丁崩溃修复

**发现**: service-layer-runcommand-confirm v5 的 .catch() 使用普通函数导致 this 绑定错误
**位置**: ai-modules-chat:7503400
**影响**: React 组件树崩溃，聊天窗口消失
**修复**: 改用箭头函数 .catch(e=>{...})
```

关键要素：
- 时间戳（便于追溯时序）
- 简短标题（便于快速扫描）
- 结构化内容（发现/位置/影响/修复等）

### Requirement: 规则系统作为通信子系统

现有的 rules/ + rules-engine.ps1 不废弃，而是作为通信系统的子模块：

1. `shared/rules.md` 由 `rules-engine.ps1` 从 `rules/*.yaml` 自动生成
2. AI 读取 `shared/rules.md` 获取当前协作规则
3. 修改规则仍通过编辑 `rules/*.yaml` → 运行引擎 → 更新 `shared/rules.md`
4. 规则只是通信内容的一种，与 discoveries/decisions/status 并列

#### Scenario: 规则更新流程
- **WHEN** 修改了 `rules/*.yaml` 文件
- **THEN** 运行 `powershell scripts/rules-engine.ps1 --output shared/rules.md`
- **AND** `shared/rules.md` 被更新为最新规则内容
- **AND** 下一个会话的 AI 读取到最新规则

### Requirement: AGENTS.md 洞察传承

AGENTS.md 中 SHALL 包含关于自身特殊性的元认知声明，确保这个关键洞察不会丢失：

```markdown
## 🔑 关于本文件的关键洞察

**AGENTS.md 会被 AI 每次回复时自动读取。**

这意味着：
1. 它是跨会话通信的天然入口 — AI 不需要"记住"去读它，因为每次都会读
2. 写在这里的指令具有最高执行力 — 比 README、progress 等文件的优先级更高
3. 它应该保持精简 — 只做路由/跳板，不存储具体内容
4. 如果你想设计跨会话系统，利用这个文件的"每次必读"特性是最巧妙的方式

如果你是未来想改进跨会话通信的 AI，请记住：**AGENTS.md 是你的锚点。**
```

#### Scenario: 未来 AI 想改进跨会话系统
- **WHEN** 一个 AI 会话想要改进或重新设计跨会话通信机制
- **THEN** 从 AGENTS.md 中读到这个洞察
- **AND** 理解为什么 AGENTS.md 是跨会话通信的关键锚点
- **AND** 基于这个洞察做出更好的设计决策

## MODIFIED Requirements

### Requirement: AGENTS.md 定位升级

**原定位**：规则路由器 / 入口点
**新定位**：跨会话通信入口 + 跨会话意识声明

AGENTS.md 的职责从"引导 AI 加载规则"扩展为：
1. 声明跨会话意识（最核心）
2. 引导 AI 读取 shared/ 共享知识库
3. 传承关于自身特殊性的洞察
4. 规则加载降级为其中一个引导项

## REMOVED Requirements

### Requirement: AGENTS.md 仅作为规则路由器

**原因**：规则只是跨会话通信内容的一种。将 AGENTS.md 限制为"规则路由器"过于狭隘，无法承载更广泛的跨会话通信需求。

**迁移**：AGENTS.md 升级为"跨会话通信入口"，规则加载成为其功能子集。
