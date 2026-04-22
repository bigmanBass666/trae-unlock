# auto-continue-thinking v7 Spec — 基于"手动点击也没反应"的根因修复

## Why

用户测试结果（2026-04-22）提供的关键证据：

```
① 黄色警告出现     → if(V&&J) 通过，Alert 正常渲染 ✅
② 无红色错误2000000 → DEFAULT入J 生效，二次覆盖被阻止 ✅  
③ 暂停按钮(发送中)   → 有请求发出 ⏸️
④ 自动续接未触发    → queueMicrotask 或执行或未执行 ❌
⑤ 手动点"继续"也没反应 → ec()回调本身失效 🔴🔴🔴
```

**核心发现：第 ⑤ 条改变了一切。**

之前所有版本（v3→v4→v5→v6）都在优化"调度时机"：
- v3: ed() → ec() （换API入口）
- v4: 直调 D.resumeChat() + fallback + 2000ms延迟
- v5: 500ms + 嵌套retry + DEFAULT入J
- v6: queueMicrotask 替代setTimeout

但 **手动点击"继续"按钮走的是同一个 `ec()` 函数**，它也不工作。这说明：

> **问题不在何时调用 resumeChat，而在 resumeChat 本身在循环检测场景下就不可用。**

## 历史假设演进

| 版本 | 假设 | 证据反驳 |
|------|------|---------|
| v4 | ed() 条件判断 `"v3"===p` 不满足 | 改直调 D.resumeChat() |
| v5 | setTimeout(500) 被 React cleanup 杀死 | 改 queueMicrotask |
| v6-debug | queueMicrotask 应该能工作 | **手动点击也不行 → 推翻"时机论"** |
| **v7** | **resumeChat 在循环检测后 session 状态异常，需要全新方案** | **待验证** |

## What Changes

- **诊断 `ec()` 函数为什么失败**：检查其内部条件链（`"v3"===p`、`a/h` 参数、服务端响应）
- **如果 ec()/D.resumeChat() 不可用，换一个完全不同的续接路径**
- 候选方案：
  - 方案 A：直接用 `D.sendChatMessage({message:"继续", ...})` 绕过 resumeChat
  - 方案 B：找到循环检测后仍然有效的 session/API 入口
  - 方案 C：不依赖 Alert 组件的 onActionClick，而是在错误处理更早的阶段拦截并续接

## Impact

- Affected code: index.js ~8706660 (auto-continue-thinking), ~9335799 (ec/D.resumeChat 区域)
- Affected patches: auto-continue-thinking v6 → v7
- Affected specs: verify-pause-button-hypothesis (Task 4-5)

## ADDED Requirements

### Requirement: 必须先确认 ec() 失败的具体原因

在实施 v7 之前，必须通过调试日志或代码分析确认 ec() 为什么失败。

#### Scenario: 分析 ec() 内部条件链

ec() 函数（~9335799 附近）内部有已知条件：
```javascript
// 伪代码还原（基于之前调查）
function ec() {
  if (!a || !h) return;                    // 条件1: messageId/sessionId 为空？
  if ("v3" === p && e.includes(_)) {       // 条件2: 版本匹配 + 错误码匹配
    D.resumeChat({messageId: a, sessionId: h});
  } else {
    b.retryChatByUserMessageId(a);         // 条件3: fallback
  }
}
```

**必须确认**：
- `a`(messageId) 和 `h`(sessionId) 在循环检测触发时是否有值？
- `p`(agentProcessSupport) 是否等于 `"v3"`？
- `e.includes(_)` 中的 `_`(errorCode) 是什么值？是否在 e 中？

### Requirement: v7 必须绕过不可用的 resumeChat 路径

如果确认 resumeChat/ec() 在循环检测后不可用，v7 SHALL 使用不依赖该路径的续接方式。

#### Scenario: 循环检测后的自动续接

- **WHEN** 循环检测警告(4000009) 出现且用户希望自动续接
- **THEN** 系统 SHALL 通过可工作的 API 发送续接消息
- **AND** 不依赖可能已失效的 resumeChat/session 机制

## MODIFIED Requirements

### Requirement: auto-continue-thinking 补丁定义 (v6 → v7)

v6 的 replace_with 在 `if(V&&J){...}` 内部调用 `queueMicrotask(() => { D.resumeChat(...) || sendChatMessage(...) })`。

v7 需要根据 ec() 失败的真实原因选择新的调用路径。

**候选方向**：

**方向 A — 纯 sendChatMessage（最简单）**:
完全放弃 resumeChat，始终用 sendChatMessage 发送"继续"文本消息。
- 优点：不依赖 session 状态、messageId、agentProcessSupport
- 缺点：不是真正的"续接"，而是发一条新消息；AI 可能不理解上下文

**方向 B — 延迟重试 resumeChat（中等复杂）**:
在 queueMicrotask 内加 retry 循环，多次尝试 resumeChat，间隔递增。
- 优点：如果只是时序问题可以解决
- 缺点：如果 resumeChat 根本不可用则无效

**方向 C — 更早阶段拦截（最彻底）**:
不在 Alert 组件的 if(V&&J) 分支中处理，而在 D7.Error 处理阶段（~8701000 附近）直接拦截 4000009 并发起续接。
- 优点：在 session 还有效的时候拦截
- 缺点：需要定位新的代码位置、风险更高
