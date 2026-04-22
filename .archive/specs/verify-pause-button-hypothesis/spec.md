# 验证"暂停按钮=已发送"假设 — 重新定位续接失效根因 Spec

## Why

用户提出关键观察："发送按钮变成暂停按钮恰恰说明我们发送了个东西"。正常发消息等待 AI 响应时，按钮也会变暂停。如果这个观察正确，则：

**之前的根因分析（v5 spec）可能是错误的：**
- ❌ 旧假设：setTimeout(500) 未触发 / React cleanup 先于定时器清理 session
- ✅ 新假设：setTimeout/queueMicrotask **确实触发了**，resumeChat/sendChatMessage **确实被调用了**，但请求失败（服务端拒绝/session 已终止/返回空响应）

**如果是这样，v6 的 queueMicrotask 修复完全无效**——问题不在调度时机，而在请求本身的成功率。

## What Changes

- 在 auto-continue-thinking 补丁中添加 console.log 调试输出
- 验证暂停按钮与"正在等待响应"状态的关系
- 确定真正的失败点是：请求未发出 vs 请求发出但失败
- 根据真实根因调整修复方向

## Impact

- Affected specs: investigate-v5-failure-pause-button（其结论可能需要修正）
- Affected code: index.js ~8706660 (auto-continue-thinking v6)
- Affected patches: auto-continue-thinking v6（可能需要 v7）

## ADDED Requirements

### Requirement: 暂停按钮含义必须被精确确认

系统 SHALL 通过代码搜索和 UI 观察确认暂停按钮出现的所有场景。

#### Scenario: 对比暂停按钮出现条件

- **WHEN** 用户手动发送消息后等待 AI 响应
- **THEN** 发送按钮应变为暂停按钮
- **AND** 当循环检测触发且 auto-continue-thinking 执行后，应观察到相同的暂停按钮状态

### Requirement: 续接请求的实际执行必须有可观测证据

系统 SHALL 在 auto-continue-thinking 的回调中添加调试日志，确认：
1. 回调是否被执行
2. resumeChat/sendChatMessage 是否被调用
3. 调用是否成功（Promise resolved/rejected）
4. 如果 rejected，具体的错误信息是什么

## MODIFIED Requirements

### Requirement: auto-continue-thinking v6→v7?

如果新假设成立（请求发出了但失败），修复方向从"调度时机"转向"请求成功率"：
- 可能需要 retry 机制（一次失败后自动重试）
- 可能需要在不同的 API 入口点发起请求
- 可能需要检查 session 在循环检测后的有效状态
