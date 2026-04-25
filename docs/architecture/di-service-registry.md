# DI 服务注册表文档

> Trae AI 聊天模块的依赖注入系统完整逆向工程

## 1. DI 容器概述

| 属性 | 值 |
|------|-----|
| 容器类 | `uj` |
| 偏移量 | ~6268469 |
| 模式 | 单例 `uj.getInstance()` |
| 注册服务数 | 51 |
| 注入点数 | 101 |
| 全局 Token (Symbol.for) | 30+ |
| 局部 Token (Symbol) | 20+ |

## 2. 核心 DI 装饰器

| 装饰器 | 用途 | 调用次数 | 搜索模板 |
|--------|------|---------|---------|
| `uX(token)` | 注入服务到类属性 | 101 | `uX(` |
| `uJ({identifier: token})` | 注册服务实现 | 51 | `uJ({identifier:` |
| `uB(token)` | React Hook useInject | — | `uB=(hX=` |
| `hX = () => uj.getInstance()` | 容器快捷方式 | 2 | `hX=` |

## 3. 完整服务注册表

### 全局 Token (Symbol.for — ⭐⭐⭐⭐⭐ 最稳定)

| DI Token | Symbol 字符串 | 偏移量 | 服务名 | 说明 |
|----------|-------------|--------|--------|------|
| `bY` | `"aiAgent.ILogService"` | ~6473533 | LogService | 日志服务 |
| `Ei` | `"aiAgent.ICredentialFacade"` | ~7015771 | CredentialFacade | 凭证服务 |
| `M0` | `"aiAgent.ISessionService"` | ~7150072 | SessionService (Ci) | 会话服务 |
| `Ma` | `"aiAgent.ITeaFacade"` | ~7135785 | TeaFacade (Ms) | 遥测服务 |

### 局部 Token (Symbol — ⭐⭐⭐⭐ 稳定)

| DI Token | Symbol 字符串 | 偏移量 | 服务名 | 说明 |
|----------|-------------|--------|--------|------|
| `xC` | `"ISessionStore"` | ~7087490 | SessionStore (xI) | 主聊天会话存储 |
| `I2` | `"IInlineSessionStore"` | ~7221939 | InlineSessionStore (I4) | 内联聊天存储 |
| `k1` | `"IModelStore"` | ~7186457 | ModelStore (k2) | 模型配置存储 |
| `IN` | `"ISessionRelationStoreInternal"` | ~7203850 | SessionRelationStore (ID) | 会话关系存储 |
| `BO` | `"ISessionServiceV2"` | ~7545196 | SessionServiceV2 | 会话服务 V2 |
| `I7` | (推断 IProjectStore) | ~7224039 | ProjectStore (Ti) | 项目存储 |
| `TG` | (推断 IAgentExtensionStore) | ~7248275 | AgentExtensionStore (TH) | Agent 扩展存储 |
| `Na` | (推断 ISkillStore) | ~7258315 | SkillStore (Ns) | 技能存储 |
| `Nc` | (推断 IEntitlementStore) | ~7259427 | EntitlementStore (Nu) | 权限存储 |

### SSE Parser Token (Symbol.for — ⭐⭐⭐⭐⭐)

| DI Token | Symbol 字符串 | Parser 类 |
|----------|-------------|-----------|
| — | `"IPlanItemStreamParser"` | PlanItemStreamParser |
| — | `"IErrorStreamParser"` | ErrorStreamParser (zU) |
| — | `"INotificationStreamParser"` | NotificationStreamParser |
| — | `"ITextMessageChatStreamParser"` | TextMessageChatStreamParser |
| — | `"IUserMessageStreamParser"` | UserMessageStreamParser (zJ) |
| — | `"ITokenUsageStreamParser"` | TokenUsageStreamParser (z2) |
| — | `"IContextTokenUsageStreamParser"` | ContextTokenUsageStreamParser (z3) |
| — | `"ISessionTitleMessageStreamParser"` | SessionTitleMessageStreamParser (z8) |

### SSE Parser Token (Symbol — ⭐⭐⭐⭐)

| DI Token | Symbol 字符串 | Parser 类 |
|----------|-------------|-----------|
| — | `"IMetadataParser"` | MetadataParser (DQ) |
| — | `"IUserMessageContextParser"` | UserMessageContextParser (DV) |
| — | `"IFeeUsageStreamParser"` | FeeUsageStreamParser (za) |
| — | `"IDoneStreamParser"` | DoneStreamParser (zW) |
| — | `"IQueueingStreamParser"` | QueueingStreamParser (zV) |
| — | `"ITaskAgentMessageParser"` | TaskAgentMessageParser |

## 4. 服务依赖图

```
uj (DI Container)
├── SessionService (M0) ←── SessionServiceV2 (BO)
│   ├── xC (SessionStore)
│   ├── bY (LogService)
│   └── Ma (TeaFacade)
├── SessionServiceV2 (BO)
│   ├── xC (SessionStore)
│   ├── M0 (SessionService)
│   └── bY (LogService)
├── PlanItemStreamParser
│   ├── _sessionServiceV2 (BO)
│   ├── _taskService
│   └── _storeService (xC)
├── ErrorStreamParser (zU)
│   ├── _sessionServiceV2 (BO)
│   └── _aiChatRequestErrorService
├── ChatStreamService (Bo)
│   ├── _sessionServiceV2 (BO)
│   ├── _teaService (Ma)
│   └── _storeService (xC)
├── F3/sendToAgentBackground
│   ├── bY (LogService)
│   ├── sessionService (M0)
│   ├── sessionServiceV2 (BO)
│   ├── commandService
│   └── docsetService
└── React Components
    ├── uB(xC) → SessionStore
    ├── uB(BR) → _sessionServiceV2
    └── N.useStore(selector) → Store slice
```

## 5. 关键纠正

| 旧认知 | 正确认知 | 影响 |
|--------|---------|------|
| `BR` = `_sessionServiceV2` DI Token | `BR` = `s(72103)` = Node.js `path` 模块 | auto-continue 补丁中 `resolve(BR)` 错误 |
| `FX` = DI 解构模式 | `FX` = `findTargetAgent` 辅助函数 | 无 DI 关联 |
| 正确的 sessionServiceV2 Token | `BO` = `Symbol("ISessionServiceV2")` 或 `M0` = `Symbol.for("aiAgent.ISessionService")` | 应 resolve `BO` 或 `M0` |

## 6. 搜索模板

| 目标 | 搜索关键词 | 稳定性 |
|------|-----------|--------|
| DI 容器 | `class uj` | ⭐⭐ |
| 注入装饰器 | `uX(` | ⭐⭐ |
| 注册装饰器 | `uJ({identifier:` | ⭐⭐ |
| React Hook | `uB=(hX=` | ⭐⭐ |
| LogService | `Symbol.for("aiAgent.ILogService")` | ⭐⭐⭐⭐⭐ |
| SessionService | `Symbol.for("aiAgent.ISessionService")` | ⭐⭐⭐⭐⭐ |
| SessionStore | `Symbol("ISessionStore")` | ⭐⭐⭐⭐ |
| SessionServiceV2 | `Symbol("ISessionServiceV2")` | ⭐⭐⭐⭐ |
| TeaFacade | `Symbol.for("ITeaFacade")` | ⭐⭐⭐⭐⭐ |
