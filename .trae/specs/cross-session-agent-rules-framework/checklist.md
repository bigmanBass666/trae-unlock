# Checklist: 跨会话 Agent 规则遵守框架

## Phase 1: 本项目落地 (MVP) 验证

### Task 1: 规则定义 Schema 和 YAML 结构
- [ ] 规则 Schema 支持所有 5 种规则类型（RequiredReading, PreActionCheck, MandatoryBehavior, ProhibitedBehavior, DocumentationContract）
- [ ] YAML 结构清晰，包含 id、priority、condition、action、enforcement_level 等必要字段
- [ ] JSON Schema 文件能正确验证规则的格式和完整性
- [ ] `.trae/rules/project-rules.yaml` 模板文件包含示例规则和注释说明

### Task 2: 现有规则迁移到结构化格式
- [ ] AGENTS.md 中所有"必读文档"要求已提取为 RequiredReading 规则
- [ ] AGENTS.md 中所有"操作前检查"要求已提取为 PreActionCheck 规则
- [ ] AGENTS.md 中所有"强制行为"（如 commit 后 push）已提取为 MandatoryBehavior 规则
- [ ] AGENTS.md 中所有"禁止行为"（如禁止 merge）已提取为 ProhibitedBehavior 规则
- [ ] AGENTS.md 中所有"文档更新"要求已提取为 DocumentationContract 规则
- [ ] 迁移后的规则覆盖了原 AGENTS.md 的所有核心内容，无遗漏

### Task 3: Trae IDE 规则注入机制
- [ ] 升级后的 AGENTS.md 包含规则系统版本信息和结构化文件链接
- [ ] 新会话启动时能自动加载增强后的 AGENTS.md（通过 workspace rules）
- [ ] Plan Mode 下注入完整规则 + 架构文档索引
- [ ] Agent Mode 下注入核心行为规则 + 关键检查点
- [ ] Chat Mode 下注入简要规则摘要 + 文档链接
- [ ] 注入的规则内容准确，无截断或格式错误

### Task 4: 关键操作验证脚本
- [ ] `check-pre-reading.ps1` 能检测 Agent 是否已读取 README.md、source-architecture.md、progress.txt
- [ ] `check-git-workflow.ps1` 能检测是否有未 push 的 commit、是否尝试了 merge 操作
- [ ] `check-doc-sync.ps1` 能检测代码修改后是否更新了 progress.txt 和 source-architecture.md
- [ ] 所有验证脚本有清晰的输出格式（通过/失败/警告 + 原因说明）
- [ ] 验证脚本可在 PowerShell 环境中独立运行，无需额外依赖

### Task 5: 跨会话状态同步机制
- [ ] progress.txt 新增了时间戳、会话 ID、规则类型标签等元数据
- [ ] `generate-session-briefing.ps1` 能生成包含最近活动、当前状态、待办事项的摘要
- [ ] source-architecture.md 有"决策记录"章节模板，记录重要决策及其原因
- [ ] 新会话 Agent 通过脚本能快速了解项目状态（< 30 秒获取关键信息）
- [ ] 决策记录可通过 git log 或文档追溯完整讨论过程

### Task 6: 使用指南和最佳实践文档
- [ ] `docs/guides/agent-rules-framework.md` 包含完整的系统介绍、安装配置、使用方法
- [ ] 快速上手教程能让新项目在 10 分钟内完成规则系统初始化
- [ ] 常见问题文档覆盖了至少 5 个典型场景和解决方案
- [ ] README.md 已更新，包含规则系统的介绍章节和相关链接
- [ ] 所有文档的代码示例可实际运行，无过时或错误内容

## Phase 2: 框架抽象与可移植性验证

### Task 7: 通用规则框架核心组件
- [ ] 规则 Schema 支持自定义规则类型扩展（不仅限于 5 种预定义类型）
- [ ] 适配器接口定义清晰，包含 load_rules()、inject_rules()、validate_actions() 等核心方法
- [ ] 核心库代码包含规则加载器、解析器、验证器三个独立模块
- [ ] 框架代码有单元测试覆盖主要逻辑路径
- [ ] 框架设计遵循 SOLID 原则，易于扩展和维护

### Task 8: 多平台适配器实现
- [ ] Trae 适配器能正确读写 .trae/rules/ 和 AGENTS.md
- [ ] Cursor 适配器能正确读写 .cursorrules 文件
- [ ] VS Code + Copilot 适配器能正确读写 .github/copilot-instructions.md
- [ ] 通用适配器能正确处理 .ai-agents/ 目录约定
- [ ] 所有适配器通过统一的接口调用，切换平台只需更换适配器实例

### Task 9: 项目初始化脚手架工具
- [ ] `init-agent-rules.ps1` 支持交互式引导用户完成初始化
- [ ] 提供 3 种以上常见项目类型的规则模板（前端/后端/DevOps 等）
- [ ] 支持从现有 AGENTS.md 或类似文档导入规则（解析并转换为结构化格式）
- [ ] 生成的项目包含完整的规则文件、验证脚本和使用说明
- [ ] 初始化过程 < 5 分钟，生成的项目可直接使用

### Task 10: 移植指南和 API 文档
- [ ] 移植指南包含从 Trae Mod 到其他项目的完整步骤和注意事项
- [ ] Schema 文档详细说明每个字段的作用、类型、默认值、可选值
- [ ] 适配器接口文档包含方法签名、参数说明、返回值、异常处理
- [ ] 示例项目展示框架在至少 2 个不同类型项目中的应用
- [ ] 所有文档有目录索引和交叉引用，便于查阅

## 综合验收标准

### 功能完整性
- [ ] 本项目的所有原有规则都已成功迁移到新系统
- [ ] 新会话 Agent 能自动接收并遵守规则（通过测试验证）
- [ ] 关键操作有验证机制防止违规行为
- [ ] 跨会话知识传承有效，减少重复工作

### 可移植性
- [ ] 框架能在不修改核心代码的情况下适配新项目
- [ ] 至少在 Trae 和另一个平台上成功测试
- [ ] 初始化脚手架能在 5 分钟内为新项目生成可用规则系统
- [ ] 移植指南足够详细，独立开发者能按步骤完成迁移

### 文档质量
- [ ] 所有组件都有对应的使用文档或 API 文档
- [ ] 代码注释覆盖率 > 80%（核心逻辑部分）
- [ ] 示例代码可直接运行，无占位符或 TODO
- [ ] README 更新及时，反映最新功能状态

### 可维护性
- [ ] 规则定义采用声明式格式，非程序员也能理解和编辑
- [ ] 验证脚本有良好的错误提示，便于定位问题
- [ ] 版本管理策略清晰，支持规则集的升级和回滚
- [ ] 日志和监控机制完善，能追踪规则执行情况
