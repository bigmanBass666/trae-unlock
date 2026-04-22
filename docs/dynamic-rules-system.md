# Anchor 规则子系统使用指南

> ⚠️ **架构升级通知 (2026-04-20)**：本规则系统已升级为**Anchor**的子模块。规则只是通信内容的一种——AI 还可以通过 `shared/` 目录持久化发现、决策、状态等信息。详见 `shared/` 目录和 `AGENTS.md` 中的Anchor 声明。

> **Anchor 规则子系统** — 让 AI 在每次会话中自动加载、理解和执行项目规范

本系统解决的核心问题：**如何让 AI Agent 跨会话保持一致的行为规范？** 通过三层架构（路由器 + 引擎 + 规则仓库），实现规则的**动态管理**、**版本控制友好**和**零维护成本**。核心优势：修改 YAML 即生效，无需改代码；规则按优先级排序，重要规则优先展示；支持启用/禁用，灵活适应不同场景。

## 三层架构概览

```
┌─────────────────────────────────────────┐
│  Layer 1: AGENTS.md (轻量级路由器)       │  ← AI 每次必读的入口文件
│  - 强制引导指令                           │
│  - 触发规则引擎执行                       │
└──────────────┬──────────────────────────┘
               ↓ 调用
┌─────────────────────────────────────────┐
│  Layer 2: rules-engine.ps1 (规则引擎)    │  ← PowerShell 脚本
│  - YAML 解析 → 过滤 → 排序 → 格式化      │
│  - 支持 --check / --list / --output 模式  │
└──────────────┬──────────────────────────┘
               ↓ 加载
┌─────────────────────────────────────────┐
│  Layer 3: rules/*.yaml (规则仓库)        │  ← 4 个 YAML 文件，15 条规则
│  - core.yaml / workflow.yaml             │
│  - git.yaml / safety.yaml                │
│  - 结构化定义 + 启用/禁用控制              │
└─────────────────────────────────────────┘
```

---

## 快速开始

### Step 1: 运行规则引擎查看当前规则

```powershell
cd d:\Test\trae-unlock
powershell scripts/rules-engine.ps1
```

**预期输出**: 完整的 Markdown 格式规则清单，按类别分组，包含所有启用的规则。

### Step 2: 编辑 rules/*.yaml 添加自定义规则

```powershell
# 例如：编辑 Git 规则文件
notepad rules/git.yaml
```

在 `rules:` 数组末尾追加新规则（详见第 4 章 YAML Schema）。

### Step 3: 重新运行引擎验证新规则生效

```powershell
# 验证语法正确性
powershell scripts/rules-engine.ps1 --check

# 查看完整输出（新规则应出现在列表中）
powershell scripts/rules-engine.ps1

# 或以表格形式快速查看状态
powershell scripts/rules-engine.ps1 --list
```

**完成！** 新规则已生效，AI 下次会话将自动遵守。

---

## 系统架构详解

### Layer 1: AGENTS.md 路由器

**作用**: 为什么 AI 每次都会读这个文件？

Trae IDE 的机制是：**每个新会话开始时，AI 会自动读取项目根目录的 AGENTS.md 文件**。我们利用这一特性，将 AGENTS.md 设计为"轻量级路由器"——只包含强制引导指令，不包含具体规则内容。

**设计哲学**:
- **极简入口**: 仅保留核心的"必读文档列表"和"文档更新要求"
- **强制引导**: 使用 `⚠️` 和粗体强调关键操作
- **零维护成本**: 规则变更只需编辑 YAML，无需改动 AGENTS.md

**维护频率**: 几乎为零（仅当需要新增核心流程时才需修改）

**当前结构**:
- 新会话开始前必读（3 个核心文档）
- 核心规则（4 种触发场景的文档更新要求）
- Git 提交规则（格式 + 强制 push）
- 目录结构和工作流程参考

### Layer 2: 规则引擎 (rules-engine.ps1)

**功能**: YAML 解析 → 过滤 → 排序 → 格式化的完整流水线。

**技术实现**:
- 使用 `powershell-yaml` 库（PowerShell Gallery）进行 YAML 解析
- `ConvertFrom-Yaml` 处理标准 YAML 格式（数组、嵌套键值对、引号清理等）
- 模块自动加载：优先使用本地路径，回退到 PowerShell 模块路径

**支持的运行模式**:

| 模式 | 命令 | 用途 | 输出格式 |
|------|------|------|----------|
| 默认模式 | `powershell scripts/rules-engine.ps1` | 生成完整规则清单 | Markdown |
| 验证模式 | `powershell scripts/rules-engine.ps1 --check` | 检查 YAML 语法 | 终端文本 (✅/❌) |
| 列表模式 | `powershell scripts/rules-engine.ps1 --list` | 查看规则状态摘要 | 表格 |
| 输出模式 | `powershell scripts/rules-engine.ps1 --output "file.md"` | 导出到文件 | Markdown 文件 |

**核心处理逻辑**:
1. **扫描**: 递归读取 `rules/` 目录下所有 `.yaml` 文件
2. **解析**: 将 YAML 内容转换为 PowerShell 对象数组
3. **过滤**: 移除 `enabled: false` 的规则
4. **排序**: 按 `priority` (high > medium > low) 排序，同优先级按 ID 升序
5. **格式化**: 生成分组 Markdown（按 category 分组）或表格输出

### Layer 3: 规则仓库 (rules/*.yaml)

**结构化规则定义**: 每个 YAML 文件包含一个 `rules:` 数组，数组元素是独立的规则对象。

**当前规则分布**:

| 文件 | 类别 | 规则数量 | 说明 |
|------|------|----------|------|
| [core.yaml](../rules/core.yaml) | 核心规范 | 4 条 | 文档阅读、更新、共享要求 |
| [workflow.yaml](../rules/workflow.yaml) | 工作流程 | 3 条 | 八步循环、时机控制、迭代原则 |
| [git.yaml](../rules/git.yaml) | Git 规范 | 4 条 | 提交格式、强制 push、风险控制 |
| [safety.yaml](../rules/safety.yaml) | 安全原则 | 4 条 | 代码安全、仓库保护、防重复工作 |

**管理特性**:
- ✅ **启用/禁用控制**: 通过 `enabled: true/false` 开关
- ✅ **优先级排序**: `high` / `medium` / `low` 三级
- ✅ **分类管理**: 按 `category` 字段分组显示
- ✅ **版本控制友好**: 纯文本 YAML，Git diff 友好

---

## YAML Schema 完整参考

### 规则对象完整结构

```yaml
rules:
  - id: "rule-XXX"           # 必填，唯一标识符（如 rule-016）
    name: "规则名称"          # 必填，简短的中文名称
    category: core            # 必填，分类：core/workflow/git/safety/custom
    priority: high            # 必填，优先级：high/medium/low
    enabled: true             # 必填，是否启用：true/false
    description: "描述文字"    # 必填，1-2 句话说明规则用途
    actions:                  # 必填，操作步骤数组（至少 1 个）
      - "步骤 1"
      - "步骤 2"
    enforcement: mandatory     # 必填，强制级别：mandatory/recommended/optional
    conditions: {}             # 可选，条件触发（留空表示始终生效）
```

### 字段约束表

| 字段 | 类型 | 必填 | 可选值 | 示例 | 说明 |
|------|------|------|--------|------|------|
| `id` | string | ✅ | 唯一 ID | `"rule-016"` | 格式：`rule-NNN`，编号连续 |
| `name` | string | ✅ | 中文 | `"代码审查前必读"` | 简短明确，≤20 字 |
| `category` | string | ✅ | 枚举值 | `"core"` | 见下方分类说明 |
| `priority` | string | ✅ | 枚举值 | `"high"` | high > medium > low |
| `enabled` | boolean | ✅ | `true`/`false` | `true` | 控制规则是否生效 |
| `description` | string | ✅ | 自由文本 | `"描述文字"` | ≤50 字，说明用途 |
| `actions` | array | ✅ | 字符串数组 | `["步骤1", "步骤2"]` | 至少 1 个，以动词开头 |
| `enforcement` | string | ✅ | 枚举值 | `"mandatory"` | 见下方强制级别说明 |
| `conditions` | object | ❌ | JSON 对象 | `{}` | 预留字段，暂未使用 |

### 分类 (category) 可选值

| 值 | 含义 | 适用场景 |
|----|------|----------|
| `core` | 核心规范 | 文档阅读、知识共享、基础要求 |
| `workflow` | 工作流程 | 操作顺序、迭代循环、阶段控制 |
| `git` | Git 规范 | 提交格式、push 要求、分支策略 |
| `safety` | 安全原则 | 代码安全、风险控制、防误操作 |
| `custom` | 自定义 | 项目特有规则（用户扩展） |

### 强制级别 (enforcement) 可选值

| 值 | 图标 | 含义 | AI 行为 |
|----|------|------|----------|
| `mandatory` | ⚠️ | 强制执行 | 必须遵守，不得跳过 |
| `recommended` | 💡 | 推荐执行 | 建议遵守，特殊情况下可调整 |
| `optional` | 📌 | 可选执行 | 参考性建议，灵活处理 |

### 最佳实践

✅ **ID 编号连续**: `rule-001`, `rule-002`, ..., `rule-015`（当前最大编号）

✅ **每个 YAML 文件 2-5 条规则**: 保持文件聚焦，便于维护

✅ **description 控制在 50 字以内**: 一句话说清楚"为什么需要这条规则"

✅ **actions 步骤清晰可操作**: 以动词开头（"阅读"、"记录"、"执行"），避免模糊表述

✅ **优先级合理分配**:
- `high`: 核心安全要求、必须执行的流程
- `medium`: 推荐的最佳实践、重要的工作习惯
- `low`: 辅助性建议、可选的优化项

---

## 常见操作教程

### 操作 1: 添加新规则

**场景**: 需要添加一条新的 Git 规则 —— "Commit 消息必须关联 Issue"

```yaml
# 步骤 1: 选择合适的 YAML 文件
# Git 相关规则 → 编辑 rules/git.yaml

# 步骤 2: 在 rules: 数组末尾追加新规则（注意缩进：2 空格）
  - id: "rule-016"
    name: "Commit 消息必须关联 Issue"
    category: git
    priority: medium
    enabled: true
    description: "每次提交必须关联对应的 Issue 编号，便于追溯"
    actions:
      - "在 commit message 中包含 #Issue编号"
      - "例如: git commit -m '[修复] 解决了 #123 的登录问题'"
      - "如果没有对应 Issue，先创建 Issue 再提交"
    enforcement: recommended
```

```powershell
# 步骤 3: 验证语法
powershell scripts/rules-engine.ps1 --check
# 预期输出: ✅ git.yaml: 5 rules validated

# 步骤 4: 查看新规则是否出现在输出中
powershell scripts/rules-engine.ps1 --list
# 预期输出: 表格中出现 rule-016 行
```

### 操作 2: 临时禁用规则

**场景**: 某条规则暂时不适用，但不想删除

```yaml
# 将 enabled: true 改为 enabled: false
# 示例：禁用 rule-010 (Git 操作风险控制)
  - id: "rule-010"
    name: "Git 操作风险控制"
    ...
    enabled: false    # ← 改为 false
    ...
```

下次运行引擎时，该规则不再出现在输出中（但在 `--list` 模式下仍会显示为灰色）。

### 操作 3: 修改现有规则

**场景**: 更新某条规则的描述或操作步骤

直接编辑对应字段即可：
- 修改 `description`: 更新规则说明
- 修改 `actions`: 增加/删除/修改操作步骤
- 修改 `enforcement`: 调整强制级别

⚠️ **注意**: 保持 YAML 缩进正确（2 空格层级），避免使用 Tab。

### 操作 4: 调整规则优先级

**场景**: 某条规则变得更重要，需要提升优先级

```yaml
# 修改 priority 字段
  - id: "rule-006"
    name: "文档更新时机控制"
    priority: high    # ← 从 medium 改为 high
    ...
```

优先级影响规则在输出中的排序位置：`high` > `medium` > `low`。

### 操作 5: 创建新的规则类别

**场景**: 项目有特殊的规则需求，不适合放入现有分类

```powershell
# 步骤 1: 创建新的 YAML 文件
notepad rules/custom.yaml
```

```yaml
# 步骤 2: 编写规则文件（注意顶层必须有 rules: 键）
rules:
  - id: "rule-017"
    name: "自定义规则名称"
    category: custom       # ← 设置为 custom
    priority: medium
    enabled: true
    description: "这是一条项目特有的规则"
    actions:
      - "执行特定操作"
    enforcement: recommended
```

```powershell
# 步骤 3: 验证并查看
powershell scripts/rules-engine.ps1 --check
powershell scripts/rules-engine.ps1
# 引擎会自动识别并加载新文件
```

---

## 故障排除

| 问题 | 可能原因 | 解决方案 |
|------|---------|---------|
| **运行引擎报错 "rules/ 目录不存在"** | 目录未创建或路径错误 | 确保在项目根目录 (`d:\Test\trae-unlock`) 运行命令；检查 `rules/` 目录是否存在 |
| **某 YAML 文件被跳过** | YAML 语法错误（缩进/冒号/引号问题） | 运行 `powershell scripts/rules-engine.ps1 --check` 查看详细错误信息；检查是否有 Tab 字符（必须用空格） |
| **新规则没出现在输出中** | `enabled: false` 或 ID 重复 | 检查 `enabled` 字段是否为 `true`；确认 ID 在所有文件中唯一 |
| **输出为空或显示"无有效规则"** | 所有规则都设置为 `enabled: false` | 至少启用一条规则（将某个 `enabled: false` 改为 `true`） |
| **中文乱码或显示异常** | 文件编码问题 | 确保 YAML 文件保存为 UTF-8 编码（推荐 UTF-8 without BOM）；用 VS Code 打开并检查右下角编码标识 |
| **--check 模式显示 "缺少顶层 rules: 键"** | YAML 文件格式错误 | 确保文件第一行（忽略注释后）是 `rules:` ；检查冒号后是否有空格 |
| **actions 数组解析失败** | 数组元素格式错误 | 确保每个 action 以 `- "` 开头（短横线 + 空格 + 引号）；检查引号是否成对 |

### 快速诊断命令

```powershell
# 1. 检查所有文件的语法
powershell scripts/rules-engine.ps1 --check

# 2. 查看所有规则的状态（包括禁用的）
powershell scripts/rules-engine.ps1 --list

# 3. 导出完整报告到文件以便分析
powershell scripts/rules-engine.ps1 --output "debug-report.md"

# 4. 检查 rules 目录是否存在且包含文件
ls rules/
```

---

## 迁移到其他项目

### 前置条件检查清单

- [ ] 目标项目使用 Trae IDE（或有类似的 AGENTS.md 自动读取机制）
- [ ] PowerShell 5.1+ 环境（Windows 10/11 自带）
- [ ] 有明确的团队协作规则需要 AI 遵守
- [ ] 团队愿意维护规则文件（预计每季度 review 一次）

### 迁移步骤（预计 15-30 分钟）

#### Step 1: 复制核心文件

```powershell
# 从 trae-unlock 项目复制到目标项目
Copy-Item -Path "d:\Test\trae-unlock\rules" -Destination "D:\your-project\rules" -Recurse
Copy-Item -Path "d:\Test\trae-unlock\scripts\rules-engine.ps1" -Destination "D:\your-project\scripts\rules-engine.ps1"

# 如果目标项目没有 scripts 目录，先创建
New-Item -ItemType Directory -Path "D:\your-project\scripts" -Force
```

#### Step 2: 自定义规则内容

根据目标项目的实际需求修改规则：

**编辑 `rules/core.yaml`**:
```yaml
# 替换为目标项目的文档阅读要求
rules:
  - id: "rule-001"
    name: "新会话开始前必读文档"
    category: core
    priority: high
    enabled: true
    description: "阅读目标项目的 README.md 和开发指南"
    actions:
      - "阅读 README.md 了解项目整体情况"
      - "阅读 CONTRIBUTING.md 了解贡献指南"
      - "阅读 docs/architecture.md 了解架构设计"
    enforcement: mandatory
  # ... 其他规则类似修改
```

**编辑 `rules/git.yaml`**:
```yaml
# 替换为目标的提交规范（例如：Conventional Commits）
  - id: "rule-008"
    name: "Git 提交信息格式规范"
    category: git
    priority: high
    enabled: true
    description: "使用 Conventional Commits 规范"
    actions:
      - "格式: type(scope): subject"
      - "type: feat/fix/docs/refactor/chore/style/test"
      - "例如: feat(auth): add OAuth2 login support"
    enforcement: mandatory
```

**删除不适用的规则文件**:
```powershell
# 如果目标项目不需要 safety.yaml 的某些规则
Remove-Item "D:\your-project\rules\safety.yaml"

# 或者清空文件内容，保留空壳
"" | Set-Content "D:\your-project\rules\safety.yaml" -Encoding UTF8
```

**添加目标项目特有规则**:
```yaml
# 在 rules/core.yaml 末尾追加
  - id: "rule-020"
    name: "代码审查前运行测试"
    category: core
    priority: high
    enabled: true
    description: "提交 PR 前必须运行完整测试套件"
    actions:
      - "执行 npm test 或 pytest"
      - "确保所有测试用例通过"
      - "修复失败的测试后再提交"
    enforcement: mandatory
```

#### Step 3: 重构目标的 AGENTS.md

将原 AGENTS.md 中的硬编码规则迁移到 YAML 文件，AGENTS.md 只保留路由器功能：

```markdown
# Agent Rules for Your Project

## ⚠️ 新会话开始前必读

**在开始任何工作之前，必须先运行规则引擎加载最新规则：**

```powershell
powershell scripts/rules-engine.ps1
```

**禁止在不了解项目背景的情况下直接开始工作！**

## 核心规则

详细规则请参见 rules/*.yaml 文件，通过规则引擎动态加载。
```

#### Step 4: 测试验证

```powershell
cd D:\your-project

# 测试 1: 查看完整规则
powershell scripts/rules-engine.ps1
# 预期: 显示定制后的规则清单

# 测试 2: 验证语法
powershell scripts/rules-engine.ps1 --check
# 预期: 所有文件 ✅ 通过

# 测试 3: 列表模式
powershell scripts/rules-engine.ps1 --list
# 预期: 表格显示所有规则及其状态
```

### 定制化建议

**根据团队规模调整规则数量**:
- 小团队 (1-3 人): 5-10 条规则，聚焦核心流程
- 中型团队 (4-10 人): 10-15 条规则，增加协作规范
- 大型团队 (10+ 人): 15-30 条规则，细化角色分工

**根据项目类型调整分类**:
- 前端项目: 可能需要增加 `ui.yaml`（组件规范、样式指南）
- 后端项目: 可能需要增加 `api.yaml`（接口设计、数据库规范）
- 库/框架项目: 可能需要增加 `compat.yaml`（兼容性、版本策略）

**定期 Review 建议**:
- **每季度一次**: 检查规则是否仍然适用，禁用过时规则
- **每次重大变更后**: 新增功能或流程变化时，及时补充规则
- **收到反馈后**: 如果 AI 反复违反某条规则，考虑强化措辞或提升优先级

---

## 高级主题与扩展方向

以下功能不在当前实现范围内，作为未来可能的扩展方向记录：

### 1. 规则版本控制与回滚
- 为每条规则增加 `version` 字段，记录规则的历史变更
- 支持 `rules-engine.ps1 --rollback rule-008` 回滚到上一版本
- 结合 Git history 实现规则的 diff 查看和恢复

### 2. 多环境规则 (dev/staging/prod)
- 创建 `rules/dev.yaml`、`rules/staging.yaml`、`rules/prod.yaml`
- 引擎通过环境变量 `$env:RULES_ENV` 加载不同规则集
- 开发环境允许更宽松的规则，生产环境强制严格规则

### 3. AI 合规评分与日志分析
- 引擎输出增加合规评分：`📊 合规度: 92% (13/14 rules followed)`
- 记录 AI 会话中的规则执行日志到 `logs/compliance-YYYYMMDD.log`
- 定期生成合规报告，识别高频违规规则

### 4. Web UI 可视化管理
- 开发基于 Web 的规则管理界面（React + Node.js）
- 支持在线编辑、实时预览、拖拽排序
- 提供规则启用/禁用的开关控件
- 集成规则模板库，一键导入常用规则集

### 5. 与 CI/CD 集成 (pre-commit hooks)
- 在 `pre-commit` hook 中调用 `rules-engine.ps1 --check`
- 确保 YAML 语法正确、ID 不重复、必要字段齐全
- 阻止不符合规范的规则提交到仓库
- GitHub Actions 中增加规则验证步骤

### 当前限制与已知问题

| 限制 | 影响 | 应对方案 |
|------|------|----------|
| 不支持条件触发 (conditions 字段) | 所有启用的规则始终生效 | 通过 `enabled` 字段手动控制 |
| 无规则依赖关系 | 无法表达"A 规则依赖 B 规则" | 在 description 中注明依赖关系 |
| 单语言支持 (中文) | 多语言团队可能需要英文版 | 创建 `rules-en/` 目录存放英文规则 |
| 无 GUI 管理工具 | 必须手动编辑 YAML 文件 | 使用 VS Code + YAML 插件获得语法高亮 |

---

## 附录: 完整命令速查表

```powershell
# === 基础操作 ===
powershell scripts/rules-engine.ps1                    # 查看完整规则清单 (Markdown)
powershell scripts/rules-engine.ps1 --check             # 验证 YAML 语法
powershell scripts/rules-engine.ps1 --list              # 查看规则状态表格
powershell scripts/rules-engine.ps1 --output "out.md"   # 导出到文件

# === 故障诊断 ===
ls rules/                                              # 列出规则文件
Get-Content rules/core.yaml -Encoding UTF8             # 查看文件内容
powershell scripts/rules-engine.ps1 --output debug.md  # 导出调试报告

# === 批量操作示例 ===
# 启用所有被禁用的规则
(Get-ChildItem rules\*.yaml) | ForEach-Object {
  (Get-Content $_.FullName -Raw) -replace 'enabled: false', 'enabled: true' | Set-Content $_.FullName -Encoding UTF8
}

# 统计规则总数
powershell scripts/rules-engine.ps1 --list | Select-String "总计:"
```

---

> **文档版本**: v1.0
> **最后更新**: 2026-04-19
> **适用范围**: Trae Mod Anchor 规则子系统 Phase 1-4
> **相关文件**: [rules-engine.ps1](../scripts/rules-engine.ps1) | [AGENTS.md](../AGENTS.md) | [rules/](../rules/)
