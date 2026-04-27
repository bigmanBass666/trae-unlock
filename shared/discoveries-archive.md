# Discoveries Archive — 历史探索记录

> 本文件存储从 discoveries.md 主文件中归档的历史探索记录。
> 这些记录具有历史参考价值，但不再需要日常查阅。

---

## [04-23 03:20] v10 实施过程中的关键发现

> ⚠️ 已归档：v10 实施过程的详细调试记录，约 995 行。
> 关键结论已整合到主文件的 11 域映射和 v2 探索远征中。

### 归档原因
- 包含大量过程性调试记录和临时分析
- 核心发现已提取到主文件对应 section
- 保留供历史追溯需要

### 关键结论索引（已迁移到主文件）
- SSE 事件两条路径 → 见 [SSE] 域映射
- React Scheduler 后台冻结 → 见 [React] 组件层
- TaskAgentMessageParser.parse 变异源头 → 见 [IPC] 域
- teaEventChatFail 后台触发成功 → 见 [Event] 事件总线
- Hybrid flag+visibilitychange → 见 auto-continue-thinking 补丁

---

*归档时间: 2026-04-27*
*原始行数: ~995 行 (L713-L1707)*
