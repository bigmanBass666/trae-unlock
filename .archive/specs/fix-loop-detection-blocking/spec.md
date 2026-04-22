# 修复循环检测阻塞对话 Spec

## Why

循环检测（LLM_STOP_DUP_TOOL_CALL=4000009, LLM_STOP_CONTENT_LOOP=4000012）在用户进行轮询设计时被误触发，直接中断对话并显示"检测到模型陷入循环，为避免更多消耗已主动中断对话，建议更换描述后重试"。当前 `bypass-loop-detection v2` 补丁（`J=!1`）实际上**未被应用到正确的 J 变量**，且该方案本身就有逻辑缺陷——`J=!1` 会让 `if(V&&J)` 永远不满足，导致 `auto-continue-thinking` 补丁也失效。

## What Changes

- **bypass-loop-detection v2 → v3**: 从 `J=!1`（永远 false）改为扩展 J 数组，加入 `kg.LLM_STOP_DUP_TOOL_CALL` 和 `kg.LLM_STOP_CONTENT_LOOP`，使循环检测错误进入"可继续"分支
- **efh-resume-list v1 → v2**: 在 efh 可恢复错误列表中加入 `kg.TASK_TURN_EXCEEDED_ERROR`、`kg.LLM_STOP_DUP_TOOL_CALL`、`kg.LLM_STOP_CONTENT_LOOP`，使 resumeChat 路径也可用
- **修正偏移量**: 更新 definitions.json 中的 offset_hint 为实际偏移

## Impact

- Affected specs: bypass-loop-detection, efh-resume-list, auto-continue-thinking
- Affected code: 目标文件偏移 8701180（J 变量）、8699513（efh 列表）

## ADDED Requirements

### Requirement: 循环检测错误自动续接

系统 SHALL 在收到循环检测错误码（4000009/4000012）时，自动发送"继续"消息续接对话，不阻塞用户工作流。

#### Scenario: 重复工具调用循环被自动续接
- **WHEN** 服务端返回 LLM_STOP_DUP_TOOL_CALL (4000009)
- **THEN** J=true → 进入 if(V&&J) 分支 → auto-continue-thinking setTimeout 自动触发 ed() → 发送 "Continue" → 对话无缝继续

#### Scenario: 内容循环被自动续接
- **WHEN** 服务端返回 LLM_STOP_CONTENT_LOOP (4000012)
- **THEN** J=true → 进入 if(V&&J) 分支 → auto-continue-thinking setTimeout 自动触发 ed() → 发送 "Continue" → 对话无缝继续

### Requirement: efh 可恢复列表包含循环检测错误

系统 SHALL 将 LLM_STOP_DUP_TOOL_CALL 和 LLM_STOP_CONTENT_LOOP 加入 efh 列表，使 resumeChat 路径也可用。

#### Scenario: resumeChat 路径可用
- **WHEN** agentProcess==="v3" 且错误码为 4000009/4000012
- **THEN** ec 回调自动调用 D.resumeChat() 恢复对话

## MODIFIED Requirements

### Requirement: bypass-loop-detection 补丁策略

从 `J=!1`（永远 false，破坏 auto-continue-thinking）改为扩展 J 数组（包含循环检测错误码），使循环检测错误进入"可继续"分支并自动续接。

### Requirement: efh-resume-list 补丁范围

从仅添加 TASK_TURN_EXCEEDED_ERROR 扩展为同时添加 TASK_TURN_EXCEEDED_ERROR + LLM_STOP_DUP_TOOL_CALL + LLM_STOP_CONTENT_LOOP。

## REMOVED Requirements

### Requirement: J=!1 方案
**Reason**: `J=!1` 让 J 永远为 false，导致 `if(V&&J)` 永远不满足，auto-continue-thinking 的 setTimeout 永远不执行。这是逻辑冲突。
**Migration**: 改为扩展 J 数组方案。

## 根因分析

### 当前补丁实际状态（2026-04-21 扫描）

| 补丁 | 偏移(definitions.json) | 实际偏移 | 状态 |
|------|----------------------|---------|------|
| data-source-auto-confirm v3 | ~7318787 | 7323241 | ✅ 已应用 |
| auto-confirm-commands v4 | ~7503301 | 7507671 | ✅ 已应用 |
| service-layer-runcommand-confirm v8 | ~7503879 | 7508254 | ✅ 已应用 |
| bypass-runcommandcard-redlist v2 | ~8070634 | 8075009 | ✅ 已应用 |
| auto-continue-thinking v2 | ~8957874 | 8706576 | ✅ 已应用 |
| **bypass-loop-detection v2** | ~8957350 | **8701180** | ❌ **未应用** |
| **efh-resume-list** | ~8695303 | **8699513** | ❌ **未应用** |

**关键发现**: bypass-loop-detection v2 和 efh-resume-list 两个补丁从未被成功应用到当前版本的目标文件。definitions.json 中的 offset_hint 是旧版偏移，apply-patches 脚本在旧偏移处找不到 find_original 模式，导致补丁静默跳过。

### J=!1 方案的逻辑缺陷

```
J=!1 → J 永远为 false
  → if(V&&J) 永远不满足
  → auto-continue-thinking 的 setTimeout 永远不执行
  → 思考上限(4000002)也无法自动续接
  → 所有错误都变成"不可继续"类型
```

### 正确方案：扩展 J 数组

```
J=!![kg.MODEL_OUTPUT_TOO_LONG, kg.TASK_TURN_EXCEEDED_ERROR,
     kg.LLM_STOP_DUP_TOOL_CALL, kg.LLM_STOP_CONTENT_LOOP].includes(_)
  → 循环检测错误: J=true → if(V&&J) 满足 → setTimeout 自动触发 → 对话续接
  → 思考上限: J=true → 同样自动续接
  → 其他错误: J=false → 正常显示错误消息
```
