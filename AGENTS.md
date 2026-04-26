# Trae Unlock — 项目导航

## 一句话说明

修改 Trae IDE 源码（`@byted-icube/ai-modules-chat/dist/index.js`），解锁 AI Agent 能力：
命令自动确认、思考上限续接、循环检测绕过等。
目标文件 ~10MB 压缩 JS，可通过工具链转为 347,244 行可读代码。

---

## 🚀 三层导航

### Layer 1: 必读（每次会话，5 分钟）

| 文件 | 用途 | 操作 |
|------|------|------|
| `shared/handoff.md` | 路由入口 + 全局状态 | **必须先读** |
| `shared/status.md` | 当前状态 + 补丁表 | 了解进度 |

> 启动步骤：① 读 handoff.md → ② 运行 `powershell scripts/auto-heal.ps1 -DiagnoseOnly` → ③ 按需加载工具链

### Layer 2: 按需读（开发/探索时）

| 文件 | 用途 | 触发场景 |
|------|------|----------|
| `patches/definitions.json` | 补丁定义（唯一真实来源） | 开发/维护补丁 |
| `shared/discoveries.md` | 源码发现 + 代码定位（⭐ 核心） | 定位代码/理解架构 |
| `docs/architecture/*.md` | 架构文档（12 个） | 深入理解某领域 |

**角色快速路径：**
- 🔍 **Explorer** → 加载工具链 → 读 `shared/handoff-explorer.md` → 按 [explorer-protocol.md](docs/architecture/explorer-protocol.md) 探索
- 🔧 **Developer** → 自检后读 `shared/handoff-developer.md` → 改 definitions.json → apply + verify
- 📋 **Reviewer** → 读 discoveries.md + handoff.md → 验证关键点

### Layer 3: 参考级（深度调查时）

| 资源 | 内容 |
|------|------|
| `scripts/` | 工具链（unpack/ast-search/module-search/snapshot/auto-heal/**auto-cleanup**） |
| `unpacked/beautified.js` | 美化后源码（347,244 行） |
| `shared/context.md` | 项目上下文 + 架构洞察 |
| `shared/_registry.md` | 资产注册表 + 脚本生命周期 |

---

## ⚡ 核心原则

1. **服务层 > UI 层** — PlanItemStreamParser 不受 React 冻结影响，React 组件内补丁切窗口后失效
2. **必须用箭头函数** — `.catch(e=>{...})` 而非 `.catch(function(e){...})`，否则严格模式 this=undefined 崩溃
3. **先搜索再动手** — L0: IndexOf(<1s) / L1: AST搜索(20-90s) / L3: 全量索引(一次性)
4. **改 definitions.json 后必须 apply + verify** — 自动备份到 backups/
5. **🧹 自动清理** — `auto-cleanup.ps1` 在每次 auto-heal 后自动运行，保持项目整洁（无需手动干预）

---

## 📁 最重要文件速查

| 文件 | 一句话定位 |
|------|-----------|
| `patches/definitions.json` | 补丁定义的唯一真实来源 |
| `scripts/apply-patches.ps1` | 应用/验证补丁的主入口 |
| `scripts/auto-heal.ps1` | 自动诊断 + 修复 |
| `shared/handoff.md` | 交接路由入口（指向 explorer/developer） |
| `shared/discoveries.md` | ⭐ 源码发现 + 代码定位（核心资产） |
| `shared/status.md` | 当前状态 + 待办事项 |

---

## 📝 写入规则速查

```powershell
$ts = (Get-Date -Format "yyyy-MM-dd HH:mm")  # 禁止编造时间戳！
```

- 发现代码位置 → **追加**到 `shared/discoveries.md`
- 技术决策 → **追加**到 `shared/decisions.md`
- 格式：`### [$ts] 标题`（永远追加，不重写整个文件）
- Explorer 会话结束 → 更新 `handoff-explorer.md` + `handoff.md` 入口
- Developer 会话结束 → 更新 `handoff-developer.md` + `handoff.md` 入口
- T1/T2 脚本保留 `scripts/`，**T3/T4 用完即删（auto-cleanup 自动清理）**
- Specs 完成后直接删除（Git history 有完整记录）

---

## 🧹 Auto-Cleanup 自动化（2026-04-26 新增）

> **告别手动大扫除！** 项目现在具备自我净化能力。

### 工作原理

```
auto-heal.ps1 运行完成
    ↓ (自动触发)
auto-cleanup.ps1 执行（~2 秒）
    ↓
Layer 1: Archive 配额 enforcement (< 20 文件)
Layer 2: Backups 滚动窗口 (5 clean + 10 normal)
Layer 3: 健康度监控 + 报告
    ↓
项目永远保持整洁 ✅
```

### 使用方式

```powershell
# 正常情况：无需手动调用（auto-heal 后自动运行）

# 手动运行：
powershell scripts/auto-cleanup.ps1

# 预览模式（只看不删）：
powershell scripts/auto-cleanup.ps1 -WhatIf
```
