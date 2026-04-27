# Trae Unlock — AI 路由引擎

修改 Trae IDE 源码解锁 AI Agent 能力（命令确认/思考续接/循环绕过等）。
目标文件 ~10MB 压缩 JS → 347,244 行可读代码。

---

## 六大支柱

| 支柱 | 一句话 | 核心动作 |
|------|--------|----------|
| Context | 上下文是护城河 | 渐进式索引 + 业务知识 Skill |
| Skills | 封装领域专长 | 评估驱动 + 五项标准 + 单一职责 |
| Spec | 不确定性前置 | 五阶段工作流 + 人工校准 |
| Rules | 分层控制行为 | L0-L3 + 四种激活模式 |
| MCP | 标准化交互 | ≤20 工具 + 输入输出规范 |
| Agent | 主动协作 | 专业角色 + 主动汇报 + 多 Agent 编排 |

---

## 📚 三层导航

### Layer 1: 必读（每次会话）
| 文件 | 用途 |
|------|------|
| `shared/handoff.md` | 路由入口 + 全局状态 → **必须先读** |
| `skills/_index.md` | 渐进式知识索引 → **按需加载详情** |
| `shared/status.md` | 当前状态 + 补丁表 |

> 启动：① 读 handoff.md → ② 读 skills/_index.md → ③ 运行 `auto-heal.ps1 -DiagnoseOnly` → ④ 按需加载工具链

### Layer 2: 按需读
| 文件 | 触发场景 |
|------|----------|
| `patches/definitions.json` | 开发/维护补丁（唯一真实来源）|
| `shared/discoveries.md` | 定位代码/理解架构（⭐ 核心）|
| `shared/failure-modes.md` | 遇到问题时（诊断前必读）|
| `skills/explore-source.md` | 探索源码时 |
| `skills/develop-patch.md` | 开发补丁时 |
| `skills/verify-patch.md` | 验证补丁时 |
| `skills/spec-rfc.md` | 需求工程时 |
| `docs/architecture/*.md` | 深入理解某领域 |

### Layer 3: 参考级
| 资源 | 内容 |
|------|------|
| `scripts/` | 工具链（unpack/ast-search/auto-heal 等）|
| `unpacked/beautified.js` | 美化后源码（347,244 行）|
| `shared/context.md` | 项目上下文 + 架构洞察 |
| `shared/_registry.md` | 资产注册表 + 脚本生命周期 |
| `shared/evolution-log.md` | 自我进化日志 |

---

## 🔍 我需要什么信息？

| 需求 | → 去哪里找 |
|------|-----------|
| 当前有哪些补丁？ | status.md §已完成功能 |
| 补丁定义详情？ | definitions.json |
| 源码中 XX 功能在哪？ | skills/_index.md → discoveries.md |
| 遇到问题怎么防？ | failure-modes.md |
| 已知的失败模式？ | failure-modes.md |
| 进化历史？ | evolution-log.md |

---

## 🎯 我是哪种角色？

### 🔍 Explorer（探索源码）
→ 读 [handoff-explorer.md](shared/handoff-explorer.md) → 加载 `skills/explore-source.md` → 按步骤探索
→ **专业角色**: Frontend Architect + Performance Expert
→ **闭环**: 写入 discoveries.md → 更新 handoff-explorer.md → 记录 evolution-log.md

### 🔧 Developer（开发/维护补丁）
→ 自检(auto-heal) → 读 [handoff-developer.md](shared/handoff-developer.md) → 加载 `skills/develop-patch.md`
→ **专业角色**: Backend Architect + DevOps Architect
→ **闭环**: 改 definitions.json → apply+verify → 更新 status.md → 记录 evolution-log.md

### 📋 Reviewer（代码审查）
→ 读 discoveries.md + handoff.md → 验证关键点
→ **专业角色**: Compliance Checker
→ **产出**: 更新 handoff.md 审查结论

---

## 🔄 闭环保障 (Loop Closure)

> **核心原则**: Agent 应形成自治闭环，所有机械性操作自动完成，无需人类介入。

| 角色 | 启动时 | 结束时 | 验证 |
|------|--------|--------|------|
| **Explorer** | 读 handoff + _index | 写 discoveries + handoff + evolution-log | 报告含同步状态 |
| **Developer** | 读 handoff + auto-heal | 改 definitions + apply+verify + evolution-log | 验证报告含两者结果 |

### 主动汇报规则（§7.3）

完成阶段性工作后**主动汇报**，不要等人类来问：
- 已完成的工作项
- 下一步计划
- 遇到的问题和风险
- 需要人类决策的事项

---

## ⚡ 绝对不能违反的规则

1. **用箭头函数** — `.catch(e=>{...})` 而非 `.catch(function(e){...})`
2. **服务层 > UI 层** — PlanItemStreamParser 不受 React 冻结影响
3. **先搜索再动手** — L0-005 诊断前检索 + L2-007 假设优先
4. **改 definitions.json 后必须 apply + verify**
5. **禁止编造时间戳** — 用 `$ts = Get-Date` 获取真实值
6. **引用而非复制** — 详细数据在权威文件，这里只放指针
7. **T3/T4 用完即删** — 不要归档到 .archive/
8. **写入前检查 single_source_of_truth_for** — 确认是该信息的权威归属地
9. **复盘不可跳过** — L0-004 任务完成后必须复盘 + 记录 evolution-log

---

## 📝 Rules 速查

| 层 | 文件 | 激活 | 示例 |
|----|------|------|------|
| L0 | rules/L0-always.yaml | Always | 会话必读、操作后写入、复盘 |
| L1 | rules/L1-techstack.yaml | File | 箭头函数、补丁格式、服务层优先 |
| L2 | rules/L2-domain.yaml | Smart | DI Token 迁移、SSE 错误链、商业权限 |
| L3 | rules/L3-sop.yaml | Manual | 补丁应用流程、版本适配、Git 提交 |

---

## 🔄 自我进化

```
执行任务 → 记录失败/成功 → 提炼规则 → 更新规则文件 → 下次执行时遵守新规则
```

| 机制 | 文件 | 何时写 |
|------|------|--------|
| 进化日志 | shared/evolution-log.md | 每次重要任务完成后 |
| 失败模式 | shared/failure-modes.md | 发现新的可预防错误时 |
| 规则变更 | rules/*.yaml | 反复犯同类错误时 |
