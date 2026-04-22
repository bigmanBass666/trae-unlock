# 调查循环检测警告重现 + 新错误码 2000000 阻断续接 Spec

## Why

guard-clause-bypass v1 + auto-continue-thinking v4 实施后（8/8 PASS），用户实测发现：

1. ⚠️ **循环检测黄色警告重新出现了** — "检测到模型陷入循环，为避免更多消耗已主动中断对话，建议更换描述后重试"
2. 🔴 **随后被新错误替代** — "系统未知错误，请尝试新建任务或者重启 TRAE。 (2000000)"
3. ❌ **完全没触发自动续接** — 没有任何自动发送的"继续"或 resumeChat

这表明存在 **两个独立的问题**：
- 问题 A：循环检测警告为什么会出现？（bypass-loop-detection v3 应该抑制它）
- 问题 B：错误码 2000000 是什么？它是否阻止了续接机制？

## What Changes

- 调查并修复问题 A 和/或 B
- 可能需要修改现有补丁或新增补丁

## Impact

- Affected specs: fix-autocontinue-not-triggering（依赖它的修复结果）
- Affected code: [index.js](file:///D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js)
- Affected patches: bypass-loop-detection v3, guard-clause-bypass v1, auto-continue-thinking v4

## ADDED Requirements

### Requirement: 循环检测警告不应显示

当收到循环检测错误码（LLM_STOP_DUP_TOOL_CALL / LLM_STOP_CONTENT_LOOP）时，不应显示原始警告文字。

#### Scenario: 循环检测触发时只显示可续接提示

- **WHEN** 服务端推送 4000009 或 4000012 错误码
- **THEN** 不应显示 "检测到模型陷入循环..." 黄色警告文字
- **AND** 应直接进入 auto-continue-thinking 的续接流程（或至少显示带"继续"按钮的 Alert）

### Requirement: 错误码 2000000 不应阻断续接

如果错误码 2000000 在循环检测之后到达，不应完全阻止续接机制。

#### Scenario: 连续错误事件时的续接保持

- **WHEN** 先收到循环检测错误码（4000009），再收到错误码 2000000
- **THEN** 续接机制仍应在合理时间窗口内触发
- **OR** 如果 2000000 是致命错误导致会话无法恢复，应有明确的错误处理而非静默失败

## MODIFIED Requirements

### Requirement: bypass-loop-detection v3 可能需要升级

当前 v3 通过扩展 J 数组来让 `if(V&&J)` 分支处理循环检测错误。但如果警告仍然显示，说明：
- 要么 J 数组扩展没有生效（但 8/8 PASS 确认它在位）
- 要么警告文字是由另一个渲染路径渲染的（不是 efp 组件的 if(V&&J) 分支）
- 要么 2000000 错误在 4000009 之后到达并覆盖了状态

需要调查警告文字的具体渲染来源。
