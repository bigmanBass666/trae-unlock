# Checklist: 跨会话 Agent 动态规则遵守系统

## 基础设施验证

- [ ] `rules/` 目录已创建，包含 4 个核心 YAML 文件
  - [ ] rules/core.yaml 存在且语法正确
  - [ ] rules/workflow.yaml 存在且语法正确
  - [ ] rules/git.yaml 存在且语法正确
  - [ ] rules/safety.yaml 存在且语法正确

- [ ] 每个 YAML 文件符合 spec 定义的 schema
  - [ ] 包含必需字段：id, name, category, priority, enabled, description, actions, enforcement
  - [ ] priority 值只能是 high / medium / low
  - [ ] enforcement 值只能是 mandatory / recommended / optional
  - [ ] actions 是非空数组

- [ ] 所有原有 AGENTS.md 规则已完整迁移到对应的 YAML 文件
  - [ ] "新会话开始前必读" → core.yaml
  - [ ] "核心规则（文档更新）" → core.yaml
  - [ ] "Git 提交规则" → git.yaml
  - [ ] "安全建议" → safety.yaml

---

## 规则引擎功能验证

- [ ] `scripts/rules-engine.ps1` 脚本存在且可执行
  - [ ] 无外部依赖（纯 PowerShell 实现）
  - [ ] 执行时间 < 2 秒（100 条规则以内）

- [ ] 基础功能正常
  - [ ] 能正确解析所有 rules/*.yaml 文件
  - [ ] 只输出 enabled: true 的规则
  - [ ] 规则按 priority 排序（high → medium → low）
  - [ ] 输出为格式良好的 Markdown 文本

- [ ] Markdown 输出质量达标
  - [ ] 按类别分组显示（core / workflow / git / safety）
  - [ ] 每条规则有清晰的标题和编号
  - [ ] 操作步骤以有序列表呈现
  - [ ] 包含统计信息（总规则数、启用数、禁用数）

- [ ] CLI 参数功能正常
  - [ ] `--check` 参数：能检测 YAML 语法错误并返回非零退出码
  - [ ] `--list` 参数：输出规则状态摘要表（ID | 名称 | 启用状态 | 优先级）
  - [ ] `--output <path>` 参数：将结果写入指定文件而非 stdout

- [ ] 异常处理健壮性
  - [ ] rules/ 目录不存在时给出友好错误提示
  - [ ] 某 YAML 文件语法错误时跳过该文件并警告（不中断整体流程）
  - [ ] 所有规则都 disabled 时输出提示"当前无有效规则"

---

## AGENTS.md 路由器验证

- [ ] AGENTS.md 已重构为轻量级路由器
  - [ ] 总行数 < 50 行
  - [ ] 不包含任何具体的规则细节（如文档列表、提交格式等）
  - [ ] 只包含：强制性声明、规则引擎调用方式、刷新机制说明

- [ ] 强制性引导措辞足够强烈
  - [ ] 使用 ⚠️ 等视觉符号吸引注意
  - [ ] 明确说明"必须执行"而非"建议执行"
  - [ ] 提供完整的命令示例（可直接复制粘贴）

- [ ] 路由器机制有效性
  - [ ] 新会话 AI 读取 AGENTS.md 后知道要运行 `powershell scripts/rules-engine.ps1`
  - [ ] 规则引擎输出的 Markdown 能被 AI 正确理解和遵守
  - [ ] 修改 rules/ 文件后重新运行引擎能看到最新规则

---

## 文档完整性验证

- [ ] `docs/dynamic-rules-system.md` 使用指南已创建
  - [ ] 包含系统架构图（三层结构）
  - [ ] 包含"快速开始"教程（3 步内能跑通）
  - [ ] 包含 YAML schema 完整参考（字段说明 + 示例）
  - [ ] 包含"迁移到其他项目"检查清单（步骤清晰）

- [ ] README.md 已更新
  - [ ] 新增"动态规则系统"章节或在已有章节中提及
  - [ ] 说明与传统 AGENTS.md 方式的区别和优势

- [ ] progress.txt 已更新
  - [ ] 记录本次架构升级的关键决策和成果
  - [ ] 标注新增的文件和目录

---

## 可移植性验证

- [ ] 系统设计支持迁移到其他项目
  - [ ] 规则引擎脚本无 trae-unlock 硬编码依赖（规则路径可通过参数配置）
  - [ ] YAML schema 通用化（不依赖特定项目的概念）
  - [ ] 使用文档提供明确的迁移步骤

- [ ] 示例：模拟迁移到一个假设的新项目
  - [ ] 复制 rules/、scripts/ 目录到新项目
  - [ ] 修改 rules/*.yaml 中的规则内容为新项目的规则
  - [ ] 执行规则引擎确认能正常工作
  - [ ] 新项目的 AGENTS.md 能作为路由器正常工作

---

## 边界情况与安全性验证

- [ ] 规则引擎不会执行恶意代码
  - [ ] YAML 解析不使用 `Invoke-Expression` 或类似危险函数
  - [ ] 不引入外部依赖（减少供应链攻击风险）
  - [ ] 输入验证充分（防止注入攻击）

- [ ] 并发安全性
  - [ ] 多个 AI 会话同时运行规则引擎不会产生竞态条件
  - [ ] 规则文件正在被编辑时引擎能优雅处理（报错或等待）

- [ ] 向后兼容性
  - [ ] 如果用户暂时不想用新系统，能否快速回退到旧的静态 AGENTS.md？
  - [ ] （建议：git 保留旧版本，或提供 rollback 脚本选项）

---

## 最终验收标准

- [ ] **功能完整性**：所有 spec 中的 ADDED Requirements 都已实现
- [ ] **质量标准**：代码可读性好、注释充分、无明显 bug
- [ ] **文档齐全**：使用者能独立上手，无需口头传授
- [ ] **可移植性**：能在 30 分钟内迁移到一个全新的项目中使用
- [ ] **零回归**：原有的 AGENTS.md 功能（规则传达）未被削弱，只是实现方式更优
