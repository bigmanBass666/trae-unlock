# 修复循环检测后自动续接不触发 Spec

## Why

v4 补丁已应用且指纹验证通过，但实测发现循环检测触发后：
1. ✅ 警告文字消失（bypass-loop-detection v3 生效）
2. ❌ 自动续接完全没触发（auto-continue-thinking v4 的 `if(V&&J)` 未进入）
3. ❌ 对话直接停止，无任何后续动作

**根因假设**：`if(V&&J)` 前存在 guard clause `if(!n||!q||et) return null`，如果消息状态(n)、错误类型(q)或 JV() 条件(et) 不满足，整个错误组件返回 null，`if(V&&J)` 根本不会被评估。需要调查循环检测触发时这些变量的实际值。

## What Changes

- 新增补丁或修改现有补丁，确保循环检测触发后自动续接机制能被触发
- 可能的方向：
  - 方向 A：修改 guard clause 条件，让循环检测错误码不被拦截
  - 方向 B：在更早/不同的代码路径上拦截循环检测事件并触发续接
  - 方向 C：调查 Trae 是否更新了循环检测的错误处理机制（新的 SSE 事件类型？新的状态码？）

## Impact

- Affected specs: fix-manual-stop-blocking, fix-loop-detection-blocking
- Affected code: [index.js](file:///D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js) 偏移 ~8706067 (guard clause) 和 ~8706654 (if(V&&J))

## ADDED Requirements

### Requirement: 循环检测后自动续接必须触发

系统 SHALL 在收到循环检测错误码（4000009/4000012）后，自动发起对话恢复请求。

#### Scenario: 循环检测触发后的完整恢复流程

- **WHEN** 服务端通过 SSE 推送循环检测错误码（4000009 或 4000012）
- **THEN** 客户端 SHALL 在 2000ms 后自动调用 `D.resumeChat({messageId:o, sessionId:h})` 或 fallback 到 `D.sendChatMessage({message:"继续", ...})`
- **AND** 对话 SHALL 无感继续，AI 继续执行未完成的任务（如 sleep 轮询）

### Requirement: Guard Clause 不应阻止循环检测续接

efp 组件的 guard clause `if(!n||!q||et) return null` SHALL NOT 阻止循环检测错误码进入 `if(V&&J)` 分支。

#### Scenario: Guard clause 对循环检测透明

- **WHEN** 消息状态为 bQ.Error/bQ.Warning 且错误码为 LLM_STOP_DUP_TOOL_CALL/LLM_STOP_CONTENT_LOOP
- **THEN** guard clause SHALL 返回 false（允许继续到 if(V&&J)）
- **AND** `if(V&&J)` SHALL 为 true（V=当前是最后一条消息, J=错误码在可续接列表）

## MODIFIED Requirements

### Requirement: auto-continue-thinking 补丁 (v4→v5?)

当前的 v4 补丁依赖 `if(V&&J)` 分支被触发。如果 guard clause 阻止了该分支，v4 补丁需要升级。

**可能的修改**：
- 如果问题是 guard clause 拦截 → 将 setTimeout 移到 guard clause 之前，或在 guard clause 中加入循环检测例外
- 如果问题是错误不走 D7.Error 路径 → 找到新的错误处理路径并在那里注入续接逻辑
