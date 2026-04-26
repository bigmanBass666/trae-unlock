---
domain: architecture
sub_domain: store
focus: Zustand Store 状态管理系统——8 个核心 Store 实例、DI Token 映射、两种 currentSession 模式和状态更新机制
dependencies: [model-domain.md, commercial-permission-domain.md]
consumers: Developer, Reviewer
created: 2026-04-26
updated: 2026-04-26
format: reference
---

# Store 架构文档

> Zustand Store 状态管理系统的完整架构映射

> last_verified: 2026-04-26 | 兼容版本: Trae v3.3.x (10490354 chars)

## §1 概述

> 本文档记录了 Trae AI 聊天模块中所有 Zustand Store 的架构映射。包括 8 个核心 Store 的 DI Token、混淆名、偏移量，以及 SessionStore 和 InlineSessionStore 两种不同的 currentSession 管理模式。
>
> **为什么重要**: Store 是前端状态的唯一数据源（SSOT），理解 Store 架构是定位任何状态相关 bug 或开发新功能的基础。
> **在整体中的位置**: Store 位于 SSE 解析层（PlanItemStreamParser）和 React UI 层之间，通过 DI 容器注入到各服务中。

## 1. Store 实例

| Store | DI Token | 混淆名 | 偏移量 | 说明 |
|-------|----------|--------|--------|------|
| SessionStore | `xC` = Symbol("ISessionStore") | xI | ~7087490 | 主聊天会话存储 |
| InlineSessionStore | `I2` = Symbol("IInlineSessionStore") | I4 | ~7221939 | 内联聊天会话存储 |
| ModelStore | `k1` = Symbol("IModelStore") | k2 | ~7186457 | 模型配置存储 |
| SessionRelationStore | `IN` = Symbol("ISessionRelationStoreInternal") | ID | ~7203850 | 会话关系存储 |
| ProjectStore | `I7` | Ti | ~7224039 | 项目存储 |
| AgentExtensionStore | `TG` | TH | ~7248275 | Agent 扩展存储 |
| SkillStore | `Na` | Ns | ~7258315 | 技能存储 |
| EntitlementStore | `Nc` = Symbol("IEntitlementStore") | Nu | ~7259427 | 权限存储 |

## 2. 两种 currentSession 模式

**SessionStore (主聊天)**:
- `currentSession` 是**计算属性**: 从 `sessions[]` + `currentSessionId` 派生
- `updateMessage()` 操作 `sessions[]` 数组
- `updateLastMessage()` 操作 `sessions[]` 数组

**InlineSessionStore (内联聊天)**:
- `currentSession` 是**直接字段**
- `updateMessage()` 和 `updateLastMessage()` 都调用 `setCurrentSession({...i, messages:[...]})`

**影响**: 补丁目标不同，策略不同。

## 3. setCurrentSession 调用点

| 偏移量 | 上下文 | Store |
|--------|--------|-------|
| ~7087490 | Store 定义 | SessionStore |
| ~7221939 | Store 定义 | InlineSessionStore |
| ~7584046 | subscribe #8 回调 | SessionStore |
| ~7605848 | runningStatusMap subscribe | SessionStore |

## 4. 关键 subscribe 调用

| 偏移量 | 监听内容 | 用途 |
|--------|---------|------|
| ~7584046 | `currentSession.messages.length` + `currentSessionId` | 更新全局上下文 |
| ~7605848 | `runningStatusMap` | 解析 waitForResponseComplete promise |
| ~7588518 | subscribe #8 (已有) | 消息数量变化检测 |

## 5. 无 Immer

代码库使用**展开运算符**进行不可变更新，不使用 Immer 的 `produce()`。
- `setCurrentSession({...i, messages:[...]})` — 标准展开
- 这简化了补丁设计——不需要担心 draft proxy

## 6. Store-React 连接

```javascript
// uB(token) — React Hook 注入 Store
// 等价于: const store = useSyncExternalStore(subscribe, getSnapshot)
// 返回: store 实例，可调用 .getState() / .subscribe() / .setState()
```

## 7. confirm_info 流经 PlanItemStreamParser

```
SSE PlanItem 事件 → PlanItemStreamParser._handlePlanItem() (~7504035)
  → 检查 confirm_info.confirm_status
  → 调用 provideUserResponse() (自动确认补丁)
  → 更新 confirm_info.confirm_status = "confirmed"
  → storeService.updateMessage() → Store 更新 → React re-render
```

## 8. 搜索模板

| 目标 | 搜索关键词 | 稳定性 |
|------|-----------|--------|
| SessionStore | `Symbol("ISessionStore")` | ⭐⭐⭐⭐ |
| InlineSessionStore | `Symbol("IInlineSessionStore")` | ⭐⭐⭐⭐ |
| setCurrentSession | `setCurrentSession` | ⭐⭐⭐ |
| subscribe | `.subscribe(` | ⭐⭐⭐ |
| getState | `.getState()` | ⭐⭐⭐ |
| useStore | `N.useStore` | ⭐⭐ |

## 9. 盲区列表

- Store 的完整 state 结构（每个 Store 有哪些字段）
- Store 的 action 方法完整列表
- Store 之间的依赖关系（哪些 Store 引用了其他 Store）
- subscribe 的回调函数完整实现
- Zustand middleware 使用情况（是否有 persist/devtools 等）
