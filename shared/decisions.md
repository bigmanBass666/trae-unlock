---
module: decisions
description: 技术决策记录
read_priority: P2
read_when: 需要理解决策时
write_when: 做出重要决策时
format: registry
---

# 技术决策记录

> 只保留有技术参考价值的决策。过程/流程类决策已归档。

### [2026-04-18 18:00] 为什么服务层补丁才有效

**选择**: PlanItemStreamParser 服务层补丁 | **否决**: React 组件内补丁
**原因**: 切换 AI 会话窗口后 React 组件冻结，useEffect/useMemo/useCallback 全部暂停。PlanItemStreamParser 是 SSE 流解析器，不属于任何 React 组件，数据到达时立即执行，不受窗口状态影响。
**验证**: v7 日志三阶段确认（聚焦→触发 / 切走→静默 / 切回→延迟）→ L1 冻结原则。

### [2026-04-19 12:00] 为什么自动确认用黑名单而非白名单

**选择**: `e?.toolName!=="response_to_user"` 黑名单 | **否决**: 白名单
**原因**: 白名单太保守（只允许 run_command）。黑名单只排除需要用户交互的工具，其余所有工具类型默认自动确认，更灵活实用。
**最终黑名单**: response_to_user + AskUserQuestion + ExitPlanMode（NotifyUser 已移除）

### [2026-04-20 10:00] 为什么补丁中必须用箭头函数

**选择**: `.catch(e=>{...})` 箭头函数 | **否决**: `.catch(function(e){...})`
**原因**: service-layer-runcommand-confirm v5 使用普通函数，严格模式下 this 为 undefined，Promise reject 时抛出 TypeError，未捕获异常导致整个 React 组件树崩溃。

### [2026-04-21 14:00] ed() vs ec() — sendChatMessage vs resumeChat

**选择**: `D.resumeChat()` | **否决**: `D.sendChatMessage({message:"Continue"})`
**原因**: sendChatMessage 创建全新消息轮次，服务端不识别为续接 → 空响应 → Cancel。resumeChat 是服务端级别恢复对话。
**注意**: v7-debug 日志证实 resumeChat 在循环检测后可能为 no-op → v8 改用 L2 轮询器直接调 sendChatMessage 作为 fallback。

### [2026-04-22 16:00] L1 冻结原则 — v7 日志验证 4/18 架构决策

**数据**: auto-continue-thinking 迭代 6 次（L1）vs service-layer 迭代 3 次（L2）vs data-source 迭代 2 次（L3）
**结论**: 迭代次数与所在层级强相关。L1 补丁因冻结问题反复失败。新补丁优先考虑 L2/L3 注入点。
