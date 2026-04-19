# 跨会话 Agent 规则遵守框架 Spec

## Why

在多 AI 协作项目中（如本项目的 Trae Mod），存在一个核心痛点：**每个新会话的 AI Agent 都可能忽略项目已有的规则文档（如 AGENTS.md），导致行为不一致、重复工作、违反约定等问题**。

**根本原因分析**:
1. **被动依赖**: 当前 AGENTS.md 依赖 AI "主动阅读"，但 AI 可能跳过或遗忘
2. **无强制机制**: 缺乏技术层面的规则注入和验证手段
3. **上下文丢失**: 新会话没有历史记忆，无法继承前序会话的经验教训
4. **不可移植**: 规则硬编码在特定文档格式中，难以迁移到其他项目

**机会**: 设计一套**主动式、可验证、可移植**的 Agent 规则治理系统，让项目规则从"建议性文档"升级为"强制性契约"。

## What Changes

### 第一阶段：在本项目落地（Trae Mod 项目专用）

- **新增规则引擎层**: 在 AGENTS.md 基础上增加结构化规则定义
- **新增规则注入机制**: 确保每次新会话启动时自动加载规则
- **新增规则验证检查点**: 在关键操作前验证是否遵守规则
- **新增跨会话状态同步**: 让后续会话能感知前序会话的重要决策

### 第二阶段：抽象为通用框架（可迁移至任意项目）

- **提取规则定义模式**: 将规则结构标准化（YAML/JSON Schema）
- **提取注入适配器**: 支持多种 IDE/工具链（Trae, Cursor, VS Code + Copilot 等）
- **提取验证器接口**: 可插拔的规则检查逻辑
- **提供模板和工具**: 快速初始化新项目的规则系统

## Impact

- Affected specs: 无（全新功能）
- Affected code:
  - `AGENTS.md` — 升级为结构化规则定义
  - `.trae/rules/` (新建) — 规则配置目录
  - `scripts/` (扩展) — 规则注入和验证脚本
  - `docs/guides/` (新建) — 使用指南

---

## ADDED Requirements

### Requirement: 结构化规则定义系统

系统 SHALL 提供标准化的规则定义格式，支持以下规则类型：

#### R1.1: 必读文档规则 (RequiredReading)
- **WHEN** 新会话启动时
- **THEN** Agent MUST 按优先级读取指定文档列表
- **示例**: 必须先读 README.md → source-architecture.md → progress.txt

#### R1.2: 操作前检查规则 (PreActionCheck)
- **WHEN** Agent 准备执行敏感操作（修改代码、提交 Git 等）
- **THEN** Agent MUST 先验证是否满足前置条件
- **示例**: 修改代码前必须先读相关文档；提交前必须更新 progress.txt

#### R1.3: 强制行为规则 (MandatoryBehavior)
- **WHEN** Agent 执行特定操作时
- **THEN** Agent MUST 按照规定的方式执行
- **示例**: 每次 commit 后必须立即 push；禁止 merge 操作

#### R1.4: 禁止行为规则 (ProhibitedBehavior)
- **WHEN** Agent 考虑执行危险操作时
- **THEN** Agent MUST 拒绝执行并提示替代方案
- **示例**: 禁止在没有 push 的情况下进行 merge；禁止删除 .git 目录

#### R1.5: 文档更新契约 (DocumentationContract)
- **WHEN** Agent 完成特定类型的操作后
- **THEN** Agent MUST 同步更新指定的文档
- **示例**: 发现新代码位置 → 更新 source-architecture.md；完成补丁 → 更新 progress.txt

### Requirement: 规则注入机制

系统 SHALL 确保 Agent 在新会话中**不可避免地**接收到规则：

#### Scenario: 自动化规则加载
- **WHEN** 用户打开新会话并发送第一条消息
- **THEN** 系统 SHOULD 自动将核心规则摘要注入到 system prompt 或初始上下文中
- **实现方式**: 利用 IDE 的自定义指令功能 / workspace rules / .trae/rules 目录

#### Scenario: 分级规则加载
- **WHEN** 会话类型不同（Plan Mode / Agent Mode / Chat Mode）
- **THEN** 系统 SHOULD 注入不同级别的规则详情
- **Plan Mode**: 完整规则 + 架构文档索引
- **Agent Mode**: 核心行为规则 + 关键检查点
- **Chat Mode**: 简要规则摘要 + 文档链接

### Requirement: 规则验证与强制执行

系统 SHALL 提供机制验证 Agent 是否遵守规则：

#### Scenario: 关键操作前的规则检查
- **WHEN** Agent 准备执行高风险操作（Git commit/push, 删除文件, 修改核心代码等）
- **THEN** 系统 SHOULD 在工具调用层面拦截并验证是否符合规则
- **验证方式**: 通过 IDE 的权限控制 / 自定义工具包装器 / 后置检查脚本

#### Scenario: 违规检测与纠正
- **WHEN** 检测到 Agent 可能违反规则（如未读文档就改代码）
- **THEN** 系统 SHOULD 发出警告并提供纠正指导
- **警告级别**: Error（必须停止） / Warning（建议 reconsider） / Info（提醒注意）

### Requirement: 跨会话知识传承

系统 SHALL 让后续会话能够利用前序会话的成果：

#### Scenario: 进度状态可见性
- **WHEN** 新会话启动时
- **THEN** Agent SHOULD 能快速了解项目的当前状态和最近活动
- **数据来源**: progress.txt, git log, docs/architecture/ 下的最新文档

#### Scenario: 决策记录追溯
- **WHEN** Agent 需要理解之前的某个决策原因时
- **THEN** Agent SHOULD 能找到对应的决策记录和讨论过程
- **存储方式**: git commit messages, docs/ 下的决策文档, 代码注释

### Requirement: 可移植性抽象

系统 SHALL 设计为可在不同项目和工具链中复用：

#### Scenario: 项目模板生成
- **WHEN** 用户在新项目中初始化规则系统
- **THEN** 系统 SHOULD 提供脚手架工具生成基础规则文件
- **输出**: `.trae/rules/project-rules.yaml`, `AGENTS.md` 模板, `scripts/validate-rules.ps1`

#### Scenario: 工具链适配
- **WHEN** 项目使用不同的 IDE 或 AI 工具
- **THEN** 系统 SHOULD 通过适配器层支持不同平台的规则注入
- **支持平台**: Trae (优先), Cursor (.cursorrules), VS Code Copilot (.github/copilot-instructions.md), 通用 (.ai-agents/)

---

## MODIFIED Requirements

### Requirement: AGENTS.md 升级

现有的 AGENTS.md SHALL 从纯文本规则文档升级为**规则入口 + 引擎配置**：

```markdown
# Agent Rules for [Project Name]

## 📋 规则系统版本: v2.0
- **规则定义**: .trae/rules/project-rules.yaml (结构化)
- **注入机制**: 已集成到 IDE workspace rules
- **验证脚本**: scripts/validate-agent-actions.ps1

## ⚠️ 快速开始（给新 AI 的必读指引）

[保留现有核心规则的精简版...]
```

### Requirement: 文档体系增强

现有文档 SHALL 增加规则相关的元数据和索引：

- **progress.txt**: 增加 `[规则]` 类型的条目
- **source-architecture.md**: 增加"规则系统架构"章节
- **README.md**: 增加"规则合规要求"章节

---

## REMOVED Requirements

无（增量改进，不移除现有功能）

---

## 技术架构概览

```
┌─────────────────────────────────────────────────────┐
│                  跨会话 Agent 规则框架                 │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────┐    ┌──────────────────────────┐   │
│  │ 规则定义层     │    │ 规则注入层                │   │
│  │              │    │                          │   │
│  │ • YAML/JSON  │───▶│ • Workspace Rules 配置   │   │
│  │ • Schema 校验 │    │ • System Prompt 注入     │   │
│  │ • 版本管理    │    │ • 工具描述增强            │   │
│  └──────────────┘    └──────────────────────────┘   │
│           │                      │                   │
│           ▼                      ▼                   │
│  ┌──────────────────────────────────────────┐       │
│  │              规则执行引擎                   │       │
│  │                                          │       │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  │       │
│  │  │ 加载器   │  │ 解析器   │  │ 验证器   │  │       │
│  │  └─────────┘  └─────────┘  └─────────┘  │       │
│  └──────────────────────────────────────────┘       │
│                      │                              │
│          ┌───────────┼───────────┐                  │
│          ▼           ▼           ▼                  │
│  ┌──────────────┐ ┌──────────┐ ┌──────────────┐    │
│  │ Agent 行为   │ │ 文档更新  │ │ 跨会话同步    │    │
│  │ 引导 & 约束  │ │ 契约检查  │ │ 状态 & 决策   │    │
│  └──────────────┘ └──────────┘ └──────────────┘    │
│                                                      │
└─────────────────────────────────────────────────────┘
```

## 实施路线图

### Phase 1: 本项目落地（MVP）
1. 定义 Trae Mod 项目的完整规则集（YAML 格式）
2. 实现 Trae IDE 的规则注入（.trae/rules + AGENTS.md 增强）
3. 创建关键操作的验证脚本
4. 测试多会话场景下的规则遵守情况

### Phase 2: 框架抽象
1. 提取通用规则 Schema 和定义模式
2. 实现多平台适配器（Trae/Cursor/VSCode）
3. 提供项目初始化脚手架工具
4. 编写完整的移植指南和使用文档

### Phase 3: 生态扩展（可选）
1. 规则市场/共享库（社区贡献常见规则模板）
2. IDE 插件形式的原生支持
3. 与 CI/CD 集成的自动化合规检查
