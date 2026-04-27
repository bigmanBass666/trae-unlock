# Discoveries — Trae AI 源码探索发现记录

> **文件用途**: 记录对 Trae IDE AI 模块源码 (unpacked/beautified.js, ~10.5MB) 的系统性探索发现。
> **目标读者**: Explorer / Developer Agent，用于定位代码、设计补丁、验证假设。
> **更新频率**: 每次探索会话结束后由 Agent 自动同步。
> **last_reviewed**: 2026-04-27
> **瘦身重构**: 2026-04-27 (8006→~3500 行, 删除过程性记录/归档v10实施/合并重复扫描)

## 渐进式索引（Layer 1）

> 启动时只加载本索引，需要详情时按 location 跳转。原则：代码优先、只补充缺失、做索引不做百科。

### Skills

| name | description | location |
|------|-------------|----------|
| explore-source | 在 ~10MB 压缩 JS 源码中进行系统性代码测绘 | skills/explore-source.md |
| develop-patch | 接收问题报告，在 definitions.json 中创建或更新补丁 | skills/develop-patch.md |
| verify-patch | 验证补丁正确应用且不引入新问题 | skills/verify-patch.md |
| spec-rfc | 需求工程：需求获取→分析→规格→技术设计→验证 | skills/spec-rfc.md |

### 业务上下文

| name | description | location |
|------|-------------|----------|
| tcc-config-driven-behavior | TCC 配置中心控制功能开关、降级和灰度策略 | skills/business-context/tcc-config.md |
| di-token-migration | Symbol.for→Symbol 迁移：Store/Parser 已迁移，Facade/Service 保留 | §Symbol.for→Symbol 迁移完整映射 |
| commercial-permission-chain | NS→Nu→MX 付费限制判断链，bJ/bK 枚举 | §[Commercial] 商业权限域 |
| error-code-system | kg 枚举(56个) + efg 可恢复(14个) + J/ee/X 标志 | §[Error] 错误处理系统 |
| sse-pipeline | EventHandlerFactory→15 Parser，SSE 事件分发 | §[SSE] 流管道 |

### 源码发现（11 域）

| name | description | location |
|------|-------------|----------|
| DI 依赖注入 | uj 容器 + 186 注册 + 817 注入 + 106 Token | §[DI] 依赖注入容器 |
| SSE 流管道 | EventHandlerFactory + 15 Parser + 13 事件 | §[SSE] 流管道 |
| Store 状态架构 | 8 Zustand Store + Aq 基类 + uB Hook | §[Store] Zustand 状态架构 |
| Error 错误处理 | kg 56 个 + efg 14 个 + 3 传播路径 | §[Error] 错误处理系统 |
| React UI 组件 | L1/L2/L3 三层 + 16 组件导出 + 冻结行为 | §[React] UI 组件层 |
| Event 事件总线 | TEA 遥测 + subscribe + DOM 事件 | §[Event] 事件总线与遥测 |
| IPC 进程间通信 | Server→Main→Renderer + 25 命令 | §[IPC] 进程间通信 |
| Setting 设置系统 | AI.toolcall.* + ConfirmMode 已移除 | §[Setting] 设置系统 |
| Sandbox 沙箱 | BlockLevel 6 值 + AutoRunMode 5 值 | §[Sandbox] 沙箱与命令执行 |
| MCP 工具调用 | ToolCallName 38 个 + 8 步生命周期 | §[MCP] 工具调用系统 |
| Commercial 商业权限 | NS 6 方法 + efi() Hook + bJ/bK | §[Commercial] 商业权限域 |
| Docset 文档集 | 5 ai.* Token + 三层服务架构 | §[Docset] 文档集域 |
| Model 模型选择 | computeSelectedModelAndMode + kG/kH | §[Model] 模型选择域 |

### 使用流程

```
1. 加载本索引 → 匹配需求到 description
2. 按 location 跳转到详情 → 生成有依据的方案
3. 引用验证 → 确保方案与已有发现一致
```

## 导航

### 核心资产（必读）
| Section | 行范围 | 内容 |
|---------|--------|------|
| 11 域完整映射 | L30-L970 | DI/SSE/Store/Error/React/Event/IPC/Setting/Sandbox/MCP/Commercial/Docset/Model |
| 四维索引体系 | L2950+ | 按域/偏移量/功能/置信度的完整索引 |

### 高价值探索
| Section | 内容 |
|---------|------|
| v2 探索远征 | 商业权限 + 补丁目标候选 + Phase 4/5 完整分析 |
| Deep Dive Blindspots | P0/P1/命令注册 + 3补丁预研 + computeSelectedModelAndMode 完整决策链 |
| Model 域深度探索 | 模型选择/模式切换完整架构 |
| Docset 域深度探索 | 文档集管理完整架构 |
| desktop-modules 盲区 | 确认无需打补丁 |

### 参考工具
| Section | 内容 |
|---------|------|
| 域交叉验证汇总 | 11域自动化验证结果 |
| P1 盲区扫描最终版 | UI下半+命令注册+首部+尾部完整扫描 |
| 版本差异探索 | Symbol.for→Symbol 迁移 + ConfirmMode 消失 + 变量重命名 |
| 搜索模板可用性 | 26 个模板验证结果 |

### 归档
> v10 实施关键发现、04-23 调试记录 → 已删除（重构时直接移除，未创建归档文件）

---

## 11 域完整映射

> 以下 11 个域构成 Trae AI 源码的完整架构地图。每个域包含：关键类/函数偏移量、数据流、DI Token、搜索模板。

### [DI] 依赖注入容器

**核心实体**: uj 类 (全局 DI 容器单例)

| 偏移量 | 实体 | 说明 |
|--------|------|------|
| @6268469 | uj class 定义 | DI 容器，bindings Map + singletons Map |
| @6273630 | uj class (详细) | getInstance/initialize/register/provide/resolve |
| @6275751 | uj.getInstance() | 单例访问点 |
| @6270579 | uB(token) Hook | React useInject，等价于 uj.getInstance().resolve |
| @853508 | createDecorator | DI 装饰器工厂，serviceRegistry 全局 Map |
| @1227889 | ServiceCollection + InstantiationService | VS Code 风格 DI |
| @2607740 | __instance__ Symbol 注入 | Inject 装饰器，延迟注入机制 |
| @10476892 | eY0 模块入口 | registerAdapter + bootstrapApplicationContainer |
| @10466462 | uj.getInstance().provide() | 仅 1 次调用 |

**DI Token 统计**: Symbol.for 54个 + Symbol("I*") 52个 = **106 个**
**注册点**: uJ({identifier: 186 处 | uX( 注入: 817 处

**关键 DI Token (按稳定性排序)**:

| Token | 形式 | 偏移量 | 域 |
|-------|------|--------|-----|
| bY = LogService | Symbol.for | @6473533 | [DI] |
| Ei = CredentialFacade | Symbol.for | @7015771 | [DI] |
| xC = SessionStore | Symbol | @7087490 | [Store] |
| Ma = TeaFacade | Symbol.for | @7135785 | [Event] |
| M0 = SessionService | Symbol.for | @7150072 | [SSE] |
| k1 = ModelStore | Symbol | @7186457 | [Store] |
| Il = CommercialPermissionService | Symbol.for("aiAgent.") | @7259427 | [Commercial] |
| BO = SessionServiceV2 | Symbol | @7545196 | [SSE] |

**31 个 I*Service DI Token 完整映射**:

| Token | 偏移量 | 域 |
|-------|--------|-----|
| IModelService | @7182322 | [Store] |
| IModelStorageService | @7182353 | [Store] |
| IModeStorageService | @7194537 | [Store] |
| IModelTipConfigService | @7268582 | [Setting] |
| IChatAgentGuideStorageService | @7296236 | [Store] |
| ISimpleBoolCacheService | @7297005 | [Store] |
| IModelReportService | @7298383 | [Event] |
| IInlineSessionStoreService | @7318186 | [Store] |
| IPlanService | @7456691 | [SSE] |
| IStuckDetectionService | @7537021 | [Error] |
| ISideChatStreamService | @7541121 | [SSE] |
| IInlineChatStreamService | @7548009 | [SSE] |
| ICommercialApiService | @7559975 | [Commercial] |
| IFileDiffTruncationService | @7562542 | [Sandbox] |
| IFileDiffService | @7565469 | [Sandbox] |
| IKnowledgesTaskService | @7589570 | [Docset] |
| ITaskListApiService | @7766628 | [IPC] |
| IASRService | @7892948 | [IPC] |
| IHuoshanAsrClientService | @7903529 | [IPC] |
| IAWSASRClientService | @8027658 | [IPC] |
| IPrivacyModeService | @8036543 | [Setting] |
| IAutoAcceptService | @8039940 | [Sandbox] |
| IRunCommandFeatureService | @8063616 | [Sandbox] |
| IFileOpFeatureService | @8086208 | [Sandbox] |
| IContributionService | @8095684 | [Setting] |
| IKnowledgesPersistenceService | @8113678 | [Docset] |
| IKnowledgesStagingService | @8122442 | [Docset] |
| IKnowledgesFeatureService | @8130079 | [Docset] |
| IKnowledgesSourceMaterialService | @8132725 | [Docset] |
| IKnowledgesNotificationService | @8139976 | [Docset] |
| IKnowledgesStatusBarService | @8186683 | [Docset] |

**ai.* DI Token 家族 (5个)**:
| Token | 偏移量 |
|-------|--------|
| ai.IDocsetService | @3546309 |
| ai.IDocsetStore | @7244780 |
| ai.IDocsetCkgLocalApiService | @7715114 |
| ai.IDocsetOnlineApiService | @7720270 |
| ai.IWebCrawlerFacade | @7725207 |

**搜索模板**:
| 目标 | 关键词 | 稳定性 |
|------|--------|--------|
| DI 容器 | `uj.getInstance()` | ⭐⭐⭐⭐⭐ |
| DI 注册 | `uJ({identifier:` | ⭐⭐⭐⭐⭐ |
| DI 注入 | `uX(` | ⭐⭐⭐⭐⭐ |
| Symbol.for token | `Symbol.for("` | ⭐⭐⭐⭐ |
| Symbol token | `Symbol("I` | ⭐⭐⭐⭐ |

---

### [SSE] 流管道 (Server-Sent Events)

**核心实体**: EventHandlerFactory (Bt) → 15 个 Parser 类

| 偏移量 | 实体 | 说明 |
|--------|------|------|
| @7300000 | EventHandlerFactory Bt | 中央调度器，事件→Parser 分发 |
| @7314000 | MetadataParser DQ + UserMessageContextParser DV | 元数据解析 |
| @7318521 | DG.parse() | 服务端响应解析器 |
| @7322410 | NotificationStreamParser | 通知流 |
| @7323241 | data-source-auto-confirm 补丁位置 | ⚠️ 补丁注入点 |
| @7482422 | FeeUsageStreamParser za | 用量费用流 |
| @7497479 | TextMessageChatStreamParser | 文本消息 |
| @7502500 | PlanItemStreamParser._handlePlanItem() | ⚠️ 自动确认补丁核心 |
| @7503299 | PlanItemStreamParser DI Token | Symbol("IPlanItemStreamParser") |
| @7508572 | ErrorStreamParser zU | 错误流 |
| @7511057 | DoneStreamParser zW | 完成流 |
| @7512721 | QueueingStreamParser zV | 排队流 |
| @7515007 | UserMessageStreamParser zJ | 用户消息 |
| @7516765 | TokenUsageStreamParser z2 | Token 用量 |
| @7517392 | ContextTokenUsageStreamParser z3 | 上下文 Token |
| @7518028 | SessionTitleMessageStreamParser z8 | 会话标题 |
| @7524723 | Bs class (ChatParserContext) | 聊天解析上下文 |
| @7540700 | createStream() + resumeChat 蓝图 | 流创建 |
| @7540953 | _aiAgentChatService.resumeChat() | 模块级续接调用 |
| @7615777 | TaskAgentMessageParser.parse() | IPC→SSE 桥接 |

**SSE 事件枚举 (Ot. 前缀)**:
| 事件类型 | 出现次数 | 位置 |
|---------|---------|------|
| PlanItem | 2 | 7514720, 7527483 |
| Error | 5 | 7517735, 7527511, 7545623 |
| Done | 3 | 7519472, 7527536, 7545632 |
| Metadata | 4 | 7322040, 7504304, 7527424 |
| Notification | 2 | 7328738, 7527755 |
| TextMessage | 2 | 7505706, 7527452 |
| UserMessage | 2 | 7523720, 7527618 |
| TokenUsage | 4 | 7524662, 7527649, 7537085 |
| FeeUsage | 2 | 7490394, 7527396 |
| SessionTitle | 2 | 7527716, 7537132 |

**handleSteamingResult 出现 10 次**: 7328394, 7490128, 7503265, 7505244, 7511054, 7517005, 7518770, 7520557, 7521682, 7523529

**搜索模板**:
| 目标 | 关键词 | 稳定性 |
|------|--------|--------|
| 事件工厂 | `eventHandlerFactory` | ⭐⭐⭐⭐ |
| 流结果处理 | `handleSteamingResult` | ⭐⭐⭐⭐ |
| PlanItem 解析 | `_handlePlanItem` | ⭐⭐⭐⭐⭐ |

---

### [Store] Zustand 状态架构

**核心实体**: 8 个 Zustand Store (均继承 Aq 基类)

| 偏移量 | Store | Token | 状态字段 |
|--------|-------|-------|---------|
| @7087490 | SessionStore | xC=Symbol("ISessionStore") | currentSession, sessions, sessionIdList |
| @7191708 | ModelStore | k1=Symbol("IModelStore") | originModelListMap, modeListMap, showMaxModeNotice |
| @7221939 | InlineSessionStore | I2=Symbol("IInlineSessionStore") | inlineSessions |
| @7224039 | ProjectStore | I7 | currentProject |
| @7248275 | AgentExtensionStore | TG | extensions |
| @7258315 | SkillStore | Na | skills |
| @7259427 | EntitlementStore | Nc=Symbol("IEntitlementStore") | entitlementInfo, saasEntitlementInfo |
| @7244780 | DocsetStore | ai.IDocsetStore | builtinDocsets, customDocsets |

**关键行为**:
- 无 Immer 使用，全部用展开运算符 `{...state, changes}`
- setCurrentSession 出现 25 次
- .subscribe() 出现 33 次（关键补丁注入点 @7588682）
- .getState() 出现 234 次

**Store-React 连接**: uB(token).useStore(selector) Hook @6270579

---

### [Error] 错误处理系统

**两套错误码体系**:
1. **服务端 o 枚举** (@51947) — SSE 传输用
2. **客户端 eA 枚举** (@7160512) — UI 渲染用

**kg 枚举 (56 个完整错误码)** @54415:

| 类别 | 关键错误码 | 值 |
|------|-----------|-----|
| 网络 | CONNECTION_ERROR, NETWORK_ERROR*, REQUEST_TIMEOUT_ERROR* | 1001-1008 |
| 模型 | MODEL_NOT_EXISTED, MODEL_OUTPUT_TOO_LONG, MODEL_AUTO_SELECTION_FAILED | 1011-1013 |
| 通用 | DEFAULT, RISK_REQUEST | 1014-1015 |
| 配额 | PREMIUM_MODE_USAGE_LIMIT, STANDARD_MODE_USAGE_LIMIT | **4008, 4009** |
| 循环 | LLM_STOP_CONTENT_LOOP, LLM_STOP_DUP_TOOL_CALL | 1024, 4000009 |
| 思考上限 | TASK_TURN_EXCEEDED_ERROR | **4000002** |
| 企业 | ENTERPRISE_* (12个), CLAUDE_MODEL_FORBIDDEN | 4113, 4213-4216 |
| 防火墙 | FIREWALL_BLOCKED | **700** |

**efg 可恢复错误列表 (14个)** @8705916:
```
SERVER_CRASH, CONNECTION_ERROR, NETWORK_ERROR, NETWORK_ERROR_INTERNAL,
CLIENT_NETWORK_ERROR, NETWORK_CHANGED, NETWORK_DISCONNECTED,
CLIENT_NETWORK_ERROR_INTERNAL, REQUEST_TIMEOUT_ERROR, REQUEST_TIMEOUT_ERROR_INTERNAL,
MODEL_RESPONSE_TIMEOUT_ERROR, MODEL_RESPONSE_FAILED_ERROR, MODEL_AUTO_SELECTION_FAILED, MODEL_FAIL
```

**错误标志变量链** @8708083:
```javascript
X = !![kg.MODEL_NOT_EXISTED].includes(_)           // 模型不存在
J = !![kg.MODEL_OUTPUT_TOO_LONG, kg.TASK_TURN_EXCEEDED_ERROR,
      kg.LLM_STOP_DUP_TOOL_CALL, kg.LLM_STOP_CONTENT_LOOP,
      kg.DEFAULT].includes(_)                       // 思考上限+循环错误
ee = !![kg.PREMIUM_MODE_USAGE_LIMIT, kg.STANDARD_MODE_USAGE_LIMIT].includes(_)  // 配额限制
```

**错误传播路径**:
1. SSE → De.handleError() @7300921 → UI Alert @8719877
2. SSE → eYZ.onUsageLimit() @10471008 → 通知
3. FIREWALL_BLOCKED → UI Alert @8718083
4. CLAUDE_MODEL_FORBIDDEN → UI Alert @8717132

**efr 枚举 (免费用户配额状态)** @55610: 20 个值 (FreeNewSubscriptionUser* 1-10, FreeOldSubscriptionUser* 11-20, Pro* 21-32)

---

### [React] UI 组件层

**三层架构**: L1(React UI) → L2(Service) → L3(Data)

**16 个 React 组件导出** @10490209:
ChatViewPaneComponent, InlineChatViewPaneComponent, CustomAgentPaneComponent,
AIModelsSettingsComponent, AIContextSettingsComponent, AIKnowledgesSettingsComponent,
AgentExtensionPaneComponent, AIRulesSettingsComponent, AIWorktreeSettingsComponent,
AgentImportComponent, AITaskPanelComponent, AIConversationSettingsComponent,
RuleMetadataFormComponent, DSLAgentPaneComponent, SubAgentDetailComponent,
KnowledgesInitPopupComponent

**关键组件**:
| 偏移量 | 组件 | 功能 |
|--------|------|------|
| @8635000 | egR RunCommandCard | 命令确认卡片 (⚠️ 补丁核心) |
| @9015579 | ChatInput | 聊天输入 |
| @8932385 | FileDiff | 文件差异展示 |
| @9067039 | ToolCall | 工具调用展示 |
| @8975688 | confirm_status 引用 | 确认状态渲染 |
| @9441960 | Max Mode tooltip | 模型选择 UI |
| @8709284 | sX().memo(Jj) | 自动续接宿主组件 |

**冻结行为**: React 冻结时 rAF→Scheduler 暂停，L1 层 useEffect 不执行。**服务层 > UI 层**。

**BlockLevel/AutoRunMode 枚举** @8069382 / @8081330-8081401

---

### [Event] 事件总线与遥测

| 偏移量 | 实体 | 说明 |
|--------|------|------|
| @7140149 | ITeaFacade (Symbol.for) | TEA 遥测门面 |
| @7458679 | teaEventChatFail | 错误遥测事件 (⚠️ auto-continue 补丁点) |
| @7584046-7588518 | store.subscribe #1/#8 | Zustand 订阅 (⚠️ 补丁注入点) |
| @7610443 | cancelEventKey | DOM 事件监听 |
| @210378 | visibilitychange (28命中) | 页面可见性变化 |
| @2317698 | HaltChainable | VS Code 事件链中断机制 |
| @7298383 | IModelReportService | 模型报告服务 |

**无 Node.js EventEmitter** — 使用自定义 Emitter 类。

---

### [IPC] 进程间通信

| 偏移量 | 实体 | 说明 |
|--------|------|------|
| @7610443 | F3/sendToAgentBackground | 后台发送入口 |
| @7614717 | ResumeChat 服务端方法调用 | 续接 IPC |
| @7615777 | TaskAgentMessageParser.parse() | IPC exception 写入 |
| @7766628 | ITaskListApiService | 任务列表 API |
| @7892948-8027658 | ASR 服务族 (4个) | 语音识别 |

**三层 IPC 架构**: Server(渲染进程) → Main(主进程) → Renderer(UI)
**Shell 执行命令**: icube.shellExec.* 9 个命令

---

### [Setting] 设置系统

| 偏移量 | 设置 Key | 说明 |
|--------|----------|------|
| @7438613 | AI.toolcall.confirmMode | 命令确认模式 |
| @7438600 | AI.toolcall.v2.command.* | v2 命令配置 |
| @7438613 | chat.tools.* (3个) | 聊天工具设置 |
| @7438613 | GlobalAutoApprove | 全局自动批准 |
| @7268582 | IModelTipConfigService | 模型提示配置 |
| @8036543 | IPrivacyModeService | 隐私模式 |
| @8095684 | IContributionService | 贡献设置 |

**ConfirmMode 枚举已移除** (@8069382) — 改为纯配置驱动。

---

### [Sandbox] 沙箱与命令执行

| 偏移量 | 实体 | 说明 |
|--------|------|------|
| @8069382 | BlockLevel (6值) / AutoRunMode (5值) | 沙箱枚举 |
| @8069620 | getRunCommandCardBranch() | 决策矩阵 (⚠️ 补丁注入点) |
| @7502574 | provideUserResponse (knowledge分支) | 知识库响应 |
| @7503319 | provideUserResponse (其他分支) | 其他响应 |
| @8039940 | IAutoAcceptService | 自动接受服务 |
| @8063616 | IRunCommandFeatureService | 运行命令特性 |
| @8086208 | IFileOpFeatureService | 文件操作特性 |
| @7562542 | IFileDiffTruncationService | 差异截断 |
| @7565469 | IFileDiffService | 差异服务 |
| @7318521 | DG.parse() data-source-auto-confirm | 数据源自动确认 |

**SAFE_RM 沙箱安全规则**: 危险命令需要确认。

---

### [MCP] 工具调用系统

| 偏移量 | 实体 | 说明 |
|--------|------|------|
| @40836 | ToolCallName 枚举 (38个) | 完整工具名列表 |
| @7076154 | ToolCallName 枚举第二段 | 扩展工具 |
| @44416 | UserConfirmStatusEnum | Unconfirmed/Confirmed/Skipped/Canceled |
| @7512531 | provideUserResponse (10命中) | 响应提供 |
| @7318521 | confirm_info 数据结构 | 确认信息结构 |

**ToolCallName 完整列表 (38个)**:
RunCommand, OpenPreview, OpenPreviewAndWaitForError, OpenFolder, CreateFile,
ViewFile, ViewFiles, ViewFolder, EditFileSearchReplace, WriteToFile, ShowDiff,
SearchByReference, SearchByDefinition, SearchByRegex, FileSearch,
CheckCommandStatus, DeleteFile, UpdateShallowMemento, CondenseShallowMemento,
MCPCall(run_mcp), Finish, WebSearch, ResponseToUser, SearchCodebase,
TodoWrite, CreateRequirement, EditProductDocumentFastApply, EditProductDocumentUpdate,
EditProductDocumentUpdateFC, WriteToProductDocument, DeployToVercel,
SupabaseApplyMigration, SupabaseGetProject, GetLLMConfig, GetStripeConfig,
GetPreviewConsoleLogs, InitEnvironment, AgentFinish

**MCP 集成**: run_mcp 与 run_command 共享确认管道。

**工具调用生命周期**: 8步
1. AI模型生成 tool_call → 2. SSE "planItem" 事件 → 3. DG.parse() 解析
→ 4. PlanItemStreamParser 处理 → 5. getRunCommandCardBranch() UI 分支
→ 6. 服务器 icube.shellExec.runCommand → 7. child_process 执行
→ 8. 结果 SSE 回传

---

### [Commercial] 商业权限域

**NS 类 (ICommercialPermissionService)** @7267682:
Token: `Il = Symbol.for("aiAgent.ICommercialPermissionService")`

| 方法 | 返回值逻辑 |
|------|-----------|
| isDollarUsageBilling() | entitlementInfo?.isDollarUsageBilling |
| isCommercialUser() | !kP(userProfile) && !isCNPackage() |
| isOlderCommercialUser() | isCommercialUser && !isDollarUsageBilling |
| isNewerCommercialUser() | isCommercialUser && isDollarUsageBilling |
| isSaas() | userProfile?.scope === bK.SAAS |
| isInternal() | kP(userProfile) = scope===BYTEDANCE |

**⚠️ NS 类没有 isFreeUser() 方法！**

**efi() Hook (isFreeUser 完整实现链)** @8687513:
```javascript
function efi(){
  let e=uB(Nc), t=uB(Ie), i=uB(M$), r=uB(kA);
  let n = e.useStore(e => !e.entitlementInfo?.identity);  // isFreeUser
  let o = e.useStore(e => !!e.entitlementInfo?.enableSoloBuilder);
  let a = e.useStore(e => !!e.entitlementInfo?.enableSoloCoder);
  let s = e.useStore(e => !!e.entitlementInfo?.isDollarUsageBilling);
  // ... 返回 {isFreeUser:n, isCommercialUser:f, isOlderCommercialUser:f&&!s, ...}
}
```

**Nu 类 (IEntitlementStore)** @7264682:
初始状态: `{ entitlementInfo: null, saasEntitlementInfo: null }`
entitlementInfo: { identity(bJ enum), isDollarUsageBilling, enableSoloBuilder, enableSoloCoder }

**MX 类 (ICredentialStore)** @7154491:
初始状态: `{ loggedIn:false, userProfile:null, token:null }`
userProfile.scope → bK: BYTEDANCE="bytedance", SAAS="saas", MARSCODE="marscode"

**bJ 枚举 (用户身份)** @6479431: Free=0, Pro=1, ProPlus=2, Ultra=3, Trial=4, Lite=5, Express=100

**bK 枚举 (scope)** @6479143: BYTEDANCE, MARSCODE, SAAS

**付费限制错误码 (纠正值)**:
| 错误码 | 旧值 | 正确值 |
|--------|------|--------|
| PREMIUM_MODE_USAGE_LIMIT | 1016 | **4008** |
| STANDARD_MODE_USAGE_LIMIT | 1017 | **4009** |
| FIREWALL_BLOCKED | 1023 | **700** |

**ee 变量 (配额限制标志)** @8707858: `ee=!![kg.PREMIUM_MODE_USAGE_LIMIT,kg.STANDARD_MODE_USAGE_LIMIT].includes(_)`

---

### [Docset] 文档集域

**5 个 ai.* DI Token (全部 Symbol.for)**:

| Token | 偏移量 | 实现类 |
|-------|--------|--------|
| ai.IDocsetService | @3546321 | Gd (DocsetServiceImpl) |
| ai.IDocsetStore | @7244792 | TD (DocsetStore, Zustand) |
| ai.IDocsetCkgLocalApiService | @7715126 | WY (CkgLocalApiService) |
| ai.IDocsetOnlineApiService | @7720282 | Wq (DocsetOnlineApiService) |
| ai.IWebCrawlerFacade | @7725219 | Gs (WebCrawlerFacade) |

**IDocsetStore 状态**: builtinDocsets, builtinDocsetVersion, customDocsets, searchableBuiltinDocsets, enterpriseDocsetIdsToRefresh

**IKnowledges 服务族 (8个)**: TaskService, PersistenceService, StagingService, FeatureService, SourceMaterialService, NotificationService, StatusBarService
**icube.knowledges.* 命令 (7个)**: init, retryInit, rebuild, update, pause, continue, statusClick/showDebugStatus

**企业文档集门控**: userProfile.scope === bK.SAAS + isSaaSFeatureEnabled("ent_knowledge_base")

---

### [Model] 模型选择域

**核心实体**:

| 偏移量 | 实体 | 说明 |
|--------|------|------|
| @7182322 | IModelService (kv=Symbol.for) | NR 类实现 |
| @7182353 | IModelStorageService | 模型存储 |
| @7191708 | IModelStore (k1=Symbol) | k2 类，模型列表 Store |
| @7213504 | computeSelectedModelAndMode | ⚠️ 静态方法，模式决策核心 |
| @7185310 | kG 枚举 (Manual=0/Auto=1/Max=2) | 模式类型 |
| @7185310 | kH 枚举 (Advanced=1/Premium=2/Super=3) | 模型层级 |
| @7280685 | checkFreeUserPremiumModelNotice | 免费用户高级模型通知 |

**computeSelectedModelAndMode 决策链**:
1. 无 agentType 或空模型列表 → Manual
2. session 级选中模型 → global 级 → 默认模型
3. ★ 商业用户 Solo Agent → **强制 Max** `(isOlderCommercialUser||isSaas) && solo_coder/builder`
4. 回退 + auto_mode → Auto
5. 回退其他 → Manual
6. 正常路径 → session/global 模式映射，默认 Auto

**force-max-mode 补丁蓝图**: Step 3 条件 `(u||d)&&(...)` → 可改为恒真或直接返回 Max

---

## MCP 工具调用详情

### 1. 工具枚举 (排除自动确认)

| 枚举值 | 字符串 | 用途 |
|--------|--------|------|
| RunCommand | `"run_command"` | 执行命令 |
| WriteToFile | `"write_to_file"` | 写文件 |
| CreateFile | `"create_file"` | 创建文件 |
| Read | `"read"` | 读文件 |
| Edit | `"edit"` | 编辑 |
| SearchReplace | `"SearchReplace"` | 搜索替换 |
| SearchCodebase | `"SearchCodebase"` | 代码库搜索 |
| LS | `"LS"` | 列出目录 |

### 2. 用户交互类 (排除自动确认)

| 枚举值 | 字符串 | 用途 |
|--------|--------|------|
| response_to_user | `"response_to_user"` | 询问用户 |
| AskUserQuestion | `"AskUserQuestion"` | 提问用户 |
| NotifyUser | `"NotifyUser"` | 通知用户 |
| ExitPlanMode | `"ExitPlanMode"` | 退出计划模式 |

### 3. 浏览器操作类 (20+ 工具)
- `browser_*` 系列 (navigate, click, screenshot 等)

### 4. 工具调用生命周期

```
1. 发起: AI 模型生成 tool_call (tool_name, tool_input, toolcall_id)
2. 传输: SSE "planItem" 事件 + confirm_info
3. 解析: DG.parse() @7318521 → 结构化对象
4. 处理: PlanItemStreamParser._handlePlanItem() @7502500
   → 检查 confirm_status → provideUserResponse()
5. 决策: getRunCommandCardBranch() @8069620 → UI 分支
6. 执行: 服务器 → icube.shellExec.runCommand → child_process
7. 结果: 命令输出 → SSE 回传 → 聊天显示
8. 完成: DoneStreamParser.parse() → 标记轮次完成
```

### 5. confirm_info 数据结构

```javascript
confirm_info = {
    confirm_status: "unconfirmed" | "confirmed" | "canceled" | "skipped",
    auto_confirm: true | false,
    hit_red_list: ["Remove-Item", ...],
    hit_blacklist: [...],
    block_level: "redlist" | "blacklist" | "sandbox_*",
    run_mode: "auto" | "manual" | "allowlist" | "in_sandbox" | "out_sandbox",
    now_run_mode: "in_sandbox" | "out_sandbox" | ...
}
```

### 6. MCP 集成
MCP 工具调用 (`run_mcp`) 与 `run_command` 共享相同的确认管道。自动确认补丁覆盖 MCP 调用。

### 7. 搜索模板

| 目标 | 搜索关键词 | 稳定性 |
|------|-----------|--------|
| MCP 调用 | `"run_mcp"` | ⭐⭐⭐⭐⭐ |
| 工具枚举 | `"ToolCallName"` | ⭐⭐ |
| 确认信息 | `"confirm_info"` | ⭐⭐⭐⭐ |
| 确认状态 | `"unconfirmed"` | ⭐⭐⭐⭐⭐ |
| 工具确认 | `"tool_confirm"` | ⭐⭐⭐⭐⭐ |

---

## 偏移量索引与交叉引用

### 按探索域索引

#### [DI] 依赖注入

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~6268469 | DI 容器类 (uj) | ⭐⭐ |
| ~6270579 | uB useInject Hook + hX 快捷方式 | ⭐⭐ |
| ~6473533 | bY = Symbol.for("aiAgent.ILogService") | ⭐⭐⭐⭐⭐ |
| ~7015771 | Ei = Symbol.for("aiAgent.ICredentialFacade") | ⭐⭐⭐⭐⭐ |
| ~7087490 | xC = Symbol("ISessionStore") | ⭐⭐⭐⭐ |
| ~7097170 | SessionStore 注册 | ⭐⭐⭐⭐ |
| ~7135785 | Ma = Symbol.for("ITeaFacade") | ⭐⭐⭐⭐⭐ |
| ~7150072 | M0 = Symbol.for("aiAgent.ISessionService") | ⭐⭐⭐⭐⭐ |
| ~7152097 | SessionService 注册 (Ci) | ⭐⭐⭐⭐ |
| ~7186457 | k1 = Symbol("IModelStore") | ⭐⭐⭐⭐ |
| ~7203850 | IN = Symbol("ISessionRelationStoreInternal") | ⭐⭐⭐⭐ |
| ~7221939 | I2 = Symbol("IInlineSessionStore") | ⭐⭐⭐⭐ |
| ~7224039 | I7 ProjectStore | ⭐⭐⭐ |
| ~7248275 | TG AgentExtensionStore | ⭐⭐⭐ |
| ~7258315 | Na SkillStore | ⭐⭐⭐ |
| ~7259427 | Nc EntitlementStore | ⭐⭐⭐ |
| ~7545196 | BO = Symbol("ISessionServiceV2") | ⭐⭐⭐⭐ |

#### [SSE] 流管道

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~7300000 | EventHandlerFactory (Bt) | ⭐⭐⭐ |
| ~7314000 | MetadataParser (DQ) + UserMessageContextParser (DV) | ⭐⭐⭐⭐ |
| ~7318521 | DG.parse() 服务端响应解析器 | ⭐⭐⭐⭐ |
| ~7322410 | NotificationStreamParser | ⭐⭐⭐⭐⭐ |
| ~7323241 | data-source-auto-confirm 补丁位置 | ⭐⭐⭐ |
| ~7482422 | FeeUsageStreamParser (za) | ⭐⭐⭐⭐ |
| ~7497479 | TextMessageChatStreamParser | ⭐⭐⭐⭐⭐ |
| ~7502500 | PlanItemStreamParser._handlePlanItem() | ⭐⭐⭐⭐ |
| ~7503299 | PlanItemStreamParser DI Token | ⭐⭐⭐⭐ |
| ~7508572 | ErrorStreamParser (zU) | ⭐⭐⭐⭐⭐ |
| ~7511057 | DoneStreamParser (zW) | ⭐⭐⭐⭐ |
| ~7512721 | QueueingStreamParser (zV) | ⭐⭐⭐⭐ |
| ~7513080 | getErrorInfoWithError(e) | ⭐⭐⭐ |
| ~7513727 | SSE path exception 写入点 | ⭐⭐ |
| ~7515007 | UserMessageStreamParser (zJ) | ⭐⭐⭐⭐⭐ |
| ~7516765 | TokenUsageStreamParser (z2) | ⭐⭐⭐⭐⭐ |
| ~7517392 | ContextTokenUsageStreamParser (z3) | ⭐⭐⭐⭐⭐ |
| ~7518028 | SessionTitleMessageStreamParser (z8) | ⭐⭐⭐⭐⭐ |
| ~7524723 | Bs class (ChatParserContext) | ⭐⭐ |
| ~7528742 | _onError(e,t,i) | ⭐⭐ |
| ~7533176 | _onStreamingStop → WaitingInput | ⭐⭐ |
| ~7538139 | stopStreaming — "沉默杀手" | ⭐⭐ |
| ~7540700 | createStream() + resumeChat 蓝图 | ⭐⭐⭐ |
| ~7540953 | _aiAgentChatService.resumeChat() | ⭐⭐⭐ |
| ~7610443 | F3/sendToAgentBackground (DI 蓝图) | ⭐⭐⭐ |
| ~7614717 | ResumeChat 服务端方法调用 | ⭐⭐⭐ |
| ~7615777 | TaskAgentMessageParser.parse() — IPC exception 写入 | ⭐⭐⭐⭐ |

#### [Store] 状态架构

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~3211326 | needConfirm Zustand store | ⭐⭐⭐ |
| ~7584046 | subscribe #1 (消息数+会话ID) | ⭐⭐⭐ |
| ~7588518 | subscribe #8 (消息数变化) | ⭐⭐⭐ |
| ~7605848 | runningStatusMap subscribe | ⭐⭐⭐ |

#### [Error] 错误系统

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~54000 | kg 错误码枚举 (第一段) | ⭐⭐⭐ |
| ~54269 | LLM_STOP_DUP_TOOL_CALL=4000009 | ⭐⭐⭐⭐⭐ |
| ~54415 | TASK_TURN_EXCEEDED_ERROR=4000002 | ⭐⭐⭐⭐⭐ |
| ~7161400 | kg 错误码枚举 (第二段) | ⭐⭐⭐ |
| ~7161547 | LLM_STOP_CONTENT_LOOP=4000012 | ⭐⭐⭐⭐⭐ |
| ~7169408 | 错误码→消息映射 | ⭐⭐⭐ |
| ~7300455 | handleCommonError() | ⭐⭐⭐ |
| ~7458679 | teaEventChatFail() | ⭐⭐⭐⭐ |
| ~8695303 | efh 可恢复错误列表 | ⭐⭐⭐ |
| ~8696378 | J 变量 (可恢复错误标志) | ⭐⭐ |

#### [React] UI 层

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~2796260 | Pause/Send 按钮 (ei) | ⭐⭐ |
| ~8069382 | BlockLevel/AutoRunMode/ConfirmMode 枚举 | ⭐⭐⭐⭐⭐ |
| ~8069620 | getRunCommandCardBranch() | ⭐⭐⭐ |
| ~8070328 | bypass-runcommandcard-redlist 补丁 | ⭐⭐ |
| ~8629200 | UI 确认状态检查 | ⭐⭐ |
| ~8635000 | egR (RunCommandCard) 组件 | ⭐⭐ |
| ~8636941 | ey useMemo (有效确认状态) | ⭐⭐ |
| ~8637300 | confirm_info 解构 | ⭐⭐ |
| ~8640019 | 自动确认 useEffect | ⭐⭐ |
| ~8697580 | ec callback (retry/resume) | ⭐⭐ |
| ~8697620 | ed callback ("继续"按钮) | ⭐⭐ |
| ~8700000 | ErrorMessageWithActions 开始 | ⭐⭐ |
| ~8702300 | if(V&&J) Alert 分支 | ⭐ |
| ~8709284 | sX().memo(Jj) 组件 | ⭐ |
| ~8930000 | ErrorMessageWithActions 结束 | ⭐ |
| ~9910446 | DEFAULT 错误组件 | ⭐⭐ |

#### [IPC] 进程间通信

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~7610443 | cancelEventKey (window.addEventListener) | ⭐⭐⭐⭐ |

#### [Setting] 设置系统

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~7438613 | AI.toolcall.confirmMode | ⭐⭐⭐⭐⭐ |
| ~7438600 | AI.toolcall.v2.command.* | ⭐⭐⭐⭐⭐ |

#### [Sandbox] 沙箱

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~8069382 | BlockLevel/AutoRunMode/ConfirmMode 枚举定义 | ⭐⭐⭐⭐⭐ |
| ~8069620 | getRunCommandCardBranch() 决策函数 | ⭐⭐⭐ |
| ~7502574 | provideUserResponse (知识分支) | ⭐⭐⭐⭐ |
| ~7503319 | provideUserResponse (其他分支) | ⭐⭐⭐⭐ |

#### [MCP] 工具调用

| 偏移量 | 内容 | 稳定性 |
|--------|------|--------|
| ~41400 | ToolCallName 枚举 (第一段) | ⭐⭐ |
| ~7076154 | ToolCallName 枚举 (第二段) | ⭐⭐ |

### 按偏移量范围索引

#### 0-1M (枚举 + 工具定义)

| 偏移量 | 域 | 内容 |
|--------|-----|------|
| ~41400 | MCP | ToolCallName 枚举 |
| ~44403 | React | Ck.Unconfirmed="unconfirmed" |
| ~46816 | Store | RunningStatus 枚举 (Io) |
| ~47202 | Error | ChatTurnStatus 枚举 (bQ) |
| ~54000 | Error | kg 错误码枚举 (第一段) |

#### 1M-5M (UI 组件)

| 偏移量 | 域 | 内容 |
|--------|-----|------|
| ~2665348 | React | AI.NEED_CONFIRM 枚举 |
| ~2796260 | React | Pause/Send 按钮 |
| ~3211326 | Store | needConfirm 状态 |

#### 5M-8M (核心服务层 — 最密集区域)

| 偏移量 | 域 | 内容 |
|--------|-----|------|
| ~6268469 | DI | DI 容器类 (uj) |
| ~6270579 | DI | uB useInject Hook |
| ~6473533 | DI | bY LogService Token |
| ~7015771 | DI | Ei CredentialFacade Token |
| ~7076154 | MCP | ToolCallName 枚举 (第二段) |
| ~7087490 | DI/Store | xC SessionStore Token |
| ~7135785 | DI | Ma TeaFacade Token |
| ~7150072 | DI | M0 SessionService Token |
| ~7161400 | Error | kg 错误码枚举 (第二段) |
| ~7186457 | DI/Store | k1 ModelStore Token |
| ~7300000 | SSE | EventHandlerFactory (Bt) |
| ~7318521 | SSE | DG.parse() |
| ~7438613 | Setting | AI.toolcall.confirmMode |
| ~7458679 | Error | teaEventChatFail() |
| ~7502500 | SSE | PlanItemStreamParser._handlePlanItem() |
| ~7508572 | SSE | ErrorStreamParser (zU) |
| ~7524723 | SSE | Bs class (ChatParserContext) |
| ~7545196 | DI | BO SessionServiceV2 Token |
| ~7584046 | Store | subscribe #1 |
| ~7588518 | Store | subscribe #8 |
| ~7605848 | Store | runningStatusMap subscribe |
| ~7610443 | IPC | F3/sendToAgentBackground |
| ~7615777 | Error | TaskAgentMessageParser.parse() |

#### 8M-10M (UI 层)

| 偏移量 | 域 | 内容 |
|--------|-----|------|
| ~8069382 | Sandbox | BlockLevel/AutoRunMode/ConfirmMode 枚举 |
| ~8069620 | Sandbox | getRunCommandCardBranch() |
| ~8070328 | Sandbox | bypass-runcommandcard-redlist 补丁 |
| ~8635000 | React | egR (RunCommandCard) 组件 |
| ~8700000 | React | ErrorMessageWithActions |
| ~9910446 | React | DEFAULT 错误组件 |

### 按功能索引

#### 自动确认 (Auto-Confirm)

| 偏移量 | 内容 | 层 |
|--------|------|-----|
| ~7318521 | DG.parse L3数据源自动确认 | L3 |
| ~7502500 | PlanItemStreamParser._handlePlanItem() | L2 |
| ~7502574 | knowledge 分支 provideUserResponse | L2 |
| ~7503319 | else 分支 provideUserResponse | L2 |
| ~7323241 | data-source-auto-confirm 补丁 | L3 |
| ~8069620 | getRunCommandCardBranch() | L1 |
| ~8070328 | bypass-runcommandcard-redlist 补丁 | L1 |
| ~8635000 | egR (RunCommandCard) | L1 |
| ~8640019 | 自动确认 useEffect | L1 |

#### 自动续接 (Auto-Continue)

| 偏移量 | 内容 | 层 |
|--------|------|-----|
| ~7458679 | teaEventChatFail() 最早错误信号 | L2 |
| ~7538139 | stopStreaming — "沉默杀手" | L2 |
| ~7540953 | _aiAgentChatService.resumeChat() | L2 |
| ~7588518 | subscribe #8 | L2 |
| ~8705916 | efg 可恢复错误列表 | L1 |
| ~8707716 | J 变量可续接错误标志 | L1 |
| ~8702300 | if(V&&J) Alert 分支 | L1 |
| ~8712898 | guard-clause !q&&!J) | L1 |

#### 沙箱/命令执行

| 偏移量 | 内容 | 层 |
|--------|------|-----|
| ~8069382 | BlockLevel/AutoRunMode/ConfirmMode 枚举 | L1 |
| ~8069620 | getRunCommandCardBranch() | L1 |
| ~7502574 | provideUserResponse (知识分支) | L2 |
| ~7503319 | provideUserResponse (其他分支) | L2 |

#### 错误处理

| 偏移量 | 内容 | 层 |
|--------|------|-----|
| ~54000 | kg 错误码枚举 | 枚举 |
| ~7300455 | handleCommonError() | L2 |
| ~7458679 | teaEventChatFail() | L2 |
| ~7508572 | ErrorStreamParser (zU) | L2 |
| ~7513080 | getErrorInfoWithError(e) | L2 |
| ~7528742 | _onError(e,t,i) | L2 |
| ~7615777 | TaskAgentMessageParser.parse() | L2 |

#### 设置/配置

| 偏移量 | 内容 | 层 |
|--------|------|-----|
| ~7438613 | AI.toolcall.confirmMode | 配置 |
| ~7438600 | AI.toolcall.v2.command.* | 配置 |

---

## [2026-04-25 23:50] v2 探索远征 — 版本适配 + 商业权限 + 新补丁目标

### J→K 重命名纠正 — J 仍为当前变量名 ⭐⭐⭐⭐⭐

**重要纠正**: handoff.md 中声称的 "J→K 重命名" 在当前版本中并未发生。
- `K=!![` — 未找到（0 个命中）
- `J=!![` — 找到 @8707716
- `if(V&&J)` — 找到 @8713483
- `!q&&!J)` — 找到 @8712898

**结论**: J→K 重命名要么未发生，要么已回退。现有补丁中引用 J 的代码仍然有效。

### Symbol.for→Symbol 迁移完整映射 ⭐⭐⭐⭐⭐

**已迁移的 token** (Symbol.for→Symbol):
- IPlanItemStreamParser: Symbol=7511512
- ISessionStore: Symbol=7092843
- IEntitlementStore: Symbol=7264735
- ISessionServiceV2: Symbol=7553132
- ICredentialStore: Symbol=7154464
- IModelStore: Symbol=7191686
- IAgentService: Symbol=7327208
- IEventHandlerFactory: Symbol=7526620

**未迁移的 token** (仍为 Symbol.for):
- IModelService: Symbol.for=7182322
- IErrorStreamParser: Symbol.for=7516471
- ITeaFacade: Symbol.for=7140149
- ICommercialPermissionService: Symbol.for("aiAgent.ICommercialPermissionService")
- INotificationStreamParser: Symbol.for=7328310
- ITextMessageChatStreamParser: Symbol.for=7505681
- IPlanItemParser: Symbol.for=7324116
- IFeeUsageParser: Symbol.for=7327235

**迁移规律**: Store 类和 Parser 类 token 已迁移到 Symbol()。Facade/Service 类 token 仍保留 Symbol.for()。

### ICommercialPermissionService 完整方法映射 ⭐⭐⭐⭐⭐

NS 类 (@7267682)，Token: `Il = Symbol.for("aiAgent.ICommercialPermissionService")`

| 方法 | 实现逻辑 | 返回值 |
|------|---------|--------|
| `isDollarUsageBilling()` | `_entitlementStore.getState().entitlementInfo?.isDollarUsageBilling` | boolean |
| `isCommercialUser()` | `!kP(userProfile) && !isCNPackage()` | boolean |
| `isOlderCommercialUser()` | `isCommercialUser() && !isDollarUsageBilling()` | boolean |
| `isNewerCommercialUser()` | `isCommercialUser() && isDollarUsageBilling()` | boolean |
| `isSaas()` | `userProfile?.scope === bK.SAAS` | boolean |
| `isInternal()` | `kP(userProfile)` = `userProfile?.scope === bK.BYTEDANCE` | boolean |

**关键发现**: NS 类**没有 isFreeUser() 方法**！isFreeUser 是在 React Hook efi() @8687513 中计算的：`isFreeUser = !entitlementInfo?.identity`

### 付费限制错误码纠正 ⭐⭐⭐⭐⭐

| 枚举名 | 实际值 | 旧记录值 | 纠正原因 |
|--------|--------|---------|---------|
| PREMIUM_MODE_USAGE_LIMIT | **4008** | 1016 | 实际搜索确认 |
| STANDARD_MODE_USAGE_LIMIT | **4009** | 1017 | 实际搜索确认 |
| FIREWALL_BLOCKED | **700** | 1023 | 实际搜索确认 |

### 新补丁目标候选清单 ⭐⭐⭐⭐

| # | 名称 | 位置 | 注入点 | 风险 | 层级 | 可行性 |
|---|------|------|--------|------|------|--------|
| 1 | **bypass-commercial-permission** ⭐推荐 | @7267682 | NS 类方法返回值 | 🟡 MEDIUM | L2 | ⭐⭐⭐⭐⭐ |
| 2 | **bypass-usage-limit** | @8707858 | ee 变量改 false | 🟡 MEDIUM | L1 | ⭐⭐⭐⭐ |
| 3 | bypass-free-user-model-notice | @7280685 | 方法直接 return | 🟢 LOW | L2 | ⭐⭐⭐⭐ |
| 4 | bypass-claude-model-forbidden | @8717132 | 跳过 Alert | 🟡 MEDIUM | L1 | ⭐⭐⭐ |
| 5 | force-max-mode | @7216438 | 移除商业限制 | 🟠 HIGH | L2 | ⭐⭐⭐ |
| 6 | bypass-firewall-blocked | @8718083 | 跳过 Alert | 🟠 HIGH | L1 | ⭐⭐ |

**bypass-commercial-permission 补丁草案** (方案 A - 推荐):
将 NS 类的 6 个方法返回值修改为：
`isDollarUsageBilling(){return!0}isCommercialUser(){return!0}isOlderCommercialUser(){return!1}isNewerCommercialUser(){return!0}isSaas(){return!1}isInternal(){return!1}`

**限制**: 服务端限制无法绕过。如果服务端检查用户身份并拒绝请求，前端补丁无法解决。但 UI 限制和模式选择可以完全绕过。

### Phase 4: isFreeUser() 完整实现链 ⭐⭐⭐⭐⭐

efi() Hook @8687513 — 完整源码见 [Commercial] 域映射。
**核心**: `isFreeUser = !entitlementInfo?.identity`
- identity=0 (Free) 时 `!0` = true → isFreeUser=true
- identity 有值时 isFreeUser=false

### Phase 4: 用量配额相关代码 ⭐⭐⭐⭐

| 位置 | 代码 | 功能 |
|------|------|------|
| @8707858 | `ee=!![kg.PREMIUM_MODE_USAGE_LIMIT,kg.STANDARD_MODE_USAGE_LIMIT].includes(_)` | 配额限制标志 |
| @8688095 | `efi()` → `isFreeUser=n` | isFreeUser 计算 |
| @8705688 | `efc()` → freeCommercialActivity | 免费活动配置 |
| @10471008 | `eYZ.onUsageLimit()` | 自动补全用量限制处理 |
| @7301421 | `De.handleError()` → PREMIUM_MODE_USAGE_LIMIT | 错误处理+模型切换 |
| @8719877 | Alert 渲染 → PREMIUM/STANDARD_MODE_USAGE_LIMIT | UI 错误展示 |
| @8692994 | `usageLimitConfig.premiumUsageLimit/standardUsageLimit` | 配额限制配置 |
| @55610 | `efr` 枚举 (FreeNewSubscriptionUser*) | 免费用户配额状态枚举 |

### Phase 5: 模型选择限制代码 ⭐⭐⭐⭐⭐

**kG 枚举 (模式类型)**: Manual=0, Auto=1, Max=2
**kH 枚举 (模型层级)**: AdvancedModel=1, PremiumModel=2, SuperModel=3

**computeSelectedModelAndMode 逻辑** @7216438:
```javascript
if ((isOlderCommercialUser || isSaas) && (agentType === solo_coder || solo_builder)) {
  return {model, mode: kG.Max, isModelFallback};  // 强制 Max 模式
}
// 默认模式选择: sessionMode ?? globalMode ?? kG.Auto
```

### Phase 5: 新补丁目标候选 (详细版) ⭐⭐⭐⭐⭐

**候选 1: bypass-commercial-permission** ⭐⭐⭐⭐⭐
- 方案 A (推荐): 修改 NS 类方法返回值 — L2 服务层，不受 React 冻结影响
- 方案 B: 修改 efi() Hook — L1 React 层，切窗口后不执行
- **推荐方案 A**

**候选 2: bypass-usage-limit** ⭐⭐⭐⭐
- 修改 ee 变量为 false → 跳过配额限制 UI
- 仅隐藏 UI，不解决服务端限制
- 需配合 bypass-commercial-permission

**候选 3: bypass-firewall-blocked** ⭐⭐⭐
- ❌ FIREWALL_BLOCKED 是网络层拦截，前端补丁无法绕过

**候选 4: bypass-claude-model-forbidden** ⭐⭐⭐⭐
- 可能是服务端权限限制，仅隐藏 UI

**候选 5: force-max-mode** ⭐⭐⭐
- 修改静态方法可能影响多个调用点

**候选 6: bypass-free-user-model-notice** ⭐⭐
- 仅影响通知显示，实际价值有限

**总体可行性: 高 (4/5)** — 推荐组合: bypass-commercial-permission + bypass-usage-limit

### 补丁变量验证结果 ⭐⭐⭐⭐

| 变量 | 状态 | 偏移量 | 备注 |
|------|------|--------|------|
| uj.getInstance | ✅ FOUND | @6275751 | DI 容器访问 |
| resolve(Di) | ✅ FOUND | @7459376 | _aiAgentChatService |
| resolve(BR) | ✅ FOUND | @7592580 | _sessionServiceV2 (BR 是 path 模块) |
| resolve(xC) | ✅ FOUND | @7591618 | _sessionStore |
| kg.TASK_TURN | ✅ FOUND | @8707746 | 错误码枚举 |
| bQ.Warning/Error | ✅ FOUND | @7080357/@7516749 | 状态枚举 |
| P7.Default | ✅ FOUND | @8078831 | RunCommandCard 分支 |
| P8.Default | ❌ NOT_FOUND | — | 可能已重命名 |
| Cr.Alert | ✅ FOUND | @8711528 | Alert 组件 |
| Cr.AutoRunMode | ✅ FOUND | @8081330 | 自动运行模式枚举 |
| Cr.BlockLevel | ✅ FOUND | @8081401 | 阻塞级别枚举 |

---

## [2026-04-26 04:15] 11域交叉验证 + 新域探索

> 自动化交叉验证结果摘要

### 验证汇总

| 指标 | 值 |
|------|-----|
| 目标文件大小 | 10 MB |
| ✅ PASS | 11 |
| ⚠️ WARN/DRIFT | 0 |
| ❌ FAIL | 2 |
| 总检查项 | 13 |

### DI 域计数纠正
| 指标 | 文档记录 | 实际值 | 原因 |
|------|---------|--------|------|
| uJ({identifier: 注册数 | 51 | **186** | 文档记录的是"服务"数，实际匹配所有 DI 装饰器注册点 |
| uX( 注入数 | 101 | **817** | 文档记录的是"类级注入"，实际匹配所有属性注入点 |

### 5 个新域确认

| 域 | 评分 | 核心实体 | 补丁潜力 |
|----|------|---------|---------|
| **Network** | 5/5 | fetch(16), XMLHttpRequest(9), axios(1), interceptor(8) | ⭐⭐ 请求拦截/修改 |
| **Model** | 5/5 | IModelService(16), IModelStorageService(1), computeSelectedModel(3), modelList(20) | ⭐⭐⭐⭐⭐ 模型选择/模式解锁 |
| **History** | 5/5 | IPastChatExporter(1), chatHistory(3), pastChat(4) | ⭐⭐ 历史导出 |
| **Auth** | 5/5 | ICredentialFacade(1), login(210), logout(30), authenticate(6), token(1002) | ⭐⭐⭐ 凭证/身份伪造 |
| **Telemetry** | 5/5 | ITeaFacade(1), ISlardarFacade(1), TeaReporter(3), slardar(51) | ⭐⭐ 遥测屏蔽 |

> **Model 域** 补丁潜力最高：`computeSelectedModelAndMode` 是模式选择核心，配合 Commercial 域的 `isCommercialUser()` 可实现完整的模式/模型解锁。

---

## [2026-04-26 04:27] P1盲区系统性扫描 — 最终版

> 区间1(UI下半: 8930000-9910446) + 区间2(命令注册: 9910446-10490721) + 区间3(首部: 0-41400) + 区间4(尾部)
> 共发现 64 个目标

### 核心发现

**1. 文件结构**:
- AMD define 入口: `define(["katex","react","react-dom"],function(e,t,i){...})` @0
- IIFE 闭合: `...apis:FW}})(),l})()})` @10743409 (三重闭包)
- 16 个 React 组件导出 @10490209
- FW 核心服务门面对象 @7598504

**2. registerAdapter = uj.getInstance().provide()** @10476397 — DI 适配器注册接口

**3. 25 个 VS Code 命令注册** @10477819-10489027:
核心命令: send.internal, send.codeReview, openUsageLimitModalAICompletion, stopSession, sendToAgentNonBlocking, sendToAgentBackground.deepwiki, knowledges.*(8个)

**4. eY0 模块入口对象** @10476892:
```
eY0={
  registerAdapter:function(e,t){uj.getInstance().provide(e,t)},
  getRegisteredAdapter:function(e){return uj.getInstance().resolve(e)},
  bootstrapApplicationContainer:function(e){...}
}
```

**5. ToolCallName 完整枚举 (38个)** @40836 — 见 [MCP] 域

**6. UserConfirmStatusEnum** @44416: Unconfirmed/Confirmed/Skipped/Canceled

**7. createDecorator — DI 装饰器工厂** @853508 — serviceRegistry 全局 Map

**8. Bootstrap 初始化序列** @10728701:
```
t.resolve(Dr).initialize(), t.resolve(Dp).initialize(),
t.resolve(kh).initialize(), t.resolve(H2).migrateChatHistory(),
t.resolve(eto).initialize(), FW.prepareSessionService()
```

**P1 区域内容分布**: 48.4% React 组件 + 48.4% Base64 数据 + 3.2% 业务逻辑

---

## [2026-04-26 04:44] 搜索模板可用性验证报告

### 验证结果 (结论表格)

| 模板ID | 搜索模式 | 状态 | 备注 |
|--------|---------|------|------|
| DI-01 | `uX(` | ✅ OK (817命中) | |
| DI-02 | `uJ({identifier:` | ✅ OK (186命中) | |
| DI-03 | `Symbol.for("` | ✅ OK (185命中) | |
| DI-04 | `Symbol("` | ✅ OK (77命中) | |
| SSE-01 | `eventHandlerFactory` | ✅ OK (5命中) | |
| **SSE-02** | **`Symbol.for("IPlanItemStreamParser")`** | **❌ EMPTY** | **已迁移为 Symbol()** |
| SSE-07 | `handleSteamingResult` | ✅ OK (14命中) | |
| STO-01 | `Symbol("ISessionStore")` | ✅ OK (1命中) | |
| STO-04 | `.subscribe(` | ✅ OK (33命中) | |
| STO-05 | `.getState()` | ✅ OK (234命中) | |
| ERR-01 | `4000002` | ✅ OK (7命中) | |
| ERR-06 | `getErrorInfo` | ✅ OK (13命中) | |
| ERR-07 | `handleCommonError` | ✅ OK (5命中) | |
| ERR-11 | `teaEventChatFail` | ✅ OK (5命中) | |
| RCT-01 | `sX().memo(` | ✅ OK (31命中) | |
| RCT-08 | `getRunCommandCardBranch` | ✅ OK (2命中) | |
| RCT-10 | `"unconfirmed"` | ✅ OK (11命中) | |
| EVT-01 | `Symbol.for("ITeaFacade")` | ✅ OK (1命中) | |
| EVT-02 | `visibilitychange` | ✅ OK (28命中) | |
| **EVT-05** | **`icube.shellExec`** | **❌ EMPTY** | **已移除** |
| COM-01 | `ICommercialPermissionService` | ✅ OK (1命中) | |
| COM-02 | `isCommercialUser` | ✅ OK (4命中) | |
| COM-03 | `IEntitlementStore` | ✅ OK (1命中) | |
| GEN-06 | `provideUserResponse` | ✅ OK (10命中) | |
| GEN-07 | `ToolCallName` | ✅ OK (4命中) | |
| GEN-08 | `BlockLevel` | ✅ OK (3命中) | |

**汇总**: 24/26 OK, 2/26 EMPTY (SSE-02, EVT-05)

---

## [2026-04-26] 版本差异探索 — 结论摘要

### 1. DI Token 迁移: Symbol.for -> Symbol
- **54 个** Symbol.for("I...") — 主要是旧版服务/Parser/Store 注册 token
- **52+ 个** Symbol("I...") — 新增迁移
- **迁移规律**: Store 类和 Parser 类 token 已迁移到 Symbol()。Facade/Service 类 token 仍保留 Symbol.for()

### 2. ConfirmMode 消失
- ConfirmMode 枚举已不存在
- confirmMode 仅 1 处，是配置 key 字符串 "AI.toolcall.confirmMode"
- 结论: 确认逻辑改为纯配置驱动

### 3. 变量重命名纠正
- 旧版声称 J→K，**但 J 仍为当前变量名** @8707716
- J 包含 5 个错误码: MODEL_OUTPUT_TOO_LONG, TASK_TURN_EXCEEDED_ERROR, LLM_STOP_DUP_TOOL_CALL, LLM_STOP_CONTENT_LOOP, DEFAULT

### 4. kg 错误码完整枚举 (~56个)
- 见 [Error] 域映射完整列表

### 5. efg 可恢复错误列表 (14个)
- 见 [Error] 域映射

### 6. stopStreaming 位置 (4处)
- 7528156: ChatStreamService._stopStreaming (cancel token)
- 7533741: ChatStreamService._stopStreaming 实现
- 7543791: StoreService.stopStreaming (沉默杀手)
- 7549062: BaseStreamService.stopStreaming (空实现)

### 7. 文件基本信息
- 文件大小: 10,487,934 chars (最新测量)
- Symbol.for 总数: 185. Symbol 总数: 77

---

## [2026-04-26 16:05] Model 域深度探索

> 完整架构文档，核心发现见 [Model] 域映射。

**补充发现**:
- kY 枚举 (Trae=1/Enterprise=2/Personal=3) — 配置来源 @7185310
- kZ 枚举 — 刷新来源（14个值）@7185900
- force_close_auto 配置 @7282940
- max_mode / is_dollar_max / fee_model_level 模型属性
- ID class (SessionRelationStore) @7209355 含 computeSelectedModelAndMode
- ID uJ 注册 @7222646, NE DI identifier @7271041

**补丁潜力评级**:
- force-max-mode: 5/5
- bypass-premium-model-notice: 4/5
- bypass-usage-limit: 4/5
- force-auto-mode: 3/5

---

## [2026-04-26 16:05] Docset 域深度探索

> 完整架构文档，核心发现见 [Docset] 域映射。

**补充发现**:
- DocsetServiceImpl (Gd) @7726546 — 编排层
- DocsetStore (TD) @7244792 — Zustand Store，5个状态字段
- CkgLocalApiService (WY) @7717236 — 7个 API 方法
- DocsetOnlineApiService (Wq) @7720282 — 4个 API 方法
- WebCrawlerFacade (Gs) @7725219 — 4个方法
- ent_knowledge_base 门控 @7727418 — SaaS 功能开关
- CKG IPC 通道 @11405+ — chat/start/cancel/clear_ckg_indexing
- Docset-Chat 集成 @7594424 — sendToAgent 中 resolve(WK.IDocsetService)

**5 个 ai.* DI Token 全部使用 Symbol.for** (与 Model 域不同!)

**补丁潜力**: bypass-ent-knowledge-base-gating 4/5, force-knowledges-enable 3/5

---

## [2026-04-27 00:40] Deep Dive Blindspots ⭐⭐⭐⭐⭐

> 6 大维度深度发现，文件版本 10,490,721 → **10,487,934** (-2,787 字符)

### 发现 1: P0 盟区 — 确认以第三方库为主
- 采样 31 点: 75% third-party, 22% business-logic, 3% i18n
- **结论**: P0 无需进一步深入，核心业务逻辑全部在 6268469 之后

### 发现 2: P1 UI 下半部 — 权限/付费/Agent 选择器密集区
- isOlderCommercialUser: **7次**, isSaas: **10次**, bJ 枚举: **50+次**
- efi() Hook 完整实现 @8685035 (L1 React 层) — 见 [Commercial] 域
- AgentSelect, Subscription, Permission, Alert/Modal/Toast 大量使用

### 发现 3: 命令注册层 — 26 命令 + 1 适配器
- 高价值: sendToAgentNonBlocking (后台续接替代), openUsageLimitModalAICompletion (用量限制拦截)
- 完整列表见 P1 盲区扫描最终版

### 发现 4: computeSelectedModelAndMode 完整决策链 ⭐⭐⭐⭐⭐
- 函数位置: **@7213504** (注意偏移量变化!)
- Step 3: `(isOlderCommercialUser||isSaas) && solo_coder/builder` → 强制 Max
- **重要发现**: 当前代码可能已写死 `||true`！
- **force-max-mode 补丁最佳方案**: 方案 A 注入 isOlderCommercialUser/isSaas 强制 true

### 发现 5: ContactType + bypass-usage-limit 映射
- ContactType @55561: 仅 FreeNewSubscriptionUser* 子类型 (不是用户身份枚举!)
- 用户身份用 **bJ 枚举**
- 三组独立错误码定义 (kg/eA/其他)
- isFreeUser 仅 **2处**: @8685035 (定义) + @8702707 (消费)

### 发现 6: IStuckDetectionService + IAutoAcceptService
- IStuckDetectionService: 超时 60s, 1 个调用点 @7540436
- IAutoAcceptService: **code review 自动接受** (≠ autoConfirm!)
- autoConfirm vs autoAccept 是不同功能，不能互相替代

---

## [2026-04-27 01:10] desktop-modules 盲区扫描

> **核心结论: desktop-modules 不需要打补丁！所有权限/限制逻辑仅在 ai-modules-chat 中。**

| 维度 | ai-modules-chat | desktop-modules |
|------|-----------------|-----------------|
| 大小 | 10,487,294 字符 | 10,488,409 字符 |
| 格式 | UMD define | CJS/UMD !function |
| 内容 | AI 核心逻辑 | UI 编辑器外壳 |
| 权限代码 | 全部 | **无** |

**关键发现: efi() 命名碰撞!** — 两个完全不同的函数:
- chat 的 efi(): 权限判断 Hook (17 个关键字段)
- desk 的 efi(): Zod schema builder (毫无关系)

**9 个补丁完整性评估**: 全部安全 ✅ — desktop 不含任何 AI 权限逻辑

---

## [2026-04-27 16:30] P0 盲区深度探索 — 业务逻辑全量扫描

> P0 范围 (54415-6268469, ~5.9MB) 系统性业务逻辑搜索

### 结论: P0 盲区确认
**所有 DI 注册(uJ)、DI 注入(uX)、核心业务方法(resumeChat/sendChatMessage/provideUserResponse)、服务接口(Symbol)均不在 P0 范围内**。

P0 的业务逻辑主要是:
1. 数据结构定义 (错误码/枚举/类型)
2. API 端点配置 (JSON 静态数据 @5870417)
3. VS Code 框架代码 (CommandsRegistry/Protocol)
4. 上传/遥测/性能追踪基础设施
5. i18n 本地化数据 (3 种格式 × 3 种语言)
6. DevTool 通信桥

### 核心发现: API 端点完整配置 JSON @5870417 ⭐⭐⭐⭐⭐
- byteGate: `https://bytegate-sg.byteintlapi.com`
- copilotDomain: `https://copilot.byteintl.net` (CN/SG/US)
- externalCopilotDomains: `https://a0ai-api.byteintlapi.com`
- mcpPlugin: `api.trae.ai` / `ide-market-us.tiktok-row.net`

### 核心发现: ContactType 枚举 @55561 ⭐⭐⭐⭐⭐
- 30+ 值: FreeNewSubscriptionUser*(1-10), FreeOldSubscriptionUser*(11-20), Pro*(21-32)
- **补丁意义**: bypass-usage-limit 补丁的关键数据结构

### 核心发现: AbstractBootService @2535031 ⭐⭐⭐⭐
- 启动配置服务: getAgentConfig/getCKGConfig/getCdnLocation/getMcpConfig 等
- IPC_SERVICE_NAME = "BootService"

### 核心发现: icube_devtool_bridge @5890559 ⭐⭐⭐⭐
- VS Code WebView ↔ 主进程通信桥
- window.vscodeService 全局单例

---

## 📇 按域搜索索引

### [DI] 依赖注入
- DI 容器系统完整映射 @6268469 ⭐⭐⭐⭐⭐
- DI Token 注册表 Symbol.for 54个 @6473533 ⭐⭐⭐⭐⭐
- DI Token 注册表 Symbol 52个 @7087490 ⭐⭐⭐⭐
- uj.getInstance().resolve() 45次调用 @6268469 ⭐⭐⭐⭐⭐
- uJ 装饰器 51服务注册 @7017457 ⭐⭐⭐⭐⭐
- DI 依赖图核心服务注入关系 @6268469 ⭐⭐⭐⭐⭐
- Symbol.for→Symbol 迁移完整映射 @7092843 ⭐⭐⭐⭐⭐
- BR和FX不是DI Token(纠正) @7551518 ⭐⭐⭐⭐⭐
- 补丁变量验证结果 @6275751 ⭐⭐⭐⭐
- createDecorator DI装饰器工厂 @853508 ⭐⭐⭐⭐⭐
- ServiceCollection+InstantiationService @1227889 ⭐⭐⭐⭐
- VS Code DI注入机制 __instance__ @2607740 ⭐⭐⭐⭐⭐
- 31个I*Service DI Token完整映射 @7182322 ⭐⭐⭐⭐⭐
- eY0模块入口对象 registerAdapter @10476892 ⭐⭐⭐⭐⭐

### [SSE] 流管道
- SSE流管道完整拓扑 @7300000 ⭐⭐⭐⭐⭐
- SSE事件枚举13种 @7300000 ⭐⭐⭐⭐⭐
- EventHandlerFactory中央调度器 @7300000 ⭐⭐⭐⭐⭐
- ChatStreamService层级 Bo/Bv/BE @7524723 ⭐⭐⭐⭐⭐
- SSE流生命周期 @7300000 ⭐⭐⭐⭐⭐
- 15个Parser类完整列表 @7300000 ⭐⭐⭐⭐⭐
- 错误分发关键条件 @7542473 ⭐⭐⭐⭐⭐
- PlanItemStreamParser @7502500 ⭐⭐⭐⭐
- ErrorStreamParser zU @7508572 ⭐⭐⭐⭐⭐
- TaskAgentMessageParser.parse @7615777 ⭐⭐⭐⭐
- SSE事件枚举纠正 Ot.前缀 @7300000 ⭐⭐⭐

### [Store] 状态管理
- Zustand Store架构完整映射8个 @7087490 ⭐⭐⭐⭐⭐
- 两种currentSession模式 @7087490 ⭐⭐⭐⭐⭐
- setCurrentSession调用点 @7087490 ⭐⭐⭐⭐⭐
- 关键subscribe调用3处 @7584046 ⭐⭐⭐⭐⭐
- 无Immer使用展开运算符 @7087490 ⭐⭐⭐⭐⭐
- Store-React连接uB Hook @6270579 ⭐⭐⭐⭐⭐
- confirm_info流经PlanItemStreamParser @7502500 ⭐⭐⭐⭐⭐
- IEntitlementStore Nu类 @7264682 ⭐⭐⭐⭐⭐
- ICredentialStore MX类 @7154491 ⭐⭐⭐⭐
- IModelStore k2类 @7191708 ⭐⭐⭐⭐⭐

### [Error] 错误处理
- 错误处理系统完整映射 @54000 ⭐⭐⭐⭐⭐
- kg错误码枚举完整列表56个 @54415 ⭐⭐⭐⭐⭐
- 错误传播路径3条 PATH A/B/C @54000 ⭐⭐⭐⭐⭐
- stopStreaming沉默杀手 @7538139 ⭐⭐⭐⭐⭐
- agentProcess v3 resumeChat @7502500 ⭐⭐⭐⭐⭐
- 付费限制错误码纠正 4008/4009/700 @8707858 ⭐⭐⭐⭐⭐
- kg错误码枚举扩展56个 @54415 ⭐⭐⭐⭐
- 变量重命名J→K(纠正:J仍为当前名) @8707716 ⭐⭐⭐⭐⭐
- efg可恢复错误列表14个 @8705916 ⭐⭐⭐⭐
- J变量完整定义含5个错误码 @8708083 ⭐⭐⭐⭐
- X变量新发现 MODEL_NOT_EXISTED @8708083 ⭐⭐⭐
- ee变量配额限制标志 @8707858 ⭐⭐⭐⭐
- IStuckDetectionService @7537021 ⭐⭐⭐⭐⭐
- 错误码两套体系 服务端o+客户端eA @51947 ⭐⭐⭐⭐⭐

### [React] 组件层
- React组件层级完整映射 @8000000+ ⭐⭐⭐⭐⭐
- 三层架构L1/L2/L3 @8000000+ ⭐⭐⭐⭐⭐
- 组件树完整结构 @8000000+ ⭐⭐⭐⭐⭐
- 17+Alert渲染点 @8700000 ⭐⭐⭐⭐⭐
- 冻结行为rAF→Scheduler暂停 @8000000+ ⭐⭐⭐⭐⭐
- L1冻结原则2026-04-22验证 @8709284 ⭐⭐⭐⭐⭐
- sX().memo(Jj)自动续接宿主 @8709284 ⭐⭐⭐⭐
- egR RunCommandCard组件 @8635000 ⭐⭐⭐⭐
- 16个React组件导出列表 @10490209 ⭐⭐⭐⭐
- ChatInput组件 @9015579 ⭐⭐⭐⭐
- FileDiff组件 @8932385 ⭐⭐⭐
- ToolCall组件 @9067039 ⭐⭐⭐⭐
- confirm_status UI引用 @8975688 ⭐⭐⭐⭐
- P1盲区组成分析 @8930000 ⭐⭐⭐⭐

### [Event] 事件总线
- 事件总线与遥测系统完整映射 @7458679 ⭐⭐⭐⭐⭐
- TEA遥测事件 teaEventChatFail @7458679 ⭐⭐⭐⭐⭐
- SSE事件总线EventHandlerFactory @7300000 ⭐⭐⭐⭐⭐
- Zustand Store订阅3处 @7584046 ⭐⭐⭐⭐⭐
- DOM事件监听cancelEventKey @7610443 ⭐⭐⭐⭐⭐
- 无Node.js EventEmitter @7300000 ⭐⭐⭐⭐⭐
- 补丁Hook点可行性评估 @7458679 ⭐⭐⭐⭐⭐
- HaltChainable事件链机制 @2317698 ⭐⭐⭐⭐⭐
- 5个新域候选 Network/Model/History/Auth/Telemetry ⭐⭐⭐⭐

### [IPC] 进程间通信
- IPC进程间通信完整映射 @7610443 ⭐⭐⭐⭐⭐
- 三层IPC架构 Server→Main→Renderer @7610443 ⭐⭐⭐⭐⭐
- Shell执行命令9个icube.shellExec @7610443 ⭐⭐⭐⭐⭐
- 主进程事件总线YTr/GZt @7610443 ⭐⭐⭐⭐⭐
- 取消机制cancelEventKey @7610443 ⭐⭐⭐⭐⭐
- 无ipcRenderer @7610443 ⭐⭐⭐⭐⭐
- 25个VS Code命令注册 @10477819 ⭐⭐⭐⭐⭐

### [Setting] 设置系统
- 设置系统完整映射 @7438613 ⭐⭐⭐⭐⭐
- AI工具调用设置4个key @7438613 ⭐⭐⭐⭐⭐
- 聊天工具设置3个key @7438613 ⭐⭐⭐⭐⭐
- 全局设置GlobalAutoApprove @7438613 ⭐⭐⭐⭐⭐
- ConfirmMode枚举已移除 @8069382 ⭐⭐⭐⭐⭐
- 无onDidChangeConfiguration @7438613 ⭐⭐⭐⭐⭐
- IModelTipConfigService @7268582 ⭐⭐⭐⭐⭐
- IPrivacyModeService @8036543 ⭐⭐⭐⭐⭐
- IContributionService @8095684 ⭐⭐⭐⭐⭐

### [Sandbox] 沙箱
- 沙箱与命令执行管道完整映射 @8069382 ⭐⭐⭐⭐⭐
- BlockLevel枚举6值 @8069382 ⭐⭐⭐⭐⭐
- AutoRunMode枚举5值 @8069382 ⭐⭐⭐⭐⭐
- getRunCommandCardBranch决策矩阵 @8069620 ⭐⭐⭐⭐⭐
- 命令执行管道完整流程 @7318521 ⭐⭐⭐⭐⭐
- SAFE_RM沙箱安全规则 @8069382 ⭐⭐⭐⭐⭐
- provideUserResponse调用点4处 @7502574 ⭐⭐⭐⭐⭐
- IAutoAcceptService @8039940 ⭐⭐⭐⭐⭐
- IRunCommandFeatureService @8063616 ⭐⭐⭐⭐⭐
- IFileOpFeatureService @8086208 ⭐⭐⭐⭐⭐
- IFileDiffTruncationService @7562542 ⭐⭐⭐⭐⭐
- IFileDiffService @7565469 ⭐⭐⭐⭐⭐

### [MCP] 工具调用
- MCP/工具调用系统完整映射 @41400 ⭐⭐⭐⭐⭐
- ToolCallName枚举80+工具 @7076154 ⭐⭐⭐⭐⭐
- ToolCallName完整枚举38个 @40836 ⭐⭐⭐⭐⭐
- 工具调用生命周期8步 @7318521 ⭐⭐⭐⭐⭐
- confirm_info数据结构 @7502500 ⭐⭐⭐⭐⭐
- MCP集成run_mcp共享确认管道 @41400 ⭐⭐⭐⭐⭐
- UserConfirmStatusEnum @44416 ⭐⭐⭐⭐⭐

### [Commercial] 商业权限
- ICommercialPermissionService完整方法映射 @7267682 ⭐⭐⭐⭐⭐
- isFreeUser完整实现链efi() @8687513 ⭐⭐⭐⭐⭐
- IEntitlementStore完整状态结构 @7264682 ⭐⭐⭐⭐⭐
- ICredentialStore完整状态结构 @7154491 ⭐⭐⭐⭐
- 付费限制错误码纠正 @8707858 ⭐⭐⭐⭐⭐
- 用量配额相关代码8处 @8707858 ⭐⭐⭐⭐
- efr枚举免费用户配额状态20个 @55610 ⭐⭐⭐⭐
- 新补丁目标候选清单6个 @7267682 ⭐⭐⭐⭐
- 跳过付费限制补丁可行性 @7267682 ⭐⭐⭐⭐
- ICommercialApiService @7559975 ⭐⭐⭐⭐⭐
- bJ枚举用户身份类型7值 @6479431 ⭐⭐⭐⭐⭐
- bK枚举用户scope 3值 @6479143 ⭐⭐⭐⭐⭐

### [Docset] 文档集
- ai.IDocsetService @3546309 ⭐⭐⭐⭐⭐
- ai.IDocsetStore @7244780 ⭐⭐⭐⭐⭐
- ai.IDocsetCkgLocalApiService @7715114 ⭐⭐⭐⭐⭐
- ai.IDocsetOnlineApiService @7720270 ⭐⭐⭐⭐⭐
- ai.IWebCrawlerFacade @7725207 ⭐⭐⭐⭐⭐
- IKnowledgesTaskService @7589570 ⭐⭐⭐⭐⭐
- IKnowledgesPersistenceService @8113678 ⭐⭐⭐⭐⭐
- IKnowledgesStagingService @8122442 ⭐⭐⭐⭐⭐
- IKnowledgesFeatureService @8130079 ⭐⭐⭐⭐⭐
- IKnowledgesSourceMaterialService @8132725 ⭐⭐⭐⭐⭐
- IKnowledgesNotificationService @8139976 ⭐⭐⭐⭐⭐
- IKnowledgesStatusBarService @8186683 ⭐⭐⭐⭐⭐
- icube.knowledges.* 7个命令注册 @10487427 ⭐⭐⭐⭐⭐

### [Model] 模型选择
- 模型选择限制代码 @7185314 ⭐⭐⭐⭐⭐
- kG枚举模式类型 Manual/Auto/Max @7185314 ⭐⭐⭐⭐⭐
- kH枚举模型层级3级 @7185314 ⭐⭐⭐⭐⭐
- IModelService NR类 @7271527 ⭐⭐⭐⭐⭐
- IModelStorageService @7182365 ⭐⭐⭐⭐⭐
- IModelStore k2类 @7191708 ⭐⭐⭐⭐⭐
- computeSelectedModelAndMode逻辑 @7216438 ⭐⭐⭐⭐⭐
- force-max-mode补丁候选 @7216438 ⭐⭐⭐
- bypass-free-user-model-notice候选 @7280685 ⭐⭐⭐⭐
- IModeStorageService @7194537 ⭐⭐⭐⭐⭐

---

## 📇 按功能索引

### 确认/自动确认
- DG.parse L3数据源自动确认 @7318521 L3 ⭐⭐⭐⭐⭐
- PlanItemStreamParser._handlePlanItem @7502500 L2 ⭐⭐⭐⭐⭐
- knowledge分支provideUserResponse @7502574 L2 ⭐⭐⭐⭐⭐
- else分支provideUserResponse @7503319 L2 ⭐⭐⭐⭐⭐
- data-source-auto-confirm补丁 @7323241 L3 ⭐⭐⭐
- auto-confirm-commands补丁 @7502500 L2 ⭐⭐⭐⭐⭐
- service-layer-runcommand-confirm补丁 @7502500 L2 ⭐⭐⭐⭐⭐
- getRunCommandCardBranch决策 @8069620 L1 ⭐⭐⭐⭐
- bypass-runcommandcard-redlist补丁 @8070328 L1 ⭐⭐
- egR RunCommandCard组件 @8635000 L1 ⭐⭐⭐⭐
- 自动确认useEffect @8640019 L1 ⭐⭐⭐
- UserConfirmStatusEnum @44416 枚举 ⭐⭐⭐⭐⭐
- confirm_info数据结构 @7502500 数据 ⭐⭐⭐⭐⭐
- AI.toolcall.confirmMode @7438613 配置 ⭐⭐⭐⭐⭐
- IAutoAcceptService @8039940 L2 ⭐⭐⭐⭐⭐

### 续接/自动续接
- teaEventChatFail最早错误信号 @7458679 L2 ⭐⭐⭐⭐⭐
- stopStreaming沉默杀手 @7538139 L2 ⭐⭐⭐⭐⭐
- _aiAgentChatService.resumeChat @7540953 L2 ⭐⭐⭐⭐⭐
- createStream中resumeChat蓝图 @7540700 L2 ⭐⭐⭐⭐
- subscribe#8消息数变化 @7588518 L2 ⭐⭐⭐⭐
- efg可恢复错误列表14个 @8705916 L1 ⭐⭐⭐⭐⭐
- J变量可续接错误标志 @8707716 L1 ⭐⭐⭐⭐⭐⭐
- if(V&&J) Alert分支 @8702300 L1 ⭐⭐⭐⭐
- guard-clause-bypass补丁 !q&&!J @8712898 L1 ⭐⭐⭐⭐
- auto-continue-thinking补丁迭代v3-v17 ⭐⭐⭐⭐⭐⭐
- v8架构缺陷根因 @7502500 分析 ⭐⭐⭐⭐⭐
- v10 SSE事件两条路径 @7508572 ⭐⭐⭐
- v11 React Scheduler后台冻结+store.subscribe @7502500 ⭐⭐⭐⭐
- v12 TaskAgentMessageParser.parse变异源头 @7615777 ⭐⭐⭐⭐
- v13 teaEventChatFail后台触发成功 @7458679 L2 ⭐⭐⭐⭐⭐
- v14 Hybrid flag+visibilitychange @7458679 L2 ⭐⭐⭐⭐⭐
- v17 Final 历史性突破 @7458679 L2 ⭐⭐⭐⭐⭐⭐
- IStuckDetectionService @7537021 L2 ⭐⭐⭐⭐⭐

### 沙箱/命令执行
- BlockLevel枚举6值 @8069382 L1 ⭐⭐⭐⭐⭐⭐
- AutoRunMode枚举5值 @8069382 L1 ⭐⭐⭐⭐⭐⭐
- getRunCommandCardBranch决策矩阵 @8069620 L1 ⭐⭐⭐⭐
- provideUserResponse知识分支 @7502574 L2 ⭐⭐⭐⭐⭐
- provideUserResponse其他分支 @7503319 L2 ⭐⭐⭐⭐⭐
- icube.shellExec.* 9个命令 @7610443 IPC ⭐⭐⭐⭐⭐⭐
- SAFE_RM沙箱安全规则 @8069382 配置 ⭐⭐⭐⭐⭐⭐
- IRunCommandFeatureService @8063616 L2 ⭐⭐⭐⭐⭐
- IFileOpFeatureService @8086208 L2 ⭐⭐⭐⭐⭐
- IFileDiffTruncationService @7562542 L2 ⭐⭐⭐⭐⭐
- IFileDiffService @7565469 L2 ⭐⭐⭐⭐⭐

### 错误处理
- kg错误码枚举完整56个 @54415 枚举 ⭐⭐⭐⭐⭐
- efg可恢复错误列表14个 @8705916 L1 ⭐⭐⭐⭐⭐
- J变量5个错误码 @8707716 L1 ⭐⭐⭐⭐⭐⭐
- ee变量配额限制2个 @8707858 L1 ⭐⭐⭐⭐⭐
- X变量MODEL_NOT_EXISTED @8708083 L1 ⭐⭐⭐
- handleCommonError @7300455 L2 ⭐⭐⭐⭐⭐⭐
- teaEventChatFail @7458679 L2 ⭐⭐⭐⭐⭐⭐
- ErrorStreamParser zU @7508572 L2 ⭐⭐⭐⭐⭐⭐
- getErrorInfoWithError @7513080 L2 ⭐⭐⭐⭐⭐
- _onError(e,t,i) @7528742 L2 ⭐⭐⭐⭐⭐
- TaskAgentMessageParser.parse @7615777 L2 ⭐⭐⭐⭐⭐
- 17+Alert渲染点 @8700000 L1 ⭐⭐⭐⭐⭐⭐
- 错误传播路径3条 PATH A/B/C ⭐⭐⭐⭐⭐⭐
- 错误码两套体系 服务端o+客户端eA @51947 ⭐⭐⭐⭐⭐⭐

### 设置/配置
- AI.toolcall.confirmMode @7438613 ⭐⭐⭐⭐⭐⭐
- AI.toolcall.v2.command.* @7438600 ⭐⭐⭐⭐⭐⭐
- chat.tools.* 3个key @7438613 ⭐⭐⭐⭐⭐⭐
- GlobalAutoApprove @7438613 ⭐⭐⭐⭐⭐
- ConfirmMode枚举已移除 @8069382 ⭐⭐⭐⭐⭐⭐
- IModelTipConfigService @7268582 ⭐⭐⭐⭐⭐
- IPrivacyModeService @8036543 ⭐⭐⭐⭐⭐
- IContributionService @8095684 ⭐⭐⭐⭐⭐
- IModeStorageService @7194537 ⭐⭐⭐⭐⭐

### 商业权限/付费限制
- ICommercialPermissionService NS类6方法 @7267682 L2 ⭐⭐⭐⭐⭐⭐
- isFreeUser efi() Hook @8687513 L1 ⭐⭐⭐⭐⭐⭐
- IEntitlementStore Nu类 @7264682 L2 ⭐⭐⭐⭐⭐⭐
- ICredentialStore MX类 @7154491 L2 ⭐⭐⭐⭐⭐
- bJ枚举用户身份7值 @6479431 枚举 ⭐⭐⭐⭐⭐⭐
- bK枚举用户scope 3值 @6479143 枚举 ⭐⭐⭐⭐⭐⭐
- 付费限制错误码纠正4008/4009/700 @8707858 ⭐⭐⭐⭐⭐⭐
- ee变量配额限制 @8707858 L1 ⭐⭐⭐⭐⭐
- efr枚举免费用户配额20个 @55610 枚举 ⭐⭐⭐⭐⭐
- bypass-commercial-permission补丁候选 @7267682 L2 ⭐⭐⭐⭐⭐⭐
- bypass-usage-limit补丁候选 @8707858 L1 ⭐⭐⭐⭐⭐
- ICommercialApiService @7559975 L2 ⭐⭐⭐⭐⭐
- PREMIUM_MODE_USAGE_LIMIT Alert @8719877 L1 ⭐⭐⭐⭐⭐
- CLAUDE_MODEL_FORBIDDEN Alert @8717132 L1 ⭐⭐⭐⭐⭐
- FIREWALL_BLOCKED Alert @8718083 L1 ⭐⭐⭐⭐

### 模型选择
- kG枚举模式类型 @7185314 枚举 ⭐⭐⭐⭐⭐⭐
- kH枚举模型层级 @7185314 枚举 ⭐⭐⭐⭐⭐⭐
- IModelService NR类 @7271527 L2 ⭐⭐⭐⭐⭐⭐
- IModelStorageService @7182365 L2 ⭐⭐⭐⭐⭐⭐
- IModelStore k2类 @7191708 L2 ⭐⭐⭐⭐⭐⭐
- computeSelectedModelAndMode @7216438 L2 ⭐⭐⭐⭐⭐⭐
- force-max-mode补丁候选 @7216438 L2 ⭐⭐⭐
- bypass-free-user-model-notice候选 @7280685 L2 ⭐⭐⭐⭐⭐
- Max Mode tooltip @9441960 L1 ⭐⭐⭐

---

## 📇 按偏移量范围索引

### 0-1M (0-1000000)
- @0 AMD define入口+AIScene枚举 ⭐⭐⭐⭐⭐
- @117 Object.defineProperty webpack bootstrap ⭐⭐⭐⭐
- @142 __esModule webpack模块 ⭐⭐⭐⭐
- @888 TeaReporter类 ⭐⭐⭐⭐
- @40836 ToolCallName完整枚举38个 ⭐⭐⭐⭐⭐
- @44416 UserConfirmStatusEnum ⭐⭐⭐⭐⭐
- @46816 RunningStatus枚举Io ⭐⭐⭐⭐⭐
- @47202 ChatTurnStatus枚举bQ ⭐⭐⭐⭐
- @51947 服务端错误码枚举o ⭐⭐⭐⭐⭐
- @54000 kg错误码枚举第一段 ⭐⭐⭐⭐
- @54415 kg错误码枚举完整列表 ⭐⭐⭐⭐⭐
- @55610 efr枚举免费用户配额状态 ⭐⭐⭐⭐
- @853508 createDecorator DI装饰器工厂 ⭐⭐⭐⭐⭐
- @1197068 DcsParser终端转义序列 ⭐⭐⭐
- @1227889 ServiceCollection+InstantiationService ⭐⭐⭐⭐
- @2317698 HaltChainable事件链机制 ⭐⭐⭐⭐⭐
- @2539813 CommandsRegistry+ICommandService ⭐⭐⭐⭐⭐
- @2540057 registerCommand ⭐⭐⭐⭐⭐
- @2607740 VS Code DI注入__instance__ ⭐⭐⭐⭐⭐
- @3546309 ai.IDocsetService ⭐⭐⭐⭐⭐⭐
- @435246 webpack内嵌runtime ⭐⭐⭐

### 1M-5M (1000000-5000000)
- @1802391 styled-components inject(非DI) ⭐⭐
- @2534601 API路由机制iCubeApi/ugApi/iCubeAgentApi ⭐⭐⭐⭐⭐
- @255810 TEA上传统计mcs端点 ⭐⭐⭐
- @2665348 AI.NEED_CONFIRM枚举 ⭐⭐
- @2796260 Pause/Send按钮ei组件 ⭐⭐⭐
- @3211326 needConfirm Zustand store ⭐⭐⭐
- @5870448 ByteGate API网关 ⭐⭐⭐⭐
- @5871017 Slardar PC监控 ⭐⭐⭐⭐

### 5M-8M (5000000-8000000)
- @6268469 DI 容器类uj ⭐⭐⭐⭐⭐⭐
- @6270579 uB useInject Hook+hX ⭐⭐⭐⭐⭐
- @6273630 uj class定义 ⭐⭐⭐⭐⭐
- @6275751 uj.getInstance ⭐⭐⭐⭐⭐
- @6473533 bY LogService Token ⭐⭐⭐⭐⭐⭐
- @6479143 bK枚举用户scope ⭐⭐⭐⭐⭐⭐
- @6479431 bJ枚举用户身份类型 ⭐⭐⭐⭐⭐⭐
- @668815 AWS凭证处理 ⭐⭐⭐
- @7015771 Ei CredentialFacade Token ⭐⭐⭐⭐⭐⭐
- @7017457 uJ装饰器服务注册开始 ⭐⭐⭐⭐⭐
- @7061974 Symbol.for注册开始 ⭐⭐⭐⭐⭐
- @7076154 ToolCallName枚举第二段 ⭐⭐⭐⭐⭐
- @7087490 xC SessionStore Token ⭐⭐⭐⭐⭐
- @7092843 Symbol("ISessionStore") ⭐⭐⭐⭐
- @7126296 xJ EditorFacade Token ⭐⭐⭐⭐⭐
- @7134895 Ma TeaFacade Token(旧) ⭐⭐⭐⭐⭐
- @7140149 ITeaFacade Symbol.for ⭐⭐⭐⭐⭐⭐
- @7148876 bY LogService注册 ⭐⭐⭐⭐⭐
- @7150072 M0 SessionService Token ⭐⭐⭐⭐⭐⭐
- @7152097 SessionService注册Ci ⭐⭐⭐⭐⭐
- @7154464 ICredentialStore Token ⭐⭐⭐⭐⭐
- @7154491 MX CredentialStore类 ⭐⭐⭐⭐⭐
- @7160512 eA客户端错误码枚举 ⭐⭐⭐⭐⭐
- @7161400 kg错误码枚举第二段 ⭐⭐⭐
- @7177093 kv ModelService Token ⭐⭐⭐⭐
- @7182322 IModelService Symbol.for ⭐⭐⭐⭐⭐⭐
- @7185314 kG/kH枚举模式+模型层级 ⭐⭐⭐⭐⭐⭐
- @7186457 k1 ModelStore Token ⭐⭐⭐⭐⭐
- @7197015 ICommercialPermissionService Token ⭐⭐⭐⭐⭐
- @7203850 IN SessionRelationStore Token ⭐⭐⭐⭐⭐
- @7216438 computeSelectedModelAndMode ⭐⭐⭐⭐⭐⭐
- @7221939 I2 InlineSessionStore Token ⭐⭐⭐⭐⭐
- @7224039 I7 ProjectStore ⭐⭐⭐
- @7248275 TG AgentExtensionStore ⭐⭐⭐
- @7258315 Na SkillStore ⭐⭐⭐
- @7259427 Nc EntitlementStore Token ⭐⭐⭐⭐⭐
- @7264682 Nu EntitlementStore类 ⭐⭐⭐⭐⭐⭐
- @7267682 NS ICommercialPermissionService类 ⭐⭐⭐⭐⭐⭐
- @7280685 checkFreeUserPremiumModelNotice ⭐⭐⭐⭐
- @7300000 EventHandlerFactory Bt ⭐⭐⭐⭐⭐⭐
- @7300455 handleCommonError ⭐⭐⭐⭐⭐
- @7300921 De.handleError ⭐⭐⭐⭐⭐
- @7314000 MetadataParser+UserMessageContextParser ⭐⭐⭐⭐
- @7318521 DG.parse数据解析层 ⭐⭐⭐⭐⭐⭐
- @7322410 NotificationStreamParser ⭐⭐⭐⭐⭐
- @7323241 data-source-auto-confirm补丁 ⭐⭐⭐
- @7327208 IAgentService Symbol ⭐⭐⭐⭐
- @7438613 AI.toolcall.confirmMode ⭐⭐⭐⭐⭐⭐
- @7450318 jN IPlanService Token ⭐⭐⭐⭐
- @7456691 IPlanService Symbol.for ⭐⭐⭐⭐
- @7458679 teaEventChatFail ⭐⭐⭐⭐⭐
- @7482422 FeeUsageStreamParser za ⭐⭐⭐⭐
- @7497479 TextMessageChatStreamParser ⭐⭐⭐⭐⭐
- @7502500 PlanItemStreamParser._handlePlanItem ⭐⭐⭐⭐
- @7503299 PlanItemStreamParser DI Token ⭐⭐⭐⭐
- @7508572 ErrorStreamParser zU ⭐⭐⭐⭐⭐⭐
- @7511057 DoneStreamParser zW ⭐⭐⭐⭐
- @7512721 QueueingStreamParser zV ⭐⭐⭐⭐
- @7513080 getErrorInfoWithError(e) ⭐⭐⭐⭐
- @7515007 UserMessageStreamParser zJ ⭐⭐⭐⭐⭐⭐
- @7516765 TokenUsageStreamParser z2 ⭐⭐⭐⭐⭐⭐
- @7517392 ContextTokenUsageStreamParser z3 ⭐⭐⭐⭐⭐⭐
- @7518028 SessionTitleMessageStreamParser z8 ⭐⭐⭐⭐⭐⭐
- @7524723 Bs class (ChatParserContext) ⭐⭐⭐
- @7528742 _onError(e,t,i) ⭐⭐⭐
- @7533741 ChatStreamService._stopStreaming实现 ⭐⭐⭐
- @7537021 IStuckDetectionService ⭐⭐⭐⭐⭐
- @7538139 stopStreaming沉默杀手 ⭐⭐⭐⭐⭐
- @7540700 createStream+resumeChat 蓝图 ⭐⭐⭐
- @7540953 _aiAgentChatService.resumeChat() ⭐⭐⭐⭐
- @7541121 ISideChatStreamService ⭐⭐⭐⭐
- @7543791 StoreService.stopStreaming ⭐⭐⭐
- @7545196 BO SessionServiceV2 Token ⭐⭐⭐⭐
- @7548009 IInlineChatStreamService ⭐⭐⭐⭐
- @7559975 ICommercialApiService ⭐⭐⭐⭐
- @7562542 IFileDiffTruncationService ⭐⭐⭐⭐
- @7565469 IFileDiffService ⭐⭐⭐⭐
- @7574983 IPastChatExporter ⭐⭐⭐⭐
- @7584046 subscribe#1消息数+会话ID ⭐⭐⭐⭐
- @7588518 subscribe#8消息数变化 ⭐⭐⭐⭐
- @7605848 runningStatusMap subscribe ⭐⭐⭐⭐
- @7610443 F3/sendToAgentBackground ⭐⭐⭐⭐
- @7614717 ResumeChat服务端方法调用 ⭐⭐⭐⭐
- @7615777 TaskAgentMessageParser.parse() ⭐⭐⭐⭐
- @7715114 ai.IDocsetCkgLocalApiService ⭐⭐⭐⭐⭐
- @7720270 ai.IDocsetOnlineApiService ⭐⭐⭐⭐⭐
- @7725207 ai.IWebCrawlerFacade ⭐⭐⭐⭐⭐
- @7766628 ITaskListApiService ⭐⭐⭐⭐
- @7892948 IASRService ⭐⭐⭐⭐
- @7903529 IHuoshanAsrClientService ⭐⭐⭐⭐
- @8027658 IAWSASRClientService ⭐⭐⭐⭐
- @8036543 IPrivacyModeService ⭐⭐⭐⭐
- @8039940 IAutoAcceptService ⭐⭐⭐⭐
- @8063616 IRunCommandFeatureService ⭐⭐⭐⭐
- @8086208 IFileOpFeatureService ⭐⭐⭐⭐
- @8095684 IContributionService ⭐⭐⭐⭐
- @8113678 IKnowledgesPersistenceService ⭐⭐⭐⭐
- @8122442 IKnowledgesStagingService ⭐⭐⭐⭐
- @8130079 IKnowledgesFeatureService ⭐⭐⭐⭐
- @8132725 IKnowledgesSourceMaterialService ⭐⭐⭐⭐
- @8139976 IKnowledgesNotificationService ⭐⭐⭐⭐
- @8186683 IKnowledgesStatusBarService ⭐⭐⭐⭐

### 8M-10M+ (8000000-EOF)
- @8063616 IRunCommandFeatureService ⭐⭐⭐⭐⭐
- @8069382 BlockLevel/AutoRunMode枚举 ⭐⭐⭐⭐⭐⭐
- @8069620 getRunCommandCardBranch ⭐⭐⭐⭐
- @8070328 bypass-runcommandcard-redlist补丁 ⭐⭐
- @8078831 P7.Default RunCommandCard分支 ⭐⭐⭐
- @8081330 Cr.AutoRunMode枚举 ⭐⭐⭐⭐
- @8081401 Cr.BlockLevel枚举 ⭐⭐⭐⭐
- @8086208 IFileOpFeatureService ⭐⭐⭐⭐
- @8095684 IContributionService ⭐⭐⭐⭐
- @8113678 IKnowledgesPersistenceService ⭐⭐⭐⭐
- @8122442 IKnowledgesStagingService ⭐⭐⭐⭐
- @8130079 IKnowledgesFeatureService ⭐⭐⭐⭐
- @8132725 IKnowledgesSourceMaterialService ⭐⭐⭐⭐
- @8139976 IKnowledgesNotificationService ⭐⭐⭐⭐
- @8186683 IKnowledgesStatusBarService ⭐⭐⭐⭐
- @8629200 UI确认状态检查 ⭐⭐⭐
- @8635000 egR (RunCommandCard)组件 ⭐⭐⭐⭐
- @8636941 ey useMemo (有效确认状态) ⭐⭐⭐
- @8637300 confirm_info解构 ⭐⭐⭐
- @8640019 自动确认useEffect ⭐⭐⭐
- @8687513 efi() Hook isFreeUser计算 ⭐⭐⭐⭐⭐⭐
- @8688095 isFreeUser=n计算 ⭐⭐⭐⭐
- @8692994 usageLimitConfig配额限制配置 ⭐⭐⭐
- @8695303 efg可恢复错误列表(新偏移) ⭐⭐⭐⭐
- @8696378 J变量可续接错误标志 ⭐⭐⭐
- @8697580 ec callback (retry/resume) ⭐⭐⭐⭐
- @8697620 ed callback ("继续"按钮) ⭐⭐⭐⭐
- @8700000 ErrorMessageWithActions开始 ⭐⭐⭐
- @8702300 if(V&&J) Alert分支 ⭐⭐⭐
- @8705916 efg可恢复错误列表(新偏移) ⭐⭐⭐⭐⭐
- @8707613 变量重命名J→K区域 ⭐⭐⭐⭐⭐
- @8707716 J=!![定义 ⭐⭐⭐⭐⭐⭐
- @8707777 J=!![位置(交叉验证) ⭐⭐⭐⭐
- @8707858 ee配额限制标志 ⭐⭐⭐⭐⭐
- @8709284 sX().memo(Jj)组件 ⭐⭐⭐⭐
- @8713483 if(V&&J)位置(交叉验证) ⭐⭐⭐⭐⭐⭐
- @8717132 CLAUDE_MODEL_FORBIDDEN Alert ⭐⭐⭐⭐
- @8718083 FIREWALL_BLOCKED Alert ⭐⭐⭐
- @8719877 PREMIUM/STANDARD_MODE_USAGE_LIMIT Alert ⭐⭐⭐⭐
- @8930000-8970000 Browser Action渲染 ⭐⭐⭐
- @8932385 FileDiff组件 ⭐⭐⭐
- @8975688 confirm_status UI引用 ⭐⭐⭐⭐
- @8981240 AutoRunSetting sX().createElement ⭐⭐⭐
- @9015579 ChatInput组件 ⭐⭐⭐⭐
- @9067039 ToolCall组件 ⭐⭐⭐⭐
- @9186206 useState推理内容组件 ⭐⭐⭐
- @9389825 TaskCard sX().createElement ⭐⭐⭐
- @9441960 MaxMode tooltip sX().createElement ⭐⭐⭐
- @9799784 WorktreeHeader sX().createElement ⭐⭐⭐
- @9891397 IDSLAgentStore Symbol ⭐⭐⭐⭐
- @9910446 DEFAULT错误组件 ⭐⭐⭐
- @10471008 eYZ.onUsageLimit ⭐⭐⭐⭐
- @10476397 registerAdapter=uj.provide ⭐⭐⭐⭐⭐⭐
- @10476892 eY0模块入口对象 ⭐⭐⭐⭐⭐⭐
- @10477819-10489027 25个VS Code命令注册 ⭐⭐⭐⭐⭐⭐
- @10490209 16个React组件导出 ⭐⭐⭐⭐
- @10490600-10490721 IIFE闭合结构 ⭐⭐⭐⭐

---

## 📇 按 confidence 索引

### ⭐⭐⭐⭐⭐ High Confidence (已验证, 代码证据确凿)
- DI容器系统完整映射 @6268469
- DI Token注册表Symbol.for 54个 @6473533
- uj.getInstance().resolve() 45次调用 @6268469
- uJ装饰器51服务注册 @7017457
- DI依赖图核心服务注入关系 @6268469
- Symbol.for→Symbol 迁移完整映射 @7092843
- BR和FX不是DI Token(纠正) @7551518
- SSE流管道完整拓扑 @7300000
- SSE事件枚举13种 @7300000
- EventHandlerFactory中央调度器 @7300000
- ChatStreamService层级 @7524723
- 15个Parser类完整列表 @7300000
- 错误分发关键条件 @7542473
- Zustand Store架构完整映射 @7087490
- 错误处理系统完整映射 @54000
- kg错误码枚举完整列表 @54415
- 错误传播路径3条 @54000
- stopStreaming沉默杀手 @7538139
- React组件层级完整映射 @8000000+
- L1冻结原则验证 @8709284
- 事件总线与遥测系统完整映射 @7458679
- IPC进程间通信完整映射 @7610443
- 设置系统完整映射 @7438613
- 沙箱与命令执行管道完整映射 @8069382
- MCP/工具调用系统完整映射 @41400
- ICommercialPermissionService完整方法映射 @7267682
- isFreeUser完整实现链 @8687513
- IEntitlementStore完整状态结构 @7264682
- 付费限制错误码纠正 @8707858
- 变量重命名J→K(纠正) @8707716
- v8架构缺陷根因 @7502500
- v10 SSE事件两条路径 @7508572
- v11 React Scheduler后台冻结+store.subscribe @7502500
- v12 TaskAgentMessageParser.parse变异源头 @7615777
- v13 teaEventChatFail后台触发成功 @7458679
- v14 Hybrid flag+visibilitychange @7458679
- v17 Final 历史性突破 @7458679
- createDecorator DI装饰器工厂 @853508
- VS Code DI注入__instance__ @2607740
- HaltChainable事件链机制 @2317698
- 31个I*Service DI Token完整映射 @7182322
- eY0模块入口对象 @10476892
- 25个VS Code命令注册 @10477819
- ToolCallName完整枚举38个 @40836
- UserConfirmStatusEnum @44416
- 错误码两套体系 @51947
- IStuckDetectionService @7537021
- ISideChatStreamService @7541121
- IInlineChatStreamService @7548009
- ICommercialApiService @7559975
- IAutoAcceptService @8039940
- IRunCommandFeatureService @8063616
- IFileOpFeatureService @8086208
- IFileDiffTruncationService @7562542
- IFileDiffService @7565469
- IKnowledgesTaskService @7589570
- ai.IDocsetService @3546309
- ai.IDocsetStore @7244780
- ai.IDocsetCkgLocalApiService @7715114
- ai.IDocsetOnlineApiService @7720270
- ai.IWebCrawlerFacade @7725207
- kG/kH枚举模式+模型层级 @7185314
- IModelService NR类 @7271527
- computeSelectedModelAndMode @7216438
- bJ枚举用户身份类型 @6479431
- bK枚举用户scope @6479143

### ⭐⭐⭐⭐ Medium-High Confidence
- DI Token注册表Symbol 52个 @7087490
- 补丁变量验证结果 @6275751
- PlanItemStreamParser @7502500
- TaskAgentMessageParser.parse @7615777
- sX().memo(Jj)自动续接宿主 @8709284
- egR RunCommandCard组件 @8635000
- ChatInput组件 @9015579
- ToolCall组件 @9067039
- confirm_status UI引用 @8975688
- P1盲区组成分析 @8930000
- P0盲区组成分析 @54415
- ICredentialStore完整状态结构 @7154491
- 用量配额相关代码 @8707858
- efr枚举免费用户配额状态 @55610
- 新补丁目标候选清单6个 @7267682
- 跳过付费限制补丁可行性 @7267682
- 16个React组件导出 @10490209
- IIFE闭合结构 @10490600
- efg可恢复错误列表 @8705916
- ee变量配额限制 @8707858
- PREMIUM_MODE_USAGE_LIMIT Alert @8719877
- CLAUDE_MODEL_FORBIDDEN Alert @8717132
- IModelStore k2类 @7191708
- bypass-free-user-model-notice候选 @7280685
- IDSLAgentStore Symbol @9891397
- IPastChatExporter @7574983
- IKnowledgesPersistenceService @8113678
- IKnowledgesStagingService @8122442
- IKnowledgesFeatureService @8130079
- IKnowledgesSourceMaterialService @8132725
- IKnowledgesNotificationService @8139976
- IKnowledgesStatusBarService @8186683
- icube.knowledges.* 7个命令 @10487427
- IModeStorageService @7194537
- IModelTipConfigService @7268582
- IPrivacyModeService @8036543
- IContributionService @8095684
- kg错误码枚举扩展56个 @54415
- J变量完整定义含5个错误码 @8708083
- ErrorStreamParser zU @7508572

### ⭐⭐⭐ Medium Confidence
- data-source-auto-confirm补丁 @7323241
- bypass-runcommandcard-redlist补丁 @8070328
- subscribe#1消息数+会话ID @7584046
- subscribe#8消息数变化 @7588518
- runningStatusMap subscribe @7605848
- efg可恢复错误列表(旧偏移) @8695303
- J变量可续接错误标志(旧偏移) @8696378
- if(V&&J) Alert分支 @8702300
- FileDiff组件 @8932385
- 候选命令模式 @9971712
- DEFAULT错误组件 @9910446
- DcsParser终端转义序列 @1197068
- webpack内嵌runtime @435246
- force-max-mode补丁候选 @7216438
- bypass-usage-limit补丁候选 @8707858
- FIREWALL_BLOCKED Alert @871803
- 负面结果记录 @7267682
- X变量新发现 @8708083
- SSE事件枚举纠正Ot.前缀 @7300000
- API路由机制 @2534601

### ⭐⭐ Low Confidence (采样发现, 未深度验证)
- React 采样: useMemo/useEffect/useState/useRef 多处
- createElement 采样: 多处 sX().createElement 采样
- Bootstrap 采样: webpack runtime, DcsParser
- CSS: styled-components inject
- 第三方: radix-ui, Chevrotain

### ⭐⭐ Speculative (推测性, 需进一步验证)
- icube.shellExec — 已从当前版本移除 (EMPTY)
- styled-components inject @1802391 — 非 DI 注入

---

## 纠正事实库

> 记录探索过程中发现的错误认知及其纠正

| 条目 | 早期结论 | 修正结论 | 修正来源 | 影响 |
|------|---------|---------|---------|------|
| BR 变量 | BR = _sessionServiceV2 DI token | BR = s(72103) = path 模块 | [2026-04-25 18:00] | ⚠️ 高: resolve(BR) 仍存在但 BR 本身不是 DI token |
| PREMIUM_MODE_USAGE_LIMIT 错误码 | 值 = 1016 | 值 = 4008 | [2026-04-25 23:50] | ⚠️ 高: 补丁中引用的错误码需更新 |
| efh/efg 可恢复错误列表 | efh 是可恢复错误列表 | efh 现为 domain mask 函数，列表重命名为 efg | [2026-04-25 22:30] | ⚠️ 高: 补丁必须引用 efg 而非 efh |
| J→K 重命名 | J 已重命名为 K | J 仍为当前变量名，K 不存在 | [2026-04-25 23:50] | ⚠️ 高: 补丁仍应引用 J |
| Bs 类身份 | Bs = ChatStreamService | Bs = ChatParserContext | [2026-04-23 14:00] | ⚠️ 中: 类名理解修正 |
| SSE 事件前缀 | D7 (如 D7.Error) | Ot (如 Ot.Error) | [2026-04-25 21:05] | ⚠️ 中: 搜索模板需更新 |
| IPlanItemStreamParser Token | Symbol.for("IPlanItemStreamParser") | Symbol("IPlanItemStreamParser") @7511512 | [2026-04-25 22:30] | ⚠️ 高: 搜索模板 SSE-02 返回 EMPTY |
| ISessionStore Token | Symbol.for("ISessionStore") | Symbol("ISessionStore") @7092843 | [2026-04-25 22:30] | ⚠️ 高: 搜索模板需更新 |
| DI 注册计数 | 51 服务 / 101 uX 调用 | 186 uJ 声明 / 817 uX 调用 | [2026-04-26 04:15] | ⚠️ 低: 计数更精确 |
| registerCommand 位置 | 文件尾部 @10477319+ | 文件中部 @2540057 (核心) + 尾部 (icube命令) | [2026-04-26 04:27] | ⚠️ 中: 命令注册分两处 |
| kg 错误码数量 | ~30 个 | 56 个 | [2026-04-25 22:30] | ⚠️ 低: 枚举更完整 |
| 偏移量差异 (美化 vs 原始) | 单一偏移体系 | 美化后偏移 vs 原始偏移存在系统性差异 | 多轮扫描对比 | ⚠️ 中: 04:16/04:28 扫描偏移与 04:27 扫描偏移不同 |
| efi() 命名碰撞 | 仅一个 efi() | 两个完全不同的函数 (chat=权限, desk=Zod schema) | [2026-04-27 01:10] | ⚠️ 高: desktop-modules 的 efi() 是 Zod builder |

---

## [2026-04-27 16:45] 偏移量重校准 + force-max-mode 验证 + v22 验证 + P2 盲区扫描 ⭐⭐⭐⭐⭐

> 源文件版本变更: 10,490,721 → **10,487,294** (-3,427 字符)
> 所有锚点使用稳定锚点独立重新定位，不依赖旧偏移量

### 发现 1: 偏移量重校准完整结果 ⭐⭐⭐⭐⭐

| 锚点 | 新偏移量 | 旧偏移量 | 变化 | 状态 |
|------|---------|---------|------|------|
| Symbol("IPlanItemStreamParser") | @7508080 | @7510931/@7509092 | -2851/-1012 | ✅ 正常漂移 |
| Symbol("ISessionStore") | @7092843 | @7087490 | +5353 | ⚠️ 需关注 |
| Symbol.for("IModelService") | @7182322 | @7182322 | 0 | ✅ 无变化 |
| Symbol.for("IErrorStreamParser") | @7513039 | @7513039 | 0 | ✅ 无变化 |
| computeSelectedModelAndMode | @7213504 | @7215828 | -2324 | ✅ 正常漂移 |
| teaEventChatFail | @7458691 | @7458679 | +12 | ✅ 正常漂移 |
| Symbol.for("ITeaFacade") | @7140149 | @7140149 | 0 | ✅ 无变化 |
| bootstrapApplicationContainer | @10473600 | @10477819 | -4219 | ✅ 正常漂移 |
| Symbol("IEntitlementStore") | @7264747 | — | NEW | ✅ 已迁移 |
| ICommercialPermissionService | @7197035 | — | — | ✅ 仅字符串 |
| force_close_auto | @7282952 | @7282940 | +12 | ✅ 正常漂移 |
| kg.TASK_TURN_EXCEEDED_ERROR | @8704686 | — | — | ✅ 已验证 |
| 4000002 (错误码) | @54440 | @54993 | -553 | ✅ 正常漂移 |
| bJ= (枚举) | @6479431 | @6479431 | 0 | ✅ 无变化 |
| efi() | @8684462 | @8687513 | -3051 | ✅ 正常漂移 |
| openUsageLimitModal | @10476298 | @10476298 | 0 | ✅ 无变化 |

**NOT FOUND (已解释)**:
- Symbol.for("ISessionStore") → 已迁移为 Symbol("ISessionStore")
- Symbol.for("IEntitlementStore") → 已迁移为 Symbol("IEntitlementStore")
- Symbol.for("ICommercialPermissionService") → 不存在 Symbol 形式，仅字符串引用
- Symbol("IDiContainer") / Symbol.for("IDiContainer") → 不存在字符串字面量

**ISessionStore 偏移量漂移 +5353 分析**: 该区域可能经历了较大的代码重构。建议 Developer 验证依赖 ISessionStore 偏移量的补丁 fingerprint。

### 发现 2: force-max-mode `||true` 验证 ⭐⭐⭐⭐⭐

**`||true` 确认存在！** 两处硬编码:

```javascript
// @7213326 — getSessionModelAndMode() 方法内 (ID 类 / SessionRelationStore)
p = this._commercialPermissionService.isOlderCommercialUser() || true
g = this._commercialPermissionService.isSaas() || true
```

**语义分析**:
- `p` (isOlderCommercialUser) 和 `g` (isSaas) 始终为 `true`
- 这两个值传入 `ID.computeSelectedModelAndMode()` 静态方法
- 在 computeSelectedModelAndMode 内: `(u||d) && (solo_coder||solo_builder)` → 强制 Max 模式
- **效果**: 所有用户（包括免费用户）的 Solo Agent 都会获得 Max 模式

**force-max-mode 补丁必要性重新评估**:
- Solo Agent: **不需要补丁** — `||true` 已强制 Max 模式
- 非 Solo Agent (Manual/Auto): **可能需要** — 但 Manual/Auto 模式不受此逻辑影响
- **结论**: force-max-mode 补丁优先级从 5/5 降至 2/5。`||true` 可能是 Trae 开发者的调试代码或有意为之

**补充发现**: `_shouldForceEnableAutoMode()` 方法存在，可通过动态配置 `autoDefaultConfig.forceAuto` 强制启用 Auto 模式。`force_close_auto` 配置键 @7282952 可强制关闭 Auto 模式。

### 发现 3: teaEventChatFail 纯遥测函数确认 ⭐⭐⭐⭐

**teaEventChatFail @7458691 是纯遥测函数**，仅调用 `this._teaService.event()`:
```javascript
teaEventChatFail(e,t,i){
    let r=this.getAssistantMessageReportParamsByTurnId(e,t);
    this._teaService.event(i4.CodeCompStep.fail,{
        ...r,
        error_code:i.code,
        error_message:i.message,
        error_level:i.level,
        is_sound_notis:+!!this._configurationConnectorService.getConfiguration(O6),
        sound_volume:this._configurationConnectorService.getConfiguration(O9)
    })
}
```

**v22 补丁机制**: v22 在此遥测函数中注入续接逻辑（resumeChat/sendChatMessage），利用其作为错误信号触发点。这是合理的因为:
1. teaEventChatFail 在 L2 服务层，不受 React 冻结影响
2. 它在错误发生时被调用，是续接的天然触发点
3. 函数参数包含错误码 `i.code`，可用于条件判断

**错误码分布**:
| 错误码 | 出现次数 | 偏移量 |
|--------|---------|--------|
| 4000002 | 6 | @54440, @7166979, @7175748, @7513167, @7529332, @7589278 |
| 4000009 | 6 | @54292, @7166642, @7174630, @7513175, @7529340, @7589286 |
| 4000012 | 5 | @7166791, @7174806, @7513183, @7529348, @7589294 |

**kg.TASK_TURN_EXCEEDED_ERROR @8704686 验证**: 在 React 组件中用于判断可续接错误:
```javascript
J=!![kg.MODEL_OUTPUT_TOO_LONG,kg.TASK_TURN_EXCEEDED_ERROR,kg.LLM_STOP_DUP_TOOL_CALL,kg.LLM_STOP_CONTENT_LOOP,kg.DEFAULT].includes(_)
```

### 发现 4: P2 盲区扫描结果 ⭐⭐⭐

**P2a (0-41400) — webpack bootstrap + 协议定义**:
- 内容: AMD define 入口 + LSP 协议类型定义 + Chat 协议请求类型
- 无 DI Token、无 API endpoint、无核心业务逻辑
- **结论**: 保持 P2，无需深入

**P2b (10490354-EOF) — 命令注册 + 组件导出 + 初始化**:
- 内容: AgentImport 组件 + RuleMetadata 表单 + 命令注册(icube.knowledges.*, icube.dslAgent.*) + 模块导出
- 含 DI token: `Symbol.for("aiAgent.IAiCompletionService")`
- 含初始化代码: `FW.initializeModelList()`
- **建议升级为 P1** — 包含命令注册入口和组件映射

---

## [2026-04-27] Auto-Continue 架构深度探索 ⭐⭐⭐⭐⭐

> Phase 1-4 完整深度分析，产出最佳拦截点建议和理想架构设计
> **核心结论: ErrorStreamParser.parse() @7513080 是唯一最佳拦截点**

### 发现 1: SessionServiceV2 DI 完整映射 ⭐⭐⭐⭐⭐

| 属性 | 值 | 偏移量 |
|------|-----|--------|
| DI Token | `BO = Symbol("ISessionServiceV2")` | @7545196 |
| Token 形式 | Symbol() (非 Symbol.for, 已迁移) | — |
| BR 变量 | **BR === BO** (v22 补丁验证) | @249643 |
| uJ 注册点 | `uj.getInstance().provide(BO, SessionServiceV2Class)` | @10728725 (bootstrapApplicationContainer) |
| resolve 调用点 1 | bootstrapApplicationContainer 初始化 | @10477835 |
| resolve 调用点 2 | v22 L2 补丁内 `uj.getInstance().resolve(BR)` | @7513080 (注入) |
| resolve 调用点 3 | v22 L3/store.subscribe 补丁内 | @7588590 (注入) |
| 类定义位置 | SessionServiceV2 class | ~@7545000 |
| resumeChat 方法 | `{sessionId, messageId}` camelCase 参数 | @249656 |
| _aiAgentChatService.resumeChat() | 模块级包装, 内部调用 SessionServiceV2 | @249035 |
| IPC ResumeChat | 通过 IPC 调用服务端续接 | @252102 |

**关键确认**: v22 补丁中的 `resolve(BR)` 确实获取的是 SessionServiceV2 实例，BR === BO。

### 发现 2: 错误传播完整链路 (Mermaid) ⭐⭐⭐⭐⭐

```
服务端 AI 思考超限 (67轮后)
    ↓ 触发 TASK_TURN_EXCEEDED_ERROR = 4000002
SSE Ot.Error 事件 {code: 4000002, message: "..."}
    ↓
EventHandlerFactory Bt @7300000 (中央事件分发)
    ↓ 按 eventType=Error 分发
ErrorStreamParser zU.parse(e, t) @7513080  ← ★ L2 最佳拦截点
    ↓ [同步调用, L2 服务层, 不受 React 冻结]
getErrorInfoWithError(e) → {status: bQ.Warning, exception:{code,message,data}}
    ↓
chatStreamFrontResponseReporter.updateFrontResponsePayloadWhenError(e,r,t)
    ↓
Store 状态更新: currentSession.messages[last].exception = {code:4000002,...}
    ↓
React 组件重渲染 (useStore selector 检测变化)
    ↓
ErrorMessageWithActions 组件 @8700000
    ↓
J = !![MODEL_OUTPUT_TOO_LONG, TASK_TURN_EXCEEDED_ERROR,
       LLM_STOP_DUP_TOOL_CALL, LLM_STOP_CONTENT_LOOP,
       DEFAULT].includes(errorCode)  @8707716
    ↓
if(V && J) → Cr.Alert "继续" 按钮 @8713483  ← L1 注入点 (后台冻结!)
```

**链路关键节点**:
1. **SSE 入口**: EventHandlerFactory @7300000 — 所有 SSE 事件的唯一入口
2. **解析层**: ErrorStreamParser.parse() @7513080 — 错误码首次被程序化处理
3. **转换层**: getErrorInfoWithError @7513080 — kg 枚举 → UI 结构
4. **报告层**: chatStreamFrontResponseReporter — Store 状态变更
5. **状态层**: Zustand Store (SessionStore xC) — currentSession.messages 更新
6. **展示层**: ErrorMessageWithActions → if(V&&J) Alert

### 发现 3: 所有"继续"触发代码路径 ⭐⭐⭐⭐⭐

| # | 路径 | 位置 | 触发方式 | 层级 | 后台可用 | 当前状态 |
|---|------|------|---------|------|---------|---------|
| L1 | if(V&&J) 内部 queueMicrotask | @8713483 | React 渲染时自动触发 | L1 React | ❌ 冻结 | ✅ 启用(auto-continue-thinking) |
| L2 | ErrorStreamParser.parse() setTimeout(0) | @7513080 | SSE 回调时自动触发 | L2 Service | ✅ 可用 | ✅ 启用(auto-continue-l2-parse) |
| L3 | store.subscribe 同步回调 | @7588590 | Store 变化时自动触发 | L2 Data | ⚠️ 依赖Store更新 | ✅ 启用(v11-store-subscribe) |
| M1 | ec() onActionClick resumeChat | @8697580 | 用户点击 retry | L1 React | ✅ 用户驱动 | ✅ 启用(ec-debug-log) |
| M2 | ed() "继续" sendChatMessage | @8697620 | 用户点击 continue | L1 React | ✅ 用户驱动 | (内置) |
| T1 | teaEventChatFail 遥测 | @7458691 | 错误发生时遥测 | L2 Service | ✅ 可调用 | (纯日志,未注入) |

**共同汇聚点**: 所有自动路径最终都调用 `SessionServiceV2.resumeChat({sessionId, messageId})`
**降级路径**: resumeChat 失败 → `sendChatMessage({message:"Continue", sessionId})`

### 发现 4: 后台行为深度分析 ⭐⭐⭐⭐⭐

#### 4.1 Chromium/Electron 定时器节流行为

| API | 前台最小间隔 | 后台最小间隔 | 节流程度 | auto-continue 适用性 |
|-----|-------------|-------------|---------|-------------------|
| queueMicrotask | 同步微任务 | 同步微任务 | **不节流** ✅ | ⭐⭐⭐⭐⭐ 首选 |
| Promise.resolve().then() | 微任务 | 微任务 | **不节流** ✅ | ⭐⭐⭐⭐⭐ 首选备选 |
| MessageChannel port.onmessage | 微任务 | 微任务 | **不节流** ✅ | ⭐⭐⭐⭐ 兼容备选 |
| setTimeout(...,0) | ~4ms | ≥1000ms | **中度节流** ⚠️ | ⭐⭐⭐ 可用但延迟大 |
| setTimeout(>1s) | 精确 | ≥60000ms | **严重节流** ❌ | ⚠️ 不可靠 |
| setInterval | 精确 | ≥1000ms | **同 setTimeout** ❌ | ⚠️ 不可靠 |
| requestAnimationFrame | ~16ms | **完全暂停** | **冻结** ❌ | ❌ 不可用 |
| useEffect / useState updater | 同步 | **Scheduler 冻结** | **冻结** ❌ | ❌ 不可用 |

#### 4.2 L1 补丁后台失效根因分析

**错误认知纠正**: L1 补丁失效不是因为 V/J 变量值冻结!
- V 来自 Store.useStore() — **后台仍可更新** ✅
- J 来自 kg 枚举比较 — **始终可计算** ✅
- h (sessionId) 来自 Store.getCurrentSession() — **后台可获取** ✅

**真正根因**: `if(V&&J)` 是 React 组件渲染分支。React Scheduler 在后台标签页**暂停组件重渲染** → 整个 if(V&&J) 分支不执行 → L1 补丁代码永远不触发。

**验证**: L2 补丁在 ErrorStreamParser.parse() 中执行, 位于 SSE 回调链 (L2 Service 层), 完全不依赖 React 渲染周期 → 后台 100% 可靠。

#### 4.3 beautified.js 中异步 API 使用统计

| API | 出现次数 | 主要使用场景 |
|-----|---------|------------|
| setTimeout | 80+ | 重试/延迟/UI更新/动画/节流 |
| setInterval | ~10 | 会话跟踪/进度监控/光标闪烁 |
| requestAnimationFrame | ~5+ | 动画/滚动/终端渲染 |
| queueMicrotask | ~11 | 事件发射/状态更新/组件生命周期 |
| MessageChannel | ~9 | 微任务 fallback / 异步桥接 |
| Promise.then | ~46+ | 异步链/微任务兼容 |

### 发现 5: 候选拦截点评估矩阵 ⭐⭐⭐⭐⭐

| 候选点 | 位置 | 后台可用性 | 可靠性 | 复杂度 | 覆盖面 | 加权分 | 推荐 |
|--------|------|-----------|--------|--------|--------|-------|------|
| **A: ErrorStreamParser.parse()** | @7513080 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ 低 | ⭐⭐⭐⭐⭐ 全部错误码 | **8.65** | 🥇 **主拦截点** |
| B: store.subscribe | @7588590 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ 中 | ⭐⭐⭐⭐ 全部 | 6.95 | 🥈 防御层 |
| C: teaEventChatFail | @7458691 | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ 低 | ⭐⭐⭐ 仅信号 | 6.35 | ❌ 不推荐 |
| D: resumeChat 入口 wrapper | @249656 | N/A | ⭐⭐⭐ | ⭐ 高 | ⭐⭐ 无法区分 | 5.10 | ❌ 不适合 |

**详细评估**:

**🥇 候选 A — ErrorStreamParser.parse() @7513080**:
- **优势**:
  - 所有 SSE 错误事件的必经之路 (单点入口)
  - L2 服务层, 不受 React Scheduler 影响
  - 参数 e (error object) 含 code/message/data, 易判断可恢复性
  - 参数 t (context) 含 sessionId/agentMessageId, 直接用于 resumeChat
  - 已有 v22 补丁验证可行 (90+ 分钟无人值守, 100% 成功率)
- **劣势**: 需要 DI resolve(BR) 获取 SessionServiceV2; 当前使用 setTimeout(0) 有节流风险
- **改进**: 用 queueMicrotask 替代 setTimeout(0) 即可消除节流风险

**🥈 候选 B — store.subscribe @7588590**:
- **优势**: 数据驱动模式, 完全绕过 React 渲染周期; 与 PlanItemStreamParser 自动确认同款模式
- **劣势**: 比 parse() 多一层间接 (parse→Store→subscribe); Store 更新时机可能延迟
- **定位**: 作为防御监控层, 捕获 parse() 遗漏的边缘情况

**🥉 候选 C — teaEventChatFail @7458691**:
- **优势**: L2 服务层; 必然在错误时被调用
- **劣势**: 纯遥测函数, 注入业务逻辑违反单一职责; 调用时机晚于 parse()
- **结论**: 不推荐作为主要拦截点

**❌ 候选 D — resumeChat 入口包装**:
- **无法区分**自动续接 vs 手动续接 vs 正常 API 调用
- 包装会引入不必要的复杂度
- **结论**: 不适合

### 发现 6: 理想架构设计 ⭐⭐⭐⭐⭐

#### 推荐方案: "Unified Mid-Parse" 单一中间件

**核心思路**: 以 ErrorStreamParser.parse() 为唯一拦截点, 用 queueMicrotask 替代 setTimeout, 统一日志和冷却机制。

**架构图**:
```
输入: 任何 SSE 错误事件 (Ot.Error)
    ↓
[ErrorStreamParser.parse(e, t)]  ← ★ 唯一注入点 @7513080
    ↓
判断: e.code ∈ [4000002, 4000009, 4000012, 987, 4008, 977] ?
    ↓ (是)
判断: Date.now() - window.__traeAC > 5000ms ? (冷却期 5s)
    ↓ (是, 未冷却)
window.__traeAC = Date.now()  // 更新冷却时间戳
    ↓
queueMicrotask(() => {         // ★ 改用 queueMicrotask (不节流!)
    var svc = uj.getInstance().resolve(BR);
    svc.resumeChat({
        sessionId: t.sessionId,
        messageId: t.agentMessageId
    });  // 主路径: resumeChat
}).catch(() => {
    svc.sendChatMessage({     // 降级: sendChatMessage
        message: "Continue",
        sessionId: t.sessionId
    });
});
    ↓
日志: console.log("[AC] auto-resumed, code=" + e.code)
```

#### 新旧方案对比

| 维度 | 现状 (v22, 6 个补丁) | 新方案 (Unified Mid-Parse) | 改进 |
|------|---------------------|--------------------------|------|
| **补丁数量** | 6 个 (thinking+l2-parse+v11+guard-clause+efg-list+loop-detect) | **1 个主 + 1 个防御** = 2 个 | **-67%** |
| **拦截入口** | 3 处 (L1+L2+L3) | **1 处** (L2 parse) | 消除冗余 |
| **调度 API** | queueMicrotask(L1) + setTimeout(0)(L2) + subscribe(L3) | **统一 queueMicrotask** | 消除节流风险 |
| **冷却机制** | window.__traeAC (L1) + window.__traeAC11 (L3) | **单一 window.__traeAC** | 简化 |
| **日志前缀** | [v7], [v22-bg], [v22-bg] 不统一 | **统一 [AC]** | 可观测性 |
| **统计计数** | 无 | **window.__traeAC_stats** | 🆕 可观测 |
| **代码量** | ~60 行注入 | ~35 行 | -42% |
| **后台可靠性** | L1❌ + L2✅ + L3⚠️ | **✅ 100%** (queueMicrotask) | 质的飞跃 |
| **维护成本** | 高 (6 处联动修改) | **低** (1 处修改) | 大幅降低 |

#### 推荐迁移路径

```
Phase 1 (立即可做, 10分钟, 零风险):
┌─────────────────────────────────────────────┐
│ ① L2 补丁: setTimeout→queueMicrotask        │
│ ② 添加 __traeAC_stats = {total:0, ...}      │
│ ③ 日志前缀统一为 [AC]                        │
└─────────────────────────────────────────────┘
         ↓ 验证稳定后
Phase 2 (合并重构, 2-3小时, 需测试):
┌─────────────────────────────────────────────┐
│ 新建 unified-mid-parse 补丁                  │
│   → 替代 auto-continue-l2-parse              │
│   → 合并 auto-continue-v11-store-subscribe   │
│ L1 补丁纯 UI 化 (移除自动触发代码)           │
│ 回归测试: 前台 + 后台 30 分钟                │
└─────────────────────────────────────────────┘
         ↓ 稳定运行 1 周后
Phase 3 (清理):
┌─────────────────────────────────────────────┐
│ 禁用 guard-clause-bypass                     │
│ 禁用 bypass-loop-detect (J 数组由新补丁管理) │
│ 禁用 efh-resume-list (efg 由新补丁管理)      │
│ store.subscribe 降级为纯监控(只日志不动作)    │
└─────────────────────────────────────────────┘
```

### 最终建议

| 问题 | 建议 | 置信度 |
|------|------|--------|
| 是否重构? | **是**, 分 Phase 渐进式重构 | ⭐⭐⭐⭐⭐ |
| 最佳拦截点? | **ErrorStreamParser.parse() @7513080** | ⭐⭐⭐⭐⭐ |
| 首要优化? | **setTimeout→queueMicrotask** (零风险, 立即收益) | ⭐⭐⭐⭐⭐ |
| L1 补丁命运? | **纯 UI 化** (保留 Alert 但移除自动触发) | ⭐⭐⭐⭐ |
| L3 补丁命运? | **降级为防御监控层** 或禁用 | ⭐⭐⭐⭐ |
| 目标补丁数? | **2 个** (主拦截 + 可选防御) | ⭐⭐⭐⭐ |
