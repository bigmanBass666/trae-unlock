# Trae Unlock - 命令自动确认实现方案

> 本文档记录了 Trae IDE 的命令确认机制和完整的绕过方案。

## 问题描述

Trae GUI 模式下，即使开启了所有自动运行设置，危险命令（删除/复制/移动文件）仍会被拦截，显示确认框。

---

## 核心发现：双层确认系统

Trae 有**两套独立的命令确认机制**：

| 层级 | 组件 | 触发条件 | 原触发弹窗 |
|------|------|----------|------------|
| **Layer 1** | PlanItemStreamParser | `confirm_status==="unconfirmed"` | Popover 确认框 |
| **Layer 2** | RunCommandCard | `hit_red_list` 非空 | "是否仍要在沙箱中运行" |

---

## 完整解决方案：4 个核心补丁

**文件**: `D:\apps\Trarae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js`

| # | 补丁 ID | 位置 | 功能 |
|---|---------|------|------|
| **1** | `auto-confirm-commands` | ~7502574 | knowledge 类命令自动确认 |
| **8** | `service-layer-runcommand-confirm` | ~7503319 | RunCommandCard 类命令自动确认 |
| **2** | `auto-continue-thinking` | ~8702342 | 思考上限自动点"继续" |
| **3** | `efh-resume-list` | ~8695303 | 备用恢复列表扩展 |

### 为什么只有服务层补丁有效？

```
切换 AI 会话窗口后会发生什么？
  → React 冻结后台组件
  → useEffect / useMemo / useCallback 全部暂停
  → 任何 React 组件内的修改都无法生效

解决方案：在服务层（SSE 流解析器）修改
  → PlanItemStreamParser 不属于 React
  → SSE 数据到达时立即执行，不管窗口状态
```

---

## 补丁详解

### 补丁 #1: auto-confirm-commands (~7502574)

**功能**: knowledge 类命令自动确认

```javascript
// 修改位置: PlanItemStreamParser._handlePlanItem()
// 原始逻辑: 只有 knowledge 背景任务才自动确认
// 修改后: 所有 unconfirmed 命令都自动确认

// 在检测到 confirm_status==="unconfirmed" 时:
this._taskService.provideUserResponse({
    task_id: i || "",
    type: "tool_confirm",
    toolcall_id: r,  // planItemId || id || toolCallId
    tool_name: e.toolName || "",
    decision: "confirm"
}).catch(e => {
    this._logService.warn("[PlanItemStreamParser] auto-confirm failed:", e)
})
```

### 补丁 #8: service-layer-runcommand-confirm (~7503319)

**功能**: RunCommandCard 类命令（删除/复制/移动等）自动确认

```javascript
// 修改位置: PlanItemStreamParser 的 else 分支
// 原始逻辑: 只设置 badge，不调确认 API
// 修改后: 追加 provideUserResponse 调用

// 在 else 分支追加:
(e?.toolName||e?.id||e?.toolCallId)&&
(this._taskService.provideUserResponse({
    task_id: i||"",
    type: "tool_confirm",
    toolcall_id: e?.planItemId||e?.id||e?.toolCallId||"",
    tool_name: e?.toolName||"",
    decision: "confirm"
}).catch(function(e){
    this._logService.warn("[PlanItemStreamParser] auto-confirm runcommand failed:", e)
}))
```

### 补丁 #2: auto-continue-thinking (~8702342)

**功能**: 思考次数超限时自动点"继续"

```javascript
// 修改位置: AI 思考上限 Alert 渲染分支
// 原始逻辑: 渲染 Alert 弹窗，等用户点击"继续"
// 修改后: setTimeout 50ms 后自动触发 + return null 隐藏弹窗

if(V && J){
    let e = M.localize("continue", {}, "Continue");
    setTimeout(function(){ed()}, 50);  // 自动点击
    return null;  // 隐藏弹窗
}
```

### 补丁 #3: efh-resume-list (~8695303)

**功能**: 备用恢复列表扩展

```javascript
// 修改位置: efh 可恢复错误列表
// 原始: [..., kg.MODEL_FAIL]
// 修改后: [..., kg.MODEL_FAIL, kg.TASK_TURN_EXCEEDED_ERROR]

// 使思考超限错误也能触发 resumeChat 自动恢复
```

---

## 原理分析

### 命令确认完整流程

```
服务端 SSE 流返回:
  toolCall.confirm_info = {
    confirm_status: "unconfirmed" | "confirmed" | "canceled" | "skipped",
    auto_confirm: true | false,
    hit_red_list: ["Remove-Item", ...],
    block_level: "redlist" | ...
  }
         ↓
PlanItemStreamParser._handlePlanItem() (~7502500)
  → 解析 confirm_info
  → if (confirm_status === "unconfirmed") {
      this._taskService.provideUserResponse({decision: "confirm"})
      // ↑ 补丁 #1 和 #8 在这里注入自动确认
    }
         ↓
命令自动执行，无弹窗
```

### 关键 API

| API | 作用 | 备注 |
|-----|------|------|
| `provideUserResponse({decision:"confirm"})` | 通知服务端确认执行 | **真正的执行函数** |
| `ew.confirm()` | 日志/打点 | ❌ 不是执行函数 |

---

## UI 行为

- 确认弹窗**一闪而过**（用户能看到哪个命令被标记为高风险）
- 命令**自动执行**，无需手动确认
- 最佳平衡：保留安全提示 + 支持无人值守运行

---

## 已验证可零弹窗的命令

| 命令类型 | 示例 |
|---------|------|
| 文件删除 | `Remove-Item`, `rm`, `del` |
| 文件复制 | `Copy-Item`, `cp`, `copy` |
| 文件移动 | `Move-Item`, `mv`, `move` |
| 文件重命名 | `Rename-Item`, `ren` |
| 文件创建/写入 | `New-Item`, `Set-Content` |
| Git 操作 | `git add`, `git commit`, `git push` |
| 包管理 | `npm install`, `pip install` |

---

## 备份与回滚

```powershell
# 列出备份
.\scripts\rollback.ps1 --list

# 回滚到最新备份
.\scripts\rollback.ps1 --latest

# 回滚到指定日期
.\scripts\rollback.ps1 --date 20260418
```

---

## 注意事项

1. **版本兼容**: Trae 更新后可能覆盖修改，需重新应用补丁
2. **安全风险**: 禁用确认后所有命令直接执行，请确保信任 AI Agent
3. **生效方式**: 修改后重启当前 Trae 窗口即可
4. **沙箱保护仍有效**: 文件系统限制仍然生效，AI 无法访问项目外文件

---

## 探索过程记录

### 关键发现路径

1. **初始搜索**: 在 workbench.desktop.main.js 中找到终端工具确认逻辑（位置 ~12100101）
2. **发现真正拦截点**: 通过 NLS 翻译文件 `"dangerous command"` 定位到 `@byted-icube/ai-modules-chat`
3. **核心代码**: PlanItemStreamParser 中的 `confirm_status==="unconfirmed"` 检查（位置 ~7502574）
4. **双层确认发现**: 开启沙箱模式后出现第二层弹窗，定位到 RunCommandCard 组件

### 排除的方案

| 尝试的方案 | 失败原因 |
|-----------|----------|
| workbench.desktop.main.js `z=!0` | VSCode 层，AI 模块层已覆盖 |
| 白名单放行 | 维护成本高，不完整 |
| React 组件内修改 | 切窗口后组件冻结，修改无效 |
| `ew.confirm()` 调用 | 只是日志，不是执行函数 |

---

## 相关文件索引

| 文件 | 角色 | 是否修改 |
|------|------|---------|
| `ai-modules-chat/dist/index.js` | AI 聊天模块（核心） | ✅ 已修改 |
| `workbench.desktop.main.js` | VSCode 工作台主文件 | ❌ 未修改 |
| `nls.zh-cn.messages.json` | 中文翻译 | ❌ 未修改 |
| `nls.messages.json` | 英文翻译 | ❌ 未修改 |
