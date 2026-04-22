# 修复 Spec 模式命令确认弹窗 Spec

## Why

Trae 更新后 `ey` useMemo 的逻辑变了：之前 `confirm_status=Unconfirmed` 时直接返回 `Ck.Confirmed`（自动确认），现在必须 `auto_confirm=true` 才能确认。导致 spec 模式下命令执行出现确认弹窗。

## What Changes

启用/重新实现 UI 层强制自动确认机制，让命令在不需要用户交互时自动执行。

## 根因

### ey useMemo 逻辑变化

**旧版（自动确认）**:
```javascript
ey = () => er===Unconfirmed ? Confirmed : en ? Confirmed : ...
// Unconfirmed → 直接 Confirmed ✅
```

**新版（需手动确认）**:
```javascript
ey = () => en ? Confirmed : isHistory && er===Unconfirmed ? Canceled : er
// auto_confirm=false + Unconfirmed → ey=Unconfirmed ❌ 弹窗!
```

### 解决方案选择

**方案 A: 启用 sync-force-confirm**
修改 ey useMemo，在检测到 Unconfirmed 时返回 Confirmed 并调用 eE(Confirmed)。
- 优点：同步执行，不依赖 useEffect 异步时机
- 缺点：find_original 可能不匹配新版代码（Trae 已更新）

**方案 B: 启用 data-source-auto-confirm**
在数据解析层（DG.parse）设置 `auto_confirm=true`。
- 优点：最底层拦截，所有组件都能看到 auto_confirm=true
- 缺点：影响范围大，可能影响 AskUserQuestion 等（需要配合黑名单）

**方案 C: 新写适配新版 ey 的补丁**
基于当前 ey 代码精确匹配并修改。
- 优点：精确适配当前版本
- 缺点：Trae 再更新可能又失效

## 推荐方案: B (data-source-auto-confirm) + 黑名单保护

原因：
1. 最底层拦截，不受 React 组件渲染时序影响
2. 配合已有的黑名单机制（response_to_user+AskUserQuestion+NotifyUser+ExitPlanMode），不会影响需要用户交互的工具
3. 即使 Trae 更新 ey 逻辑，只要数据层的 auto_confirm 设置生效就不受影响
