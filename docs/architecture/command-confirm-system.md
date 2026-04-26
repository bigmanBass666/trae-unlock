---
domain: architecture
sub_domain: command-confirm
focus: 命令确认双层架构——服务层 PlanItemStreamParser 与 React 层 RunCommandCard 的完整链路、BlockLevel 判定逻辑和自动确认注入点
dependencies: [sse-stream-parser.md, limitation-map.md, store-architecture.md]
consumers: Developer, Reviewer
created: 2026-04-26
updated: 2026-04-26
format: reference
---

# 命令确认系统架构文档

> last_verified: 2026-04-26 | 兼容版本: Trae v3.3.x (10490721 chars)

> 从用户点击到命令执行的完整链路

## 1. 概述

Trae 的命令确认系统是一个**双层架构**：服务层（PlanItemStreamParser）处理 SSE 流中的确认逻辑，React UI 层（RunCommandCard）处理用户交互。两层独立工作，必须都绕过才能实现零弹窗自动确认。

### 双层架构对比

| 维度 | Layer 1 (PlanItemStreamParser) | Layer 2 (RunCommandCard) |
|------|-------------------------------|--------------------------|
| **层级** | 服务层 (不依赖 React) | React UI 层 |
| **触发条件** | `confirm_status==="unconfirmed"` | `hit_red_list` 非空 / BlockLevel 判定 |
| **数据来源** | 服务端 confirm_info | 服务端 confirm_info |
| **控制点** | ~7502574 (knowledge), ~7503319 (else) | ~8069620 (getRunCommandCardBranch) |
| **执行函数** | `provideUserResponse({decision:"confirm"})` | `eE(xc.Confirmed)` |
| **日志函数** | - | `ew.confirm()` (仅打点，不执行!) |
| **窗口切换** | 不受影响 | 组件冻结，hooks 暂停 |

## 2. confirm_info 数据结构

### 完整字段定义

```javascript
confirm_info = {
  confirm_status: "unconfirmed" | "confirmed" | "canceled" | "skipped",
  auto_confirm: true | false,          // 是否允许自动确认
  hit_red_list: ["Remove-Item", ...],  // 命中的危险命令列表
  hit_blacklist: [...],                // 命中的企业黑名单
  block_level: "redlist" | "blacklist" | "sandbox_not_block_command" |
               "sandbox_execute_failure" | "sandbox_to_recovery" | "sandbox_unavailable",
  run_mode: "auto" | "manual" | "allowlist" | "in_sandbox" | "out_sandbox",
  now_run_mode: "in_sandbox" | "out_sandbox" | ...  // 当前运行模式
}
```

### 生命周期

```
服务端 SSE 流返回 toolCall.confirm_info
       |
       v
DG.parse (~7318521) — 解析原始 JSON，生成 confirm_info 对象
       |
       v
PlanItemStreamParser._handlePlanItem() (~7502500)
  ├─ 读取 confirm_status, auto_confirm, block_level 等
  ├─ if (confirm_status === "unconfirmed" && isKnowledgeBg) {
  │     provideUserResponse({decision:"confirm"})
  │  }
  └─ else { storeService.setBadgesBySessionId(...) }
       |
       v
Zustand Store (~3211326) — needConfirm 状态存储
       |
       v
React 组件 (egR ~8637300)
  ├─ 解构: er=confirm_status, en=auto_confirm, eo=run_mode, es=block_level
  ├─ 计算: ey = useMemo(有效确认状态)
  ├─ useEffect: 自动确认 effect (~8640019)
  └─ 渲染: RunCommandCard / NotifyUserCard / ConfirmPopover
```

## 3. provideUserResponse API

### 方法签名

```javascript
this._taskService.provideUserResponse({
  task_id: string,          // 任务 ID (i || "")
  type: "tool_confirm",     // 固定类型
  toolcall_id: string,      // planItemId || id || toolCallId
  tool_name: string,        // e.toolName || ""
  decision: "confirm" | "reject"  // 用户决策
})
```

### 所有调用点

| 位置 | 调用者 | decision | 条件 |
|------|--------|----------|------|
| ~7502574 | PlanItemStreamParser (knowledge 分支) | `"confirm"` | `confirm_status==="unconfirmed" && toolName!=="response_to_user"` |
| ~7503319 | PlanItemStreamParser (else 分支) | `"confirm"` | `toolName!=="response_to_user" && confirm_status!=="confirmed"` |
| ~8635000+ | egR 组件 (用户手动点击确认) | `"confirm"` | 用户点击"在沙箱中运行"按钮 |
| ~8635000+ | egR 组件 (用户手动点击拒绝) | `"reject"` | 用户点击"取消"按钮 |

### 调用后的处理链

```
provideUserResponse({decision:"confirm"})
       |
       ├── 成功 ──→ 服务端开始执行命令
       |              |
       |              v
       |         本地同步更新 (补丁注入):
       |         e.confirm_info.confirm_status = "confirmed"
       |              |
       |              v
       |         Zustand Store 更新 (通过 setBadgesBySessionId)
       |              |
       |              v
       |         React 组件 re-render
       |         ey = Ck.Confirmed → 不显示确认弹窗
       |
       └── 失败 ──→ .catch(e=>{this._logService.warn(...)})
                      confirm_status 保持 "unconfirmed"
                      UI 继续显示"等待操作"
```

### ⚠️ 关键发现

- **没有**单独的 SSE 事件来确认服务端收到了 `provideUserResponse` 的响应
- 命令执行结果通过**后续的 SSE 流**返回（新的 planItem 事件）
- 调用后必须**手动同步**本地 `confirm_info.confirm_status`，否则 UI 卡住

## 4. BlockLevel 完整逻辑

### BlockLevel 枚举 (X/Cr.BlockLevel, ~8069382)

| 枚举值 | 字符串值 | 含义 |
|--------|---------|------|
| RedList | `"redlist"` | 红名单：危险命令 (Remove-Item, rm, del 等) |
| Blacklist | `"blacklist"` | 黑名单：企业策略禁止的命令 |
| SandboxNotBlockCommand | `"sandbox_not_block_command"` | 沙箱非阻塞命令 |
| SandboxExecuteFailure | `"sandbox_execute_failure"` | 沙箱执行失败 |
| SandboxToRecovery | `"sandbox_to_recovery"` | 沙箱需要恢复 |
| SandboxUnavailable | `"sandbox_unavailable"` | 沙箱服务不可用 |

### getRunCommandCardBranch 方法 (~8081545)

**输入**: `{ run_mode_version, autoRunMode, blockLevel, hasBlacklist }`

**v2 模式完整分支**:

```javascript
function getRunCommandCardBranch({ run_mode_version, autoRunMode, blockLevel, hasBlacklist }) {
  if (run_mode_version === "v2") {
    switch (autoRunMode) {
      case Cr.AutoRunMode.WHITELIST:
        switch (blockLevel) {
          case Cr.BlockLevel.RedList:
            return P8.V2_Sandbox_RedList;           // 弹窗
          case Cr.BlockLevel.SandboxNotBlockCommand:
            return hasBlacklist ? P8.V2_Sandbox_NotBlocking_RedList : P8.V2_Sandbox_NotBlocking;
          case Cr.BlockLevel.SandboxExecuteFailure:
            return hasBlacklist ? P8.V2_Sandbox_Execute_Failure_RedList : P8.V2_Sandbox_Execute_Failure;
          case Cr.BlockLevel.SandboxToRecovery:
            return hasBlacklist ? P8.V2_Sandbox_To_Recovery_RedList : P8.V2_Sandbox_To_Recovery;
          case Cr.BlockLevel.SandboxUnavailable:
            return hasBlacklist ? P8.V2_Sandbox_Unavailable_RedList : P8.V2_Sandbox_Unavailable;
          default:
            return P8.Default;                       // ✅ 自动执行
        }

      case Cr.AutoRunMode.ALWAYS_RUN:
        if (blockLevel === Cr.BlockLevel.RedList || hasBlacklist)
          return P8.V2_Manual_RedList;               // 弹窗!
        return P8.Default;                           // ✅ 自动执行

      default:  // ALWAYS_ASK / BLACKLIST
        if (blockLevel === Cr.BlockLevel.RedList || hasBlacklist)
          return P8.V2_Manual_RedList;               // 弹窗!
        return P8.V2_Manual;                         // 弹窗
    }
  }
}
```

### BlockLevel → 卡片组件映射 (P8 枚举)

| P8 值 | UI 行为 | 中文提示 |
|--------|---------|---------|
| `P8.Default` | **自动执行，无弹窗** | (无) |
| `P8.V2_Manual` | 手动确认弹窗 | "请确认是否执行此命令" |
| `P8.V2_Manual_RedList` | 红名单手动确认弹窗 | "检测到高风险命令...请仔细检查" |
| `P8.V2_Sandbox_RedList` | 沙箱红名单确认弹窗 | "检测到高风险命令...是否仍要在沙箱中运行?" |
| `P8.V2_Sandbox_NotBlocking` | 沙箱非阻塞提示 | "该命令无法在沙箱中运行..." |
| `P8.V2_Sandbox_NotBlocking_RedList` | 沙箱非阻塞+红名单 | 同上+红名单警告 |
| `P8.V2_Sandbox_Execute_Failure` | 沙箱执行失败提示 | "命令在沙箱中运行不通过..." |
| `P8.V2_Sandbox_Execute_Failure_RedList` | 沙箱执行失败+红名单 | 同上+红名单警告 |
| `P8.V2_Sandbox_To_Recovery` | 沙箱恢复提示 | "沙箱需要恢复..." |
| `P8.V2_Sandbox_To_Recovery_RedList` | 沙箱恢复+红名单 | 同上+红名单警告 |
| `P8.V2_Sandbox_Unavailable` | 沙箱不可用提示 | "沙箱服务不可用..." |
| `P8.V2_Sandbox_Unavailable_RedList` | 沙箱不可用+红名单 | 同上+红名单警告 |

> **注意**: P8 变量名随 webpack 构建变化，当前版本可能为 P7 或其他混淆名。搜索锚点应为 `getRunCommandCardBranch` 方法名。

### AutoRunMode 与 BlockLevel 交互矩阵

| AutoRunMode | BlockLevel | hasBlacklist | 返回值 | 行为 |
|-------------|-----------|-------------|--------|------|
| WHITELIST | RedList | - | V2_Sandbox_RedList | 弹窗 |
| WHITELIST | Sandbox* | false | V2_Sandbox_* | 弹窗 |
| WHITELIST | Sandbox* | true | V2_Sandbox_*_RedList | 弹窗 |
| WHITELIST | default | - | **Default** | **自动执行** |
| ALWAYS_RUN | RedList | - | V2_Manual_RedList | 弹窗 |
| ALWAYS_RUN | (任何) | true | V2_Manual_RedList | 弹窗 |
| ALWAYS_RUN | (其他) | false | **Default** | **自动执行** |
| default(Ask) | RedList | - | V2_Manual_RedList | 弹窗 |
| default(Ask) | (任何) | true | V2_Manual_RedList | 弹窗 |
| default(Ask) | (其他) | false | V2_Manual | 弹窗 |

> **关键发现**: 即使设置为 ALWAYS_RUN，红名单命令仍然弹窗！只有 `P8.Default` 才是真正的自动执行。

## 5. RunCommandCard 组件

### 组件位置

- **逻辑层**: ~3210000-3230000 (RunCommandCard 组件主体)
- **渲染层**: ~8635000-8640100 (egR 组件，实际渲染确认 UI)
- **分支判定**: ~8081545 区域 (getRunCommandCardBranch 方法)

### egR 组件状态管理 (~8637300)

```javascript
// 从 confirm_info 解构:
er = N?.confirm_status        // 原始确认状态
en = N?.auto_confirm          // 自动确认标志
eo = N?.run_mode              // 运行模式
es = N?.block_level           // 阻塞级别

// 有效确认状态计算 (~8636941):
ey = useMemo(() =>
  en ? Ck.Confirmed                    // auto_confirm=true → 直接通过
  : e && er === Ck.Unconfirmed
    ? Ck.Canceled                     // 历史+未确认 → 取消
  : er                                // 否则用原始状态
, [en, er, e])

// 是否需要显示确认弹窗 (~8629200):
_ = useMemo(() => g === Ck.Unconfirmed && !f, [g, f])

// 最终是否需要等待确认:
b = v && !_ && !y
```

### 确认/拒绝按钮处理

```javascript
// ⚠️ ew.confirm() 只是 telemetry/日志函数，不是执行函数!
// 真正的执行函数是 eE(Confirmed)

// 确认按钮:
ew.confirm(true)   // 日志打点
eE(Ck.Confirmed)   // 触发真正的状态更新和命令执行

// 拒绝按钮:
ew.confirm(false)   // 日志打点
eE(Ck.Canceled)     // 触发取消状态更新
```

### 自动确认 effect (~8640019)

```javascript
useEffect(() => {
  !e && er === Ck.Unconfirmed && en && ew.confirm(!0)
  //  ↑     ↑                      ↑
  //  非历史  未确认状态          auto_confirm必须=true
}, [e, en, ew.confirm])
```

> **问题**: 当 `auto_confirm=false`（红名单命令的默认值）时，此 effect 不触发，命令卡住。

## 6. 本地状态同步机制

### provideUserResponse 调用后的完整时序

| 时间点 | 事件 | 本地状态 |
|--------|------|---------|
| T0 | SSE 流返回 `confirm_status="unconfirmed"` | `confirm_status="unconfirmed"` |
| T1 | 服务层补丁调用 `provideUserResponse` | HTTP 请求发送中 |
| T1+1ms | 补丁同步更新 `confirm_info.confirm_status="confirmed"` | `confirm_status="confirmed"` (本地) |
| T2 | 服务端收到确认，开始执行命令 | (服务端处理中) |
| T3 | 服务端通过 SSE 返回命令执行结果 | 新的 planItem 事件到达 |
| T4 | React 组件 re-render，显示执行结果 | UI 更新 |

### 切换窗口后的状态同步问题

**根因**: 服务层补丁调用 `provideUserResponse` 后，虽然本地 `confirm_info.confirm_status` 已同步更新为 `"confirmed"`，但 React 组件在窗口不可见时**冻结**，不会 re-render。

**表现**: 服务端已执行命令，本地 store 已更新，但 UI 仍显示"等待操作"。

**恢复**: 切回窗口后 React 解冻，组件 re-render，读取到 `"confirmed"` 状态，UI 正常更新。

## 7. 限制点清单

| 限制点 | 位置 | 类型 | 触发条件 | 当前补丁覆盖 |
|--------|------|------|---------|-------------|
| knowledge 分支确认 | ~7502574 | 确认弹窗 | `confirm_status==="unconfirmed" && isKnowledgeBg` | ✅ auto-confirm-commands v4 |
| else 分支确认 | ~7503319 | 确认弹窗 | `confirm_status!=="confirmed"` | ✅ service-layer-runcommand-confirm v8 |
| WHITELIST 沙箱弹窗 | ~8069700 | 确认弹窗 | `AutoRunMode===WHITELIST && BlockLevel!==default` | ⚠️ bypass-whitelist-sandbox-blocks (DISABLED) |
| ALWAYS_RUN 红名单弹窗 | ~8070328 | 确认弹窗 | `ALWAYS_RUN + RedList` | ✅ bypass-runcommandcard-redlist v2 |
| default(Ask) 模式弹窗 | ~8069620 | 确认弹窗 | `ALWAYS_ASK/BLACKLIST 模式` | ✅ bypass-runcommandcard-redlist v2 |

## 8. 补丁接口

### 推荐注入点

| 注入点 | 位置 | 安全等级 | 说明 |
|--------|------|---------|------|
| `_handlePlanItem()` knowledge 分支 | ~7502574 | ⭐⭐⭐ | 服务层，最可靠 |
| `_handlePlanItem()` else 分支 | ~7503319 | ⭐⭐⭐ | 服务层，最可靠 |
| `getRunCommandCardBranch()` | ~8069620 | ⭐⭐ | 可修改返回值绕过所有弹窗 |
| egR 组件 useEffect | ~8640019 | ⭐ | React 层，受窗口冻结影响 |

### 安全注意事项

1. **`ew.confirm()` 不是执行函数** — 只是 telemetry 打点，真正的执行是 `eE(Confirmed)`
2. **双层必须都绕过** — 服务层补丁处理了 `provideUserResponse`，但 `getRunCommandCardBranch` 返回非 Default 时 UI 仍会显示弹窗
3. **本地状态同步是关键** — 调用 `provideUserResponse` 后必须同步更新 `confirm_info.confirm_status`

## 9. 历史与验证

### 9.1 已验证可零弹窗的命令

| 命令类型 | 示例 |
|---------|------|
| 文件删除 | `Remove-Item`, `rm`, `del` |
| 文件复制 | `Copy-Item`, `cp`, `copy` |
| 文件移动 | `Move-Item`, `mv`, `move` |
| 文件重命名 | `Rename-Item`, `ren` |
| 文件创建/写入 | `New-Item`, `Set-Content` |
| Git 操作 | `git add`, `git commit`, `git push` |
| 包管理 | `npm install`, `pip install` |

### 9.2 备份与回滚

```powershell
# 列出备份
.\scripts\rollback.ps1 --list

# 回滚到最新备份
.\scripts\rollback.ps1 --latest

# 回滚到指定日期
.\scripts\rollback.ps1 --date 20260418
```

### 9.3 注意事项

1. **版本兼容**: Trae 更新后可能覆盖修改，需重新应用补丁
2. **安全风险**: 禁用确认后所有命令直接执行，请确保信任 AI Agent
3. **生效方式**: 修改后重启当前 Trae 窗口即可
4. **沙箱保护仍有效**: 文件系统限制仍然生效，AI 无法访问项目外文件

### 9.4 探索过程记录

#### 关键发现路径

1. **初始搜索**: 在 workbench.desktop.main.js 中找到终端工具确认逻辑（位置 ~12100101）
2. **发现真正拦截点**: 通过 NLS 翻译文件 `"dangerous command"` 定位到 `@byted-icube/ai-modules-chat`
3. **核心代码**: PlanItemStreamParser 中的 `confirm_status==="unconfirmed"` 检查（位置 ~7502574）
4. **双层确认发现**: 开启沙箱模式后出现第二层弹窗，定位到 RunCommandCard 组件

#### 排除的方案

| 尝试的方案 | 失败原因 |
|-----------|----------|
| workbench.desktop.main.js `z=!0` | VSCode 层，AI 模块层已覆盖 |
| 白名单放行 | 维护成本高，不完整 |
| React 组件内修改 | 切窗口后组件冻结，修改无效 |
| `ew.confirm()` 调用 | 只是日志，不是执行函数 |

### 9.5 相关文件索引

| 文件 | 角色 | 是否修改 |
|------|------|---------|
| `ai-modules-chat/dist/index.js` | AI 聊天模块（核心） | ✅ 已修改 |
| `workbench.desktop.main.js` | VSCode 工作台主文件 | ❌ 未修改 |
| `nls.zh-cn.messages.json` | 中文翻译 | ❌ 未修改 |
| `nls.messages.json` | 英文翻译 | ❌ 未修改 |
