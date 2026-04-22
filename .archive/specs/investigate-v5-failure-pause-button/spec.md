# 调查 v5 续接失效 + 暂停按钮状态 Spec

## Why

`investigate-warning-and-error-2000000` spec 已实施 v5 三重加固（500ms 延迟 + 嵌套 retry + DEFAULT 加入 J 数组），8/8 指纹通过。但用户实测发现循环检测后仍完全无法续接：

1. 黄色警告出现："检测到模型陷入循环..."
2. 红色错误 2000000 替代警告
3. **发送按钮从箭头变为暂停按钮** ← 新发现
4. **点击"复制请求信息"得到长 ID 字符串** ← 新发现
5. 完全停止，无任何自动续接

v5 的 setTimeout(500ms) 应该在二次错误到达前触发，但实际没有。需要排查：
- 暂停按钮状态是否意味着某种全局锁/阻塞？
- 长 ID 字符串是什么？是否是请求追踪 ID？
- setTimeout 是否被 React 状态更新吞掉了？
- sendChatMessage/resumeChat 在此状态下是否被拒绝？

## What Changes

- 排查暂停按钮状态对续接机制的影响
- 可能需要修改 auto-continue-thinking 或新增补丁
- 可能需要在不同的代码路径上注入续接逻辑

## Impact

- Affected specs: investigate-warning-and-error-2000000（其 v5 修复未完全生效）
- Affected code: index.js ~8706660 (auto-continue-thinking v5)
- Affected patches: auto-continue-thinking v5, guard-clause-bypass v1

## ADDED Requirements

### Requirement: 循环检测后必须自动续接（即使进入暂停状态）

系统 SHALL 在循环检测错误到达后成功发起续接请求，无论 UI 进入何种状态。

#### Scenario: 暂停按钮状态下续接

- **WHEN** 循环检测触发且 UI 显示暂停按钮
- **THEN** auto-continue-thinking 的 setTimeout SHALL 成功执行 resumeChat/sendChatMessage
- **AND** 对话 SHALL 无感继续

### Requirement: 错误码 2000000 后的续接保持

即使 2000000 覆盖了原始错误码，续接机制 SHALL 在合理时间窗口内触发。

#### Scenario: 连续错误事件时续接不丢失

- **WHEN** 先收到 4000009（循环检测），再收到 2000000（DEFAULT）
- **THEN** v5 的 500ms setTimeout SHALL 在任一错误到达前已触发
- **OR** 如果未触发，应有兜底机制确保续接

## MODIFIED Requirements

### Requirement: auto-continue-thinking v5→v6?

如果根因是暂停按钮状态导致 API 调用被拒绝，可能需要：
- 使用更底层的 API（绕过 UI 层限制）
- 或在暂停状态解除后再触发
- 或在更早的事件钩子中注入续接逻辑
