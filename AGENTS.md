# Trae Unlock — AI 协作指南

## 项目是什么

通过修改 Trae IDE 源码（`@byted-icube/ai-modules-chat/dist/index.js`），解锁 AI Agent 能力：
- 命令自动确认（Copy/Remove/Move/Rename 零弹窗）
- 思考上限自动续接（v8: L1展示+L2轮询双架构）
- 循环检测绕过、可恢复错误扩展等

目标文件是单行 ~10MB 压缩 JS，搜索必须用 PowerShell 子串搜索（Grep/ast-grep 均无效）。

---

## 启动必做（3 步）

1. **读 `shared/handoff.md`** — 上一个会话留下了什么（最优先）
2. **运行 `powershell scripts/auto-heal.ps1 -DiagnoseOnly`** — 补丁健康检查
3. **按需查 `shared/discoveries.md`** — 源码探索经验（索引在文末）

> 不自检 = 在破损基础上工作。不读 handoff = 重复已知调查。

---

## 关键文件速查

| 文件 | 用途 |
|------|------|
| `patches/definitions.json` | 14 个补丁定义（唯一真实来源） |
| `scripts/apply-patches.ps1` | 应用/验证补丁（主入口） |
| `scripts/auto-heal.ps1` | 自动诊断+修复 |
| `scripts/snapshot.ps1` | 备份+提交 |
| `shared/handoff.md` | 会话交接单（每次覆盖） |
| `shared/status.md` | 当前状态+补丁表 |
| `shared/discoveries.md` | 源码发现+代码定位（**核心资产**） |
| `shared/context.md` | 项目上下文+架构洞察 |
| `docs/architecture/` | 架构文档（源码解读） |

---

## 写入规则

- 发现关键代码位置 → 追加到 `shared/discoveries.md`
- 做出技术决策 → 追加到 `shared/decisions.md`
- 会话结束 → 更新 `shared/status.md` + 写 `shared/handoff.md`

格式：`### [YYYY-MM-DD HH:mm] 标题` 然后追加内容。**永远追加，不要重写整个文件。**

---

## 核心原则

1. **服务层 > UI 层** — PlanItemStreamParser（~7502574）不受 React 冻结影响，React 组件内补丁切窗口后失效（[L1 冻结原则](shared/discoveries.md)）
2. **必须用箭头函数** — `.catch(e=>{...})` 而非 `.catch(function(e){...})`，否则严格模式下 this=undefined 导致崩溃
3. **先搜索再动手** — 用 PowerShell 子串搜索定位代码：`$c=[IO.File]::ReadAllText($path); $c.IndexOf("keyword")`，不要猜偏移量
4. **改 definitions.json 后必须 apply + verify** — 自动备份到 backups/
