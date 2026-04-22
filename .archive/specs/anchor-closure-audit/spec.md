# Anchor 闭环性审计与进化方向 Spec

## Why

上一轮迭代中，我们发现了"改名规则只存在于 spec 中，AI 不知道"的闭环缺口。修复方式是将改名指引写入 `_registry.md`、决策记录写入 `decisions.md`。这暴露了一个更深层的模式：**Anchor 系统的很多设计知识只存在于人类口头传达或 spec 历史文件中，而非系统自身中**。需要系统性审计所有闭环缺口，并规划进化方向。

## 闭环性分析框架

一个"闭环"的系统意味着：**系统自身包含维护自身所需的所有知识，新 AI 会话无需人类口头传达即可正确操作和演进系统。**

闭环的三个层次：

| 层次 | 含义 | 当前状态 |
|------|------|---------|
| **操作闭环** | AI 知道怎么用系统 | ✅ 基本完成（AGENTS.md → _registry.md → 模块） |
| **维护闭环** | AI 知道怎么维护系统 | ⚠️ 部分完成（改名指引 ✅，但其他维护操作缺失） |
| **进化闭环** | AI 知道怎么改进系统 | ❌ 几乎缺失（设计原则、反模式、进化方向不在系统中） |

---

## 闭环缺口清单

### 缺口 1: 规则与 Anchor 系统脱节

**现状**: `rules/*.yaml` 中的 15 条规则仍然指向旧的工作流（"阅读 README.md"、"写入 source-architecture.md"、"更新 progress.txt"），没有一条规则提到 Anchor 系统的 shared/ 目录。

**问题**: 新 AI 读了 AGENTS.md 知道要读 shared/，但规则引擎输出的规则却引导 AI 去读 README 和 progress.txt，造成**双重引导、互相矛盾**。

**闭环缺失**: 规则系统不知道 Anchor 系统的存在。

### 缺口 2: 设计原则不在系统中

**现状**: 以下设计原则只存在于 spec 历史文件和人类记忆中：
- "去品牌化" — shared/*.md 不含系统品牌名
- "集中定义" — 系统名只在 2 个文件中硬编码
- "历史不改" — 历史文件保持原名
- "AGENTS.md 只做路由" — 不存储具体内容
- "牵一发动全身" — 增删模块不应影响其他文件

**问题**: 未来 AI 想改进系统时，不知道这些原则，可能违反它们。比如在 shared/*.md 中重新加入品牌名。

**闭环缺失**: 系统不知道自己的设计约束。

### 缺口 3: 反模式不在系统中

**现状**: 我们踩过的坑没有系统化记录：
- 在 shared/*.md 中硬编码系统名（导致改名困难）
- 在 AGENTS.md 中硬编码文件列表（导致增删模块要改 AGENTS.md）
- 修改历史文件中的系统名（篡改历史）

**问题**: 未来 AI 可能重犯同样的错误。

**闭环缺失**: 系统不知道"什么不该做"。

### 缺口 4: 写入触发不完整

**现状**: AGENTS.md 的"写入责任"表只覆盖了 4 种写入时机，但实际还有：
- 改进 Anchor 系统本身时 → 写哪里？
- 发现系统设计缺陷时 → 写哪里？
- 模块需要新增/删除时 → _registry.md 有指引，但 AGENTS.md 没提

**问题**: AI 在改进系统时不知道该往哪写。

**闭环缺失**: 系统维护的写入路径不完整。

### 缺口 5: 新鲜度无感知

**现状**: shared/ 文件没有"最后更新"时间戳机制。AI 无法判断：
- status.md 是否已过时（上次会话有没有更新？）
- discoveries.md 中的偏移量是否仍有效（Trae 更新后可能变化）
- context.md 中的技术栈信息是否仍准确

**问题**: AI 可能依赖过时信息做出错误决策。

**闭环缺失**: 系统不知道自己是否新鲜。

### 缺口 6: 可移植性知识不在系统中

**现状**: Anchor 系统的可移植性是一个核心设计目标，但"如何移植到新项目"的知识只在 `docs/dynamic-rules-system.md`（人类文档）中，不在 shared/ 系统中。

**问题**: 如果项目文档被删除或重构，移植知识就丢了。

**闭环缺失**: 系统不知道如何复制自己。

### 缺口 7: 规则引擎与 shared/ 的关系不明确

**现状**: rules-engine.ps1 生成 shared/rules.md，但：
- 规则中引用的文档路径（README.md, source-architecture.md）与 shared/ 系统的模块不一致
- 没有规则引导 AI 使用 shared/ 系统
- rules.md 作为 shared/ 模块之一，但其内容与 Anchor 系统脱节

**问题**: 规则系统和通信系统是两套独立的设计，没有融合。

**闭环缺失**: 两个子系统之间缺乏协调。

---

## 进化方向

### 方向 A: 规则系统融入 Anchor（优先级: 高）

将 rules/*.yaml 的内容与 Anchor 的 shared/ 系统对齐：
- 规则中引用 shared/ 模块而非分散的文档
- 新增 "Anchor 系统维护规则"（如：不要在 shared/*.md 中硬编码品牌名）
- 让规则引擎成为 Anchor 的真正子系统，而非独立存在

### 方向 B: 设计原则模块化（优先级: 高）

在 _registry.md 或新增 shared/principles.md 中记录 Anchor 的设计原则：
- 去品牌化原则
- 集中定义原则
- 历史不改原则
- 牵一发动全身原则
- AGENTS.md 只做路由原则

这样新 AI 读取后就知道系统的设计约束。

### 方向 C: 反模式记录（优先级: 中）

在 decisions.md 或新增 shared/antipatterns.md 中记录已知的反模式：
- "在 shared/*.md 中硬编码系统名"
- "在 AGENTS.md 中硬编码文件列表"
- "修改历史文件中的名称"

### 方向 D: 新鲜度机制（优先级: 中）

为 shared/ 模块增加新鲜度标记：
- 每个模块头部增加 `last_updated` 字段
- 或在 status.md 中增加"各模块最后更新时间"追踪

### 方向 E: 自举/移植指引（优先级: 低）

在 _registry.md 或新增 shared/bootstrap.md 中记录"如何将 Anchor 移植到新项目"的步骤。

### 方向 F: 系统健康检查（优先级: 低）

增加 `scripts/anchor-health.ps1` 或类似机制，检查：
- shared/*.md 是否包含品牌名（违反去品牌化原则）
- AGENTS.md 是否硬编码了文件列表（违反解耦原则）
- _registry.md 中的模块是否都有对应文件

---

## What Changes

### 本轮实施范围（高优先级）

- **A**: 规则系统融入 Anchor — 更新 rules/*.yaml，让规则引用 shared/ 模块
- **B**: 设计原则模块化 — 在 _registry.md 中增加"设计原则"章节

### 延后范围（中低优先级）

- **C**: 反模式记录 — 可在后续迭代中加入 decisions.md
- **D**: 新鲜度机制 — 需要更多设计思考
- **E**: 自举指引 — 可移植性暂时由人类文档承载
- **F**: 健康检查 — 需要脚本开发

## Impact

- Affected files: rules/*.yaml（内容更新）, shared/_registry.md（增加设计原则）
- Affected specs: dynamic-agent-rules-system（规则内容变更）

## ADDED Requirements

### Requirement: 规则与 Anchor 系统对齐

rules/*.yaml 中的规则 SHALL 引用 Anchor 的 shared/ 模块，而非分散的文档路径。

#### Scenario: AI 执行规则-001（新会话必读）
- **WHEN** AI 读取规则 "新会话开始前必读文档"
- **THEN** 规则引导 AI 读取 shared/_registry.md → 按 P0/P1/P2 优先级读取模块
- **AND** 不再单独列出 README.md / source-architecture.md / progress.txt

### Requirement: Anchor 设计原则持久化

Anchor 系统的设计原则 SHALL 记录在系统自身中（_registry.md 或独立模块），确保新 AI 会话能了解系统的设计约束。

#### Scenario: AI 想在 shared/*.md 中加入系统品牌名
- **WHEN** AI 考虑在 shared/context.md 中写入 "Anchor 共享知识库"
- **THEN** 从设计原则中得知"去品牌化"原则
- **AND** 改为只写功能描述

#### Scenario: AI 想在 AGENTS.md 中列出所有 shared/ 文件
- **WHEN** AI 考虑在 AGENTS.md 中硬编码 shared/ 文件列表
- **THEN** 从设计原则中得知"AGENTS.md 只做路由"原则
- **AND** 改为只指向 _registry.md

## MODIFIED Requirements

### Requirement: rules/*.yaml 内容更新

**原内容**: 引用 README.md、source-architecture.md、progress.txt 等分散文档
**修改后**: 引用 Anchor shared/ 模块系统，规则与通信系统融合

## REMOVED Requirements

无
