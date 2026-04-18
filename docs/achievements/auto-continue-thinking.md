# 成果 2: 突破思考上限

> 模型思考超限时自动续接，用户无感知

## 问题描述

使用 Trae AI 进行长任务时，模型可能会达到"思考次数上限"，显示错误信息：

> "模型思考次数已达上限，请输入'继续'后获得更多结果"

此时 AI 会停止工作，需要用户手动点击"继续"按钮才能让 AI 继续工作。这在长时间任务中会频繁中断用户体验。

## 解决方案

### 方案 1: 自动点击"继续" (主要)

修改 AI 思考上限 Alert 弹窗的渲染逻辑，使用 `setTimeout` 在 50ms 后自动触发"继续"回调，然后返回 `null` 隐藏弹窗。

```javascript
// 原始逻辑: 渲染弹窗，等用户点击
if(V && J){
    return <Alert onActionClick={ed}>...</Alert>;
}

// 修改后: 自动触发 + 隐藏弹窗
if(V && J){
    setTimeout(function(){ed()}, 50);  // 50ms 后自动触发
    return null;  // 不渲染弹窗
}
```

### 方案 2: 扩展可恢复错误列表 (备用)

将 `TASK_TURN_EXCEEDED_ERROR` (4000002) 加入 `efh` 可恢复错误列表，使该错误也能触发 `resumeChat` 自动恢复。

## 技术实现

### 涉及补丁

| 补丁 ID | 位置 | 功能 |
|---------|------|------|
| `auto-continue-thinking` | ~8702342 | 自动点击"继续" |
| `efh-resume-list` | ~8695303 | 扩展可恢复错误列表 |

### 完整错误处理链路

```
服务端限制模型思考次数
    ↓
返回 TASK_TURN_EXCEEDED_ERROR (4000002)
    ↓ SSE 流
客户端接收 stopReason + errorCode
    ↓
判断是否在 efh 可恢复列表
    ↓
如果 auto-continue-thinking 补丁生效:
    → 50ms 后自动发送 "继续" 消息
    → 用户无感知，任务无缝续接
```

### 关键位置索引

| 位置 | 内容 |
|------|------|
| ~54415 | `TASK_TURN_EXCEEDED_ERROR=4000002` 枚举定义 |
| ~8695303 | `efh` 可恢复错误列表 |
| ~8697003 | `J` 变量判断是否显示"继续"按钮 |
| ~8702342 | Alert 渲染 + onActionClick 回调 |

## 效果

- ✅ 模型思考超限时不显示错误弹窗
- ✅ 50ms 后自动发送"继续"消息
- ✅ 任务无缝续接，用户完全无感知
- ✅ 不影响正常错误处理流程

## 相关文件

- 核心修改: `ai-modules-chat/dist/index.js` (~8702342, ~8695303)
- 架构文档: [docs/architecture/source-architecture.md](../architecture/source-architecture.md)
