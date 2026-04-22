# 修复补丁崩溃 + 安全恢复自动确认功能 Spec

## Why

上一版本应用 `auto-confirm-commands` 和 `service-layer-runcommand-confirm` 补丁后，整个 AI 聊天窗口消失（组件崩溃），用户被迫回滚到 20260419-214638 备份。需要定位崩溃根因、修复补丁定义、并安全地重新应用。

## 崩溃根因分析

### 原因 1（高概率）：`service-layer-runcommand-confirm` 的 `this` 绑定错误

补丁中 `.catch()` 使用了**普通函数**而非箭头函数：

```javascript
.catch(function(e){this._logService.warn("[PlanItemStreamParser] auto-confirm runcommand failed:",e)})
```

普通函数中 `this` 不指向 PlanItemStreamParser 实例（严格模式下为 `undefined`），当 Promise 被 reject 时，`this._logService` 抛出 `TypeError`，未捕获异常导致整个组件树崩溃。

而 `auto-confirm-commands` 补丁使用了箭头函数 `.catch(e=>{...})`，不会有此问题。

### 原因 2（中概率）：双重 `provideUserResponse` 调用

`auto-confirm-commands` 和 `service-layer-runcommand-confirm` 两个补丁可能对同一个 toolcall 都调用 `provideUserResponse`，导致服务端状态混乱。

### 原因 3（中概率）：`auto-confirm-commands` 补丁改变了控制流

补丁在 `if(!r)` 块中添加了 `return` 语句，改变了原始控制流，可能导致某些 toolcall 的处理被意外中断。

## What Changes

- **修复 `service-layer-runcommand-confirm`**：将 `.catch(function(e){this._logService...})` 改为 `.catch(e=>{this._logService...})`
- **修复 `auto-confirm-commands`**：移除 `return` 语句，改为仅跳过 provideUserResponse 调用但继续执行后续逻辑
- **消除双重调用风险**：在 `service-layer-runcommand-confirm` 中增加条件判断，跳过已被 knowledge 分支（auto-confirm-commands）处理的 toolcall
- **安全重新应用补丁**：逐个应用并验证，每步都确认聊天窗口正常

## Impact

- Affected files: `patches/definitions.json`, 目标文件 `ai-modules-chat/dist/index.js`
- Affected patches: `auto-confirm-commands`, `service-layer-runcommand-confirm`

## ADDED Requirements

### Requirement: 补丁中的箭头函数规范

所有补丁中涉及 `this` 引用的回调函数 SHALL 使用箭头函数而非普通函数，确保 `this` 正确绑定到外层上下文。

#### Scenario: .catch() 回调中的 this 绑定
- **WHEN** 补丁代码需要在 `.catch()` 回调中访问 `this._logService` 或 `this._taskService`
- **THEN** 必须使用箭头函数 `.catch(e=>{...})` 而非普通函数 `.catch(function(e){...})`

### Requirement: 补丁不改变原始控制流

补丁 SHALL NOT 引入改变原始代码控制流的语句（如 `return`、`break`、`continue`），除非该改变是补丁的核心目的。

#### Scenario: auto-confirm-commands 的 return 语句
- **WHEN** `auto-confirm-commands` 补丁检测到 toolcall id 为空
- **THEN** 仅跳过 provideUserResponse 调用，不使用 `return` 提前退出函数

### Requirement: 消除双重 provideUserResponse 调用

两个自动确认补丁 SHALL NOT 对同一个 toolcall 都调用 provideUserResponse。

#### Scenario: knowledge 分支和 else 分支的互斥
- **WHEN** `auto-confirm-commands` 已处理了 knowledge 分支的 toolcall
- **THEN** `service-layer-runcommand-confirm` 不应再次对同一 toolcall 调用 provideUserResponse

### Requirement: 安全的补丁应用流程

补丁应用 SHALL 采用逐步验证的方式，每应用一个补丁后都确认聊天窗口正常工作。

#### Scenario: 逐个应用补丁
- **WHEN** 重新应用 `auto-confirm-commands` 和 `service-layer-runcommand-confirm`
- **THEN** 先应用一个，验证无崩溃，再应用下一个

## MODIFIED Requirements

### Requirement: service-layer-runcommand-confirm 补丁定义 (v6)

修复 `.catch()` 的 `this` 绑定问题，改用箭头函数：

原（v5，有 bug）：
```
.catch(function(e){this._logService.warn("[PlanItemStreamParser] auto-confirm runcommand failed:",e)})
```

改（v6）：
```
.catch(e=>{this._logService.warn("[PlanItemStreamParser] auto-confirm runcommand failed:",e)})
```

### Requirement: auto-confirm-commands 补丁定义 (v3)

移除 `return` 语句，避免改变控制流。同时确保与 `service-layer-runcommand-confirm` 不会双重调用。
