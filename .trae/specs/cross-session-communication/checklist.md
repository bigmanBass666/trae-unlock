# Checklist: 跨会话通信系统

## shared/ 共享知识库

- [ ] `shared/` 目录已创建，包含 5 个核心文件
  - [ ] shared/context.md 存在且内容非空（项目核心上下文）
  - [ ] shared/decisions.md 存在且内容非空（技术决策记录）
  - [ ] shared/discoveries.md 存在且内容非空（重要发现）
  - [ ] shared/status.md 存在且内容非空（当前状态和待办）
  - [ ] shared/rules.md 存在且内容非空（协作规则，由引擎生成）

- [ ] shared/ 文件内容来源于现有项目文档
  - [ ] context.md 包含项目简介、技术栈、目录结构等核心信息
  - [ ] decisions.md 包含至少 3 条已有技术决策
  - [ ] discoveries.md 包含至少 5 条关键代码位置/架构发现
  - [ ] status.md 包含当前进度和待办事项

- [ ] 每个文件有写入格式约定
  - [ ] 文件开头有格式说明
  - [ ] 有示例条目
  - [ ] AI 能根据格式正确追加新条目

---

## AGENTS.md 跨会话意识声明

- [ ] AGENTS.md 最开头包含跨会话意识声明
  - [ ] 声明"AGENTS.md 会被 AI 每次回复时读取"
  - [ ] 声明"用户会开启多个会话"
  - [ ] 声明"当前 AI 有责任持久化重要信息"

- [ ] AGENTS.md 包含关于自身特殊性的元认知洞察
  - [ ] 说明 AGENTS.md 的"每次必读"特性
  - [ ] 说明这是跨会话通信的天然入口
  - [ ] 提醒未来 AI 利用这个特性设计跨会话系统

- [ ] AGENTS.md 引导 AI 读取 shared/ 目录
  - [ ] 明确指出 shared/context.md 是必读文件
  - [ ] 推荐 shared/status.md 作为进度了解
  - [ ] 说明 shared/ 其他文件的用途

- [ ] AGENTS.md 引导 AI 写入 shared/ 目录
  - [ ] 说明何时写入（发现重要信息、做出决策、完成工作后）
  - [ ] 说明写哪里（discoveries/decisions/status）
  - [ ] 说明什么格式（时间戳 + 标题 + 结构化内容）

- [ ] AGENTS.md 保持精简
  - [ ] 总行数 < 60 行
  - [ ] 不包含具体的规则内容或项目细节
  - [ ] 只做路由/跳板，不存储具体内容

---

## 规则系统兼容性

- [ ] rules/ 目录和 rules-engine.ps1 正常工作
  - [ ] `powershell scripts/rules-engine.ps1` 输出正确
  - [ ] `powershell scripts/rules-engine.ps1 --check` 正常验证
  - [ ] `powershell scripts/rules-engine.ps1 --output shared/rules.md` 能更新文件

- [ ] shared/rules.md 内容与引擎输出一致
  - [ ] 包含所有 15 条启用的规则
  - [ ] 格式与直接运行引擎的输出相同

---

## 文档更新

- [ ] docs/dynamic-rules-system.md 已更新定位
  - [ ] 说明规则系统是跨会话通信系统的子模块
  - [ ] 引用 shared/ 目录

- [ ] progress.txt 已记录范式升级
  - [ ] 记录从"规则引擎"到"跨会话通信系统"的升级
  - [ ] 记录核心洞察

---

## 最终验收

- [ ] **跨会话意识**: 新会话 AI 读取 AGENTS.md 后意识到"用户会开启多个会话"
- [ ] **通信能力**: AI 知道如何从 shared/ 读取前序会话信息
- [ ] **写入能力**: AI 知道如何向 shared/ 写入当前会话的发现和决策
- [ ] **洞察传承**: AGENTS.md 中的元认知声明能让未来 AI 理解 AGENTS.md 的特殊性
- [ ] **零回归**: 原有规则系统功能不受影响
