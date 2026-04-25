# SSE 管道拓扑文档

> SSE 事件分发系统的完整架构映射
> last_verified: 2026-04-26 | 兼容版本: Trae v3.3.x (10490354 chars)

## 1. SSE 事件枚举 (D7)

| 事件类型 | 枚举值 | 说明 | Parser 类 | DI Token |
|---------|--------|------|-----------|----------|
| Metadata | `"metadata"` | 元数据 | DQ (MetadataParser) | `Symbol("IMetadataParser")` |
| UserMessage | `"userMessage"` | 用户消息 | DV (UserMessageContextParser) | `Symbol("IUserMessageContextParser")` |
| Notification | `"notification"` | 通知 | — | `Symbol.for("INotificationStreamParser")` |
| TextMessage | `"textMessage"` | 文本消息 | — | `Symbol.for("ITextMessageChatStreamParser")` |
| PlanItem | `"planItem"` | 计划项/工具调用 | zL (PlanItemStreamParser) | `Symbol("IPlanItemStreamParser")` |
| Error | `"error"` | 错误 | zU (ErrorStreamParser) | `Symbol.for("IErrorStreamParser")` |
| UserMessageStream | `"userMessageStream"` | 用户消息流 | zJ | `Symbol.for("IUserMessageStreamParser")` |
| TokenUsage | `"tokenUsage"` | Token 用量 | z2 | `Symbol.for("ITokenUsageStreamParser")` |
| ContextTokenUsage | `"contextTokenUsage"` | 上下文 Token | z3 | `Symbol.for("IContextTokenUsageStreamParser")` |
| FeeUsage | `"feeUsage"` | 费用 | za | `Symbol("IFeeUsageStreamParser")` |
| SessionTitle | `"sessionTitle"` | 会话标题 | z8 | `Symbol.for("ISessionTitleMessageStreamParser")` |
| Done | `"done"` | 完成 | zW | `Symbol("IDoneStreamParser")` |
| Queueing | `"queueing"` | 排队 | zV | `Symbol("IQueueingStreamParser")` |

## 2. EventHandlerFactory (Bt) — 中央调度器

位置: ~7300000 区域
模式: handle(event, payload, context) → parse(event, payload, context) → handleSteamingResult(result, context)

每个事件类型注册一个 Parser，handle() 调用 Parser.parse() 然后分发结果。

## 3. ChatStreamService 层级

```
Bo (ChatStreamService 基类, Template Method 模式)
├── Bv (SideChatStreamService) — 侧边栏聊天，完整事件分发
└── BE (InlineChatStreamService) — 内联聊天，简化版
```

关键: `Bs` 不是 ChatStreamService！`Bs` 是 ChatParserContext（数据类）。

## 4. SSE 流生命周期

```
SSE 连接建立
  → onMetadata → MetadataParser.parse()
  → onMessage → EventHandlerFactory.handle(eventType, payload, context)
    → Parser.parse() → handleSteamingResult() → handleSideChat()/handleInlineError()
      → storeService.updateMessage() → Zustand Store → React re-render
  → onError(e, t, i) → 仅 t=true 时分发到 ErrorStreamParser
  → onComplete → DoneParser.parse()
  → onCancel → 清理
```

## 5. 15 个 Parser 类完整列表

| Parser | 混淆名 | 偏移量 | DI Token | 处理事件 |
|--------|--------|--------|----------|---------|
| MetadataParser | DQ | ~7314000 | IMetadataParser | Metadata |
| UserMessageContextParser | DV | ~7314000 | IUserMessageContextParser | UserMessage |
| NotificationStreamParser | — | ~7322410 | INotificationStreamParser | Notification |
| TextMessageChatStreamParser | — | ~7497479 | ITextMessageChatStreamParser | TextMessage |
| PlanItemStreamParser | — | ~7503299 | IPlanItemStreamParser | PlanItem |
| ErrorStreamParser | zU | ~7508572 | IErrorStreamParser | Error |
| UserMessageStreamParser | zJ | ~7515007 | IUserMessageStreamParser | UserMessageStream |
| TokenUsageStreamParser | z2 | ~7516765 | ITokenUsageStreamParser | TokenUsage |
| ContextTokenUsageStreamParser | z3 | ~7517392 | IContextTokenUsageStreamParser | ContextTokenUsage |
| FeeUsageStreamParser | za | ~7482422 | IFeeUsageStreamParser | FeeUsage |
| SessionTitleMessageStreamParser | z8 | ~7518028 | ISessionTitleMessageStreamParser | SessionTitle |
| DoneStreamParser | zW | ~7511057 | IDoneStreamParser | Done |
| QueueingStreamParser | zV | ~7512721 | IQueueingStreamParser | Queueing |
| TaskAgentMessageParser | — | ~7614800 | (非 SSE 管道) | (IPC 消息) |
| DZ/Dq (预解析器) | DZ, Dq | ~7300000 | — | 预处理 |

关键发现: TaskAgentMessageParser 不在 SSE 管道中！它处理 IPC 来源的消息。

## 6. 错误分发的关键条件

```javascript
// Bo.onError(e, t, i):
// t=true → SSE 流错误 → eventHandlerFactory.handle(D7.Error, e, r) → ErrorStreamParser
// t=false → 其他异常 → 仅日志记录
// 思考上限错误不经过此路径！
```

## 7. DG.parse L3 数据层入口

DG.parse (~7318521) 是服务端响应的第一道解析：
- 将 information_request 映射为 query
- 处理 ViewFiles 的行号转换
- 生成 planItem 对象（含 confirm_info）

## 8. 搜索模板

| 目标 | 搜索关键词 | 稳定性 |
|------|-----------|--------|
| SSE 事件枚举 | `Symbol.for("IPlanItemStreamParser")` | ⭐⭐⭐⭐⭐ |
| EventHandlerFactory | `eventHandlerFactory` | ⭐⭐⭐ |
| ChatStreamService | `class Bo` | ⭐⭐ |
| ErrorStreamParser | `Symbol.for("IErrorStreamParser")` | ⭐⭐⭐⭐⭐ |
| PlanItemStreamParser | `Symbol("IPlanItemStreamParser")` | ⭐⭐⭐⭐ |

## 9. 盲区列表

- SSE 连接建立的具体代码（可能在 workbench.desktop.main.js 中）
- EventHandlerFactory 的完整注册表（哪些事件注册了哪些 Parser）
- InlineChatStreamService 的事件过滤逻辑
- SSE 流的认证/重连机制
