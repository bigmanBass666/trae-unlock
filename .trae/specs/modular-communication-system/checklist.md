# Checklist: 动态模块化通信系统

## 注册表 (_registry.md)

- [ ] `shared/_registry.md` 已创建
  - [ ] 包含模块元数据表（5 个现有模块）
  - [ ] 包含集中写入格式约定
  - [ ] 包含模块管理说明（新增/删除/修改操作步骤）

- [ ] 注册表元数据表完整
  - [ ] 每行包含：优先级、模块名、描述、读取时机、写入时机
  - [ ] 优先级使用 P0/P1/P2 分级
  - [ ] 5 个模块全部注册（context/status/discoveries/decisions/rules）

---

## 模块自描述头部

- [ ] 每个 shared/*.md 文件有自描述元数据块
  - [ ] shared/context.md — module: context, read_priority: P0
  - [ ] shared/status.md — module: status, read_priority: P1
  - [ ] shared/discoveries.md — module: discoveries, read_priority: P2
  - [ ] shared/decisions.md — module: decisions, read_priority: P2
  - [ ] shared/rules.md — module: rules, read_priority: P2

- [ ] 元数据块格式正确
  - [ ] 使用 `---` 包裹
  - [ ] 包含 module/description/read_priority/read_when/write_when/format 字段

- [ ] 分散格式说明已替换
  - [ ] 各文件的"📝 写入格式"章节已替换为引用 _registry.md
  - [ ] 格式约定只存在于 _registry.md

---

## AGENTS.md 解耦

- [ ] AGENTS.md 不硬编码文件列表
  - [ ] 不包含 context.md/status.md/discoveries.md/decisions.md/rules.md
  - [ ] 只指向 shared/_registry.md

- [ ] AGENTS.md 保持精简
  - [ ] 总行数 < 60 行
  - [ ] 跨会话意识声明和元认知洞察保留不变

---

## 动态性验证

- [ ] 新增模块只需 2 步
  - [ ] 创建文件（含自描述头部）
  - [ ] 在 _registry.md 添加一行
  - [ ] AGENTS.md 无需修改

- [ ] 删除模块只需 2 步
  - [ ] 删除文件
  - [ ] 从 _registry.md 移除一行
  - [ ] AGENTS.md 无需修改

- [ ] 修改优先级只需改 1 处
  - [ ] 只改 _registry.md 中的优先级列
  - [ ] 不需要改其他任何文件

---

## 最终验收

- [ ] **零耦合**: AGENTS.md 不包含任何具体模块文件名（除 _registry.md）
- [ ] **单点维护**: 增删改模块只动 _registry.md + 模块文件本身
- [ ] **自描述**: AI 读取任意 shared/ 文件能从头部了解其用途和读写时机
- [ ] **集中格式**: 写入格式约定只存在于 _registry.md
- [ ] **零回归**: 原有跨会话通信功能不受影响
