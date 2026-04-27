---
module: auto-continue-architecture-exploration
description: Auto-Continue 架构深度探索任务书
priority: P0
deadline: 2026-04-28
role: explorer
output: discoveries.md (更新)
handoff: handoff-developer.md (完成后写入)
---

# Auto-Continue 架构深度探索任务书

## 背景

当前 auto-continue 使用三层补丁（L1/L2/L3）冗余设计，方案脆弱且难以维护。需要深入理解代码架构，找到单一可信赖的拦截点。

**目标**：画出"错误从产生到 UI 显示的完整链路"，识别最佳拦截点。

---

## Phase 1: SessionServiceV2 初始化流程

### 1.1 找到 SessionServiceV2 的 DI 注册点

**任务**：
1. 搜索 `SessionServiceV2` 的定义位置
2. 找到它的 DI token（可能是 `Symbol.for("SessionServiceV2")` 或类似）
3. 找到它被 resolve 的所有位置

**交付**：
- SessionServiceV2 的 DI token 名称
- 所有 resolve 调用点列表
- 哪个 module 负责创建实例

### 1.2 找到 resumeChat 的实现

**任务**：
1. 搜索 `resumeChat` 方法的完整实现
2. 理解它接受什么参数（sessionId, messageId 等）
3. 它调用了什么服务？

**交付**：
- resumeChat 完整源码
- 参数验证逻辑
- 调用链路图（resumeChat → ??? → API）

---

## Phase 2: 错误处理完整链路

### 2.1 错误码传播路径

**任务**：追踪 `4000002`（TASK_TURN_EXCEEDED_ERROR）从产生到 UI 显示的完整路径

1. **错误产生点**：找到 `kg.TASK_TURN_EXCEEDED_ERROR` 在哪里被设置
2. **流传点**：它怎么传到 ErrorStreamParser.parse()
3. **处理点**：ErrorStreamParser.parse() 怎么处理它
4. **UI 点**：它怎么到达 `if(V&&J)` 的 Alert 组件

**交付**：用 Mermaid 画出完整流程图

```
用户消息
   ↓
AI思考 (67次后触发 TASK_TURN_EXCEEDED_ERROR)
   ↓
[???] ← 这里是什么?
   ↓
[???] ← 这里是什么?
   ↓
ErrorStreamParser.parse(e, t)
   ↓
[???] ← 这里是什么?
   ↓
if(V&&J) → Alert "继续" 按钮
```

### 2.2 识别所有能触发"继续"的代码路径

**任务**：
1. 搜索 `resumeChat` 的所有调用点（包括失败后的 fallback）
2. 搜索 `sendChatMessage` 的所有调用点
3. 搜索 `teaEventChatFail` 的所有调用点
4. 找到这些调用的共同上游

**交付**：
- 所有 resumeChat 调用点列表（含文件:行号）
- 所有 sendChatMessage 调用点列表
- "继续" Alert 的 onActionClick 完整链路

---

## Phase 3: 后台行为分析

### 3.1 React Scheduler 后台节流

**任务**：
1. 找到 React Scheduler 在 Electron 环境下对后台标签页的处理
2. 找到 `if(V&&J)` Alert 组件的渲染依赖哪些状态
3. 确定哪些状态在后台会停止更新

**交付**：
- Alert 组件的完整渲染依赖链
- 哪些 hook 在后台会冻结
- L1 补丁为什么在后台不工作（理论分析）

### 3.2 Chromium 定时器后台节流

**任务**：
1. 确认 `setTimeout` 在 Electron 后台标签页的最小间隔
2. 确认 `queueMicrotask` 是否被节流
3. 确认 `MessageChannel` 是否被节流

**交付**：
- 各 API 在后台的表现
- 推荐的不被节流的替代方案

---

## Phase 4: 最佳拦截点识别

### 4.1 单一拦截点候选

基于 Phase 1-3 的发现，评估以下候选点：

| 候选点 | 位置 | 后台可用性 | 可靠性 | 复杂度 |
|--------|------|-----------|--------|--------|
| SessionServiceV2.resumeChat 调用前 | ? | ? | ? | ? |
| ErrorStreamParser.parse() | ~7513080 | ✅ 已知可用 | 高 | 低 |
| teaEventChatFail() | ~7458691 | ? | ? | ? |
| Store subscribe | ~7588590 | ? | 中 | 中 |

**任务**：为每个候选点写出：
1. 精确的代码位置
2. 如何在那里拦截
3. 拦截后如何判断是否是可恢复错误

### 4.2 设计理想架构

**任务**：基于以上分析，设计一个"中间件/拦截器"方案

```
输入: 任何错误事件
   ↓
[AutoContinue Middleware] ← 单一入口
   ↓
判断: 错误码是否在白名单 [4000002, 4000009, ...]
   ↓
判断: 是否在冷却期
   ↓
动作: resumeChat() 或 fallback sendChatMessage()
   ↓
日志: console.log("[auto-continue] ...")
```

**交付**：
- 推荐的拦截点位置
- 需要的代码修改（最小化）
- 新方案的补丁数量（目标: 1-2 个，而不是 6 个）

---

## 交付物清单

1. **Phase 1**: SessionServiceV2 完整报告
2. **Phase 2**: 错误传播链路图（Mermaid 格式）
3. **Phase 3**: 后台行为分析报告
4. **Phase 4**: 最佳拦截点 + 理想架构设计
5. **最终建议**: 是否重构 auto-continue？还是维持现状？

---

## 执行顺序

1. 先做 Phase 1（理解 SessionServiceV2）
2. 再做 Phase 2（理解错误链路）
3. Phase 3 和 4 可以并行

**预计工作量**：4-6 小时探索 + 2 小时文档整理

---

## 参考文件

- `shared/discoveries.md` — 现有发现（包含 DI token 映射、错误码枚举等）
- `patches/definitions.json` — 当前补丁定义（了解 L1/L2/L3 分别打在哪里）
- `scripts/v22-injection.txt` — v22 原始注入代码（了解当前实现）
