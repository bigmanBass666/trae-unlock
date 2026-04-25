# Trae Source Architecture - 源码架构探索记录

> last_verified: 2026-04-26 | 兼容版本: Trae v3.3.x (10490354 chars)

> 本文档记录了 Trae IDE 源码的完整架构和关键位置，供后续 AI 探索和修改时参考。

## 安装信息

- **安装路径**: `D:\apps\Trae CN\resources\app\`
- **版本**: v3.3.x
- **打包状态**: 已解包（无 app.asar，直接编辑 JS 即可生效）
- **主进程**: Electron

---

## 目录结构总览

```
D:\apps\Trae CN\resources\app\
│
├── out/                                    # 编译后的前端代码
│   ├── main.js                             # 主进程入口
│   └── vs/workbench/
│       └── workbench.desktop.main.js       # 工作台主文件 (~15MB, 压缩)
│
├── node_modules/@byted-icube/              # Trae 自定义模块
│   └── ai-modules-chat/dist/index.js      # ⭐ AI 聊天模块 (核心!)
│
├── extensions/                             # 内置扩展
│   ├── cloudide.icube-agent-shell-exec/    # Shell 执行扩展
│   │   └── dist/
│   │       ├── services/shellExecService.js # Shell 服务
│   │       └── shell/shellExecutor.js     # Shell 执行器
│   └── mermaid-chat-features/              # 聊天功能扩展
│       └── dist/extension.js              # 扩展入口
│
├── modules/                                # 原生模块 (二进制 DLL/EXE)
│   ├── ai-agent/                           # AI Agent 模块
│   ├── ckg/                                # 配置管理
│   └── sandbox/                            # ⭐ 沙箱模块
│       ├── trae-sandbox.exe                 # 沙箱执行器
│       ├── sbox_sdk.dll                    # Windows Sandbox SDK
│       └── trae_sbox.dll                   # Trae 沙箱封装
│
└── resources/                              # 资源文件
    └── app/                               # 应用根目录
        └── ...                             # (当前已在 app 内)
```

---

## 核心文件详解

### 架构文档索引

以下子系统文档包含更详细的分析：

| 文档 | 内容 | 关键发现 |
|------|------|---------|
| [sse-stream-parser.md](sse-stream-parser.md) | SSE 流解析系统 | PlanItemStreamParser 完整生命周期、事件分发、状态管理 |
| [command-confirm-system.md](command-confirm-system.md) | 命令确认系统 | 双层确认架构、BlockLevel 完整逻辑、本地状态同步 |
| [limitation-map.md](limitation-map.md) | 限制点地图 | 错误码枚举、Alert 渲染点、BlockLevel、ToolCallName |
| [module-boundaries.md](module-boundaries.md) | 模块边界与依赖 | DI 容器、服务注入、事件系统、模块依赖关系图 |
| [di-service-registry.md](di-service-registry.md) | DI 服务注册表 | 51 个注册服务、101 个注入点、Symbol 迁移状态 |
| [sse-pipeline-topology.md](sse-pipeline-topology.md) | SSE 管道拓扑 | 13 事件类型、15 Parser、EventHandlerFactory 分发逻辑 |
| [store-architecture.md](store-architecture.md) | Store 架构 | 8 个 Zustand Store、两种 currentSession 模式、无 Immer |
| [explorer-protocol.md](explorer-protocol.md) | 探险家协议 | 工具决策树、交叉验证流程、发现记录规范 |
| [exploration-toolkit.md](exploration-toolkit.md) | 工具箱使用指南 | js-beautify、AST 搜索、模块级搜索的使用方法 |

### 1. ai-modules-chat/dist/index.js

**角色**: Trae AI 聊天系统的核心前端组件

**大小**: ~87MB（压缩后）

**关键功能**:
- AI 对话渲染
- Tool Call 显示和管理
- 命令确认流程（详见 [command-confirm-system.md](command-confirm-system.md)）
- PlanItem 解析流（详见 [sse-stream-parser.md](sse-stream-parser.md)）

#### 关键位置索引

| 位置 | 内容 | 重要性 | 专题文档 |
|------|------|--------|---------|
| ~41400 | ToolCallName 枚举定义 (RunCommand, ResponseToUser 等) | ⭐⭐⭐ | [limitation-map.md](limitation-map.md) |
| ~44403 | `Ck.Unconfirmed="unconfirmed"` 枚举定义 | ⭐⭐⭐ | [command-confirm-system.md](command-confirm-system.md) |
| ~46856 | RunningStatus 枚举 (Io) | ⭐⭐ | [store-architecture.md](store-architecture.md) |
| ~47202 | ChatTurnStatus 枚举 (bQ) | ⭐⭐ | [store-architecture.md](store-architecture.md) |
| ~54000 | 错误码枚举 (kg) 第一处定义 | ⭐⭐⭐ | [limitation-map.md](limitation-map.md) |
| ~54269 | `LLM_STOP_DUP_TOOL_CALL=4000009` | ⭐⭐⭐ | [limitation-map.md](limitation-map.md) |
| ~54415 | `TASK_TURN_EXCEEDED_ERROR=4000002` | ⭐⭐⭐ | [limitation-map.md](limitation-map.md) |
| ~2665348 | `AI.NEED_CONFIRM="unconfirmed"` 枚举定义 | ⭐⭐⭐ | [command-confirm-system.md](command-confirm-system.md) |
| ~3211326 | `needConfirm` zustand store 状态 | ⭐⭐⭐ | [store-architecture.md](store-architecture.md) |
| ~7161400 | 错误码枚举 (kg) 第二处定义 | ⭐⭐⭐ | [limitation-map.md](limitation-map.md) |
| ~7161547 | `LLM_STOP_CONTENT_LOOP=4000012` | ⭐⭐⭐ | [limitation-map.md](limitation-map.md) |
| ~7169408 | 错误码→消息映射表 | ⭐⭐ | [limitation-map.md](limitation-map.md) |
| ~7298705 | stopReason 字段接收 | ⭐⭐ | [sse-stream-parser.md](sse-stream-parser.md) |
| ~7318521 | DG.parse 服务端响应解析 | ⭐⭐⭐ | [sse-stream-parser.md](sse-stream-parser.md) |
| ~7438600 | `command.mode` / `command.allowList` / `command.denyList` 设置 | ⭐⭐ | [command-confirm-system.md](command-confirm-system.md) |
| ~7479332 | StreamStopType 枚举 (j9) | ⭐⭐ | [sse-stream-parser.md](sse-stream-parser.md) |
| ~7502500 | PlanItemStreamParser._handlePlanItem() 方法入口 | ⭐⭐⭐⭐⭐ | [sse-stream-parser.md](sse-stream-parser.md) |
| ~7502574 | `confirm_status==="unconfirmed"` 检查 + 自动确认 | ⭐⭐⭐⭐⭐ | [command-confirm-system.md](command-confirm-system.md) |
| ~7503319 | storeService.setBadgesBySessionId + 服务层确认 | ⭐⭐⭐⭐⭐ | [command-confirm-system.md](command-confirm-system.md) |
| ~7533176 | _onStreamingStop → WaitingInput | ⭐⭐⭐ | [sse-stream-parser.md](sse-stream-parser.md) |
| ~7614717 | ResumeChat 服务端方法调用 | ⭐⭐ | [sse-stream-parser.md](sse-stream-parser.md) |
| ~8069382 | BlockLevel/AutoRunMode/ConfirmMode 枚举定义 | ⭐⭐⭐⭐ | [command-confirm-system.md](command-confirm-system.md) |
| ~8069620 | getRunCommandCardBranch 核心判定方法 | ⭐⭐⭐⭐ | [command-confirm-system.md](command-confirm-system.md) |
| ~8069700 | WHITELIST 模式沙箱确认弹窗逻辑 | ⭐⭐⭐⭐ | [command-confirm-system.md](command-confirm-system.md) |
| ~8629200 | UI 确认状态判断 `g===Ck.Unconfirmed&&!f` | ⭐⭐⭐ | [command-confirm-system.md](command-confirm-system.md) |
| ~8630204 | 终端工具卡片确认状态 useMemo | ⭐⭐⭐ | [command-confirm-system.md](command-confirm-system.md) |
| ~8635000 | egR (RunCommandCard) React 组件 | ⭐⭐⭐⭐ | [command-confirm-system.md](command-confirm-system.md) |
| ~8636941 | ey useMemo 有效确认状态计算 | ⭐⭐⭐ | [command-confirm-system.md](command-confirm-system.md) |
| ~8640019 | 自动确认 useEffect | ⭐⭐⭐ | [command-confirm-system.md](command-confirm-system.md) |
| ~8695303 | efh 可恢复错误列表 | ⭐⭐⭐⭐⭐ | [limitation-map.md](limitation-map.md) |
| ~8696378 | J 变量定义（可继续错误判断） | ⭐⭐⭐⭐⭐ | [limitation-map.md](limitation-map.md) |
| ~8697580 | ec 回调（重试/恢复处理） | ⭐⭐⭐ | [limitation-map.md](limitation-map.md) |
| ~8697620 | ed 回调（"继续"按钮处理） | ⭐⭐⭐ | [limitation-map.md](limitation-map.md) |
| ~8697781 | D.resumeChat() 自动恢复 API | ⭐⭐⭐ | [sse-stream-parser.md](sse-stream-parser.md) |
| ~8700000 | ErrorMessageWithActions 组件起始 | ⭐⭐⭐ | [limitation-map.md](limitation-map.md) |
| ~8702300 | if(V&&J) Alert 渲染分支 | ⭐⭐⭐⭐⭐ | [limitation-map.md](limitation-map.md) |
| ~8702342 | auto-continue-thinking 补丁位置 | ⭐⭐⭐⭐⭐ | [limitation-map.md](limitation-map.md) |
| ~8930000 | ErrorMessageWithActions 组件结束 | ⭐⭐ | [limitation-map.md](limitation-map.md) |

### 2. workbench.desktop.main.js

**角色**: VSCode 工作台主文件（继承自 VSCode）

**大小**: ~15MB

**与命令确认相关的内容**:

| 位置 | 内容 | 重要性 |
|------|------|--------|
| ~12100101 | 终端工具 prepare 方法中的 `z` 变量（确认控制） | ⭐⭐⭐ |
| ~8925200 | `blockDetectedFileWrites` 文件写入检测 | ⭐⭐ |
| ~12072000 | TerminalAutoApproveRules 分析器 | ⭐⭐⭐ |
| ~6146361 | ShellExec sandbox 判断逻辑 | ⭐⭐⭐ |
| ~6154300 | SAFE_RM_ALLOWED_PATH / DENIED_PATH | ⭐⭐⭐ |

#### 终端工具确认机制

```javascript
// 位置 ~12100101
const z = w && C.some($ => $.isAutoApproved)
       && C.every($ => $.isAutoApproved !== !1)
       && x;
// z = true → confirmationMessages = undefined → 不弹窗
// z = false → 显示确认消息
```

这是 VSCode 层面的终端工具确认，但被 AI 模块层的确认覆盖。

### 3. cloudide.icube-agent-shell-exec (Shell 扩展)

**角色**: 实际执行终端命令的扩展

**关键文件**:
- `shellExecService.js` — 服务层，接收命令请求
- `shellExecutor.js` — 执行层，实际启动进程

**沙箱集成**:
```javascript
// 只在 execEnv === "sandbox" 时启用
if (e.execEnv === "sandbox" && TRAE_SANDBOX_CLI_PATH) {
    command = wrapWithSandbox(command);  // 通过 trae-sandbox.exe 包装
}
// 否则: 直接执行原始命令
```

### 4. modules/sandbox (沙箱原生模块)

**组成**:
- `trae-sandbox.exe` — 基于 Windows Sandbox SDK 的隔离执行环境
- `sbox_sdk.dll` — Microsoft Sandbox API
- `trae_sbox.dll` — Trae 的沙箱封装

**保护能力**:
- `SAFE_RM_AUTO_ADD_TEMP` — 自动添加临时目录到白名单
- `SAFE_RM_ALLOWED_PATH` — 允许删除的路径白名单
- `SAFE_RM_DENIED_PATH` — 禁止访问的路径黑名单
- `TRAE_SANDBOX_TRACE_FILE` — 命令执行追踪日志

**注意**: 只有设置 "在沙箱内运行" 时才生效。"始终在沙箱外运行" = 无保护。

---

## NLS 翻译系统

翻译文件是定位功能的关键线索：

| 文件 | 用途 |
|------|------|
| `out/nls.messages.json` | 英文翻译 |
| `out/nls.zh-cn.messages.json` | 中文翻译 |
| `out/nls.keys.json` | 翻译 key 列表 |

**搜索技巧**: 先搜中文/英文关键词找到 key，再用 key 定位代码。

已知的确认相关 key:
- `"dangerous command"` — 高风险命令提示
- `"severe consequence"` — 严重后果警告
- `"auto approve"` — 自动批准规则

---

## 设置系统

### 与命令确认相关的设置 ID

| 设置 ID | 类型 | 说明 |
|---------|------|------|
| `chat.tools.terminal.autoApprove` | boolean | 终端命令自动批准 |
| `chat.tools.terminal.ignoreDefaultAutoApproveRules` | boolean | 忽略默认规则 |
| `chat.tools.edits.autoApproveEdits` | boolean | 编辑自动批准 |
| `AI.toolcall.v2.command.mode` | string | 命令模式 |
| `AI.toolcall.v2.command.allowList` | array | 命令白名单 |
| `AI.toolcall.v2.command.denyList` | array | 命令黑名单 |
| `GlobalAutoApprove` | boolean | 全局自动批准 (YOLO 模式) |

---

## 搜索技巧总结

### 从现象到代码的搜索路径

```
用户看到: "检测到高风险命令" 弹窗
         ↓
搜索中文: Select-String -Pattern "高风险" *.json
         ↓
找到: nls.zh-cn.messages.json 中的翻译文本
         ↓
找对应英文: "dangerous command"
         ↓
搜索英文: 在 index.js 中搜索 "dangerous command"
         ↓
找到: @byted-icube/ai-modules-chat 模块
         ↓
深入分析: confirm_status / provideUserResponse / Unconfirmed 枚举
```

### PowerShell 搜索大文件的技巧

```powershell
# 搜索关键词并显示上下文
$content = [System.IO.File]::ReadAllText("file.js")
$idx = $content.IndexOf("keyword")
$content.Substring($idx - 100, 200)  # 前后各 100 字符

# 统计出现次数
($content.Split("pattern")).Count - 1

# 替换并验证
$content.Replace("old", "new")
[System.IO.File]::WriteAllText("file.js", $content)
```

### 注意事项

- Grep/Glob 工具对超大文件（>15MB）可能超时或失败
- 使用 `[System.IO.File]::ReadAllText()` 更可靠
- 沙箱限制下需用 `.NET API` 而非 PowerShell cmdlet 操作文件
- 修改后重启 Trae 窗口即可生效，无需完全退出

---

## 补丁安全规范 (2026-04-20 血的教训)

### ⚠️ 箭头函数规则

补丁中所有涉及 `this` 引用的回调函数 **必须** 使用箭头函数：

```javascript
// ❌ 错误：普通函数中 this 为 undefined（严格模式）
.catch(function(e){this._logService.warn("...",e)})

// ✅ 正确：箭头函数继承外层 this
.catch(e=>{this._logService.warn("...",e)})
```

**教训**: `service-layer-runcommand-confirm` v5 使用了普通函数 `.catch(function(e){...})`，当 Promise 被 reject 时，`this._logService` 抛出 `TypeError: Cannot read property 'warn' of undefined`，未捕获异常导致整个 React 组件树崩溃 → AI 聊天窗口消失。

### ⚠️ 不改变原始控制流

补丁 **不得** 引入 `return`、`break`、`continue` 等改变原始控制流的语句：

```javascript
// ❌ 错误：return 提前退出整个方法
if(!r){this._logService.warn("...");return}

// ✅ 正确：用 if/else 结构避免 return
if(r){provideUserResponse(...)}else{this._logService.warn("...")}
```

### ⚠️ check_fingerprint 必须精确匹配

`check_fingerprint` 字符串必须与 `replace_with` 生成的实际代码**完全一致**，包括括号：

```javascript
// ❌ 错误：缺少 ) 导致指纹不匹配，补丁被重复应用
"check_fingerprint": "confirm_status!==\"confirmed\"&&(this._taskService..."

// ✅ 正确：包含 ) 匹配实际代码
"check_fingerprint": "confirm_status!==\"confirmed\")&&(this._taskService..."
```

### ⚠️ find_original 不得是 replace_with 的子串

如果 `find_original` 是 `replace_with` 的前缀/子串，每次运行 `apply-patches.ps1` 都会重复应用补丁。必须确保 `find_original` 在 `replace_with` 中**不存在**（被替换后不应残留）。

### ⚠️ 双重调用防护

当多个补丁可能对同一数据调用同一 API 时，必须增加守卫条件：

```javascript
// 在 service-layer 补丁中检查 confirm_status 防止 knowledge 分支已处理
(e?.confirm_info?.confirm_status!=="confirmed")&&(this._taskService.provideUserResponse(...))
```
