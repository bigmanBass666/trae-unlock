
### [2026-04-26 16:30] P0 盲区深度探索 — 业务逻辑全量扫描 ⭐⭐⭐⭐
> P0 范围 (54415-6268469, ~5.9MB) 系统性业务逻辑搜索，确认 DI/核心服务不在 P0，发现 API 配置/错误码/ContactType/CueTrace 等关键数据结构
#### 搜索统计
| 搜索类型 | 命中数 | 分类 |
|---------|--------|------|
| DI_REG (uJ) | 0 | P0 无 DI 注册 |
| DI_INJECT (uX) | 0 | P0 无 DI 注入 |
| CLASS_DEF | 200 | 大部分第三方库 |
| ASYNC_FUNC | 91 | 大部分第三方库 |
| REG_CMD | 117 | VS Code 框架 + Lexical 编辑器 |
| HTTPS_URL | 155 (24 api_endpoint) | API 端点 |
| HTTP_URL | 121 (2 api_endpoint) | API 端点 |
| CN_CHARS | 20275 | i18n |
| CONSOLE_LOG/WARN/ERR | 232/187/147 | 遥测 |
| GET_STATE | 15 | 大部分第三方 |
| SUBSCRIBE | 1 | 第三方 |
| SET_STATE | 1 | 第三方 |
| resumeChat/sendChatMessage/provideUserResponse | 0 | 确认不在 P0 |
| Symbol.for("aiAgent.") / Symbol("I") | 0 | 确认不在 P0 |
| tool_confirm | 0 | 确认不在 P0 |

#### 核心发现 1: API 端点完整配置 JSON @5870417 ⭐⭐⭐⭐⭐
- 偏移量: @5870417 - @5874921 (4505 chars)
- webpack 模块 84312: `e.exports=JSON.parse('{...}')`
- 完整配置已提取到 `scripts/p0-api-endpoints.json`
- 关键端点:
  - **byteGate**: `https://bytegate-sg.byteintlapi.com` (CN/i18n/ToB 统一)
  - **tea.verifyUrl**: `https://mcs.byteoversea.net` (遥测验证)
  - **tea.abService**: `https://libraweb-va.tiktok.com` (AB 实验)
  - **slardarPC**: `https://pc-mon-sg.byteintlapi.com` (监控)
  - **deviceRegister**: `https://log.byteoversea.com` (设备注册)
  - **copilotDomain**: `https://copilot.byteintl.net` (CN/US), `https://copilot-sg.byteintl.net` (SG)
  - **mcpPlugin**: `api.trae.ai` (MCP 插件市场), `ide-market-us.tiktok-row.net` (内部)
  - **appProviderLogin.marscode**: `api.marscode.com` / `www.marscode.com`
  - **externalCopilotDomains**: `https://a0ai-api.byteintlapi.com` (usex/cnex/boe)
  - **SaasServer**: boeCopilot/ppeCopilot/prodCopilot (CN/SG/US 均为空字符串)
  - **cdnPrefix/cdnLocation**: CDN 区域配置
  - **USER_GROUP**: TOB_USER_GROUP_OVERSEA=`https://www.marscode.com`
  - **TRAE_AI_HOME_PAGE**: 空字符串

#### 核心发现 2: ChatError 类 + 完整错误码枚举 @54993 ⭐⭐⭐⭐⭐
- 偏移量: @54993 (webpack 模块开头)
- ChatError 类定义: `class l extends Error`
  - constructor(e, t, i=n.ERROR, r) — code, message, level, extra
  - static create(e, t, i, r)
  - static createWithError(e, t, i, r)
- ChatErrorLevel: ERROR / WARN
- ERROR_LEVEL: WARN / ERROR / INFO
- 错误码枚举 (部分新发现):
  - CLAUDE_MODEL_FORBIDDEN = 4113
  - CAN_NOT_USE_SOLO_MODE = 4120
  - FAST_APPLY_FILE_TOO_LARGE = 0xa7d8c1 (十进制 1099649)
  - FAST_APPLY_FIX_INVALID_FORMAT = 0xa7d8c2 (十进制 1099650)
  - LLM_INVALID_JSON = 4000003
  - LLM_INVALID_JSON_START = 4000004
  - LLM_QUEUING = 4000005
  - LLM_STOP_DUP_TOOL_CALL = 4000009
  - LLM_TASK_PROMPT_TOKEN_EXCEED_LIMIT = 4000010
  - TASK_TURN_EXCEEDED_ERROR = 4000002
  - PROJECT_NOT_FOUND_ERROR = 5000001
  - CLIENT_UNAUTHORIZED_ERROR = 1010002
- NetworkErrorCodes 数组: CONNECTION_ERROR, NETWORK_ERROR, NETWORK_ERROR_INTERNAL, CLIENT_NETWORK_ERROR, CLIENT_NETWORK_ERROR_INTERNAL, REQUEST_TIMEOUT_ERROR, REQUEST_TIMEOUT_ERROR_INTERNAL, MODEL_RESPONSE_TIMEOUT_ERROR, MODEL_RESPONSE_FAILED_ERROR

#### 核心发现 3: ContactType 枚举 — 用户配额状态完整映射 @55561 ⭐⭐⭐⭐⭐
- 偏移量: @55561 (webpack 模块 65544)
- 完整的免费/付费用户配额状态枚举 (30+ 值):
  - FreeNewSubscription: CompletionRemaining(1) / CompletionExhausted(2) / AdvancedModelRemaining(3) / AdvancedModelExhaustedPremiumModelRemaining(4) / AdvancedModelExhausted(5) / PremiumModelFlashRemaining(6) / PremiumModelFlashExhaustedNormalRemaining(7) / PremiumModelNormalRemaining(8) / PremiumModelNormalExhaustedAdvancedModelRemaining(9) / PremiumModelNormalExhausted(10)
  - FreeOldSubscription: CompletionRemaining(11) / CompletionExhausted(12) / AdvancedModelRemaining(13) / AdvancedModelExhaustedPremiumModelRemaining(14) / AdvancedModelExhausted(15) / PremiumModelFlashRemaining(16) / PremiumModelFlashExhaustedNormalRemaining(17) / PremiumModelNormalRemaining(18) / PremiumModelNormalExhaustedAdvancedModelRemaining(19) / PremiumModelNormalExhausted(20)
  - ProNewSubscription: CompletionRemaining(21) / CompletionExhausted(22) / AdvancedModelRemaining(23) / AdvancedModelExhausted(24) / PremiumModelFlashRemaining(25) / PremiumModelNormalRemaining(26)
  - ProOldSubscription: CompletionRemaining(27) / CompletionExhausted(28) / AdvancedModelRemaining(29) / AdvancedModelExhausted(30) / PremiumModelFlashRemaining(31) / PremiumModelNormalRemaining(32)
- **补丁意义**: ContactType 是 bypass-usage-limit 补丁的关键数据结构，控制 UI 显示的配额提示

#### 核心发现 4: CueTrace 性能追踪类 @113091 ⭐⭐⭐⭐
- 偏移量: @113091 (webpack 模块 31202)
- 完整的代码补全性能追踪类
- 追踪时间点: startTime → preProcess → request → firstToken → end → postProcess → render
- 图片渲染追踪: renderImage(Start/End) / Syntax / Canvas / FormatCanvas
- 上下文获取: preProcessTotalEditContext / LspDiagnostics / RewriteRange / NodeBoundary / Tokenizer
- 防抖追踪: remainingDebounce / contextFetchingDebounce
- CSP 预检: cspPreCheck(Start/End)
- logId 字段用于关联服务端日志

#### 核心发现 5: AbstractBootService — 启动配置服务 @2535031 ⭐⭐⭐⭐
- 偏移量: @2535031 - @2537000
- 服务方法: getAgentConfig / getCueConfig / getCKGConfig / getThreePgHost / getCdnLocation / getHomeUrl / getConsoleUrl / getImageXConfig / getExtensionConfig / getMcpConfig / getStoreRegion / getCdnPrefix / getDocsUrl / getGuideHelperConfig / getCdnPrefixes
- IPC_SERVICE_NAME = "BootService"
- AbstractBootManagementService: 管理 userInfo / originBootConfig / storeRegion / bootConfig / deviceId
- 事件: onDidBootConfigChanged / onDidOriginBootConfigChanged / onDidStoreRegionChanged / onDidUserInfoChanged / onDidDeviceIdChange
- throttle(50) 限流 refreshBootConfigDebounce

#### 核心发现 6: icube_devtool_bridge — VS Code 通信桥 @5890559 ⭐⭐⭐⭐
- 偏移量: @5890559
- s8 类: VS Code WebView 与主进程的通信桥
  - register/unregister/fire 方法
  - get/set state 通过 `window.__icube_devtool_vscode__`
  - handleReceive 处理回调
- vscodeService 全局单例: `window.vscodeService = new s8`
- callJS 消息处理器: 支持 callback(成功/失败) 和 event 两种类型
- la() 函数: 注册回调到 `__icube_devtool_bridge_callbacks`
- s7() 函数: 错误处理 — "The query has been canceled" 特殊处理 (-1 errCode)

#### 核心发现 7: Lexical 编辑器命令注册 @2834865 ⭐⭐⭐
- 偏移量: @2834865
- Chat 输入框的 Lexical 编辑器命令:
  - ADD_WORKSPACE_MENTION_SYMBOL — 添加工作区引用
  - ADD_FILE_MENTION_SYMBOL — 添加文件引用
  - ADD_FILE_MENTION_SYMBOL_WITH_SELECTION — 带选区的文件引用
  - ADD_FILE_MENTION_SYMBOL_FROM_EXTERNAL — 外部文件引用
  - ADD_CODE_MENTION_SYMBOL — 代码引用
  - ADD_FOLDER_MENTION_SYMBOL — 文件夹引用
  - ADD_FOLDER_MENTION_SYMBOL_FROM_EXTERNAL — 外部文件夹引用
- 遥测回调: es.GP.ContextAddClick + context_type + add_type

#### 核心发现 8: 多模态图片上传 @2681467 ⭐⭐⭐
- 偏移量: @2681467
- uploadSingleImageToServer: image_id + width + height + raw_body
- uploadFilesToServer: 批量上传，进度追踪，Slardar 事件
- 图片限制: 3MB / 最小尺寸 / jpeg/png/gif/webp
- ToB 图片 ID 格式: `ToB-{userId}_{timestamp}_{random}_{type}_{width}_{height}`

#### 核心发现 9: CancelReason / FinishReason 枚举 @111249 ⭐⭐⭐
- 偏移量: @111249
- FinishReason: CANCEL_BY_TOKEN / TRUNCATE_BY_PLUGIN_AST / TRUNCATE_BY_PLUGIN_INDENT / MAX_TOKEN_LIMIT / CANCEL_BY_SENSITIVE / SAME / CANCEL_BY_CONTENT_SECURITY
- CancelReason: REQUEST_TIMEOUT(20) / PARAMS_INVALID(21) / CANCEL_BY_TOKEN(22) / DOCUMENT_UNDEFINED(23) / UNKNOWN_ERROR(24) / CONTENT_SECURITY_PRE_INTERCEPTED(25) / CONTENT_SECURITY_POST_INTERCEPTED(26)

#### 核心发现 10: DocumentSetStatus / ExternalDocumentType @100870 ⭐⭐⭐
- 偏移量: @100870 (webpack 模块 64977)
- ExternalDocumentType: Official / Custom
- DocumentSetStatus: Ready / Indexing / Failed
- DocumentPageStatus: Ready / Fetching / FetchFailed / Indexing / IndexFailed / Deleted

#### P0 JSON 配置文件清单
| 偏移量 | 模块 | 内容 |
|--------|------|------|
| @2473418 | - | Unicode 字符分类表 |
| @2494107 | - | Unicode 空白字符表 |
| @2734967 | - | i18n 中文 (zh-cn) |
| @2742207 | - | i18n 日文 (ja) |
| @5870417 | 84312 | API 端点配置 (byteGate/tea/slardarPC/copilotDomain/mcpPlugin) |
| @5874967 | 99771 | i18n 英文 (en) |
| @5992978 | - | i18n 英文 (逗号分隔格式) |
| @6107094 | - | i18n 中文 (逗号分隔格式) |
| @6184670 | - | i18n 日文 (逗号分隔格式) |

#### 补丁影响评估
| 发现 | 对现有补丁的影响 |
|------|-----------------|
| ContactType 枚举 @55561 | bypass-usage-limit 补丁可直接引用此枚举值 |
| ChatError + 错误码 @54993 | efh-resume-list 补丁可扩展新错误码 (LLM_QUEUING/LLM_STOP_DUP_TOOL_CALL) |
| externalCopilotDomains @5874343 | AI API 端点 `a0ai-api.byteintlapi.com`，可用于理解请求路径 |
| AbstractBootService @2535031 | getStoreRegion/getMcpConfig 可用于条件化补丁逻辑 |
| icube_devtool_bridge @5890559 | window.vscodeService 可作为补丁的 IPC 通信替代通道 |

#### 结论
P0 盲区确认: **所有 DI 注册(uJ)、DI 注入(uX)、核心业务方法(resumeChat/sendChatMessage/provideUserResponse)、服务接口(Symbol)均不在 P0 范围内**。P0 的业务逻辑主要是:
1. 数据结构定义 (错误码/枚举/类型)
2. API 端点配置 (JSON 静态数据)
3. VS Code 框架代码 (CommandsRegistry/Protocol)
4. 上传/遥测/性能追踪基础设施
5. i18n 本地化数据 (3 种格式 × 3 种语言)
6. DevTool 通信桥
