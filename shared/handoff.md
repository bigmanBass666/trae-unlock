---
module: handoff-router
description: 交接路由入口 — 指向 Explorer/Developer/Reviewer 交接单
read_priority: P0
read_when: 每次 AI 会话开始（第一件事）
write_when: Explorer 或 Developer 会话结束时
format: navigation
role: router
sync_with:
  - shared/status.md (全局状态)
  - shared/discoveries.md (源码发现)
last_reviewed: 2026-04-26
---

# 会话交接路由 (Handoff Router)

> ⚡ **使用说明**: Explorer 读 [handoff-explorer.md](./handoff-explorer.md), Developer 读 [handoff-developer.md](./handoff-developer.md). 本文件仅作路由入口。

> **拆分时间**: 2026-04-26 18:39 — 从单一 handoff.md 拆分为角色专属文件

---

## 📍 Explorer 最新摘要

**最新成果**: Grand Exploration & Documentation Overhaul 完成（2026-04-26 18:00）— DI 注册表 51→186 完整更新、Model/Docset 两域架构文档新建、9 个搜索模板修复、P0 盲区完全探明、discoveries 四维索引构建。Symbol.for→Symbol 迁移模式完整映射（4 已迁移 / 6+ 未迁移）。

**→ 详细内容**: [handoff-explorer.md](./handoff-explorer.md)

## 🔧 Developer 最新摘要

**最新成果**: v22 后台自动续接历史性突破（2026-04-26）— teaEventChatFail 注入点 + sendChatMessage 降级，5 次完整后台续接，90+ 分钟无人值守，100% 成功率，平均耗时 4 秒。当前 9 个活跃补丁全部正常运行。高优待办：v22 固化到 definitions.json、force-max-mode 补丁开发。

**→ 详细内容**: [handoff-developer.md](./handoff-developer.md)

---

## 📊 项目全局状态

> → [详见 status.md](shared/status.md) （唯一权威数据源）

## 🗺️ 文件导航

```
shared/
├── handoff.md              ← 你在这里（路由入口）
├── handoff-explorer.md     ← 探索家专属：源码发现/偏移量/DI映射/模板验证
├── handoff-developer.md    ← 开发者专属：补丁状态/测试结果/版本适配/待办
├── status.md               ← 当前状态总览（每次会话结束更新）
├── discoveries.md          ← 核心资产：源码发现+代码定位（四维索引）
└── context.md              ← 项目上下文+架构洞察
```

## 🔄 写入规则

| 角色 | 写入文件 | 触发时机 |
|------|---------|---------|
| Explorer Agent | `handoff-explorer.md` | 发现新代码位置/偏移量/DI token/修复模板 |
| Developer Agent | `handoff-developer.md` | 补丁状态变更/测试结果/版本适配/待办更新 |
| 任一角色 | `handoff.md`（本文件） | 仅更新上方摘要段落，保持精简 |
| 任一角色 | `status.md` | 每次会话结束时必须更新 |
