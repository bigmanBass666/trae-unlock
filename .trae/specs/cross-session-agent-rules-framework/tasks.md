# Tasks: 跨会话 Agent 规则遵守框架

## Phase 1: 本项目落地 (MVP)

- [ ] Task 1: 设计规则定义 Schema 和 YAML 结构
  - [ ] SubTask 1.1: 定义规则类型枚举（RequiredReading, PreActionCheck, MandatoryBehavior, ProhibitedBehavior, DocumentationContract）
  - [ ] SubTask 1.2: 设计规则属性结构（id, priority, condition, action, enforcement_level 等）
  - [ ] SubTask 1.3: 创建 `.trae/rules/project-rules.yaml` 模板文件
  - [ ] SubTask 1.4: 编写 JSON Schema 验证文件用于校验规则格式

- [ ] Task 2: 将 Trae Mod 项目现有规则迁移到结构化格式
  - [ ] SubTask 2.1: 从 AGENTS.md 提取"必读文档"规则 → RequiredReading 类型
  - [ ] SubTask 2.2: 从 AGENTS.md 提取"操作前检查"规则 → PreActionCheck 类型
  - [ ] SubTask 2.3: 从 AGENTS.md 提取"强制行为"规则 → MandatoryBehavior 类型（如 commit 后必须 push）
  - [ ] SubTask 2.4: 从 AGENTS.md 提取"禁止行为"规则 → ProhibitedBehavior 类型（如禁止 merge）
  - [ ] SubTask 2.5: 从 AGENTS.md 提取"文档更新"规则 → DocumentationContract 类型

- [ ] Task 3: 实现 Trae IDE 规则注入机制
  - [ ] SubTask 3.1: 升级 AGENTS.md 为规则入口文档（保留核心规则 + 指向结构化文件）
  - [ ] SubTask 3.2: 创建 `.trae/rules/README.md` 说明规则系统使用方法
  - [ ] SubTask 3.3: 测试新会话是否能自动加载增强后的 AGENTS.md
  - [ ] SubTask 3.4: 验证不同模式（Plan/Agent/Chat）下的规则注入效果

- [ ] Task 4: 创建关键操作验证脚本
  - [ ] SubTask 4.1: 编写 `scripts/check-pre-reading.ps1` - 验证 Agent 是否已读取必要文档
  - [ ] SubTask 4.2: 编写 `scripts/check-git-workflow.ps1` - 验证 Git 操作是否符合规范（commit→push, 禁止 merge）
  - [ ] SubTask 4.3: 编写 `scripts/check-doc-sync.ps1` - 验证代码修改后是否同步更新了文档
  - [ ] SubTask 4.4: 创建验证脚本的调用示例和集成说明

- [ ] Task 5: 实现跨会话状态同步机制
  - [ ] SubTask 5.1: 增强 progress.txt 格式，增加结构化元数据（时间戳、会话 ID、规则类型标签）
  - [ ] SubTask 5.2: 创建 `scripts/generate-session-briefing.ps1` - 为新会话生成快速摘要
  - [ ] SubTask 5.3: 在 source-architecture.md 中增加"决策记录"章节模板
  - [ ] SubTask 5.4: 测试新会话能否通过脚本快速了解项目状态

- [ ] Task 6: 编写使用指南和最佳实践文档
  - [ ] SubTask 6.1: 创建 `docs/guides/agent-rules-framework.md` - 完整使用指南
  - [ ] SubTask 6.2: 编写"如何为新项目定制规则"的快速上手教程
  - [ ] SubTask 6.3: 记录常见问题和故障排查方法
  - [ ] SubTask 6.4: 更新 README.md 增加规则系统的介绍和链接

## Phase 2: 框架抽象与可移植性

- [ ] Task 7: 提取通用规则框架核心组件
  - [ ] SubTask 7.1: 将规则 Schema 抽象为通用格式（支持自定义规则类型扩展）
  - [ ] SubTask 7.2: 设计适配器接口（Adapter Interface）用于不同平台集成
  - [ ] SubTask 7.3: 创建框架的核心库代码（规则加载器、解析器、验证器）

- [ ] Task 8: 实现多平台适配器
  - [ ] SubTask 8.1: 实现 Trae 适配器（基于 .trae/rules 和 AGENTS.md）
  - [ ] SubTask 8.2: 实现 Cursor 适配器（基于 .cursorrules）
  - [ ] SubTask 8.3: 实现 VS Code + Copilot 适配器（基于 .github/copilot-instructions.md）
  - [ ] SubTask 8.4: 实现通用适配器（基于 .ai-agents/ 目录约定）

- [ ] Task 9: 开发项目初始化脚手架工具
  - [ ] SubTask 9.1: 编写 `scripts/init-agent-rules.ps1` - 交互式初始化新项目规则系统
  - [ ] SubTask 9.2: 提供常见项目类型的规则模板（前端/后端/DevOps/数据科学等）
  - [ ] SubTask 9.3: 支持从现有 AGENTS.md 或类似文档自动导入规则
  - [ ] SubTask 9.4: 生成项目特定的验证脚本和配置文件

- [ ] Task 10: 编写完整的移植指南和 API 文档
  - [ ] SubTask 10.1: 编写"从 Trae Mod 迁移到其他项目的完整指南"
  - [ ] SubTask 10.2: 文档化规则 Schema 的所有字段和选项
  - [ ] SubTask 10.3: 文档化适配器接口和扩展方法
  - [ ] SubTask 10.4: 创建示例项目展示框架在不同场景下的应用

# Task Dependencies

## Phase 1 内部依赖
- [Task 2] depends on [Task 1] — 需要先定义好 Schema 才能迁移现有规则
- [Task 3] depends on [Task 2] — 需要先有结构化规则才能实现注入
- [Task 4] depends on [Task 2] — 验证脚本需要基于具体规则编写
- [Task 5] depends on [Task 2] — 状态同步需要规则元数据
- [Task 6] depends on [Task 3, 4, 5] — 使用指南需要在实现完成后编写

## Phase 2 依赖
- [Task 7] depends on [Phase 1 完成] — 需要本项目作为参考实现
- [Task 8] depends on [Task 7] — 适配器需要基于核心框架
- [Task 9] depends on [Task 7, 8] — 脚手架需要框架和适配器支持
- [Task 10] depends on [Task 7, 8, 9] — 文档需要覆盖所有组件
