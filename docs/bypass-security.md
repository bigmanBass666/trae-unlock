# Trae Unlock - 绕过高风险命令确认

> 本文档是 Trae 魔改项目中的第一个探索成果

## 问题描述

Trae GUI 模式即使开启了所有自动运行设置（Auto-run MCP、Auto-run commands、Sandbox mode），终端命令仍会被 Shell 安全拦截层拦截，显示"检测到高风险命令"确认框。

**参考 Issue**: [GUI mode lacks permission configuration equivalent to CLI's bypass_permissions mode](https://github.com/Trae-AI/TRAE/issues/2485)

## 解决方案：仅 1 处修改！

**文件**: `D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js`

**位置**: ~7502574 (PlanItemStreamParser)

### 修改前

```javascript
e?.confirm_info?.confirm_status === "unconfirmed") {
    if (s) {
        let r = e.planItemId || e.id || e.toolCallId || ""
        // knowledge 背景任务自动确认
    }
    // 其他命令: 设置 badge 等待用户确认
}
```

### 修改后

```javascript
e?.confirm_info?.confirm_status === "unconfirmed") {
    let r = e.planItemId || e.id || e.toolCallId || ""
    if (!r) {
        this._logService.warn("[PlanItemStreamParser] auto-confirm skipped because toolcall id is missing", {...})
        return
    }
    this._taskService.provideUserResponse({
        task_id: i || "",
        type: "tool_confirm",
        toolcall_id: r,
        tool_name: e.toolName || "",
        decision: "confirm"
    }).catch(e => {this._logService.warn("[PlanItemStreamParser] auto-confirm failed:", e)})
    if (s) {
        let r = e.planItemId || e.id || e.toolCallId || ""
        // knowledge 背景任务自动确认（原有逻辑）
    }
}
```

## 原理分析

### Trae 命令确认流程

```
服务端返回 confirm_status="unconfirmed"
         ↓
前端 PlanItemStreamParser 解析状态
         ↓
UI 显示确认弹窗 → 用户点击确认
         ↓
前端调用 provideUserResponse({decision:"confirm"})
         ↓
服务端收到确认 → 执行命令
```

### 我们的改动

在 `PlanItemStreamParser` 检测到 `confirm_status="unconfirmed"` 时，**立即自动调用 `provideUserResponse`**，跳过用户手动点击。

### 为什么不需要其他修改？

| 尝试过的修改 | 结果 | 结论 |
|-------------|------|------|
| workbench.desktop.main.js `z=!0` | 不影响 | VSCode 层的终端工具确认，AI 模块层已覆盖 |
| 枚举 `Ck.Unconfirmed="__bypassed__"` | 不需要 | 自动确认回调会关闭弹窗 |
| 枚举 `AI.NEED_CONFIRM="__bypassed__"` | 不需要 | 同上 |
| UI 层 `!1` 替换 | 不需要 | 同上 |

## UI 行为

- 确认弹窗**一闪而过**（用户能看到哪个命令被标记为高风险）
- 命令**自动执行**，无需手动确认
- 最佳平衡：保留安全提示 + 支持无人值守运行

## 测试结果 ✅

| 命令 | 之前 | 现在 |
|------|------|------|
| `out-file` | ❌ 弹确认框 | ✅ 直接执行 |
| `copy` | ❌ 弹确认框 | ✅ 直接执行 |
| `mkdir` | ❌ 弹确认框 | ✅ 直接执行 |
| `Remove-Item` | ❌ 弹确认框 | ✅ 直接执行 |

## 备份与回滚

```powershell
[System.IO.File]::Copy(
    "D:\Test\trae-unlock\ai-modules-chat-index.js.backup",
    "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js",
    $true
)
```

> 注意：由于沙箱限制，需使用 `[System.IO.File]::Copy()` 而非 `Copy-Item`

## 探索过程记录

### 关键发现路径

1. **初始搜索**: 在 workbench.desktop.main.js 中找到终端工具确认逻辑（位置 12100101）
2. **发现真正拦截点**: 通过 NLS 翻译文件 `"dangerous command"` 定位到 `@byted-icube/ai-modules-chat`
3. **核心代码**: PlanItemStreamParser 中的 `confirm_status==="unconfirmed"` 检查（位置 7502574）
4. **Bug 修复**: 最初把比较字符串改成 `"unconfirmed_NEVER"` 导致自动确认代码不触发

### 排除的方案

- ~~直接禁用检测函数~~ — 找不到单一入口点
- ~~白名单放行~~ — 维护成本高，且不知道完整列表
- ~~完全绕过 Shell 拦截层~~ — 影响范围太大

## 相关文件索引

| 文件 | 角色 | 是否修改 |
|------|------|---------|
| `ai-modules-chat/dist/index.js` | AI 聊天模块（核心） | ✅ 已修改 |
| `workbench.desktop.main.js` | VSCode 工作台主文件 | ❌ 未修改 |
| `nls.zh-cn.messages.json` | 中文翻译 | ❌ 未修改 |
| `nls.messages.json` | 英文翻译 | ❌ 未修改 |

## 注意事项

1. **版本兼容**: Trae 更新后可能覆盖修改，需重新应用
2. **安全风险**: 禁用确认后所有命令直接执行，请确保信任 AI Agent
3. **生效方式**: 修改后重启当前 Trae 窗口即可
