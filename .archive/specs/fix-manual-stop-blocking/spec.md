# 修复手动终止输出阻塞轮询 Spec

## Why

用户进行轮询设计（反复执行 `Start-Sleep`）时，Trae 的循环检测中断对话后，auto-continue-thinking 自动发送"继续"，但 AI 返回"手动终止输出"而非继续执行。这导致轮询设计完全不可用。

## 根因分析

### 完整事件链

```
1. AI 反复执行 Start-Sleep → 服务端检测到循环
2. 返回 LLM_STOP_DUP_TOOL_CALL (4000009) → stopType=j9.Error
3. bypass-loop-detection v3: J=true → if(V&&J) 满足
4. auto-continue-thinking: setTimeout(()=>ed(), 50) → 发送 "Continue"
5. ed() 调用 D.sendChatMessage({message:"Continue", sessionId:...})
6. 新一轮对话开始 → stopType=j9.Complete（正常完成）
7. 但 AI 没有产出 → 返回空响应 → stopType=j9.Cancel
8. stopStreaming() 被调用 → 消息状态设为 bQ.Canceled
9. UI 显示 "手动终止输出"（icube_chat_turn_cancel_status）
10. auto-continue-thinking 再次触发 → 又发"继续" → 又被 Cancel → 死循环
```

### 三个关键问题

1. **ed() 发送 "Continue" 是新消息，不是恢复**：`D.sendChatMessage()` 创建全新对话轮次，服务端可能不识别这是续接，直接返回空响应
2. **Cancel 状态不触发 auto-continue**：`if(V&&J)` 中的 J 变量只在 `stopType=j9.Error` 时计算，Cancel 时 J 不适用
3. **"手动终止输出" 是 Cancel 状态的 UI 展示**：NLS key `icube_chat_turn_cancel_status`，当消息 status=bQ.Canceled 时显示

### 关键代码位置

| 偏移 | 内容 | 作用 |
|------|------|------|
| 8702633 | `ed=()=>{D.sendChatMessage({message:"Continue",...})}` | 发送"继续"消息 |
| 8702228 | `D.resumeChat({messageId:o,sessionId:h})` | resumeChat 恢复 |
| 7537888 | `onStreamingStop(e){...setRunningStatusMap(t,Io.WaitingInput)}` | 流停止后设状态 |
| 7538100 | `stopStreaming(e){...updateMessageStatus(e,...,bQ.Canceled)}` | 停止时设Canceled |
| 8872937 | `i("icube_chat_turn_cancel_status",{},"Manually stopped")` | UI显示"手动终止" |
| 7527119 | `_onCancel→_onStreamingStop({...e,stopType:j9.Cancel})` | Cancel事件触发 |

## What Changes

- **修改 ed() 回调**：从 `D.sendChatMessage` 改为 `D.resumeChat`，使用服务端恢复而非发送新消息
- **新增 cancel-auto-retry 补丁**：当消息状态为 Canceled（"手动终止输出"）时，自动调用 ec() 回调（resumeChat 路径）而非 ed()（sendChatMessage 路径）

## Impact

- Affected specs: auto-continue-thinking, bypass-loop-detection
- Affected code: 目标文件偏移 8702633（ed 回调）、8706524（if(V&&J) 分支）

## ADDED Requirements

### Requirement: ed() 使用 resumeChat 而非 sendChatMessage

auto-continue-thinking 的 ed() 回调 SHALL 使用 `D.resumeChat({messageId,sessionId})` 而非 `D.sendChatMessage({message:"Continue",...})`。

#### Scenario: 循环检测后自动续接使用 resumeChat
- **WHEN** 循环检测错误触发 auto-continue-thinking
- **THEN** ed() 调用 D.resumeChat() 而非 D.sendChatMessage()
- **AND** 服务端恢复对话而非创建新消息轮次

### Requirement: Canceled 状态自动恢复

当消息状态为 Canceled（"手动终止输出"）时，系统 SHALL 自动调用 ec() 回调（resumeChat 路径）恢复对话。

#### Scenario: Cancel 后自动恢复
- **WHEN** 消息状态变为 Canceled（stopType=j9.Cancel）
- **THEN** 自动调用 ec() 回调 → D.resumeChat() → 对话恢复

## MODIFIED Requirements

### Requirement: auto-continue-thinking 补丁

从 `setTimeout(()=>{ed()},50)` 改为 `setTimeout(()=>{ec()},50)`，使用 resumeChat 路径。

## REMOVED Requirements

无。
