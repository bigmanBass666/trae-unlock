# SSE 流解析系统架构文档

> PlanItemStreamParser — Trae AI 聊天系统的核心 SSE 流解析器

> last_verified: 2026-04-26 | 兼容版本: Trae v3.3.x (10490721 chars)

## 1. 概述

PlanItemStreamParser 是 Trae AI 聊天模块的服务层核心组件，负责解析服务端推送的 SSE（Server-Sent Events）流数据，并将其分发到对应的处理逻辑。**它不属于 React 组件，不依赖 React 渲染周期**，因此是补丁最可靠的注入点。

### 在整体架构中的位置

```
服务端 SSE 流 → DG.parse → PlanItemStreamParser → Zustand Store → React 组件
                  (解析)       (分发+处理)          (状态管理)      (UI渲染)
               ~7318521       ~7502500            ~3211326       ~8635000+
```

## 2. 核心类/方法

### PlanItemStreamParser

| 属性 | 说明 |
|------|------|
| **位置** | ~7502500 区域 |
| **层级** | 服务层（非 React 组件） |
| **识别方式** | 日志字符串 `"[PlanItemStreamParser]"` |

### 注入的服务

| 服务属性 | 类型推断 | 用途 | 出现位置 |
|---------|---------|------|---------|
| `this._taskService` | TaskService | 调用 `provideUserResponse()` 发送确认/取消决策 | ~7502574, ~7503319 |
| `this._logService` | LogService | 调用 `info()`, `warn()` 记录日志 | ~7502574, ~7503319 |
| `this.storeService` | StoreService | 调用 `setBadgesBySessionId()` 更新 UI 标记 | ~7503319 |

> **注意**: `storeService` 没有 `_` 前缀，可能是公共属性。注入方式通过 `uX(token)` 装饰器注入，非构造函数参数注入。DI token 已从 `Symbol.for()` 迁移至 `Symbol()`：`IPlanItemStreamParser` → `Symbol("IPlanItemStreamParser")`，`ISessionStore` → `Symbol("ISessionStore")`。

### 核心方法

| 方法名 | 偏移位置 | 功能 |
|--------|----------|------|
| `_handlePlanItem()` | ~7502500 | 处理 planItem 事件，解析 confirm_info，触发自动确认 |
| `_onStreamingStop()` | ~7533176 | 流停止时设置 `WaitingInput` 状态 |

### 关键 API

| API | 所属服务 | 签名 | 用途 |
|-----|---------|------|------|
| `provideUserResponse` | _taskService | `({task_id, type, toolcall_id, tool_name, decision}) => Promise` | 通知服务端确认/取消工具调用 |
| `resumeChat` | ChatService (D) | `({messageId, sessionId}) => void` | 自动恢复中断的对话 |
| `sendChatMessage` | ChatService (D) | `({message, sessionId}) => void` | 发送新消息 |
| `setBadgesBySessionId` | storeService | `(sessionId, confirm_status) => void` | 更新会话标记 |

## 3. 数据流图

### SSE 流完整处理流程

```
服务端 SSE 流推送
       |
       v
DG.parse (~7318521) — 解析原始 JSON 响应
  ├─ 将 information_request 映射为 query
  ├─ 处理 ViewFiles 的行号转换
  └─ 生成 planItem 对象（含 confirm_info）
       |
       v
PlanItemStreamParser._handlePlanItem() (~7502500)
  ├─ 读取 confirm_status, auto_confirm, block_level 等
  ├─ 记录日志: confirmStatus, autoConfirm, isKnowledgesBg
  |
  ├─ [分支1] confirm_status === "unconfirmed" (~7502574)
  │   └─ if (auto_confirm / isKnowledgeBg) {
  │        provideUserResponse({decision:"confirm"})  // 原始：仅 knowledge 自动确认
  │        confirm_info.confirm_status = "confirmed"  // 补丁：本地状态同步
  │      }
  |
  └─ [分支2] 非 unconfirmed (~7503319)
      └─ storeService.setBadgesBySessionId(...)  // 设置 badge
         + 补丁追加: provideUserResponse + confirm_status 同步
       |
       v
Zustand Store (~3211326) — needConfirm 状态存储
       |
       v
React 组件渲染
  ├─ egR (RunCommandCard, ~8635000)
  ├─ ErrorMessageWithActions (~8700000)
  └─ Alert (Cr.Alert, ~8702300)
```

### 流停止处理

```
SSE 流结束
       |
       v
_onStreamingStop() (~7533176)
  └─ 设置 RunningStatus = "WaitingInput"
       |
       v
  根据 stopReason 和 errorCode 分发:
  ├─ stopReason = "Complete" → 正常完成
  ├─ stopReason = "Error" + J=true → 显示"继续"按钮
  └─ stopReason = "Error" + J=false → 显示错误消息，对话终止
```

## 4. 事件类型处理

### planItem 事件

| 属性 | 值 |
|------|-----|
| **事件类型** | planItem (通过 SSE 流推送的 tool_call 数据) |
| **处理函数** | `PlanItemStreamParser._handlePlanItem()` |
| **偏移位置** | ~7502500 |
| **期望数据结构** | 包含 `confirm_info`, `toolName`, `planItemId`/`id`/`toolCallId` 的对象 |
| **触发的状态变更** | 调用 `provideUserResponse()` 或 `setBadgesBySessionId()` |

### error 事件

错误通过 `errorCode` 字段传递，由 J 变量判断是否为"可继续"错误：

| 条件 | 行为 |
|------|------|
| J=true (可继续错误) | 显示 Alert + "继续"按钮 → 可自动续接 |
| J=false (不可继续) | 只显示错误消息 → 对话终止 |

### 流停止事件 (StreamStopType)

| 枚举值 | 字符串值 | 含义 | 偏移 |
|--------|---------|------|------|
| Cancel | `"Cancel"` | 用户取消 | ~7479332 |
| Error | `"Error"` | 错误终止 | ~7479332 |
| Complete | `"Complete"` | 正常完成 | ~7479332 |

## 5. 状态管理

### confirm_status 状态转换

```
unconfirmed → confirmed    (用户确认或自动确认)
unconfirmed → canceled     (用户取消或历史记录中的未确认项)
unconfirmed → skipped      (跳过)
confirmed   → (终态)       (命令执行中/已完成)
```

### 关键状态变量

| 变量 | 位置 | 类型 | 说明 |
|------|------|------|------|
| `confirm_status` | 服务端数据 | `"unconfirmed"/"confirmed"/"canceled"/"skipped"` | 工具调用确认状态 |
| `auto_confirm` | 服务端数据 | boolean | 是否允许自动确认 |
| `needConfirm` | Zustand Store (~3211326) | boolean | 是否需要用户确认 |
| `badges` | storeService | object | 会话标记 |

### RunningStatus 枚举 (Io, ~46856)

| 枚举值 | 字符串值 |
|--------|---------|
| Running | `"Running"` |
| Pending | `"Pending"` |
| WaitingInput | `"WaitingInput"` |
| Disabled | `"Disabled"` |
| IntentRecognizing | `"intentRecognizing"` |
| Sending | `"Sending"` |

### ChatTurnStatus 枚举 (bQ, ~47202)

| 枚举值 | 字符串值 |
|--------|---------|
| InProgress | `"in_progress"` |
| Canceled | `"canceled"` |
| Pause | `"paused"` |
| Queuing | `"queuing"` |
| Completed | `"completed"` |
| Failed | `"failed"` |
| WaitAIResponse | `"wait-ai-response"` |
| AIGenerating | `"ai-generate-ing"` |
| Error | `"error"` |
| Warning | `"warning"` |
| Success | `"success"` |
| Deleted | `"deleted"` |

## 6. 限制点清单

| 限制点 | 位置 | 类型 | 触发条件 | 当前补丁覆盖 |
|--------|------|------|---------|-------------|
| knowledge 分支自动确认 | ~7502574 | 确认弹窗 | `confirm_status==="unconfirmed" && auto_confirm` | ✅ auto-confirm-commands v4 |
| else 分支自动确认 | ~7503319 | 确认弹窗 | `confirm_status!=="confirmed"` | ✅ service-layer-runcommand-confirm v8 |
| 可继续错误判断 | ~8696378 | 错误阻断 | J 变量不包含错误码 | ✅ bypass-loop-detection v4 |
| 可恢复错误列表 | ~8695303 | 错误阻断 | efh 列表不包含错误码 | ✅ efh-resume-list v3 |
| Alert "继续"按钮 | ~8702342 | UI限制 | 需要手动点击 | ✅ auto-continue-thinking v7 |

> **注意**: 当前版本中 efh 变量已重命名为 efg，偏移量 ~8705916。

## 7. 补丁接口

### 推荐注入点

| 注入点 | 位置 | 安全等级 | 说明 |
|--------|------|---------|------|
| `_handlePlanItem()` knowledge 分支 | ~7502574 | ⭐⭐⭐ 最安全 | 服务层，不受窗口冻结影响 |
| `_handlePlanItem()` else 分支 | ~7503319 | ⭐⭐⭐ 最安全 | 服务层，不受窗口冻结影响 |
| J 变量定义 | ~8696378 | ⭐⭐ 安全 | 仅修改数组内容 |
| efh 列表定义 | ~8695303 | ⭐⭐ 安全 | 仅修改数组内容 |
| Alert 渲染分支 | ~8702342 | ⭐ 一般 | React 组件内，受窗口冻结影响 |

### 安全注意事项

1. **箭头函数规则**: 所有 `.catch()` 回调必须使用箭头函数，避免 `this` 绑定错误
2. **不改变控制流**: 不要在补丁中添加 `return`/`break`/`continue`
3. **本地状态同步**: 调用 `provideUserResponse` 后必须同步更新 `confirm_info.confirm_status`
4. **防双重调用**: 多个补丁可能对同一 toolcall 调用同一 API，需要守卫条件

## 8. P0 新发现

| 发现 | 偏移量 | 与 SSE 流解析的关系 | 重要性 |
|------|--------|-------------------|--------|
| ChatError 枚举 | @54993 | 聊天错误码的补充/替代枚举，可能影响错误事件分发逻辑 | ⭐⭐⭐⭐ |
| ContactType 枚举 | @55561 | 30+ 配额状态枚举，影响配额限制错误的触发条件 | ⭐⭐⭐⭐⭐ |
| API endpoints config | @5870417 | API 端点配置，影响 SSE 流的连接地址 | ⭐⭐⭐⭐ |
