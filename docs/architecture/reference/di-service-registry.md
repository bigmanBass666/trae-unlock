---
domain: architecture
sub_domain: di-registry
module: architecture-reference
description: DI 服务注册表文档 — 依赖注入系统完整逆向工程（186 服务 / 817 注入点）
read_priority: P2
format: reference
focus: DI 容器、装饰器模式、服务注册表、Symbol 迁移状态
last_verified: 2026-04-26
---

# DI 服务注册表文档

> Trae AI 聊天模块的依赖注入系统完整逆向工程
> last_verified: 2026-04-26 | 兼容版本: Trae v3.3.x (10490721 chars)

## 1. DI 容器概述

| 属性 | 值 |
|------|-----|
| 容器类 | `uj` |
| 偏移量 | ~6268469 |
| 模式 | 单例 `uj.getInstance()` |
| 注册服务数 | 186 |
| 注入点数 | 817 |
| Symbol.for Token | 126 |
| Symbol Token | 55 |
| String Token | 1 |
| 自引用 Token | 4 |
| 唯一 Token 变量（注册） | 170 |
| 唯一 Token 变量（注入） | 127 |
| 已解析注册 | 182 / 186 (97.8%) |

## 2. 核心 DI 装饰器

| 装饰器 | 用途 | 调用次数 | 搜索模板 |
|--------|------|---------|---------|
| `uX(token)` | 注入服务到类属性 | 817 | `uX(` |
| `uJ({identifier: token})` | 注册服务实现 | 186 | `uJ({identifier:` |
| `uB(token)` | React Hook useInject | — | `uB=(hX=` |
| `hX = () => uj.getInstance()` | 容器快捷方式 | 2 | `hX=` |

### 注册模式分类

| 模式 | 数量 | 示例 | 稳定性 |
|------|------|------|--------|
| `uJ({identifier:XX})` + `XX=Symbol.for("...")` | 126 | `uJ({identifier:bY})` → `bY=Symbol.for("aiAgent.ILogService")` | ⭐⭐⭐⭐⭐ |
| `uJ({identifier:XX})` + `XX=Symbol("...")` | 55 | `uJ({identifier:xC})` → `xC=Symbol("ISessionStore")` | ⭐⭐⭐⭐ |
| `uJ({identifier:"..."})` 字符串字面量 | 1 | `uJ({identifier:"ITokenService"})` | ⭐⭐⭐ |
| `uJ({identifier:WK.XX})` 属性访问 | 1 | `uJ({identifier:WK.IDocsetService})` → `Symbol.for("ai.IDocsetService")` | ⭐⭐⭐⭐⭐ |
| `uJ({identifier:XX})` 自引用（XX=类名） | 4 | `uJ({identifier:Do})` → Do 类自身即 Token | ⭐⭐ |

## 3. 完整服务注册表（186 项）

### 3.1 Agent 域（54 项）

| # | Token Var | Token 类型 | Symbol 字符串 | 实现类 | 注入数 |
|---|-----------|-----------|--------------|--------|--------|
| 1 | kS | Symbol.for | aiAgent.IAiAgentClientManagerService | kM | 24 |
| 2 | Au | Symbol.for | aiAgent.IFileFacade | — | 23 |
| 3 | Cv | Symbol.for | aiAgent.II18nService | Hx | 22 |
| 4 | Ci | Symbol | aiAgent.ICredentialConnectorService | M3 | 21 |
| 5 | ED | Symbol.for | aiAgent.IEnvironmentFacade | EJ | 17 |
| 6 | Ei | Symbol.for | aiAgent.ICredentialFacade | E_ | 17 |
| 7 | kA | Symbol.for | aiAgent.IAiNativeModelService | — | 11 |
| 8 | Di | Symbol.for | aiAgent.IAiAgentNativeChatService | Um | 10 |
| 9 | Os | Symbol.for | aiAgent.IConfigurationConnectorService | Hl | 9 |
| 10 | Il | Symbol.for | aiAgent.ICommercialPermissionService | NT | 7 |
| 11 | M5 | Symbol.for | aiAgent.IAiClientManagerService | ku | 7 |
| 12 | D6 | Symbol | IAgentService | Uz | 7 |
| 13 | M0 | Symbol.for | aiAgent.ISessionService | Ht | 25 |
| 14 | Eh | Symbol.for | aiAgent.IStorageFacade | Ey | 25 |
| 15 | AM | Symbol.for | IUtilFacade | — | 10 |
| 16 | MY | Symbol.for | aiAgent.IConfigurationFacade | MQ | 4 |
| 17 | Fe | Symbol.for | aiAgent.IAiAgentIDEChatImageService | WP | 4 |
| 18 | UR | Symbol.for | aiAgent.IAiAgentNativeDSLAgentService | — | 3 |
| 19 | Mz | Symbol.for | aiAgent.IContextKeyFacade | MV | 3 |
| 20 | Dp | Symbol.for | aiAgent.IChatService | HD | 3 |
| 21 | Dr | Symbol.for | aiAgent.IChatSnapshotService | H4 | 3 |
| 22 | xU | Symbol.for | aiAgent.ICodeActionFacade | xK | 2 |
| 23 | Wm | Symbol.for | aiAgent.IAiNativeFastApplyBaseService | WS | 2 |
| 24 | jW | Symbol.for | aiAgent.ICKGService | j9 | 2 |
| 25 | Wh | Symbol.for | aiAgent.IAiNativeIDEApiService | Wv | 2 |
| 26 | WE | Symbol.for | aiAgent.IAiNativeFastApplyTodoListService | — | 2 |
| 27 | zO | Symbol.for | aiAgent.ITaskService | UN | 2 |
| 28 | x3 | Symbol.for | aiAgent.IFileIconFacade | Mt | 1 |
| 29 | Mc | Symbol.for | aiAgent.IFpsRecordFacade | Mw | 1 |
| 30 | xq | Symbol.for | aiAgent.IOpenerFacade | x0 | 1 |
| 31 | Uw | Symbol.for | aiAgent.IProjectApiService | UM | 1 |
| 32 | Uk | Symbol.for | aiAgent.ISnapshotApiService | UL | 1 |
| 33 | GP | Symbol.for | aiAgent.ICodeActionService | Hh | 1 |
| 34 | GB | Symbol.for | aiAgent.IViewsService | Ya | 1 |
| 35 | HB | Symbol.for | aiAgent.IUtilService | HH | 1 |
| 36 | Mb | Symbol.for | aiAgent.ISessionHistoryInfra | MC | 1 |
| 37 | j5 | Symbol.for | aiAgent.IAskQuestionFeatureService | ee5 | 1 |
| 38 | E$ | Symbol.for | aiAgent.IFastApplyFacade | Ad | 0 |
| 39 | Up | Symbol.for | aiAgent.IAiModuleManagerService | Ub | 0 |
| 40 | B7 | Symbol.for | aiAgent.IAiNativeIDEChatImageService | WO | 0 |
| 41 | Ww | Symbol.for | aiAgent.IAiNativeFastApplyPoolService | WM | 0 |
| 42 | eYV | Symbol.for | aiAgent.IAiCompletionService | — | 0 |
| 43 | Ho | Symbol.for | aiAgent.INativeUIService | Hu | 0 |
| 44 | Hp | Symbol.for | aiAgent.IOpenerService | Hw | 0 |
| 45 | Hv | Symbol.for | aiAgent.IThemeService | HA | 0 |
| 46 | H2 | Symbol.for | aiAgent.IHistoryService | Yr | 0 |
| 47 | B8 | Symbol.for | aiAgent.IPastChatExporter | Fa | 0 |
| 48 | Jf | Symbol.for | aiAgent.INetworkService | Jw | 0 |
| 49 | U_ | Symbol.for | aiAgent.IToolCallService | UA | 0 |
| 50 | J3 | Symbol.for | aiAgent.IChatSuperCompletionService | — | 0 |
| 51 | etr | Symbol.for | aiAgent.IForkChatService | etc | 0 |
| 52 | ee4 | Symbol.for | aiAgent.IAskUserQuestionDraftCacheService | ee7 | 0 |
| 53 | Mr | Symbol.for | aiAgent.ISlardarFacade | Ms | 4 |
| 54 | MR | Symbol.for | aiAgent.ISlardarFacade | MB | 4 |

> **注意**: Mr/MR、ks/kS、Ma/MA、Tm/TM、Dj/DJ、zf/zF、zp/zP、ka/kA、eto/etO 是同名 Symbol 的不同变量注册（重复注册），后注册的会覆盖先注册的。

### 3.2 Session 域（10 项）

| # | Token Var | Token 类型 | Symbol 字符串 | 实现类 | 注入数 |
|---|-----------|-----------|--------------|--------|--------|
| 1 | xC | Symbol | ISessionStore | xR | 13 |
| 2 | IN | Symbol | ISessionRelationStoreInternal | — | 12 |
| 3 | BR | Symbol | ISessionServiceV2 | BW | 4 |
| 4 | I2 | Symbol | IInlineSessionStore | I8 | 2 |
| 5 | DU | Symbol.for | IInlineSessionStoreService | DY | 2 |
| 6 | Ix | Symbol | ISessionRelationStorageService | ID | 1 |
| 7 | I$ | Symbol | IInlineChatPaneStore | I4 | 0 |
| 8 | G8 | Symbol.for | aiChat.IInlineChatSessionService | Hn | 0 |
| 9 | z9 | Symbol.for | ISessionTitleMessageStreamParser | Br | 0 |
| 10 | Mb | Symbol.for | aiAgent.ISessionHistoryInfra | MC | 1 |

### 3.3 Store 域（23 项）

| # | Token Var | Token 类型 | Symbol 字符串 | 实现类 | 注入数 |
|---|-----------|-----------|--------------|--------|--------|
| 1 | Tm | Symbol.for | ai.IDocsetStore | — | 21 |
| 2 | Nc | Symbol | IEntitlementStore | Nf | 9 |
| 3 | k1 | Symbol | IModelStore | Ii | 5 |
| 4 | I7 | Symbol | IProjectStore | Ta | 6 |
| 5 | IZ | Symbol | IConfigurationStore | IX | 4 |
| 6 | T5 | Symbol | IAgentStore | T9 | 4 |
| 7 | T8 | Symbol | ILintErrorAutoFixStore | Nn | 4 |
| 8 | TQ | Symbol | ITasksHubStore | T3 | 3 |
| 9 | Db | Symbol | IFastApplyStore | Dz | 3 |
| 10 | Ie | Symbol | ISoloModeManagerStore | — | 3 |
| 11 | k5 | Symbol.for | IModeStorageService | N1 | 3 |
| 12 | M$ | Symbol | ICredentialStore | M4 | 0 |
| 13 | Td | Symbol | IChatStore | Tm | 0 |
| 14 | TG | Symbol | IAgentExtensionStore | TV | 0 |
| 15 | Na | Symbol.for | ISkillStore | Nu | 1 |
| 16 | Ng | Symbol | aiChat.IGitReposStore | NS | 0 |
| 17 | Tz | Symbol | aiChat.ICustomRuleStore | TH | 1 |
| 18 | Nr | Symbol | aiChat.IRulesModeStore | Ns | 1 |
| 19 | Of | Symbol | aiChat.IMultiRulesStore | — | 1 |
| 20 | To | Symbol | IChatTurnImageMenuStore | Th | 1 |
| 21 | I6 | Symbol | IMarkdownContextMenuStore | Ti | 1 |
| 22 | JJ | Symbol | ICommercialActivityStore | J5 | 2 |
| 23 | egl | Symbol | ITaskSectionStore | — | 0 |

### 3.4 Stream/Parser 域（28 项）

| # | Token Var | Token 类型 | Symbol 字符串 | 实现类 | 注入数 |
|---|-----------|-----------|--------------|--------|--------|
| 1 | zf | Symbol.for | IErrorStreamParser | zb | 9 |
| 2 | Dj | Symbol.for | IUserMessageParser | DW | 9 |
| 3 | zN | Symbol.for | IChatStreamBizReporter | zj | 6 |
| 4 | zt | Symbol.for | IChatStreamEmitter | zo | 6 |
| 5 | zp | Symbol | IChatStreamFirstTokenReporter | zm | 7 |
| 6 | zC | Symbol.for | IChatStreamWaitingMessageReporter | zk | 4 |
| 7 | DK | Symbol | IMetadataParser | D0 | 4 |
| 8 | Ul | Symbol | IHistoryMessagesParser | Uh | 3 |
| 9 | D5 | Symbol | IPlanItemParser | D9 | 3 |
| 10 | zi | Symbol.for | IInlineChatStreamEmitter | za | 3 |
| 11 | DQ | Symbol | IUserMessageContextParser | D | 2 |
| 12 | j8 | Symbol.for | IChatStreamRequestFactory | zr | 2 |
| 13 | Un | Symbol | IAgentMessageParser | Uc | 1 |
| 14 | Bb | Symbol.for | ISideChatStreamService | BC | 1 |
| 15 | BA | Symbol.for | IInlineChatStreamService | BI | 1 |
| 16 | Bk | Symbol.for | IChatStreamContributionReporter | BP | 1 |
| 17 | Oi | Symbol.for | INotificationStreamParser | — | 1 |
| 18 | D2 | Symbol.for | IGeneralMessageParser | D3 | 1 |
| 19 | D8 | Symbol | IFeeUsageParser | Or | 1 |
| 20 | zl | Symbol | IFeeUsageStreamParser | zh | 0 |
| 21 | zv | Symbol | IMetadataStreamHandler | zA | 0 |
| 22 | zE | Symbol.for | ITextMessageChatStreamParser | zx | 0 |
| 23 | zH | Symbol | IDoneStreamParser | zq | 0 |
| 24 | zQ | Symbol | IQueueingStreamParser | zJ | 0 |
| 25 | zX | Symbol | ITimingEventStreamHandler | z2 | 0 |
| 26 | z1 | Symbol.for | IUserMessageStreamParser | z3 | 0 |
| 27 | z5 | Symbol.for | ITokenUsageStreamParser | z8 | 0 |
| 28 | z6 | Symbol.for | IContextTokenUsageStreamParser | z7 | 0 |

### 3.5 Credential 域（2 项）

| # | Token Var | Token 类型 | Symbol 字符串 | 实现类 | 注入数 |
|---|-----------|-----------|--------------|--------|--------|
| 1 | Ci | Symbol | aiAgent.ICredentialConnectorService | M3 | 21 |
| 2 | Ei | Symbol.for | aiAgent.ICredentialFacade | E_ | 17 |

### 3.6 Commercial 域（4 项）

| # | Token Var | Token 类型 | Symbol 字符串 | 实现类 | 注入数 |
|---|-----------|-----------|--------------|--------|--------|
| 1 | Il | Symbol.for | aiAgent.ICommercialPermissionService | NT | 7 |
| 2 | BU | Symbol.for | ICommercialApiService | BQ | 1 |
| 3 | kh | Symbol | ICommercialActivityService | J7 | 2 |
| 4 | JJ | Symbol | ICommercialActivityStore | J5 | 2 |

### 3.7 Log/Telemetry 域（3 项）

| # | Token Var | Token 类型 | Symbol 字符串 | 实现类 | 注入数 |
|---|-----------|-----------|--------------|--------|--------|
| 1 | bY | Symbol.for | aiAgent.ILogService | MX | 66 |
| 2 | Ma | Symbol.for | ITeaFacade | Mu | 10 |
| 3 | JI | Symbol.for | NotificationService | J0 | 1 |

### 3.8 File/Doc 域（7 项）

| # | Token Var | Token 类型 | Symbol 字符串 | 实现类 | 注入数 |
|---|-----------|-----------|--------------|--------|--------|
| 1 | Au | Symbol.for | aiAgent.IFileFacade | — | 23 |
| 2 | B$ | Symbol.for | IFileDiffService | B1 | 0 |
| 3 | B0 | Symbol.for | IFileDiffProvider | B9 | 0 |
| 4 | BZ | Symbol.for | IFileDiffTruncationService | BX | 1 |
| 5 | Wj | Symbol.for | ai.IDocsetCkgLocalApiService | Wq | 1 |
| 6 | WV | Symbol.for | ai.IDocsetOnlineApiService | — | 1 |
| 7 | eej | Symbol.for | IFileOpFeatureService | — | 0 |

### 3.9 UI/View 域（4 项）

| # | Token Var | Token 类型 | Symbol 字符串 | 实现类 | 注入数 |
|---|-----------|-----------|--------------|--------|--------|
| 1 | Me | Symbol.for | IViewsFacade | Mn | 3 |
| 2 | MT | Symbol.for | aiAgent.IThemeFacade | MP | 0 |
| 3 | xJ | Symbol.for | IEditorFacade | — | 2 |
| 4 | xL | Symbol.for | IWorkspaceFacade | xW | 8 |

### 3.10 Network/API 域（5 项）

| # | Token Var | Token 类型 | Symbol 字符串 | 实现类 | 注入数 |
|---|-----------|-----------|--------------|--------|--------|
| 1 | Ju | Symbol.for | IAWSASRClientService | Jg | 1 |
| 2 | Yq | Symbol.for | IHuoshanAsrClientService | Y | 1 |
| 3 | GI | Symbol.for | ITaskListApiService | GR | 1 |
| 4 | eeo | Symbol | ISandboxAPIService | eel | 1 |
| 5 | Jf | Symbol.for | aiAgent.INetworkService | Jw | 0 |

### 3.11 Config 域（5 项）

| # | Token Var | Token 类型 | Symbol 字符串 | 实现类 | 注入数 |
|---|-----------|-----------|--------------|--------|--------|
| 1 | eeC | Symbol | IAutoRunFeatureConfigService | — | 1 |
| 2 | eed | Symbol | IButtonConfigFactory | eem | 1 |
| 3 | eew | Symbol | IPopoverConfigFactory | eex | 1 |
| 4 | eef | Symbol | IWarningTipsConfigFactory | — | 1 |
| 5 | NE | Symbol.for | IModelTipConfigService | NR | 0 |

### 3.12 Command 域（1 项）

| # | Token Var | Token 类型 | Symbol 字符串 | 实现类 | 注入数 |
|---|-----------|-----------|--------------|--------|--------|
| 1 | eee | Symbol.for | IRunCommandFeatureService | eeF | 1 |

### 3.13 Knowledge 域（6 项）

| # | Token Var | Token 类型 | Symbol 字符串 | 实现类 | 注入数 |
|---|-----------|-----------|--------------|--------|--------|
| 1 | eth | Symbol.for | IKnowledgesPersistenceService | etw | 2 |
| 2 | etb | Symbol.for | IKnowledgesStagingService | etL | 2 |
| 3 | etj | Symbol.for | IKnowledgesSourceMaterialService | etG | 1 |
| 4 | etW | Symbol.for | IKnowledgesNotificationService | et | 1 |
| 5 | FC | Symbol.for | IKnowledgesTaskService | — | 1 |
| 6 | et8 | Symbol.for | IKnowledgesStatusBarService | — | 0 |

### 3.14 其他域（46 项）

| # | Token Var | Token 类型 | Symbol 字符串 | 实现类 | 注入数 |
|---|-----------|-----------|--------------|--------|--------|
| 1 | kd | Symbol.for | aiChat.IAIChatRequestErrorService | Do | 9 |
| 2 | G0 | Symbol.for | aiNg.IWorkspaceService | — | 6 |
| 3 | jO | Symbol.for | IPlanService | Ym | 4 |
| 4 | Bf | Symbol.for | IStuckDetectionService | Bw | 2 |
| 5 | GU | Symbol | ITasksHubService | G6 | 2 |
| 6 | Gh | Symbol.for | aiChat.IMemoryPaneService | GN | 2 |
| 7 | GS | Symbol.for | aiChat.IMemoryStore | Gk | 2 |
| 8 | kv | Symbol.for | IModelService | Nz | 2 |
| 9 | Gz | Symbol.for | aiNg.IAgentProjectService | H1 | 2 |
| 10 | TL | Symbol.for | aiChat.ICustomRulesService | GE | 1 |
| 11 | Bi | Symbol | IEventHandlerFactory | Bs | 1 |
| 12 | Ga | Symbol.for | ai.IWebCrawlerFacade | Gd | 1 |
| 13 | T$ | Symbol | ITeamAgentSyncService | Wn | 0 |
| 14 | TX | Symbol | ITeamAgentSubmittedService | Ws | 3 |
| 15 | TJ | Symbol | ITeamAgentFirstSubmittedService | Wd | 1 |
| 16 | HN | Symbol | IChatListService | HW | 0 |
| 17 | eRW | Symbol | aiChat.IDSLAgentStore | — | 0 |
| 18 | eto | Symbol.for | aiChat.IDSLAgentService | etp | 4 |
| 19 | etO | Symbol.for | aiChat.IDSLAgentService | etz | 0 |
| 20 | JS | Symbol.for | IAutoAcceptService | Jk | 0 |
| 21 | Jy | Symbol.for | IPrivacyModeService | JE | 0 |
| 22 | Yh | Symbol.for | IASRService | J_ | 0 |
| 23 | JC | Symbol | ILintErrorService | — | 0 |
| 24 | N0 | Symbol.for | IChatAgentGuideStorageService | N4 | 0 |
| 25 | N2 | Symbol.for | ISimpleBoolCacheService | N8 | 0 |
| 26 | N6 | Symbol.for | IModelReportService | De | 0 |
| 27 | kb | Symbol.for | IModelStorageService | NJ | 1 |
| 28 | ee3 | Symbol.for | IContributionService | etn | 0 |
| 29 | WK.IDocsetService | Symbol.for | ai.IDocsetService | Gd | 0 |
| 30 | "ITokenService" | String | ITokenService | GR | 0 |
| 31 | Do | 自引用 | (类名即Token) | Do | 12 |
| 32 | jP | 自引用 | (类名即Token) | jG | 7 |
| 33 | Hx | 自引用 | (类名即Token) | HT | 1 |
| 34 | HH | 自引用 | (类名即Token) | Hq | 0 |
| 35 | ks | Symbol.for | aiAgent.IAiAgentClientManagerService | — | 0 |
| 36 | ka | Symbol.for | aiAgent.IAiNativeModelService | Wf | 0 |
| 37 | MA | Symbol.for | ITeaFacade | MN | 0 |
| 38 | TM | Symbol.for | ai.IDocsetStore | TB | 0 |
| 39 | DJ | Symbol.for | IUserMessageParser | D4 | 0 |
| 40 | zF | Symbol.for | IErrorStreamParser | zY | 0 |
| 41 | zP | Symbol | IChatStreamFirstTokenReporter | zU | 0 |
| 42 | e | Symbol.for | react.fragment | — | 1 |
| 43 | Er | (未知) | (未知) | — | 2 |
| 44 | Gf | (未知) | (未知) | GW | 0 |
| 45 | Ie | Symbol | ISoloModeManagerStore | — | 3 |
| 46 | Bf | Symbol.for | IStuckDetectionService | Bw | 2 |

## 4. 注入热点分析（Top 30）

| 排名 | Token Var | Symbol 字符串 | 注入数 | 主要目标属性 |
|------|-----------|-------------|--------|------------|
| 1 | bY | aiAgent.ILogService | 66 | _agentAvatarMap, _configurationStore, _credentialConnectorService, _persistenceService, _sessionService, _storageFacade, _teaService, _viewsInfra |
| 2 | Eh | aiAgent.IStorageFacade | 25 | _credentialConnectorService, _logService, _nativeUIInfra, _sessionStore |
| 3 | M0 | aiAgent.ISessionService | 25 | _agentAvatarMap, _aiClientManagerService, _fpsRecord, _persistenceService, _promise, _viewsInfra |
| 4 | kS | aiAgent.IAiAgentClientManagerService | 24 | _agentAvatarMap, _aiClientManagerService, _chatStreamFirstTokenReporter, _stora, _teaFirstToken, _tokenUsageConfig |
| 5 | Au | aiAgent.IFileFacade | 23 | _agentAvatarMap, _persistenceService |
| 6 | Cv | aiAgent.II18nService | 22 | _agentAvatarMap, _credentialConnectorService, _startWaitingMessage |
| 7 | Ci | aiAgent.ICredentialConnectorService | 21 | _credentialConnectorService, _initFromCachePromise, _sessionStore, _storageFacade |
| 8 | Tm | ai.IDocsetStore | 21 | _fileIconFacade |
| 9 | Ei | aiAgent.ICredentialFacade | 17 | _credentialConnectorService, _promise |
| 10 | ED | aiAgent.IEnvironmentFacade | 17 | _storageFacade |
| 11 | xC | ISessionStore | 13 | _bootService |
| 12 | Do | (自引用) | 12 | _fpsRecord |
| 13 | IN | ISessionRelationStoreInternal | 12 | _beforeStreamingStart, _bootService, _credentialConnectorServic |
| 14 | kA | aiAgent.IAiNativeModelService | 11 | — |
| 15 | Ma | ITeaFacade | 10 | — |
| 16 | Di | aiAgent.IAiAgentNativeChatService | 10 | _viewsInfra |
| 17 | AM | IUtilFacade | 10 | _fpsRecord |
| 18 | Nc | IEntitlementStore | 9 | _credentialConnectorService |
| 19 | zf | IErrorStreamParser | 9 | _chatStreamFirstTokenReporter, _fileDiffState |
| 20 | Dj | IUserMessageParser | 9 | — |
| 21 | kd | aiChat.IAIChatRequestErrorService | 9 | _configurationStore, _fileDiffState, _logService |
| 22 | Os | aiAgent.IConfigurationConnectorService | 9 | — |
| 23 | xL | IWorkspaceFacade | 8 | _fpsRecord |
| 24 | zp | IChatStreamFirstTokenReporter | 7 | _chatStreamFirstTokenReporter |
| 25 | Il | aiAgent.ICommercialPermissionService | 7 | _beforeStreamingStart, _credentialConnectorService, _slardar |
| 26 | jP | (自引用) | 7 | — |
| 27 | M5 | aiAgent.IAiClientManagerService | 7 | — |
| 28 | D6 | IAgentService | 7 | _configurationStore |
| 29 | zN | IChatStreamBizReporter | 6 | _chatStreamFirstTokenReporter, _fileDiffState |
| 30 | zt | IChatStreamEmitter | 6 | — |

## 5. 服务依赖图

```
uj (DI Container) — 186 registrations, 817 injections
│
├── 🔥 高频注入 (>10次)
│   ├── bY (ILogService) ←── 66 services
│   ├── Eh (IStorageFacade) ←── 25 services
│   ├── M0 (ISessionService) ←── 25 services
│   ├── kS (IAiAgentClientManagerService) ←── 24 services
│   ├── Au (IFileFacade) ←── 23 services
│   ├── Cv (II18nService) ←── 22 services
│   ├── Ci (ICredentialConnectorService) ←── 21 services
│   ├── Tm (ai.IDocsetStore) ←── 21 services
│   ├── Ei (ICredentialFacade) ←── 17 services
│   ├── ED (IEnvironmentFacade) ←── 17 services
│   ├── xC (ISessionStore) ←── 13 services
│   ├── Do (自引用) ←── 12 services
│   └── IN (ISessionRelationStoreInternal) ←── 12 services
│
├── Session 服务链
│   ├── M0 (ISessionService) ←── SessionServiceV2 (BO)
│   │   ├── xC (SessionStore)
│   │   ├── bY (LogService)
│   │   └── Ma (TeaFacade)
│   ├── BR (ISessionServiceV2)
│   │   ├── xC (SessionStore)
│   │   └── IZ (ConfigurationStore)
│   └── xC (SessionStore)
│       └── Eh (StorageFacade)
│
├── Stream Parser 链
│   ├── zf (IErrorStreamParser)
│   │   ├── zp (ChatStreamFirstTokenReporter)
│   │   └── _fileDiffState
│   ├── Dj (IUserMessageParser)
│   ├── zN (IChatStreamBizReporter)
│   │   ├── zp (ChatStreamFirstTokenReporter)
│   │   └── _fileDiffState
│   ├── zt (IChatStreamEmitter)
│   └── DK (IMetadataParser)
│
├── Commercial 权限链
│   ├── Il (ICommercialPermissionService)
│   │   ├── Ci (CredentialConnectorService)
│   │   └── Mr/MR (SlardarFacade)
│   ├── BU (ICommercialApiService)
│   ├── Nc (IEntitlementStore)
│   │   └── Ci (CredentialConnectorService)
│   └── kh (ICommercialActivityService)
│
├── Agent 服务链
│   ├── Di (IAiAgentNativeChatService)
│   │   └── _viewsInfra
│   ├── D6 (IAgentService)
│   │   └── IZ (ConfigurationStore)
│   ├── kS (IAiAgentClientManagerService)
│   │   ├── _agentAvatarMap
│   │   ├── _aiClientManagerService
│   │   └── _chatStreamFirstTokenReporter
│   └── Os (IConfigurationConnectorService)
│
└── React Components
    ├── uB(xC) → SessionStore
    ├── uB(BR) → _sessionServiceV2
    └── N.useStore(selector) → Store slice
```

## 6. 关键纠正

| 旧认知 | 正确认知 | 影响 |
|--------|---------|------|
| `BR` = `_sessionServiceV2` DI Token | **`BR` = `Symbol("ISessionServiceV2")`** (beautified.js:249643) | v11/v22 补丁中 `resolve(BR)` 是正确的！ |
| `Di` 可用于 resumeChat | `Di` = `Symbol.for("aiAgent.IAiAgentNativeChatService")`，低层服务，参数直接发服务器 | v10/v21 用 `Di` 是错误的，应改用 `BR` |
| `FX` = DI 解构模式 | `FX` = `findTargetAgent` 辅助函数 | 无 DI 关联 |
| 正确的 sessionServiceV2 Token | `BO` = `Symbol("ISessionServiceV2")` 或 `M0` = `Symbol.for("aiAgent.ISessionService")` | 应 resolve `BO` 或 `M0` |
| J→K 重命名已发生 | J→K 重命名**未发生**，J 仍是当前变量名 | 现有补丁中引用 J 的代码仍然有效 |
| `ICommercialPermissionService` 有 `isFreeUser()` 方法 | `isFreeUser` 是在 React Hook `efi()` @8687513 中计算的，NS 类没有此方法 | 补丁应修改 NS 类方法，不是搜索 isFreeUser |
| ICommercialPermissionService 使用 Symbol.for 注册 | **ICommercialPermissionService 通过 `Symbol.for("aiAgent.ICommercialPermissionService")` 注册** (@7268550)，属于 aiAgent. 命名空间前缀家族 | 搜索字符串 `aiAgent.ICommercialPermissionService` 仍有效 |
| DI 注册数为 51 | **DI 注册数为 186** (`uJ({identifier:` 搜索确认) | 所有引用"51 个服务"的文档需更新 |
| DI 注入数为 101 | **DI 注入数为 817** (`uX(` 搜索确认) | 所有引用"101 个注入"的文档需更新 |
| 全局 Token 30+ | **Symbol.for Token 126 个** | 全局 Token 远超之前估计 |
| 局部 Token 20+ | **Symbol Token 55 个** | 局部 Token 远超之前估计 |

## 7. 搜索模板

| 目标 | 搜索关键词 | 稳定性 | 匹配数 |
|------|-----------|--------|--------|
| DI 容器 | `class uj` | ⭐⭐ | 1 |
| 注入装饰器 | `uX(` | ⭐⭐ | 817 |
| 注册装饰器 | `uJ({identifier:` | ⭐⭐ | 186 |
| React Hook | `uB=(hX=` | ⭐⭐ | 2 |
| LogService | `Symbol.for("aiAgent.ILogService")` | ⭐⭐⭐⭐⭐ | 1 |
| SessionService | `Symbol.for("aiAgent.ISessionService")` | ⭐⭐⭐⭐⭐ | 1 |
| SessionStore | `Symbol("ISessionStore")` | ⭐⭐⭐⭐ | 1 |
| SessionServiceV2 | `Symbol("ISessionServiceV2")` | ⭐⭐⭐⭐ | 1 |
| TeaFacade | `Symbol.for("ITeaFacade")` | ⭐⭐⭐⭐⭐ | 2 (Ma, MA) |
| CommercialPermission | `Symbol.for("aiAgent.ICommercialPermissionService")` | ⭐⭐⭐⭐⭐ | 1 |
| CredentialStore | `Symbol("ICredentialStore")` | ⭐⭐⭐⭐ | 1 |
| FastApplyFacade | `Symbol.for("aiAgent.IFastApplyFacade")` | ⭐⭐⭐⭐⭐ | 1 |
| FileDiffService | `Symbol.for("IFileDiffService")` | ⭐⭐⭐⭐⭐ | 1 |
| TokenService | `"ITokenService"` | ⭐⭐⭐ | 1 |
| DocsetService | `WK.IDocsetService` / `Symbol.for("ai.IDocsetService")` | ⭐⭐⭐⭐⭐ | 1 |

## 8. Symbol.for→Symbol 迁移状态

### 已迁移到 Symbol 的 Token（搜索时必须用 Symbol 而非 Symbol.for）

| Token 字符串 | 当前类型 | Token Var | 偏移量 |
|-------------|---------|-----------|--------|
| `ISessionStore` | Symbol | xC | 7102392 |
| `IEntitlementStore` | Symbol | Nc | 7265404 |
| `ISessionServiceV2` | Symbol | BR | 7559425 |
| `ICredentialStore` | Symbol | M$ | 7154461 |
| `IModelStore` | Symbol | k1 | 7194451 |
| `IAgentService` | Symbol | D6 | 7651341 |
| `IEventHandlerFactory` | Symbol | Bi | 7527307 |
| `IMetadataParser` | Symbol | DK | 7322592 |
| `IUserMessageContextParser` | Symbol | DQ | 7320597 |
| `IFeeUsageStreamParser` | Symbol | zl | 7491172 |
| `IDoneStreamParser` | Symbol | zH | 7520237 |
| `IQueueingStreamParser` | Symbol | zQ | 7521469 |
| `ICredentialConnectorService` | Symbol | Ci | 7157319 |
| `IConfigurationStore` | Symbol | IZ | 7225520 |
| `IInlineSessionStore` | Symbol | I2 | 7228299 |
| `IProjectStore` | Symbol | I7 | 7230092 |
| `IAgentStore` | Symbol | T5 | 7261403 |
| `IFastApplyStore` | Symbol | Db | 7311760 |
| `IPlanItemParser` | Symbol | D5 | 7327176 |
| `IFeeUsageParser` | Symbol | D8 | 7327621 |
| `IChatStreamFirstTokenReporter` | Symbol | zp | 7498512 |
| `IMetadataStreamHandler` | Symbol | zv | 7504721 |
| `ITimingEventStreamHandler` | Symbol | zX | 7522516 |
| `IInlineChatPaneStore` | Symbol | I$ | 7225749 |
| `ICustomRuleStore` | Symbol | Tz | 7253497 |
| `IAgentExtensionStore` | Symbol | TG | 7254532 |
| `ITasksHubStore` | Symbol | TQ | 7256727 |
| `ITeamAgentSyncService` | Symbol | T$ | 7256826 |
| `IRulesModeStore` | Symbol | Nr | 7263537 |
| `IGitReposStore` | Symbol | Ng | 7266895 |
| `ILintErrorAutoFixStore` | Symbol | T8 | 7261961 |
| `IChatStore` | Symbol | Td | 7233822 |
| `IChatTurnImageMenuStore` | Symbol | To | 7230951 |
| `IMarkdownContextMenuStore` | Symbol | I6 | 7229261 |
| `ISessionRelationStoreInternal` | Symbol | IN | 7222646 |
| `ISessionRelationStorageService` | Symbol | Ix | 7209045 |
| `ISoloModeManagerStore` | Symbol | Ie | 7195662 |
| `ICommercialActivityStore` | Symbol | JJ | 8049896 |
| `ICommercialActivityService` | Symbol | kh | 8059817 |
| `IChatListService` | Symbol | HN | 7856911 |
| `ILintErrorService` | Symbol | JC | 8042738 |
| `ITasksHubService` | Symbol | GU | 7774072 |
| `IAgentMessageParser` | Symbol | Un | 7621955 |
| `IHistoryMessagesParser` | Symbol | Ul | 7624823 |
| `ISandboxAPIService` | Symbol | eeo | 8067855 |
| `IButtonConfigFactory` | Symbol | eed | 8070046 |
| `IWarningTipsConfigFactory` | Symbol | eef | 8070756 |
| `IPopoverConfigFactory` | Symbol | eew | 8074258 |
| `IAutoRunFeatureConfigService` | Symbol | eeC | 8074962 |
| `IMultiRulesStore` | Symbol | Of | 7344819 |
| `ITaskSectionStore` | Symbol | egl | 8628834 |
| `aiChat.IDSLAgentStore` | Symbol | eRW | 9893009 |
| `IInlineChatPaneStore` | Symbol | I$ | 7225749 |
| `ITeamAgentSubmittedService` | Symbol | TX | 7670279 |
| `ITeamAgentFirstSubmittedService` | Symbol | TJ | 7671739 |

### 仍为 Symbol.for 的 Token（126 项，含 aiAgent./ai./aiChat./aiNg. 前缀）

| 前缀 | 数量 | 示例 |
|-------|------|------|
| `aiAgent.` | 42 | aiAgent.ILogService, aiAgent.ISessionService, aiAgent.ICommercialPermissionService |
| `ai.` | 5 | ai.IDocsetStore, ai.IDocsetService, ai.IDocsetCkgLocalApiService, ai.IDocsetOnlineApiService, ai.IWebCrawlerFacade |
| `aiChat.` | 5 | aiChat.IAIChatRequestErrorService, aiChat.ICustomRulesService, aiChat.IMemoryStore, aiChat.IMemoryPaneService, aiChat.IDSLAgentService |
| `aiNg.` | 2 | aiNg.IWorkspaceService, aiNg.IAgentProjectService |
| 无前缀 (I*) | 72 | ITeaFacade, IWorkspaceFacade, IErrorStreamParser, ICommercialApiService, etc. |

## 9. 重复注册（同名 Symbol，不同变量）

以下 Symbol 字符串被多个变量注册，后注册覆盖先注册：

| Symbol 字符串 | 变量1 (先) | 变量2 (后) | 偏移量1 | 偏移量2 |
|-------------|-----------|-----------|---------|---------|
| aiAgent.IAiAgentClientManagerService | ks | kS | 7160482 | 7182985 |
| aiAgent.ISlardarFacade | Mr | MR | 7140117 | 7150671 |
| ITeaFacade | Ma | MA | 7141007 | 7147151 |
| ai.IDocsetStore | Tm | TM | 7234317 | 7250026 |
| IUserMessageParser | Dj | DJ | 7318154 | 7323500 |
| IErrorStreamParser | zf | zF | 7502824 | 7518577 |
| IChatStreamFirstTokenReporter | zp | zP | 7498512 | 7515858 |
| aiAgent.IAiNativeModelService | kA | ka | 7184832 | 7638373 |
| aiChat.IDSLAgentService | eto | etO | 8113587 | 8132690 |

## 10. 自引用注册（4 项）

这些注册的 Token 不是 Symbol，而是直接使用类名作为 Token：

| Token/类名 | 偏移量 | 注入数 | 注入的目标属性 |
|-----------|--------|--------|-------------|
| Do | 7303131 | 12 | _fpsRecord |
| jP | 7475995 | 7 | — |
| Hx | 7841713 | 1 | — |
| HH | 7859447 | 0 | — |

> Do 同时也是 `kd` (aiChat.IAIChatRequestErrorService) 的实现类，形成双重身份。

## 11. 特殊注册模式

| 模式 | Token 表达式 | 实际值 | 实现类 | 偏移量 |
|------|------------|--------|--------|--------|
| 属性访问 | `WK.IDocsetService` | `Symbol.for("ai.IDocsetService")` (webpack模块36518导出) | Gd | 7749472 |
| 字符串字面量 | `"ITokenService"` | 字符串 "ITokenService" | GR | 7769113 |

## 12. eY0 模块入口对象 (@10476892)

| 方法 | 说明 |
|------|------|
| registerAdapter | 适配器注册 |
| getRegisteredAdapter | 获取已注册适配器 |
| bootstrapApplicationContainer | 应用容器引导 (含 25 个 VS Code 命令注册, @10477819) |
