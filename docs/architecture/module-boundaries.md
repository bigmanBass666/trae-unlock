# 模块边界与依赖关系

> Trae AI 聊天模块的整体架构地图
>
> last_verified: 2026-04-26 | 兼容版本: Trae v3.3.x (10490721 chars)

## 1. 概述

Trae AI 聊天模块打包为单个 AMD 模块文件，使用 webpack 打包和 minify。原始类名已被混淆为短变量名，但可通过日志字符串和代码上下文反推。

### 打包格式

```javascript
define(["katex","react","react-dom"], function(e,t,i) {
  return (() => {
    var r, n, o = {
      88690: function(e,t) { ... },  // AIScene 枚举模块
      32499: function(e,t,i) { ... }, // createInternalContributionSdk
      16866: function(e,t) { ... },  // TeaReporter
      // ... 数百个 webpack 模块
    }
  })()
})
```

### 外部依赖

| 依赖 | 用途 |
|------|------|
| katex | 数学公式渲染 |
| react | React 核心库 |
| react-dom | React DOM 渲染 |

## 2. 主要类/模块定义

### 核心模块

| 模块 | 混淆名/标识 | 位置 | 职责 |
|------|-----------|------|------|
| PlanItemStreamParser | 日志字符串 `"[PlanItemStreamParser]"` | ~7502500 | SSE 流解析和事件分发 |
| DG.parse | `DG.parse` | ~7318521 | 服务端响应解析 |
| RunCommandCard (egR) | `egR` | ~8635000 | 终端命令卡片组件 |
| ErrorMessageWithActions | - | ~8700000-8930000 | 错误消息+操作按钮组件 |
| TeaReporter | `t.TeaReporter=class{...}` | ~16866 | TEA 遥测报告器 |
| AIContributionTracker | - | ~31397 | AI 贡献追踪器 |

### 模块 ID 映射

| 模块 ID | 内容 | 位置 |
|---------|------|------|
| 88690 | AIScene 枚举 + BYTEDANCE_SCOPE | 文件开头 |
| 32499 | createInternalContributionSdk | 文件开头 |
| 16866 | TeaReporter 类 | 文件开头 |
| 39124 | createInternalContributionSdk 工厂 | 文件开头 |
| 31397 | AIContributionTracker 类 | 文件开头 |

## 3. 服务注入机制

### 注入模式

PlanItemStreamParser 中的服务通过 `this._xxxService` 模式注入：

| 服务属性 | DI Token | 类型 | 用途 |
|---------|---------|------|------|
| `this._taskService` | (推断 ITaskService) | TaskService | 调用 `provideUserResponse()` |
| `this._logService` | `bY` = Symbol.for("aiAgent.ILogService") | LogService | 调用 `info()`, `warn()` |
| `this.storeService` | `xC` = Symbol("ISessionStore") | SessionStore (xI) | 调用 `setBadgesBySessionId()` |
| `this._sessionServiceV2` | `BO` = Symbol("ISessionServiceV2") | SessionServiceV2 | resumeChat/sendChatMessage |

### 注入方式（已确认）

- **uX(token) 装饰器注入** — 服务通过 `uX(token)` 装饰器注入到类属性
- **uJ({identifier: token}) 装饰器注册** — 服务实现通过 `uJ` 注册到 DI 容器
- **uj.getInstance()** — 全局 DI 容器单例，偏移量 ~6268469
- **uB(token)** — React Hook `useInject`，等价于 `useSyncExternalStore`
- `storeService` 没有 `_` 前缀，可能是通过 uX 注入的公共属性

### DI 容器

| 属性 | 值 |
|------|-----|
| 容器类 | `uj` |
| 偏移量 | ~6268469 |
| 模式 | 单例 `uj.getInstance()` |
| 注册服务数 | 186 |
| 注入点数 | 817 |
| resolve 调用 | `uj.getInstance().resolve(token)` |

## 4. 事件系统

### SSE 流事件系统（核心）

```
服务端 → SSE 流 → PlanItemStreamParser._handlePlanItem() → 数据分发
```

- 不依赖 React 渲染周期
- SSE 数据到达时立即执行
- 是服务层补丁成功的关键

### React Hooks 回调系统

| Hook | 变量名 | 位置 | 用途 |
|------|--------|------|------|
| useCallback | ec | ~8697580 | 重试/恢复处理 |
| useCallback | ed | ~8697620 | "继续"按钮点击 |
| useMemo | ey | ~8636941 | 计算有效确认状态 |
| useMemo | _ | ~8629200 | 计算是否需要显示确认弹窗 |
| useEffect | (匿名) | ~8640019 | 自动确认 effect |

### TEA 遥测事件

- TeaReporter 类 (~16866)
- 方法: `tea.collect(eventName, properties)`
- 调用: `A.teaEventChatRetry(g, e, {isResume: true})`

### React 组件冻结机制

切换 AI 会话窗口后：
- React 冻结后台组件
- `useEffect` / `useMemo` / `useCallback` 全部暂停
- 任何 React 组件内的修改都无法生效
- **只有服务层代码（PlanItemStreamParser）不受影响**

## 5. 状态管理

### Zustand Store

| Store 状态 | 位置 | 类型 | 用途 |
|-----------|------|------|------|
| needConfirm | ~3211326 | boolean | 是否需要用户确认 |
| badges | storeService | object | 会话标记 |

### 状态传播路径

```
服务端 SSE → PlanItemStreamParser (服务层)
  → 解析 confirm_info
  → 更新 storeService.setBadgesBySessionId()
  → React 组件读取 store 状态
    → useMemo 计算确认状态 (ey)
    → useEffect 触发自动确认
    → UI 渲染确认弹窗或自动执行
```

## 6. 模块依赖关系图

```
┌─────────────────────────────────────────────────────────────┐
│                     外部依赖                                  │
│  katex (数学公式)  │  react (核心)  │  react-dom (DOM渲染)    │
└─────────────────────────────────────────────────────────────┘
                              │
                              v
┌─────────────────────────────────────────────────────────────┐
│                   AMD 模块入口                                │
│  define(["katex","react","react-dom"], function(e,t,i){...}) │
│  → webpack 内部模块系统                                       │
│  → Object.defineProperty(t, "__esModule", {value: true})     │
└─────────────────────────────────────────────────────────────┘
                              │
           ┌──────────────────┼──────────────────┐
           v                  v                  v
┌──────────────┐  ┌──────────────┐  ┌──────────────────┐
│  遥测模块     │  │  枚举定义     │  │  核心业务模块      │
│  TeaReporter  │  │  ToolCallName │  │  PlanItemStream  │
│  AIContrib    │  │  BlockLevel   │  │  Parser          │
│  Tracker      │  │  ErrorCodes   │  │  DG.parse        │
│  (~16866)     │  │  (~41400)     │  │  (~7502500)      │
└──────────────┘  └──────────────┘  └──────────────────┘
                                            │
                         ┌──────────────────┼──────────────────┐
                         v                  v                  v
                  ┌────────────┐  ┌──────────────┐  ┌──────────────┐
                  │ 服务层      │  │ UI 判定层     │  │ React 渲染层  │
                  │ _taskSvc   │  │ getRunCommand │  │ egR          │
                  │ _logSvc    │  │ CardBranch    │  │ RunCmdCard   │
                  │ storeSvc   │  │ (@8081545)   │  │ Alert        │
                  │ (~7503319) │  │              │  │ (~8635000+)  │
                  └────────────┘  └──────────────┘  └──────────────┘
                         │                  │                  │
                         v                  v                  v
                  ┌────────────────────────────────────────────────┐
                  │              Zustand Store                      │
                  │  needConfirm (~3211326)  │  badges  │  ...     │
                  └────────────────────────────────────────────────┘
```

## 7. 关键位置总索引

| 偏移量 | 内容 | 重要性 |
|--------|------|--------|
| ~41400 | ToolCallName 枚举定义 | 高 |
| ~44403 | Ck.Unconfirmed 枚举 | 高 |
| ~46856 | RunningStatus 枚举 (Io) | 中 |
| ~47202 | ChatTurnStatus 枚举 (bQ) | 中 |
| ~54000 | 错误码枚举 (kg) 第一处 | 高 |
| ~54269 | LLM_STOP_DUP_TOOL_CALL=4000009 | 高 |
| ~54415 | TASK_TURN_EXCEEDED_ERROR=4000002 | 高 |
| ~2665348 | AI.NEED_CONFIRM 枚举 | 中 |
| ~3211326 | needConfirm zustand store | 中 |
| ~6656253 | 英文 NLS "Loop detected..." | 低 |
| ~6801584 | 中文 NLS "检测到模型陷入循环..." | 低 |
| ~7161400 | 错误码枚举 (kg) 第二处 | 高 |
| ~7161547 | LLM_STOP_CONTENT_LOOP=4000012 | 高 |
| ~7169408 | 错误码→消息映射表 | 中 |
| ~7298705 | stopReason 字段接收 | 中 |
| ~7318521 | DG.parse 服务端响应解析 | 中 |
| ~7438600 | command.mode/allowList/denyList | 中 |
| ~7479332 | StreamStopType 枚举 (j9) | 中 |
| ~7502574 | confirm_status 检查+自动确认 | **极高** |
| ~7503319 | storeService + 服务层确认 | **极高** |
| ~7533176 | _onStreamingStop → WaitingInput | 中 |
| ~7614717 | ResumeChat 服务端方法 | 中 |
| ~8069382 | BlockLevel/AutoRunMode/ConfirmMode | 高 |
| @8081545 | getRunCommandCardBranch 核心判定 | 高 |
| ~8069700 | WHITELIST 模式沙箱逻辑 | 高 |
| ~8629200 | UI 确认状态判断 | 高 |
| ~8635000 | egR (RunCommandCard) 组件 | 高 |
| ~8636941 | ey useMemo 确认状态计算 | 高 |
| ~8640019 | 自动确认 useEffect | 高 |
| ~8695303 | efh 可恢复错误列表 | **极高** |
| ~8696378 | J 变量定义（可继续错误判断） | **极高** |
| ~8697580 | ec 回调（重试/恢复处理） | 高 |
| ~8697620 | ed 回调（"继续"按钮处理） | 高 |
| ~8697781 | D.resumeChat() 自动恢复 | 高 |
| ~8700000 | ErrorMessageWithActions 起始 | 高 |
| ~8702300 | if(V&&J) Alert 渲染分支 | **极高** |
| ~8702342 | auto-continue-thinking 补丁位置 | **极高** |
| ~8930000 | ErrorMessageWithActions 结束 | 低 |

### P0 新发现位置

| 偏移量 | 内容 | 重要性 |
|--------|------|--------|
| @55561 | ContactType 枚举（30+ 配额状态） | ⭐⭐⭐⭐⭐ |
| @54993 | ChatError 错误码枚举 | ⭐⭐⭐⭐ |
| @5870417 | API endpoints 配置 | ⭐⭐⭐⭐ |
| @7215828 | computeSelectedModelAndMode（Model 域核心） | ⭐⭐⭐⭐⭐ |

### 新域候选

| 域 | 核心位置 | 补丁潜力 | 说明 |
|----|---------|---------|------|
| Model 域 | @7215828 | 5/5 | computeSelectedModelAndMode 可开发 force-max-mode 补丁 |
| Docset 域 | 待探索 | 待评估 | 文档集/知识库相关逻辑 |
