---
module: agents-navigation
description: AI 路由引擎 - 项目入口导航 + 高频规则提醒
read_priority: P0
read_when: 每次 AI 回复时自动加载
write_when: 项目重大变更时
format: navigation
single_source_of_truth_for:
  - 项目全局导航结构
  - AI 行为约束（高频规则）
last_reviewed: 2026-04-26
---

# Trae Unlock — AI 路由引擎

修改 Trae IDE 源码解锁 AI Agent 能力（命令确认/思考续接/循环绕过等）。
目标文件 ~10MB 压缩 JS → 347,244 行可读代码。

---

## 📚 三层导航

### Layer 1: 必读（每次会话）
| 文件 | 用途 |
|------|------|
| `shared/handoff.md` | 路由入口 + 全局状态 → **必须先读** |
| `shared/status.md` | 当前状态 + 补丁表 |

> 启动：① 读 handoff.md → ② 运行 `auto-heal.ps1 -DiagnoseOnly` → ③ 按需加载工具链

### Layer 2: 按需读
| 文件 | 触发场景 |
|------|----------|
| `patches/definitions.json` | 开发/维护补丁（唯一真实来源）|
| `shared/discoveries.md` | 定位代码/理解架构（⭐ 核心）|
| `docs/architecture/*.md` | 深入理解某领域 |

### Layer 3: 参考级
| 资源 | 内容 |
|------|------|
| `scripts/` | 工具链（unpack/ast-search/auto-heal 等）|
| `unpacked/beautified.js` | 美化后源码（347,244 行）|
| `shared/context.md` | 项目上下文 + 架构洞察 |
| `shared/_registry.md` | 资产注册表 + 脚本生命周期 |

---

## 🔍 我需要什么信息？

| 需求 | → 去哪里找 | Section |
|------|-----------|---------|
| 当前有哪些补丁？ | status.md | §已完成功能 |
| 补丁定义详情？ | definitions.json | （直接读取）|
| 源码中 XX 功能在哪？ | discoveries.md | （搜索关键词）|
| 我是 Explorer 怎么开始？ | handoff-explorer.md | §当前焦点 |
| 我是 Developer 该做什么？ | handoff-developer.md | §待办清单 |
| 架构知识？ | docs/architecture/ | source-architecture.md §索引 |
| 工具链怎么用？ | _registry.md | §脚本生命周期 |

---

## 🎯 我是哪种角色？

### 🔍 Explorer（探索源码）
→ 读 [handoff-explorer.md](shared/handoff-explorer.md) → 加载工具链 → 按 explorer-protocol 探索
→ **产出**: 写入 discoveries.md

### 🔧 Developer（开发/维护补丁）
→ 自检(auto-heal) → 读 [handoff-developer.md](shared/handoff-developer.md) → 改 definitions.json → apply+verify
→ **产出**: 更新 status.md

### 📋 Reviewer（代码审查）
→ 读 discoveries.md + handoff.md → 验证关键点
→ **产出**: 更新 handoff.md 审查结论

---

## ⚡ 绝对不能违反的规则

1. **用箭头函数** — `.catch(e=>{...})` 而非 `.catch(function(e){...})`
2. **服务层 > UI 层** — PlanItemStreamParser 不受 React 冻结影响
3. **先搜索再动手** — L0 IndexOf / L1 AST搜索 / L3 全量索引
4. **改 definitions.json 后必须 apply + verify**
5. **禁止编造时间戳** — 用 `$ts = Get-Date` 获取真实值
6. **引用而非复制** — 详细数据在权威文件，这里只放指针
7. **T3/T4 用完即删** — 不要归档到 .archive/
8. **写入前检查 single_source_of_truth_for** — 确认是该信息的权威归属地

---

## 📝 快速参考

**写入规则详情** → [_registry.md](shared/_registry.md)
**Auto-Cleanup 说明** → [架构文档](docs/architecture/)
**完整文件速查** → [status.md](shared/status.md) §重要文件
