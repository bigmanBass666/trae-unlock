# 跨会话 Agent 动态规则遵守系统 Spec

## Why

**问题现状**：
- 当前项目依赖 `AGENTS.md` 硬编码所有协作规则 → 新会话 AI 可能忽略或不完全遵守
- 规则分散在多个文档中（README.md、progress.txt、source-architecture.md） → 维护成本高、牵一发而动全身
- 缺乏"规则是否被遵守"的可观测性 → 无法知道新会话 AI 是否真的读了并理解了规则

**机会点**：
- `AGENTS.md` 是 Trae IDE 的特殊文件 → **AI 每次回复都会自动读取**
- 可以利用这个特性将 AGENTS.md 从"静态规则文档"升级为**"动态规则引擎入口"**
- 通过"配置驱动 + 脚本生成"实现规则的动态化管理和跨项目移植

## What Changes

### 核心创新：三层架构

```
┌─────────────────────────────────────────────┐
│  Layer 1: AGENTS.md (路由器/入口)            │
│  - 极简引导指令                              │
│  - 指向规则加载器                            │
│  - 强制性措辞确保被执行                      │
├─────────────────────────────────────────────┤
│  Layer 2: 规则引擎 (scripts/rules-engine.ps1)│
│  - 读取 rules/ 目录下的配置                  │
│  - 动态生成当前有效的规则集                   │
│  - 支持条件判断、优先级、版本控制             │
├─────────────────────────────────────────────┤
│  Layer 3: 规则仓库 (rules/*.yaml)           │
│  - 结构化规则定义                            │
│  - 分类管理（必读/工作流/提交/安全等）        │
│  - 支持启用/禁用单个规则                     │
└─────────────────────────────────────────────┘
```

### 具体变更

#### 1. **新增 `rules/` 规则仓库目录**
- `rules/core.yaml` — 核心必读规则（读文档、更新进度等）
- `rules/workflow.yaml` — 工作流程规则（探索→修改→测试→提交）
- `rules/git.yaml` — Git 提交规范（格式、push 要求）
- `rules/safety.yaml` — 安全规则（不泄露密钥、不破坏 .git）
- 每个规则支持：`enabled: true/false`、`priority: high/medium/low`、`conditions` 条件触发

#### 2. **新增 `scripts/rules-engine.ps1` 规则引擎脚本**
- 功能：读取所有 `.yaml` 规则文件 → 过滤出 `enabled: true` 的规则 → 按 priority 排序 → 生成格式化的 Markdown 规则文本
- 输出：可直接嵌入 AGENTS.md 的动态内容块
- 支持 `--check` 模式：验证规则语法、检测冲突

#### 3. **重构 `AGENTS.md` 为轻量级路由器**
- 从 ~128 行精简到 ~30 行
- 移除所有硬编码规则细节
- 只保留：
  - ⚠️ 强制执行声明（必须运行规则引擎）
  - 📍 规则加载命令（`powershell scripts/rules-engine.ps1`）
  - 🔄 规则刷新机制（修改 rules/ 后重新生成）

#### 4. **新增 `docs/dynamic-rules-system.md` 使用文档**
- 说明如何添加/修改/禁用规则
- 规则 YAML 格式规范
- 可移植性指南（迁移到其他项目）

### **BREAKING Changes**
- ❌ AGENTS.md 不再包含详细规则 → 必须依赖规则引擎生成
- ⚠️ 需要 PowerShell 5.1+ 环境（Trae IDE 默认已满足）

## Impact

### Affected Specs
- 无已有 spec 受影响（这是全新功能）

### Affected Code/Documents
- ✅ **新增文件**：
  - `rules/core.yaml`
  - `rules/workflow.yaml`
  - `rules/git.yaml`
  - `rules/safety.yaml`
  - `scripts/rules-engine.ps1`
  - `docs/dynamic-rules-system.md`
- 📝 **重构文件**：
  - `AGENTS.md` (从静态规则 → 动态路由)
- 🔍 **优化文件**：
  - `README.md` (新增动态规则系统说明)

## ADDED Requirements

### Requirement: 动态规则加载与渲染

系统 SHALL 提供一个规则引擎，能够：

1. **读取规则仓库**：扫描 `rules/*.yaml` 目录下所有规则文件
2. **过滤有效规则**：只加载 `enabled: true` 的规则条目
3. **按优先级排序**：`high > medium > low`
4. **生成标准化输出**：输出格式化的 Markdown 文本，可直接被 AGENTS.md 引用
5. **支持条件判断**：规则可定义 `conditions` 字段，只在满足条件时生效

#### Scenario: 成功加载规则集
- **WHEN** 执行 `powershell scripts/rules-engine.ps1`
- **THEN** 输出完整的规则 Markdown 文本，包含所有已启用的规则
- **AND** 规则按优先级排序（核心规则在前）
- **AND** 禁用的规则不出现在输出中

#### Scenario: 规则文件不存在或格式错误
- **WHEN** rules/ 目录为空或某个 .yaml 文件语法错误
- **THEN** 输出错误提示并退出（非零状态码）
- **AND** 列出具体哪个文件有问题

### Requirement: 结构化规则定义格式

每个规则 YAML 文件 SHALL 遵循统一 schema：

```yaml
rules:
  - id: "rule-001"
    name: "读文档再动手"
    category: core
    priority: high
    enabled: true
    description: "在开始任何工作前，必须阅读指定文档"
    actions:
      - "阅读 README.md 了解项目整体情况"
      - "阅读 docs/architecture/source-architecture.md 了解已有知识"
      - "阅读 progress.txt 了解当前进度"
    enforcement: mandatory  # mandatory / recommended / optional
    conditions: {}  # 可选：空表示始终生效
```

#### Scenario: 添加新规则
- **WHEN** 在 `rules/custom.yaml` 中添加一条新规则定义
- **AND** 设置 `enabled: true`
- **THEN** 下次运行规则引擎时，该规则自动出现在输出中

#### Scenario: 临时禁用规则
- **WHEN** 将某条规则的 `enabled` 改为 `false`
- **THEN** 下次运行规则引擎时，该规则不再出现在输出中
- **AND** 规则文件本身保留（便于后续重新启用）

### Requirement: AGENTS.md 路由器机制

AGENTS.md SHALL 作为轻量级入口，具备以下特性：

1. **极简设计**：总行数 < 50 行
2. **强制性引导**：使用强烈的措辞要求 AI 执行规则加载命令
3. **指向规则引擎**：明确告诉 AI 如何获取完整规则
4. **缓存友好**：规则内容通过命令动态生成，避免手动维护

#### Scenario: 新会话 AI 启动时
- **WHEN** AI 开始新的对话会话
- **AND** 自动读取 AGENTS.md
- **THEN** 看到"⚠️ 必须先执行规则加载命令"的强提醒
- **AND** 执行 `powershell scripts/rules-engine.ps1` 获取完整规则集
- **AND** 按照输出的规则指导后续行为

### Requirement: 规则可观测性与合规检查

系统 SHALL 提供验证机制：

1. **`--check` 模式**：验证所有规则文件的语法正确性
2. **`--list` 模式**：列出所有规则及其启用状态（不生成完整内容）
3. **冲突检测**：检查是否有重复 ID 或矛盾的条件

#### Scenario: 运行合规检查
- **WHEN** 执行 `powershell scripts/rules-engine.ps1 --check`
- **THEN** 输出每个规则文件的验证结果（✅ 通过 / ❌ 错误详情）
- **AND** 如果有错误，返回非零退出码

## MODIFIED Requirements

### Requirement: AGENTS.md 维护成本降低

**原需求**：AGENTS.md 包含所有协作规则（~128 行），每次修改规则都要编辑此文件

**修改后**：
- AGENTS.md 缩减为 ~30 行的路由器
- 规则细节全部外置到 `rules/*.yaml` 文件
- 修改规则只需编辑对应的 YAML 文件，无需触碰 AGENTS.md
- 规则引擎自动合并和格式化所有规则

## REMOVED Requirements

### Requirement: 硬编码的多文档引用链

**原因**：原有设计要求 AI 依次阅读 README.md → source-architecture.md → progress.txt，形成固定链路。这种硬编码方式：
- 不灵活（无法跳过某些文档或调整顺序）
- 维护困难（新增文档要改 AGENTS.md 多处）
- 可移植性差（其他项目文档结构不同）

**迁移**：
- 将"必读文档列表"作为一条规则写入 `rules/core.yaml`
- 其他项目可以自定义自己的文档链路
- 规则引擎动态生成当前的文档阅读要求

---

## 未来扩展方向（不在本次实现范围）

1. **规则版本控制**：支持规则文件的 git 版本管理，可回滚到历史版本
2. **AI 合规评分**：通过日志分析 AI 是否真正遵守了规则（需要集成层支持）
3. **多环境规则**：开发/测试/生产环境使用不同规则集（通过 `conditions` 字段）
4. **Web UI 管理界面**：可视化编辑规则（需要前端支持）
