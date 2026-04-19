# 📋 Trae Mod 动态规则清单

> 由 rules-engine.ps1 自动生成 | 2026-04-20 05:01:53

---

## 🎯 核心规范 (Core)

### [🔴] rule-001: 新会话开始前必读 Anchor 共享知识库

**强制级别**: ⚠️ mandatory

在开始任何工作之前，必须先通过 Anchor 系统获取项目上下文和当前状态

**操作步骤**:
1. 读取 shared/_registry.md 了解所有可用模块
2. 按 P0 → P1 → P2 优先级读取所需模块
3. P0 必读: shared/context.md（项目核心上下文）
4. P1 推荐: shared/status.md（当前状态和待办）
5. 禁止在不了解项目背景的情况下直接开始修改代码

### [🔴] rule-002: 操作后写入 Anchor 共享模块

**强制级别**: ⚠️ mandatory

每次完成关键操作后，必须将信息持久化到 Anchor shared/ 对应模块

**操作步骤**:
1. 发现关键代码/架构 → 写入 shared/discoveries.md
2. 做出技术决策 → 写入 shared/decisions.md
3. 完成工作后 → 更新 shared/status.md
4. 项目重大变更 → 更新 shared/context.md

### [🔴] rule-003: 新发现必须写入 discoveries 模块

**强制级别**: ⚠️ mandatory

发现新东西时第一时间写入 shared/discoveries.md，避免后续 AI 重复探索

**操作步骤**:
1. 记录关键位置（文件名 + 偏移量 + 作用）
2. 记录模块之间的关系和调用链
3. 记录枚举值、设置 ID 等元数据
4. 记录排除的错误方向（哪些路走不通）

### [🔴] rule-004: 写入格式遵循注册表约定

**强制级别**: ⚠️ mandatory

向 shared/ 模块追加条目时，使用 shared/_registry.md 中定义的统一格式

**操作步骤**:
1. 格式: ### [YYYY-MM-DD HH:mm] 简短标题
2. 使用 **关键字**: 值 的结构化内容
3. 条目之间用 --- 分隔
4. 详见 shared/_registry.md 的'写入格式约定'章节

---

## ⚓ Anchor 系统维护 (Anchor)

### [🔴] rule-016: 不要在 shared/*.md 中硬编码系统品牌名

**强制级别**: ⚠️ mandatory

shared/*.md 只描述功能，不含系统品牌名。品牌名只在 AGENTS.md 和 _registry.md 中定义

**操作步骤**:
1. shared/*.md 的描述行只写功能，不写品牌名前缀
2. 例如写'每个新会话 AI 必读的项目核心信息'而非'Anchor 共享知识库 — 每个新会话 AI 必读的项目核心信息'
3. 如果需要引用系统名，使用'本系统'或指向 _registry.md

### [🔴] rule-017: 不要在 AGENTS.md 中硬编码文件列表

**强制级别**: ⚠️ mandatory

AGENTS.md 只做路由，指向 _registry.md。不硬编码 shared/ 文件列表

**操作步骤**:
1. AGENTS.md 中不列出具体的 shared/*.md 文件名（除 _registry.md 外）
2. 新增模块时只改 _registry.md + 创建文件，不改 AGENTS.md
3. 删除模块时只改 _registry.md + 删除文件，不改 AGENTS.md

### [🟡] rule-018: 不要修改历史文件中的系统名

**强制级别**: ⚠️ mandatory

历史文件（progress.txt, .trae/specs/）保持创建时的原始名称，改名等于篡改历史

**操作步骤**:
1. progress.txt 中的历史条目保持原名不改
2. .trae/specs/ 下的文件保持原名不改
3. 如需标注当前名称，可在条目末尾追加注释（现称 XXX）

### [🟡] rule-019: 系统改名只改 AGENTS.md 和 _registry.md

**强制级别**: ⚠️ mandatory

系统名集中定义在 AGENTS.md 和 _registry.md，改名只需修改这 2 个文件

**操作步骤**:
1. AGENTS.md: 修改'Anchor 声明'和'Anchor 共享知识库'（2 处）
2. _registry.md: 修改标题行和'系统名称:'行（2 处）
3. 不要修改 shared/*.md（已去品牌化）
4. 不要修改历史文件（保持原名）

---

## 🔄 工作流程 (Workflow)

### [🔴] rule-005: 标准工作流程八步循环

**强制级别**: ⚠️ mandatory

遵循标准化的 8 步工作循环，确保每次会话都基于最新状态且知识持续积累

**操作步骤**:
1. 步骤1：读 README.md 了解项目整体情况
2. 步骤2：读 docs/architecture/source-architecture.md 了解已有知识
3. 步骤3：读 progress.txt 了解当前进度
4. 步骤4：开始探索/修改
5. 步骤5：有新发现 → 立即写进对应文档
6. 步骤6：有代码修改 → 备份 + 记录到对应文档
7. 步骤7：git add . && git commit && git push
8. 步骤8：继续下一步（回到步骤4形成循环）

### [🟡] rule-006: 文档更新时机控制

**强制级别**: 💡 recommended

在工作流程中识别关键节点，确保在正确的时机进行文档更新和版本控制

**操作步骤**:
1. 探索阶段：每有新发现立即记录到 source-architecture.md 或 bypass-security.md
2. 修改阶段：代码修改后立即备份并记录修改内容、位置和原因
3. 测试阶段：记录测试结果（成功/失败）、测试方法和结论
4. 提交阶段：确保所有相关文档已更新后再执行 git commit

### [🟡] rule-007: 循环迭代原则

**强制级别**: 💡 recommended

工作流程是迭代循环的，每个周期都要基于上一周期的成果继续推进

**操作步骤**:
1. 每个工作周期完成后返回步骤4继续下一轮工作
2. 新周期开始前重新读取 progress.txt 确认当前状态
3. 利用 source-architecture.md 中已有的知识避免重复探索
4. 将本轮未完成的工作记录到 progress.txt 方便下个会话接续

---

## 📦 Git 规范 (Git)

### [🔴] rule-008: Git 提交信息格式规范

**强制级别**: ⚠️ mandatory

使用标准化的提交信息格式，确保提交历史清晰可追溯

**操作步骤**:
1. 使用 git add . 暂存所有更改
2. 使用 git commit -m \"[类型] 简要说明\" 格式提交
3. 提交类型包括：[发现] 找到 xxx 在 yyy:zzzz
4. [功能] 实现了 xxx
5. [修复] 解决了 xxx 问题
6. [文档] 更新了 xxx
7. [测试] 验证了 xxx

### [🔴] rule-009: 强制 Push 规则

**强制级别**: ⚠️ mandatory

每次 commit 后必须立即 push 到 GitHub，防止本地 .git 目录损坏导致历史丢失

**操作步骤**:
1. 每次执行 git commit 后立即执行 git push
2. 不要等到最后一起 push，必须逐次推送
3. 禁止在没有 push 的情况下继续其他操作（如 git merge）
4. 禁止使用 git add . && git commit 的链式操作而不包含 git push

### [🟡] rule-010: Git 操作风险控制

**强制级别**: 💡 recommended

避免可能导致本地 Git 仓库损坏的危险操作，保护版本历史完整性

**操作步骤**:
1. 避免使用 git merge 操作（可能损坏本地 .git 目录）
2. 如果必须合并，先确保已 push 所有本地提交到远程
3. 定期检查 .git 目录完整性
4. 重要修改完成后立即备份到远程仓库

### [🟡] rule-011: 正确 Git 操作流程示例

**强制级别**: 💡 recommended

展示正确的 Git 操作顺序和常见错误模式

**操作步骤**:
1. 正确流程：git add . → git commit -m \"...\" → git push（立即执行）
2. 错误流程1：git add . && git commit -m \"...\"（缺少 push）
3. 错误流程2：在未 push 的情况下执行 git merge ...（风险高）
4. 每次 commit-push 完成后再开始下一项工作

---

## 🛡️ 安全原则 (Safety)

### [🔴] rule-012: 代码修改安全原则

**强制级别**: ⚠️ mandatory

遵循安全最佳实践，确保代码修改不会引入安全风险或泄露敏感信息

**操作步骤**:
1. 始终遵循安全最佳实践进行代码开发
2. 绝不引入会泄露密钥或密钥的代码
3. 绝不将 secrets 或 keys 提交到仓库中
4. 在修改任何文件前先理解其上下文和现有模式

### [🔴] rule-013: Git 仓库完整性保护

**强制级别**: ⚠️ mandatory

保护本地 Git 仓库免受损坏，防止版本历史丢失

**操作步骤**:
1. 认识到本地 Git 仓库可能在 merge/rebase 操作中损坏（.git 目录消失）
2. 理解已有教训：merge 失败导致 .git 损坏 → 所有 commit 历史丢失
3. 通过强制 push 规则确保每次提交都立即备份到远程
4. 避免执行可能导致 .git 损坏的高风险操作（如 git merge）

### [🟡] rule-014: 知识共享与防重复工作

**强制级别**: 💡 recommended

通过及时文档更新避免团队重复探索，保护项目知识资产不丢失

**操作步骤**:
1. 遵循'不要让后面的 AI 重复你已经做过的探索工作'原则
2. 新发现第一时间写入共享文档，不要延迟或遗漏
3. 记录排除的错误方向，帮助后续 AI 避免走弯路
4. 保持 progress.txt 实时更新，方便快速了解项目状态

### [🟡] rule-015: 项目背景认知要求

**强制级别**: ⚠️ mandatory

在缺乏项目背景的情况下直接修改代码可能引入错误和风险

**操作步骤**:
1. 禁止在不了解项目背景的情况下直接开始修改代码
2. 修改前必须阅读核心文档（README.md、source-architecture.md、progress.txt）
3. 理解现有架构和代码约定后再进行修改
4. 遵循项目的框架选择、命名规范和编码风格

---

📊 **规则统计**: 共 **19** 条 | ✅ **19** 条启用 | ❌ **0** 条禁用 | 📂 **5** 个类别

