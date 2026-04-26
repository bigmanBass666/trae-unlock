# Trae Unlock — AI 协作指南

## 项目是什么

通过修改 Trae IDE 源码（`@byted-icube/ai-modules-chat/dist/index.js`），解锁 AI Agent 能力：
- 命令自动确认（Copy/Remove/Move/Rename 零弹窗）
- 思考上限自动续接（v7: L1展示+服务捕获）
- 循环检测绕过、可恢复错误扩展等

现已具备完整探索工具链（js-beautify 美化 → AST 结构分析 → 模块级搜索），详见 `docs/architecture/exploration-toolkit.md`。
目标文件仍是单行 ~10MB 压缩 JS，但可通过工具链转为 347,244 行可读代码。

---

## 🚀 快速路由（按你的任务选择路径）

### 🔍 我是来探索源码的（Explorer Agent）

1. 加载工具链：`. "scripts/unpack.ps1"; . "scripts/ast-search.ps1"; . "scripts/module-search.ps1"`
2. 检查工具：`Test-ToolAvailability`
3. 读协议：`docs/architecture/explorer-protocol.md`
4. **读交接：`shared/handoff-explorer.md`** ← Explorer 专用
5. 选工作流：按 `docs/architecture/exploration-toolkit.md` §4 选择模板

### 🔧 我是来开发/维护补丁的（Developer Agent）

1. 自检：`powershell scripts/auto-heal.ps1 -DiagnoseOnly`
2. **读交接：`shared/handoff-developer.md`** ← Developer 专用
3. 读状态：`shared/status.md`
4. 读定义：`patches/definitions.json`
5. 按需定位：`shared/discoveries.md`

### 📋 我是来做代码审查的（Reviewer Agent）

1. 读发现：`shared/discoveries.md`
2. 读路由：`shared/handoff.md` （跨角色摘要）
3. 读协议验证章节：`docs/architecture/explorer-protocol.md` §5-§6
4. 验证关键点：`Search-AST` 或 `Search-UnpackedModules`

---

## 启动必做（4 步）

0. **选择路由**（见上方 🚀 快速路由）
1. **读 `shared/handoff.md`** — 路由入口，决定读 explorer 还是 developer 交接单
2. **运行 `powershell scripts/auto-heal.ps1 -DiagnoseOnly`** — 补丁健康检查
3. **按需加载** — 探索者加载工具链脚本 + 查 `shared/discoveries.md`

> 不自检 = 在破损基础上工作。不读 handoff = 重复已知调查。不选路由 = 可能走错路径。

---

## 关键文件速查

### 核心资产

| 文件 | 用途 |
|------|------|
| `patches/definitions.json` | 补丁定义（唯一真实来源） |
| `scripts/apply-patches.ps1` | 应用/验证补丁（主入口） |
| `scripts/auto-heal.ps1` | 自动诊断+修复 |
| `scripts/snapshot.ps1` | 备份+提交 |

### 共享知识

| 文件 | 用途 |
|------|------|
| `shared/handoff.md` | **交接路由入口**（指向 explorer/developer） |
| `shared/handoff-explorer.md` | 探索家交接单（域测绘/源码发现/搜索模板） |
| `shared/handoff-developer.md` | 开发者交接单（补丁状态/版本适配/待处理问题） |
| `shared/status.md` | 当前状态+补丁表 |
| `shared/discoveries.md` | 源码发现+代码定位（**核心资产**） |
| `shared/context.md` | 项目上下文+架构洞察 |

### 🔧 探索工具链

| 文件/目录 | 用途 |
|----------|------|
| `scripts/unpack.ps1` | 解包+工具检测（Unpack-TraeIndex） |
| `scripts/ast-search.ps1` | AST 搜索+批量提取 |
| `scripts/module-search.ps1` | webpack 模块级搜索 |
| `unpacked/beautified.js` | 美化后源码（347,244行） |

### 📚 架构文档

| 文件 | 用途 |
|------|------|
| `docs/architecture/source-architecture.md` | 源码架构导航索引+关键位置速查 |
| `docs/architecture/di-service-registry.md` | DI 服务注册表（186 注册+817 注入） |
| `docs/architecture/sse-pipeline-topology.md` | SSE 管道拓扑（13 事件+15 Parser） |
| `docs/architecture/store-architecture.md` | Store 架构（8 个 Zustand Store） |
| `docs/architecture/command-confirm-system.md` | 命令确认系统（双层架构+BlockLevel） |
| `docs/architecture/limitation-map.md` | 限制点地图（错误码+Alert 渲染点） |
| `docs/architecture/module-boundaries.md` | 模块边界与依赖关系 |
| `docs/architecture/sse-stream-parser.md` | SSE 流解析系统 |
| `docs/architecture/commercial-permission-domain.md` | 商业权限域（服务链+用户身份枚举） |
| `docs/architecture/model-domain.md` | Model 域（computeSelectedModelAndMode + force-max-mode） |
| `docs/architecture/docset-domain.md` | Docset 域（5 ai.* Token + CKG API + Knowledges） |
| `docs/architecture/explorer-protocol.md` | 探险家协议（含工具决策树） |
| `docs/architecture/exploration-toolkit.md` | 工具箱使用指南 |

---

## 核心原则

1. **服务层 > UI 层** — PlanItemStreamParser（~7510931）不受 React 冻结影响，React 组件内补丁切窗口后失效（[L1 冻结原则](shared/discoveries.md)）
2. **必须用箭头函数** — `.catch(e=>{...})` 而非 `.catch(function(e){...})`，否则严格模式下 this=undefined 导致崩溃
3. **先搜索再动手，选对工具层级** — L0: IndexOf(<1s) / L1: AST搜索(20-90s) / L3: 全量索引(一次性)
4. **改 definitions.json 后必须 apply + verify** — 自动备份到 backups/
5. **🔍 探索者必须遵循协议** — 读 explorer-protocol.md，交叉验证，记录发现
6. **🔍 工具链分层使用** — 详见 exploration-toolkit.md §4.6-4.7

---

## 写入规则

### ⏰ 时间戳（强制）

> **禁止编造时间戳！每次写入前必须获取真实时间**

```powershell
$ts = (Get-Date -Format "yyyy-MM-dd HH:mm")
```

| ❌ 禁止 | ✅ 正确 |
|---------|---------|
| `[2026-04-26 06:00]` 硬编码 | `$ts` 变量（真实值） |
| 复制上一条的时间戳 | 每条独立 Get-Date |
| 多条目用相同分钟数 | 每条独立 Get-Date |
| "约 18:00" | 精确到分钟 |

### 内容写入

- 发现关键代码位置 → 追加到 `shared/discoveries.md`
- 做出技术决策 → 追加到 `shared/decisions.md`
- 格式：`### [$ts] 标题`（$ts 来自 Get-Date）
- **永远追加，不要重写整个文件**（仅 status.md 结构性表格和 handoff.md 路由除外）

### Handoff 写入规则

- **Explorer 会话结束** → 写 `shared/handoff-explorer.md` + 更新 `shared/handoff.md` 路由入口的 Explorer 摘要
- **Developer 会话结束** → 写 `shared/handoff-developer.md` + 更新 `shared/handoff.md` 路由入口的 Developer 摘要
- **Reviewer 会话结束** → 更新 `shared/handoff.md` 的审查结论部分
- `handoff.md` 是路由入口，需要覆盖式更新；`handoff-explorer.md` 和 `handoff-developer.md` 追加即可

### 脚本管理

- T1/T2 脚本保留在 `scripts/`
- T3 一次性产出归档到 `.archive/scripts/YYYYMMDD-/`
- T4 临时垃圾直接删除
- 详见 `shared/_registry.md` §脚本生命周期
