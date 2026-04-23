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

### [2026-04-23 00:45] v9 早捕获 — 为什么 v8 的 L2 独立设计是假的

**选择**: v9 早捕获（在 if(V&&J) 外无条件捕获服务） | **否决**: v8 设计（L2 依赖 L1 先设置 __traeSvc）
**根因分析**: v8 的 L2 轮询器虽然用 setInterval 不受 rAF 影响，但它读取的 `window.__traeSvc` 是由 L1 (if(V&&J)) 设置的。后台窗口时 L1 冻结 → __traeSvc 永远为空 → L2 拿到 undefined → 静默退出。**L2 形式上独立，实际上完全依赖 L1。**
**v9 方案**: 将 `window.__traeSvc = {D,b,M}` 移到 if(V&&J) **之前**，使其在组件每次渲染时都执行（不依赖错误状态）。用户只要看到聊天界面，__traeSvc 就被设置。
**否决的其他方案**:
- 直接从模块级获取 D/b: PowerShell 子串搜索确认 SessionServiceImpl/sendChatMessage 在更新后变量名全变，无法可靠定位
- DOM 操作模拟点击: React 冻结时 DOM 也不更新，按钮不存在
- fetch 直接调 API: 需要 auth token 格式，复杂度高

### [2026-04-23 01:00] 白屏预防决策 — 未来修改补丁的强制检查清单

**背景**: 会话 #27 通过对比 6cfb3de (v7, 正常) 和当前版 (白屏) 确认：新增 `auto-continue-l2-event` + 修改 `auto-continue-thinking` v7→v9 的组合导致白屏。

**决策**: 所有未来补丁修改必须通过以下检查：

| # | 检查项 | 说明 | 失败处理 |
|---|--------|------|---------|
| 1 | **是否新增补丁?** | 新增 = 最高风险，必须在干净目标上测试 | 先 apply 到 clean backup → node --check → 重启 Trae 验证 |
| 2 | **是否改变 replace_with 结构位置?** | 如从 if 内部移到外部、从函数内移到函数外 | 同上，视为新补丁 |
| 3 | **是否有互相依赖的新/改补丁同时上线?** | 如 A 补丁设置 window 变量，B 补丁读取 | 必须分步验证：先 A → 测试 → 再 B → 测试 |
| 4 | **注入位置是否在 IIFE 边界?** | 文件头/尾的 IIFE 注入最危险 | 特别验证括号匹配和闭包完整性 |
| 5 | **node --check 通过后是否重启验证?** | 语法 ≠ 运行时安全 | **必须重启 Trae 看界面**，不能只看语法 |

**核心原则**: `node --check Exit code 0 ≠ 不会白屏`。这是本次白屏事件最重要的教训。

### [2026-04-23 02:00] 废弃 ast-grep — PowerShell 子串搜索是唯一可靠的源码搜索方式

**选择**: PowerShell 子串搜索 (`$c=[IO.File]::ReadAllText($path); $c.IndexOf("keyword")`) | **否决**: ast-grep (`sg`)

**实测数据**（2026-04-23，目标文件 ~10MB 单行压缩 JS）:

| 搜索关键词 | PowerShell | ast-grep |
|-----------|-----------|----------|
| `resumeChat` | ✅ @7540953 | ❌ 空 |
| `sendChatMessage` | ✅ @7524962 | ❌ 空 |
| `provideUserResponse` | ✅ @7509668 | ❌ 空 |
| `_taskService` | ✅ @7509655 | ✅ 勉强 |
| `storeService` | ✅ @7320181 | ✅ 勉强 |
| **成功率** | **7/7 (100%)** | **2/5 (40%)** |

**ast-grep 失败根因**:
1. **单行压缩文件** — terser/webpack 打包为单行 10MB，ast-grep 的 AST 解析器对超长行处理不佳
2. **变量名混淆** — 函数调用模式（`resumeChat($$$)`、`sendChatMessage($$$)`）在混淆后 AST 结构失配
3. **只能匹配简单属性访问** — `this._taskService` 这类固定模式能搜到，但实际需要的函数调用模式全军覆没

**PowerShell 子串搜索优势**:
- 100% 可靠：只要字符串在文件中就一定能找到精确偏移量
- 额外发现：搜到了之前不知道的 `_aiAgentChatService`(@7500589) 和 `_sessionServiceV2`(@7776387)
- 无需安装任何额外工具：纯 .NET API，Windows 自带
- 速度极快：10MB 文件 IndexOf 操作毫秒级完成

**操作**: 已执行 `npm uninstall -g @ast-grep/cli`，全局移除。所有文档中的 ast-grep 引用已替换为 PowerShell 子串搜索。
**未来禁止重新安装 ast-grep** — 除非有证据表明它能处理本项目的单行压缩文件格式。

### [2026-04-23 03:00] "切窗口就失效"根因研究结论 — 推荐 DI 容器方案

**研究结论**: "切窗口后失效"的根因不是"后台不能执行代码"，而是 **L1 补丁放在了 React 组件 render 函数内**，而 React 在后台标签页中时序不可预测。

**推荐方案**: Direction A/G — **在 PlanItemStreamParser（L2 层）中使用 `uj.getInstance().resolve(BR)` 获取 `_sessionServiceV2`，直接调用其 `resumeChat()`/`sendChatMessage()` 方法**。

**选择理由**:
1. PlanItemStreamParser 运行在 SSE 回调内，完全不受 React 冻结影响
2. `uj.getInstance()` 是模块级全局单例，任何位置都可访问
3. `_sessionServiceV2` 的 `resumeChat()` 和 `sendChatMessage()` 已被 Trae 自身在多个模块级位置使用（@7789264、@8146411）
4. F3/sendToAgentBackground 函数（@7610443）已证明此模式的可行性
5. 无需 IIFE 注入、无需 window 变量 hack、不会导致白屏

**实施前提**:
1. 需确认 PlanItemStreamParser 内可获取到 sessionId 和 messageId
2. 需确定 auto-continue 的触发条件放在 L2 的哪个具体位置（confirm_status 检查？error handler？）
3. DI token `BR` 可能随 Trae 更新变化，需要建立搜索定位机制

**备选方案**: Direction D — visibilitychange 事件 + L1 补丁组合。切回窗口时立即触发一次续接检查。简单但非真正的后台执行。

### [2026-04-23 03:20] v10 实施决策 — 用 `this._aiAgentChatService` 而非 DI 容器 resolve

**选择**: `this._aiAgentChatService.resumeChat()` | **否决**: `uj.getInstance().resolve(BR).resumeChat()`

**理由**:
1. Bs 类（ChatStreamService）已通过 DI 注入了 `_aiAgentChatService`（DI token=Di）
2. Trae 自己的 `createStream` 方法就用 `this._aiAgentChatService.resumeChat()` — 这是标准模式
3. 无需额外的 `uj.getInstance().resolve()` 调用 — 更简洁、更安全
4. `resolve(BR)` 获取的是 `_sessionServiceV2`，其 `resumeChat` 参数是 `{messageId, sessionId}`
5. `_aiAgentChatService.resumeChat` 参数是 `{message_id}` — 与 Trae 已有调用一致

### [2026-04-23 03:20] v10 实施决策 — 用数字字面量而非 kg.XXX 引用

**选择**: `[4000002,4000009,4000012,2000000,987,4008,977].indexOf(_rc)` | **否决**: `[kg.TASK_TURN_EXCEEDED_ERROR,...].includes(_rc)`

**理由**:
1. Bs 类区域中 `kg.` 使用次数为 0 — 虽然模块级可访问，但不符合该类的代码风格
2. 数字字面量不依赖 `kg` 变量名 — Trae 更新后更稳定
3. `indexOf` 比 `includes` 兼容性更好（虽然现代浏览器都支持）
4. 补丁中的代码越少依赖外部变量越好

**教训**: 错误码是**数字枚举**（`kg.XXX = 数字`），不是字符串。`MODEL_PREMIUM_EXHAUSTED` 在源码中不存在！之前 spec 中的字符串白名单完全错误。

### [2026-04-23 08:35] v11 方案决策 — store.subscribe 模块级监听

**背景**: v10 L2 两次失败(_onError和parse位置都不对)。用户指出三个成功案例(命令确认/DG.parse/沙箱)都解决了冻结问题。

**决策**: 采用 store.subscribe() 方案(v11), 放弃 React 组件内方案。

**理由**:
1. 成功案例共同模式: 全部在React渲染管线外执行(数据驱动)
2. Zustand store.subscribe基于MessageChannel, 后台tab正常工作
3. 已有subscribe #8先例证明此模式可行
4. 完全绕过React Scheduler, 无后台节流问题

**技术约束**:
- 必须用箭头函数 `.catch(e=>{})` 避免strict mode this=undefined
- 5秒防重复窗口 window.__traeAC11
- try-catch包裹防崩溃
- 错误码白名单: [4000002,4000009,4000012,987]

### [2026-04-23 09:00] v11.1 修复决策 — subscribe 参数顺序修正

**问题**: 首次测试失败, 日志中完全无 v11 输出。
**原因**: subscribe 回调的 prevState/currentState 搞反 + 条件逻辑反转。
**修复**: 交换 _m/_o 变量来源, 条件不变(因为语义也变了)。
**验证**: node --check 通过, fingerprint 存在, 待用户重新测试。
