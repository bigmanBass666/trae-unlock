---
module: context
description: 项目核心上下文
read_priority: P0
read_when: 每个新会话
write_when: 项目重大变更时
format: registry
---

# 项目核心上下文

> 每个新会话 AI 必读的项目核心信息

## 项目基本信息

**项目名称**: Trae Mod — Trae IDE 定制框架
**定位**: 通过源码修改解锁 Trae IDE 的更多能力，不是插件，是对源码的直接定制修改
**仓库**: https://github.com/bigmanBass666/trae-unlock

## 技术栈

**目标平台**: Trae IDE v3.3.x + Windows
**核心源码**: ~10MB 压缩 JS（当前版本 10490721 chars），已解包（无 app.asar，直接编辑即可生效）
**主进程**: Electron

## 核心源码位置

```
D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js
```

这是 AI 聊天系统的核心前端组件，包含对话渲染、Tool Call 管理、命令确认流程、PlanItem 解析流。

## 补丁系统简介

每个补丁包含：`find_original`（原始代码定位）、`replace_with`（替换代码）、`check_fingerprint`（短字符串验证）、`enabled`（是否启用）。

操作流程：`verify.ps1` 检测状态 → `apply-patches.ps1` 应用补丁（自动备份） → `rollback.ps1` 回滚。

> 📌 补丁详情与状态 → [status.md](./status.md) §已应用补丁列表
> 📌 关键位置速查 → [discoveries.md](./discoveries.md)
> 📌 目录结构 → AGENTS.md §关键文件速查

## 核心架构洞察

1. **服务层补丁才有效** — PlanItemStreamParser 是 SSE 流解析器，不依赖 React 渲染，切窗口不冻住
2. **L1 冻结原则** ⚠️ — 切换 AI 会话窗口后，后台组件的 hooks 全部暂停。需要实时响应的补丁必须放在 L2/L3。详见 discoveries.md [2026-04-22 16:00]
3. **双层确认系统** — 服务层(PlanItemStreamParser) + UI层(RunCommandCard) 完全独立，两层都需补丁
4. **ew.confirm() 不是执行** — 它是 telemetry/日志，真正执行函数是 eE(Confirmed)
5. **补丁安全** — 箭头函数防 this 丢失、不改变控制流、fingerprint 精确匹配
6. **Symbol.for→Symbol 迁移** — IPlanItemStreamParser、ISessionStore、IEntitlementStore 等已迁移到 Symbol，搜索时必须用正确类型
7. **商业权限域** — ICommercialPermissionService(NS)/IEntitlementStore(Nu)/ICredentialStore(MX) 是付费限制判断的核心服务链，bJ 枚举定义用户身份类型（Free=0,Pro=1,ProPlus=2,Ultra=3,Trial=4,Lite=5,Express=100）
8. **DI 系统规模** — 实际 186 个注册、817 个注入，远超文档记录
9. **Model 域补丁潜力 5/5** — computeSelectedModelAndMode @7215828，可开发 force-max-mode 补丁

## 架构文档索引

| 文档 | 内容 |
|------|------|
| docs/architecture/source-architecture.md | 源码架构导航索引+关键位置速查 |
| docs/architecture/di-service-registry.md | DI 服务注册表（186 注册+817 注入） |
| docs/architecture/sse-pipeline-topology.md | SSE 管道拓扑（13 事件+15 Parser） |
| docs/architecture/store-architecture.md | Store 架构（8 个 Zustand Store） |
| docs/architecture/command-confirm-system.md | 命令确认系统（双层架构+BlockLevel） |
| docs/architecture/limitation-map.md | 限制点地图（错误码+Alert 渲染点） |
| docs/architecture/module-boundaries.md | 模块边界与依赖关系 |
| docs/architecture/sse-stream-parser.md | SSE 流解析系统 |
| docs/architecture/commercial-permission-domain.md | 商业权限域（服务链+用户身份枚举） |
| docs/architecture/model-domain.md | Model 域（computeSelectedModelAndMode + force-max-mode） |
| docs/architecture/docset-domain.md | Docset 域（5 ai.* Token + CKG API + Knowledges） |
| docs/architecture/explorer-protocol.md | 探险家协议（含工具决策树） |
| docs/architecture/exploration-toolkit.md | 工具箱使用指南 |

### 新域文档

| 域 | 核心位置 | 补丁潜力 | 说明 |
|----|---------|---------|------|
| Model 域 | @7215828 | 5/5 | computeSelectedModelAndMode，6步决策链，force-max-mode 补丁 |
| Docset 域 | @7749472 | 4/5 | 5个ai.* DI Token，三层服务架构，ent_knowledge_base 门控 |
