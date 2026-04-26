# DI 服务注册表文档

> Trae AI 聊天模块的依赖注入系统完整逆向工程
> last_verified: 2026-04-26 | 兼容版本: Trae v3.3.x (10490415 chars)

## 1. DI 容器概述

| 属性 | 值 |
|------|-----|
| 容器类 | `uj` |
| 偏移量 | ~6268469 |
| 模式 | 单例 `uj.getInstance()` |
| 注册服务数 | 186 |
| 注入点数 | 816 |
| 全局 Token (Symbol.for / aiAgent.前缀) | 30+ |
| 局部 Token (Symbol) | 20+ |

## 2. 核心 DI 装饰器

| 装饰器 | 用途 | 调用次数 | 搜索模板 |
|--------|------|---------|---------|
| `uX(token)` | 注入服务到类属性 | 816 | `uX(` |
| `uJ({identifier: token})` | 注册服务实现 | 186 | `uJ({identifier:` |
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
| `Di` | `"aiAgent.IAiAgentNativeChatService"` | ~241083 | IAiAgentNativeChatService | 低层原生聊天服务，resumeChat 参数直接发服务器验证 |

### 局部 Token (Symbol — ⭐⭐⭐⭐ 稳定)

| DI Token | Symbol 字符串 | 偏移量 | 服务名 | 说明 |
|----------|-------------|--------|--------|------|
| `xC` | `"ISessionStore"` | ~7087490 | SessionStore (xI) | 主聊天会话存储 |
| `I2` | `"IInlineSessionStore"` | ~7221939 | InlineSessionStore (I4) | 内联聊天存储 |
| `k1` | `"IModelStore"` | ~7186457 | ModelStore (k2) | 模型配置存储 |
| `IN` | `"ISessionRelationStoreInternal"` | ~7203850 | SessionRelationStore (ID) | 会话关系存储 |
| `BO` | `"ISessionServiceV2"` | ~7545196 | SessionServiceV2 | 会话服务 V2 |
| `BR` | `"ISessionServiceV2"` | beautified.js:249643 | SessionServiceV2 | 同 ISessionServiceV2 Token，具有 `resumeChat` 和 `sendChatMessage` 方法 |
| `I7` | (推断 IProjectStore) | ~7224039 | ProjectStore (Ti) | 项目存储 |
| `TG` | (推断 IAgentExtensionStore) | ~7248275 | AgentExtensionStore (TH) | Agent 扩展存储 |
| `Na` | (推断 ISkillStore) | ~7258315 | SkillStore (Ns) | 技能存储 |
| `Nc` | (推断 IEntitlementStore) | ~7259427 | EntitlementStore (Nu) | 权限存储 |

### 商业权限域 Token (aiAgent.前缀 / Symbol — ⭐⭐⭐⭐)

| DI Token | Symbol 字符串 | 偏移量 | 服务名 | 说明 |
|----------|-------------|--------|--------|------|
| `Il` | `"aiAgent.ICommercialPermissionService"` (aiAgent.命名空间前缀, @7197027) | ~7267682 | NS | 商业权限判断服务 |
| `Nc` | `"IEntitlementStore"` (Symbol) | ~7259427 | Nu | 订阅/权益管理 Store |
| `MX` | `"ICredentialStore"` (Symbol) | ~7154491 | MX | 凭证/用户信息 Store |

> **⚠️ 关键纠正 (2026-04-26)**: ICommercialPermissionService 不使用 `Symbol.for()` 或 `Symbol()` 模式，而是通过 `aiAgent.ICommercialPermissionService` 命名空间前缀注册 (@7197027)。之前文档中标注为 `Symbol.for("aiAgent.ICommercialPermissionService")` 是不准确的——虽然搜索字符串 `aiAgent.ICommercialPermissionService` 仍然有效，但其注册机制属于 aiAgent. 命名空间前缀家族，与 `aiAgent.ILogService` 等同类。

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
| `BR` = `_sessionServiceV2` DI Token | **`BR` = `Symbol("ISessionServiceV2")`** (beautified.js:249643) | v11/v22 补丁中 `resolve(BR)` 是正确的！ |
| `Di` 可用于 resumeChat | `Di` = `Symbol.for("aiAgent.IAiAgentNativeChatService")`，低层服务，参数直接发服务器 | v10/v21 用 `Di` 是错误的，应改用 `BR` |
| `FX` = DI 解构模式 | `FX` = `findTargetAgent` 辅助函数 | 无 DI 关联 |
| 正确的 sessionServiceV2 Token | `BO` = `Symbol("ISessionServiceV2")` 或 `M0` = `Symbol.for("aiAgent.ISessionService")` | 应 resolve `BO` 或 `M0` |
| J→K 重命名已发生 | J→K 重命名**未发生**，J 仍是当前变量名 | 现有补丁中引用 J 的代码仍然有效 |
| `ICommercialPermissionService` 有 `isFreeUser()` 方法 | `isFreeUser` 是在 React Hook `efi()` @8687513 中计算的，NS 类没有此方法 | 补丁应修改 NS 类方法，不是搜索 isFreeUser |
| ICommercialPermissionService 使用 Symbol.for 注册 | **ICommercialPermissionService 通过 `aiAgent.ICommercialPermissionService` 命名空间前缀注册** (@7197027)，不是 `Symbol.for()` 或 `Symbol()` | 搜索字符串 `aiAgent.ICommercialPermissionService` 仍有效，但注册机制与 ILogService 等同属 aiAgent. 前缀家族 |
| DI 注册数为 51 | **DI 注册数为 186** (`uJ({identifier:` 搜索确认) | 所有引用"51 个服务"的文档需更新 |
| DI 注入数为 101 | **DI 注入数为 816** (`uX(` 搜索确认) | 所有引用"101 个注入"的文档需更新 |

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

## 7. Symbol.for→Symbol 迁移状态

### 已迁移到 Symbol 的 Token（搜索时必须用 Symbol 而非 Symbol.for）

| Token 字符串 | 当前类型 | 偏移量 |
|-------------|---------|--------|
| `IPlanItemStreamParser` | Symbol | 7511512 |
| `ISessionStore` | Symbol | 7092843 |
| `IEntitlementStore` | Symbol | 7264735 |
| `ISessionServiceV2` | Symbol | 7553132 |
| `ICredentialStore` | Symbol | 7154464 |
| `IModelStore` | Symbol | 7191686 |
| `IAgentService` | Symbol | 7327208 |
| `IEventHandlerFactory` | Symbol | 7526620 |
| `IMetadataParser` | Symbol | — |
| `IUserMessageContextParser` | Symbol | — |
| `IFeeUsageStreamParser` | Symbol | — |
| `IDoneStreamParser` | Symbol | — |
| `IQueueingStreamParser` | Symbol | — |

### 仍为 Symbol.for 的 Token

| Token 字符串 | 偏移量 |
|-------------|--------|
| `aiAgent.ILogService` | ~6473533 |
| `aiAgent.ICredentialFacade` | ~7015771 |
| `aiAgent.ISessionService` | ~7150072 |
| `aiAgent.ITeaFacade` | ~7135785 |
| `aiAgent.ICommercialPermissionService` | ~7197027 (aiAgent.命名空间前缀, 非Symbol.for) |
| `IErrorStreamParser` | 7516471 |
| `INotificationStreamParser` | 7328310 |
| `ITextMessageChatStreamParser` | 7505681 |
| `IUserMessageStreamParser` | — |
| `ITokenUsageStreamParser` | — |
| `IContextTokenUsageStreamParser` | — |
| `ISessionTitleMessageStreamParser` | — |

## 8. 新增服务与 Token (2026-04-26 审计更新)

### 新增关键服务

| 服务名 | 偏移量 | DI Token 类型 | 说明 |
|--------|--------|-------------|------|
| IStuckDetectionService | @7537021 | (待确认) | 卡住检测服务 |
| IAutoAcceptService | @8039940 | (待确认) | 自动接受服务 |
| ICommercialApiService | @7559975 | (待确认) | 商业 API 服务 |
| IPrivacyModeService | @8036543 | (待确认) | 隐私模式服务 |

### 新增 ai.* DI Token 家族

| DI Token 字符串 | 说明 |
|-----------------|------|
| `ai.IDocsetService` | 文档集服务 |
| `ai.IDocsetStore` | 文档集存储 |
| `ai.IDocsetCkgLocalApiService` | 文档集本地 API 服务 |
| `ai.IDocsetOnlineApiService` | 文档集在线 API 服务 |
| `ai.IWebCrawlerFacade` | 网页爬虫门面 |

### eY0 模块入口对象 (@10476892)

| 方法 | 说明 |
|------|------|
| registerAdapter | 适配器注册 |
| getRegisteredAdapter | 获取已注册适配器 |
| bootstrapApplicationContainer | 应用容器引导 (含 25 个 VS Code 命令注册, @10477819) |
