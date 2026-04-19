# Checklist: Anchor 命名集中化

## 集中化原则

- [x] 系统名 "Anchor" 只在 2 个文件中硬编码
  - [x] AGENTS.md 包含 "Anchor 声明"
  - [x] shared/_registry.md 包含 "Anchor 共享知识库" 和系统名称标注
  - [x] 其他 shared/*.md 不包含 "Anchor" 品牌名

---

## 去品牌化

- [x] shared/context.md 描述行不含系统品牌名
- [x] shared/status.md 描述行不含系统品牌名
- [x] shared/discoveries.md 描述行不含系统品牌名
- [x] shared/decisions.md 描述行不含系统品牌名
- [x] shared/context.md 目录树注释不含系统品牌名
- [x] shared/status.md 表格不含系统品牌名

---

## 历史文件完整性

- [x] .trae/specs/ 下文件未被改名
- [x] progress.txt 中的历史条目保持原名（已回退 2 处不当改名）

---

## 人类文档

- [x] README.md 使用 "Anchor 规则子系统"
- [x] docs/dynamic-rules-system.md 使用 "Anchor 规则子系统"

---

## 最终验收

- [x] **改名集中度**: 未来改名只需修改 AGENTS.md + _registry.md（共 4 处）
- [x] **去品牌化**: shared/*.md 功能描述不含系统品牌名
- [x] **历史完整性**: 历史文件保持创建时的原始名称
- [x] **零回归**: AI 读取 AGENTS.md → _registry.md → shared/*.md 的链路不受影响
