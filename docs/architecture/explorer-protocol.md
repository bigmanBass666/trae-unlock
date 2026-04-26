---
domain: architecture
sub_domain: protocol
focus: Explorer Agent 标准操作程序（SOP）——工具决策树、交叉验证流程、发现记录规范和盲区风险评估协议
dependencies: [exploration-toolkit.md, source-architecture.md]
consumers: Explorer
created: 2026-04-25
updated: 2026-04-26
format: reference
---

# 探险家 Agent 探索协议

> **版本**: 1.0 | **创建日期**: 2026-04-25 | **适用项目**: trae-unlock
>
> last_verified: 2026-04-26 | 兼容版本: Trae v3.3.x (10490721 chars)
>
> 本文档是 Trae IDE 源码探索的**标准操作程序 (SOP)**。所有参与源码探索的 AI Agent 必须在开始工作前通读本文档，并在探索过程中严格遵循其中的规范。
>
> **目标读者**: 未来负责继续探索 Trae `@byted-icube/ai-modules-chat/dist/index.js`（~10MB 单行压缩 JS）的 AI 编码 Agent。

## §1 概述

> **定位**: Explorer Agent 标准操作程序（SOP）——工具决策树、交叉验证流程、发现记录规范和盲区风险评估协议
>
> **为什么重要**: 所有参与 Trae IDE 源码探索的 AI Agent 必须遵循的规范。确保探索结果可重复、可验证、可交接。
>
> **在整体中的位置**: 依赖 exploration-toolkit 定义的工具链，依赖 source-architecture 提供的关键位置索引。产出写入 discoveries.md。

---

## 第1章: 探险家身份与使命

### 1.1 你是谁

你是一个**自主代码探索 Agent (Explorer Agent)**，你的存在目的是在 Trae IDE 的 ~10MB 压缩 JavaScript 源码中进行系统性、可重复、可验证的代码测绘。

你不是来写补丁的（那是 Patch Agent 的工作），你是来**画地图**的。你的产出是精确的代码位置、架构关系和搜索模板，供后续的 Patch Agent 使用。

### 1.2 你的使命

Trae 的源码是一个约 10MB 的单行压缩 JS 文件（`@byted-icube/ai-modules-chat/dist/index.js`）。这个文件包含了整个 AI 聊天模块的所有逻辑：DI 容器、SSE 流管道、状态管理、错误处理、React 组件、IPC 通信等。

你的使命是：

1. **发现未知区域** — 在已有地图之外找到新的代码域
2. **验证已知位置** — 用独立路径确认前序发现的准确性
3. **记录搜索模板** — 让未来的 Agent 能在新版本中重新定位同一功能
4. **评估盲区风险** — 标注哪些未探索区域可能包含关键逻辑

### 1.3 你要解决的问题：路径依赖

前序探险家（2026-04-23 至 2026-04-25）已经完成了大规模探索，覆盖了 10 大领域、3000+ 行发现记录。但这些发现有一个根本性的弱点：

> **路径依赖**: 前序探索者只找到了他们恰好去寻找的东西。如果某个功能不在他们的搜索路径上，它就永远处于"未被发现"状态。

例如：
- 前序探索者搜索"思考上限错误"，发现了 IPC 路径 → 但可能遗漏了其他错误类型的传播路径
- 前序探索者从 DI token 出发映射了服务注册表 → 但 uJ() 注册的 186 个服务只详细记录了约 30 个
- 前序探索者聚焦于 L2 服务层 → 但 8930000+ 到文件末尾的大量 UI 代码几乎未触及

**你的工作是打破这种路径依赖，用系统化的方法扫描所有可能的区域。**

### 1.4 诚实准则 (Code of Honesty)

作为探险家，你必须遵守以下准则：

| 准则 | 说明 | 违规后果 |
|------|------|---------|
| **不伪造偏移量** | 永远用 `$c.IndexOf()` 实际测量，不要猜测或外推 | 导致后续补丁注入到错误位置 |
| **不隐瞒不确定性** | 如果无法确定某段代码的功能，明确标注 confidence=low | 虚假自信误导后续决策 |
| **记录推理链** | 每个发现都要说明"从什么锚点出发→怎么扩展→为什么这样判断" | 无法复现/无法验证 |
| **报告负面结果** | 搜索了但没找到也是有价值的信息（排除法） | 浪费后续 Agent 重复搜索 |
| **区分观察与推断** | "我看到了 X" ≠ "我认为 X 是 Y" | 推断被当作事实使用 |

### 1.5 黄金规则：稳定锚点优先 (Stable Anchors Only)

在压缩混淆的 JS 中搜索代码时，锚点的选择决定了搜索的可靠性。以下是稳定性金字塔：

```
        ⭐⭐⭐⭐⭐ Symbol.for("...") 字符串     ← 最稳定，跨版本不变
        ⭐⭐⭐⭐   Symbol("...") 字符串         ← 很稳定，模块内不变
        ⭐⭐⭐     API 方法名 (resumeChat 等)     ← 较稳定，业务逻辑不变
        ⭐⭐       枚举字符串 ("redlist" 等)     ← 稳定，协议级常量
        ⭐         混淆变量名 (uj, xC, zU 等)    ← 不稳定，每次构建变化
```

**核心规则**: 只用 ⭐⭐⭐ 及以上锚点作为搜索起点。⭐⭐ 锚点可用于确认但不作为起点。

### 1.6 关键纠正事实库

在前序探索中，以下误解曾被广泛持有并被后续纠正。你必须了解这些纠正，避免重蹈覆辙：

| 错误认知 | 正确事实 | 发现日期 | 来源 |
|---------|---------|---------|------|
| BR 是 DI Token（_sessionServiceV2） | **BR = Node.js path 模块** (`s(72103)`)，有 `.relative()`, `.basename()` | 2026-04-25 | DI 容器完整映射 |
| FX 是 DI 解构模式 | **FX = findTargetAgent 辅助函数** (`async function FX(e,t,i,r,n=!1,o)`) | 2026-04-25 | DI 容器完整映射 |
| Bs 是 ChatStreamService | **Bs 是 ChatParserContext（数据类）**，**Bo 才是 ChatStreamService 基类** | 2026-04-25 | SSE 流管道拓扑 |
| 思考上限错误走 SSE ErrorStreamParser | **思考上限错误走 IPC 路径**，不经过 SSE ErrorStreamParser.parse() | 2026-04-23 | v10/v12 失败分析 |
| ew.confirm() 是执行函数 | **ew.confirm() 仅是 telemetry 打点**，真正执行是 eE(Ck.Confirmed) | 2026-04-23 | React 组件层级 |
| J 变量控制所有可恢复错误 | **J 只控制是否显示"继续"按钮**，实际恢复还需 efh 列表 + agentProcess==="v3" | 2026-04-23 | 错误处理系统 |
| store.subscribe 参数是 (prev, curr) | **Zustand subscribe 参数顺序是 (curr, prev)**，第1个是新状态 | 2026-04-23 | v11.1 Bug修复 |
| exception 通过显式赋值写入 | **exception 在主进程构造后随 IPC 到达**，index.js 中仅 TaskAgentMessageParser 有1处显式赋值且不走思考上限路径 | 2026-04-23 | v12 零输出分析 |
| J 变量已重命名为 K | **J→K 重命名未发生**，J 仍是"显示继续按钮"变量，handoff 中的报告有误 | 2026-04-25 | v2 版本适配审计 |
| 付费限制错误码为 1016/1017/1023 | **PREMIUM_MODE_USAGE_LIMIT=4008(非1016), STANDARD_MODE_USAGE_LIMIT=4009(非1017), FIREWALL_BLOCKED=700(非1023)** | 2026-04-25 | v2 商业权限域映射 |
| auto-continue 可放在 L1 React 层 | **L1 在后台标签页冻结**（Chromium 停止 rAF → React Scheduler 降级） | 2026-04-22 | L1 冻结原则 |
| ICommercialPermissionService 使用 Symbol.for 注册 | **ICommercialPermissionService 通过 `aiAgent.ICommercialPermissionService` 命名空间前缀注册** (@7197035)，非 Symbol.for/Symbol | 2026-04-26 | DI 审计纠正 |
| DI 注册数为 51 / 注入数为 101 | **DI 注册数为 186 / 注入数为 817** (uJ/uX 搜索确认) | 2026-04-26 | DI 审计纠正 |
| kg 错误码约 30 个 | **kg 错误码完整穷举为 56 个** | 2026-04-26 | 错误码审计 |
| beautified.js 为 347,099 行 | **beautified.js 为 347,244 行** | 2026-04-26 | 文件统计更新 |
| ToolCallName 约 12 个 | **ToolCallName 完整枚举为 38 个** (@40836) | 2026-04-26 | 枚举审计 |

---

## 第2章: 启动必做清单 (Explorer Onboarding Checklist)

每个 Explorer Agent 在开始任何探索工作之前，**必须**按以下顺序完成所有步骤。跳过任何一步都可能导致在破损/过时的基础上工作，浪费计算资源并产生不可靠的发现。

### Step 1: 读 handoff.md — 上一个会话留下了什么

**操作**: 阅读 `shared/handoff.md`（全文）

**看什么**:
- 上一个会话完成了什么工作
- 当前补丁状态（哪些启用/禁用）
- 已知的问题和未解决的疑问
- 下一步建议方向

**为什么重要**: handoff.md 是会话间的"接力棒"。不读它 = 不知道上一个跑者跑到哪了，可能重复已完成的工作或在已知失败的方向上浪费时间。

**预期耗时**: 1-2 分钟

### Step 2: 运行 auto-heal — 补丁健康检查

**操作**: 在终端执行：
```powershell
powershell scripts/auto-heal.ps1 -DiagnoseOnly
```

**看什么**:
- 所有补丁的 applied/verified 状态
- 目标文件是否存在、大小是否正常
- fingerprint 匹配情况
- 是否有损坏的备份

**为什么重要**: 如果目标文件已损坏（如白屏状态的残留修改），你所有的偏移量测量都会基于错误的文件内容。不自检 = 在垃圾上建大厦。

**预期耗时**: 30 秒 - 1 分钟

### Step 3: 读 discoveries.md — 已知地图全貌

**操作**: 阅读 `shared/discoveries.md`（重点看以下部分）

**看什么**:
- **最后的偏移量索引**（通常在文末）— 了解当前已知的所有坐标点
- **各域章节的最新条目** — 特别是标注了 ⭐⭐⭐⭐⭐ 的重要发现
- **更正记录**（`> **更正 [日期]:**` 格式）— 避免使用已被推翻的认知
- **conflict_notes** 字段 — 了解现有争议点

**为什么重要**: discoveries.md 是本项目的"藏宝图"。90% 你想找的东西前人已经找过了。先查地图再出发，避免重复劳动。

**阅读策略**:
- 第一次读：快速浏览所有标题，建立全局印象
- 第二次读：精读与你当前任务相关的域
- 工作中随时查阅：把它当参考手册

**预期耗时**: 5-10 分钟（首次）/ 2-3 分钟（后续）

### Step 4: 读 context.md — 项目上下文和架构洞察

**操作**: 阅读 `shared/context.md`（全文）

**看什么**:
- 项目基本信息（技术栈、目标平台、核心源码位置）
- 关键架构洞察（6 条核心原则）
- 补丁版本总览
- 架构文档索引

**为什么重要**: context.md 提供了"元知识"——不是具体的代码位置，而是指导如何理解这些位置的框架性认识。特别是 L1 冻结原则和服务层优先原则，直接影响探索方向的决策。

**预期耗时**: 2-3 分钟

### Step 5: 读架构文档 — docs/architecture/ 下所有 .md 文件

**操作**: 列出并阅读 `docs/architecture/` 目录下的所有 .md 文件

**当前已知文档列表**:
| 文件 | 内容概要 |
|------|---------|
| [source-architecture.md](./source-architecture.md) | 源码整体架构解读 |
| [sse-stream-parser.md](./sse-stream-parser.md) | SSE 流解析系统详解 |
| [command-confirm-system.md](./command-confirm-system.md) | 命令确认系统详解 |
| [limitation-map.md](./limitation-map.md) | 限制点地图 |
| [module-boundaries.md](./reference/module-boundaries.md) | 模块边界与依赖关系 |
| [di-service-registry.md](./reference/di-service-registry.md) | DI 服务注册表 |
| [command-confirm-system.md](./command-confirm-system.md) | Trae 确认系统综合 |

**看什么**:
- 各文档中的偏移量引用（可能与 discoveries.md 一致或有更新）
- 架构图和数据流描述
- 未解决的问题和 TODO 项

**为什么重要**: 架构文档是对 discoveries.md 中原始发现的**结构化整理**。它们提供了更高层次的视角，帮助你在具体代码片段之间建立联系。

**预期耗时**: 10-15 分钟（首次）

### Step 6: 验证目标文件 — 确认 index.js 存在且可读

**操作**: 执行以下 PowerShell 命令：
```powershell
$path = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$f = Get-Item $path -ErrorAction SilentlyContinue
if ($f) {
    Write-Host "File exists: $($f.FullName)"
    Write-Host "Size: $([math]::Round($f.Length / 1MB, 2)) MB"
    Write-Host "Last modified: $($f.LastWriteTime)"
    $c = [IO.File]::ReadAllText($path)
    Write-Host "Total length: $($c.Length) chars"
} else {
    Write-Host "ERROR: File not found at $path"
}
```

**看什么**:
- 文件大小应在 9-11MB 范围内（不同版本可能有差异）
- 最后修改时间应合理（不应是未来时间）
- 总字符数应与大小匹配

**为什么重要**: Trae 更新会替换此文件。如果你基于旧版本的偏移量在新文件上工作，所有定位都会偏移。此外，确认文件可读确保没有权限问题或文件锁定。

**预期耗时**: < 10 秒

### Step 7: 验证搜索工具 — 确认 search-templates.ps1 可用

**操作**:
```powershell
# 检查脚本存在
Test-Path scripts/search-templates.ps1

# 快速测试 Search-Generic 功能
$c = [IO.File]::ReadAllText("D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js")
$idx = $c.IndexOf("Symbol(""IPlanItemStreamParser"")")
Write-Host "Test anchor found at offset: $idx"
if ($idx -gt 0) {
    Write-Host "Context (100 chars): $($c.Substring($idx, 100))"
}
```

**看什么**:
- `search-templates.ps1` 文件存在
- 能成功读取目标文件
- 至少一个已知锚点能被正确定位（如 `Symbol("IPlanItemStreamParser")` 应在 ~7510931 附近）

**为什么重要**: 所有探索工作都依赖 `$c.IndexOf()` 子串搜索。如果在启动阶段就发现工具链有问题，可以立即修复而不是在深入探索后才意识到数据不可靠。

**预期耗时**: < 30 秒

### Step 8: 检查可选工具链（新增）

**操作**: 
```powershell
# 加载工具检测脚本
. "$PSScriptRoot\..\scripts\unpack.ps1"
Test-ToolAvailability
```

**看什么**:
- webcrack 是否可用（用于 webpack 解包，注意：当前版本不兼容 TS 装饰器）
- js-beastify 是否可用（✅ 主要美化工具，已验证可用）
- Node.js + @babel/parser 是否可用（AST 分析）
- reverse-machine 是否可用（可选 AI 增强反混淆）

**为什么重要**: 工具可用性决定你能使用的探索层级。没有工具 = 只能用 Layer 0（IndexOf）。

**预期耗时**: < 30 秒

---

## 第3章: 已知地图边界声明 (Known Map Boundaries)

本章声明了前序探索已经覆盖的区域和尚未触达的盲区。你的首要任务之一就是缩小这些盲区。

### 3.1 已探索域总览

前序探索（2026-04-23 至 2026-04-25）完成了 10 大领域的系统性测绘：

| # | 域 | 标签 | 偏移量范围 | 覆盖范围估计 | 关键发现数 | confidence | 盲区评估 |
|---|-----|------|-----------|-------------|-----------|------------|---------|
| 1 | DI 依赖注入容器 | [DI] | ~6268469-7545196 | ~1.28MB | 30+ tokens, 186 services, 817 injections | **high** | FX 解析字段不完整；uJ() 186 服务只详细记录了约 30 个 |
| 2 | SSE 流管道 | [SSE] | ~7300000-7616470 | ~316KB | 13 event types, 15 parsers, EventHandlerFactory | **high** | DZ/Dq 预解析器细节不足；Bo base class Template Method 骨架不完整 |
| 3 | Store 状态管理 | [Store] | ~7087490-7605848 | ~520KB | 8 stores, 两种 currentSession 模式 | **medium** | SessionStore mutations 不完整；badges 数据流未知；setRunningStatusMap 不详 |
| 4 | 错误处理系统 | [Error] | ~54000-8696378 | 全文件散布 | 27+ error codes, 3 propagation paths | **medium** | kg 枚举完整值未知；handleCommonError 内部映射不全；_aiChatRequestErrorService API 不完整 |
| 5 | React 组件层 | [React] | ~2796260-8930000 | ~6MB | 17+ alerts, 3-layer architecture, freeze behavior | **low** | 8700000-8930000 Alert #6-#17 精度不足；8930000+ UI 代码完全未探索；组件树下半部缺失 |
| 6 | 事件总线与遥测 | [Event] | ~16866-7610443 | 全文件散布 | TEA events, Zustand subscribes, DOM listeners | **medium** | TeaReporter 方法列表不全；teaEventChatShown/Retry 定义缺失；YTr 事件接收端不详 |
| 7 | IPC 进程间通信 | [IPC] | ~619104301-7610443 | 全文件散布 | 17 shell commands, 3-layer IPC architecture | **medium** | workbench.desktop.main.js 内部细节缺失；YTr 完整注册表未知；ExtHostShellExecService 事件流不详 |
| 8 | 设置与配置 | [Setting] | ~7438600-8069382 | ~630KB | 8 setting keys, BlockLevel/AutoRunMode/ConfirmMode | **low** | onDidChangeConfiguration 实现未知；设置变更传播机制未知；GlobalAutoApprove 影响范围不明 |
| 9 | 沙箱与命令执行 | [Sandbox] | ~7502500-~8070328 | ~570KB | enums, pipeline, SAFE_RM rules | **medium** | safe_rm_aliases.ps1/sh 内容未知；trae-sandbox.exe 调用方式未知；VirtualTerminal 生命周期不详 |
| 10 | MCP 与工具调用 | [MCP] | ~41400-~8635000 | 全文件散布 | 80+ ToolCallNames, confirm_info structure, lifecycle | **low** | MCP server 注册机制未知；工具调用权限模型未知；browser_* 20+ 工具枚举不全 |
| 11 | 商业权限域 | [Commercial] | ~6479431-8707858 | 全文件散布 | ICommercialPermissionService 6方法, IEntitlementStore, ICredentialStore, bJ枚举, ee配额标志 | **high** | NS 方法实现细节; CredentialStore 完整结构; efr 枚举完整值 |

### 3.2 已知盲区详细列表

#### [DI] 盲区

| 盲区项 | 当前已知程度 | 为什么重要 | 建议探索方法 |
|-------|------------|-----------|------------|
| uJ() 注册的 186 个服务的完整参数结构 | 只记录了类名和 Token，不知道构造函数参数和依赖 | 新服务可能需要特定初始化参数才能 resolve 成功 | 对每个 uJ({identifier:X}) 向后扩展 500 字符查看 constructor |
| FX() 函数的完整参数结构和返回值 | 只知道签名 `async function FX(e,t,i,r,n=!1,o)` 和用途是 findTargetAgent | FX 可能是 Agent 路由的关键入口 | 从 @7604449 出发双向扩展，追踪所有调用点 |
| hX() 的所有使用点 | 只知道定义在 @6270579，使用点不完全 | hX 是容器的快捷方式，所有使用点都是潜在的服务访问入口 | 搜索 `hX()` 所有出现位置 |
| uP (DependencyRegistry) 类的完整实现 | 只知道 `new uP` 创建实例 | 依赖注册表可能包含延迟加载、条件注册等高级特性 | 从 `new uP` 出发追踪类定义 |
| uB (useInject Hook) 的完整实现细节 | 只知道基本结构，MockServiceContext 行为不详 | uB 是 React 组件获取 DI 服务的唯一途径，影响 L1 补丁设计 | 从 @6270579 深入分析 useMemo/useSyncExternalStore 逻辑 |
| S2 (VS Code 服务标识对象) 的完整属性列表 | 只知道部分 IEditorService/IFileService 等 | S2 包含 VS Code 原生服务接口标识，对主进程通信至关重要 | 搜索 `S2.` 所有属性访问 |

#### [SSE] 盲区

| 盲区项 | 当前已知程度 | 为什么重要 | 建议探索方法 |
|-------|------------|-----------|------------|
| DZ/Dq 预解析器的完整逻辑 | 只知道名称和大致位置 (~7300000) | 预解析器可能在 Parser 之前做数据转换，影响 payload 结构 | 从 DZ/Dq 变量名出发双向扩展 |
| Bs (ChatParserContext) 类的所有字段和方法 | 知道它是数据类，不知道完整字段列表 | Context 对象携带 session/scene 信息，影响 parse() 行为 | 从 Bs class 定义出发提取所有属性赋值 |
| Bo (ChatStreamService base) 的完整 Template Method 骨架 | 只知道继承关系 `class Bw extends Bs` (原 class Bv extends Bo 已迁移) | Template Method 模式意味着基类定义了 _onMessage/_onError/_onComplete 的默认行为 | 从 `ChatStreamService` log字符串或 `Symbol.for("ISideChatStreamService")` 出发定位基类 |
| Bw vs BC (SideChat vs Inline) 的具体差异 | 只知道一个是侧边栏一个是内联，差异细节不明 | 两者的错误处理路径可能不同，影响补丁选择 | 并列对比两者的 _onError/_onMessage 实现 |
| EventHandlerFactory (Bt) 的 register/handle 完整实现 | 只知道基本模式 `handle(event, payload, context)` | Factory 的路由逻辑决定哪个 Parser 处理哪个事件 | 从 Bt 变量出发追踪 register 调用和 handle 分发逻辑 |
| DG.parse() 的完整实现 | 只知道位置 ~7320642 和用途（L3 数据层拦截），原 DG 变量名已迁移 | DG.parse 是最早的数据拦截点，可能是最稳定的补丁位置 | 从 `Symbol("IMetadataParser")` Token 出发定位 MetadataParser 类 |

#### [Store] 盲区

| 盲区项 | 当前已知程度 | 为什么重要 | 建议探索方法 |
|-------|------------|-----------|------------|
| SessionStore 的完整 mutation 列表 | 只知道 setCurrentMessage/updateMessage/updateLastMessage | 其他 mutations（如 addMessage/removeSession/forkSession）可能对补丁设计有用 | 从 xI (SessionStore class) 定义出发，列出所有方法 |
| 所有 getState() 使用点的完整列表 | 只知道少数几个在 ~7588518 和 ~7584046 | getState() 是读取 Store 的唯一同步方式，所有使用点都是潜在的 hook 点 | 搜索 `.getState()` 所有出现位置 |
| badges 系统的完整数据流 | 完全未知 | badges 可能影响 UI 显示和用户交互决策 | 搜索 `badge` 相关字符串 |
| setRunningStatusMap / RunningStatus 枚举的完整使用链 | 只知道 RunningStatus 枚举值(~46816)，setRunningStatusMap 调用点不详 | runningStatus 影响暂停按钮状态，是用户体验的关键部分 | 从 RunningStatus 枚举出发追踪所有引用 |
| InlineSessionStore 的完整 mutation 列表 | 几乎未知 | 内联聊天的 Store 操作可能与主聊天不同 | 从 I4 (InlineSessionStore class) 定义出发 |
| Zustand middleware 配置（如有） | 确认无 Immer，但不清楚是否有其他 middleware | middleware 可能影响 setState 行为和订阅触发时机 | 搜索 `create(` 或 `devtools` 或 `persist` 等 middleware 关键字 |

#### [Error] 盲区

| 盲区项 | 当前已知程度 | 为什么重要 | 建议探索方法 |
|-------|------------|-----------|------------|
| kg 枚举的完整值列表 | 记录了 ~12 个，但注释说 "27+" 且可能更多 | 每个新错误码都可能需要对应的恢复策略 | 从 kg 变量定义出发，穷举所有 `kg.XXX =` 赋值 |
| handleCommonError() 的完整错误分类逻辑 | 只知道它在 @7300455 被 _aiChatRequestErrorService 调用 | 此函数决定账户/权限类错误的处理方式（弹窗? 重定向? 静默?） | 从 handleCommonError 定义出发完整展开 |
| _aiChatRequestErrorService 的完整 API | 只知道有 getErrorInfo() 和 handleCommonError() | 此服务是错误系统的核心，可能有更多有用的方法 | 从 kd (DI Token) 或 `_aiChatRequestErrorService` 变量出发追踪所有方法 |
| J 变量的完整定义代码 | 只知道 `J = !![...].includes(_)` 和位置 ~8696378 | J 直接控制"继续"按钮的显示，其白名单的完整性至关重要 | 从 @8696378 精确提取完整表达式 |
| efh/efg 列表的完整定义代码 | 只知道包含网络错误码，具体列表可能因版本变化 | efh 控制 resumeChat 是否被调用，遗漏会导致续接失败 | 从 @8695303 附近提取完整数组 |
| getErrorInfoWithError() vs getErrorInfo() 的区别 | 知道两者存在但差异不明 | 两个函数可能返回不同的 level/message 映射 | 并列对比两个函数的实现 |
| bQ (Status 枚举) 的完整值列表 | 只知道 Warning/Error/Canceled | status 决定 UI 渲染分支，完整的枚举有助于理解所有可能的显示状态 | 从 bQ 变量定义出发穷举 |

#### [React] 盲区

| 盲区项 | 当前已知程度 | 为什么重要 | 建议探索方法 |
|-------|------------|-----------|------------|
| Alert #6-#17 的精确位置和完整渲染逻辑 | 只有粗略偏移量（±1000误差） | 每个 Alert 都可能有独立的条件分支和操作按钮 | 从 @8702410 开始逐个精确定位 |
| 8930000-10490354 之间的 UI 代码 | **完全未探索！~1.5MB** | 这是文件的后半段，可能包含设置面板、Agent 选择器、历史列表等重要 UI | 取中点 Substring(9421723, 2000) 初步扫描 |
| sX().createElement() 的所有组件类型列表 | 只知道 memo/Alert/Button 等少量类型 | 完整的组件类型清单有助于理解 UI 架构的全貌 | 搜索 `sX().createElement(` 提取第二参数的类型 |
| 所有 useCallback/useMemo/useEffect 的完整列表 | 只知道与 auto-continue 相关的几个 | 每个 Hook 都是潜在的补丁注入点或冻结行为观察点 | 分别搜索三个 Hook 关键字 |
| ConfirmPopover 和 NotifyUserCard 的实现 | 只知道名称存在，完全不了解内部逻辑 | 这两个组件涉及用户交互确认流程 | 从组件名出发搜索定义 |
| JP.Sz 选择器的完整列表 | 只知道 status/exception/agentMessageId/sessionId 四个 | 选择器定义了 Store 到组件的数据投影 | 从 JP.Sz 或 Sz( 函数定义出发 |
| Cr.Alert 组件的 props 接口 | 只知道用于渲染错误消息 | Alert 的完整 props 接口决定了可定制的行为 | 从 Cr.Alert 或 Alert( 搜索定义 |

#### [Event] 盲区

| 盲区项 | 当前已知程度 | 为什么重要 | 建议探索方法 |
|-------|------------|-----------|------------|
| TeaReporter 类的完整方法列表 | 只知道 teaEventChatFail 一个方法 | TEA 系统可能有更多上报点可用于监控 | 从 Ma (ITeaFacade Token) 或 TeaReporter 类出发 |
| teaEventChatShown / teaEventChatRetry 的定义和调用点 | 名称来自推断，未实际定位 | 这些事件标记聊天生命周期的关键时刻 | 搜索这两个字符串的确切位置 |
| YTr/Y1s 事件在渲染进程中的接收端 | 知道主进程用 YTr.emit() 发送，不知道渲染进程如何接收 | 接收端是 IPC 消息的处理入口，可能是重要的 hook 点 | 搜索 YTr 或 Y1s 在 index.js 中的使用 |
| chatStreamBizReporter 的完整 API | 只知道有 teaEventChatFail 方法 | BizReporter 可能包含更多业务级别的上报方法 | 从 chatStreamBizReporter 变量出发追踪 |
| _codeCompEventService 的完整 API | 只知道有 teaEventChatFail 方法 | CodeComp 事件服务可能跟踪代码补全过程 | 从 _codeCompEventService 变量出发追踪 |

#### [IPC] 盲区

| 盲区项 | 当前已知程度 | 为什么重要 | 建议探索方法 |
|-------|------------|-----------|------------|
| workbench.desktop.main.js 中 GZt.create 的所有调用点 | 只知道 "exceeded maximum number of turns" 一个调用 | GZt.create 是主进程创建错误对象的工厂，每个调用对应一种错误来源 | 需要在主进程文件中搜索（本项目范围外，但值得记录） |
| YTr 事件的完整注册表 | 只知道 emit/drain/enqueueData 几个方法，原 YTr 变量名已迁移 | 主进程事件总线的完整事件列表 | 从 `ipcRenderer` 出发追踪 IPC 通道 |
| ExtHostShellExecService 的完整事件流 | 只知道 17 个命令 ID | 命令执行的完整生命周期（创建→排队→运行→输出→清理） | 从 `IICubeShellExecService` DI Token 出发追踪 |
| shellExecutor.js 的完整实现 | 完全未知（可能在 main 进程文件中） | Shell 执行是沙箱的核心机制 | 需要在 Electron 主进程中查找 |
| VS Code Command 系统的注册方式 | 只知道通过 S2.IXxxService 调用 | 完整的命令注册表可以帮助理解所有可用的 IPC 通道 | 搜索 `registerCommand` 或类似模式 |

#### [Setting] 盲区

| 盲区项 | 当前已知程度 | 为什么重要 | 建议探索方法 |
|-------|------------|-----------|------------|
| onDidChangeConfiguration 在 workbench 中的实现 | 确认不存在标准的 onDidChangeConfiguration | 设置变更如何被检测和响应？轮询？事件？ | 搜索 configuration 或 setting 相关的事件监听 |
| 设置变更如何传播到 renderer process | 完全未知 | 如果设置变更不能实时传播到 renderer，UI 可能不会更新 | 从设置 key 的使用点反向追踪数据来源 |
| GlobalAutoApprove 的实际影响范围 | 只知道设置 key 存在 | 这个设置可能绕过多层确认逻辑 | 搜索 GlobalAutoApprove 所有引用 |
| TerminalAutoApproveRules 的规则格式 | 完全未知 | 规则格式决定了哪些终端命令可以被自动批准 | 搜索 TerminalAutoApproveRules 所有引用 |
| AI.toolcall.confirmMode 设置的消费端 | 只知道 key 名，不知道谁在读这个值 | confirmMode 的消费者决定了设置变更的影响范围 | 搜索 `"AI.toolcall.confirmMode"` 或 `confirmMode` 的读取点 |

#### [Sandbox] 盲区

| 盲区项 | 当前已知程度 | 为什么重要 | 建议探索方法 |
|-------|------------|-----------|------------|
| safe_rm_aliases.ps1/sh 的完整内容 | 完全未知 | 安全删除别名列表直接决定了哪些命令被视为危险 | 搜索 safe_rm_aliases 或 SAFE_RM 相关字符串 |
| trae-sandbox.exe 的调用方式和参数 | 完全未知 | 沙箱的可执行文件是如何被调用的？参数格式是什么？ | 搜索 trae-sandbox 或 sandbox.exe |
| VirtualTerminal 的完整生命周期 | 完全未知 | VirtualTerminal 可能管理 PTY/伪终端，影响命令执行环境 | 搜索 VirtualTerminal 相关代码 |
| 环境变量突变的完整类型系统 | 完全未知 | 沙箱可能限制或修改环境变量以增强安全性 | 搜索环境变量相关的 mutation 代码 |
| BlockLevel 判定的完整决策树 | 只知道 getRunCommandCardBranch 的输入输出 | BlockLevel 是如何从命令文本判定的？黑名单/红名单的具体规则？ | 从 getRunCommandCardBranch 反向追踪 blockLevel 的来源 |

#### [MCP] 盲区

| 盲区项 | 当前已知程度 | 为什么重要 | 建议探索方法 |
|-------|------------|-----------|------------|
| MCP server 注册/发现机制 | 完全未知 | MCP server 如何被注册？如何被发现和连接？ | 搜索 mcp 或 server 注册相关模式 |
| 工具调用的权限模型 | 完全未知 | 哪些工具可以被自动调用？哪些需要用户确认？ | 从 ToolCallName 枚举反向追踪权限检查逻辑 |
| browser_* 系列 20+ 工具的完整枚举 | 只知道存在，没有完整列表 | browser 工具可能涉及敏感操作（页面截图、DOM 访问等） | 搜索 `browser_` 前缀穷举 |
| Task*/Team* 系列 Agent 工具的实现 | 只知道名称存在 | Agent 工具可能触发子 Agent 的创建和管理 | 搜索 Task* 或 Team* 前缀 |
| tool_call / function_call 的完整生命周期 | 只知道 PlanItemStreamParser 处理 planItem 类型 | 从工具调用请求到执行结果返回的完整链路 | 从 provideUserResponse 出发正向和反向追踪 |
| confirm_info 数据结构的完整字段列表 | 只知道主要字段 | 可能有隐藏字段影响确认流程 | 从 confirm_info 所有赋值点收集字段名 |

### 3.3 完全未探索区域

以下偏移量范围内**没有任何已记录的发现**。这些区域是优先级最高的扫描目标：

| 偏移量范围 | 大小估计 | 可能包含的内容 | 优先级 | 建议扫描策略 |
|-----------|---------|---------------|--------|------------|
| **0-41400** | ~41KB | webpack bootstrap, polyfills, early module definitions, require/define 函数 | 低 | 通常不含业务逻辑，快速采样即可确认 |
| **44403-46816** | ~2KB | Ck 枚举（ConfirmMode）与 RunningStatus 枚举之间的过渡代码 | 低 | 小区间，可直接完整读取 |
| **46816-54000** | ~7KB | RunningStatus 枚举到 Error 枚举(kg)之间的代码 | 低 | 小区间，可直接完整读取 |
| **54415-6268469** | **~6.2MB** | **最大盲区！** Error 枚举到 DI 容器(uj)之间 | **极高** | 分段扫描：每 500KB 取中点采样；重点关注函数/类定义关键字 |
| **6665xxx-7000000** (workbench 区域) | ? | 主进程相关代码的 renderer 代理层 | 高 | 如果文件延伸到此范围 |
| **8930000-9910446** | ~1MB | ErrorMessageWithActions 之后到 DEFAULT error 组件 | **高** | UI 下半部分，含可能的设置面板、Agent 选择器等 |
| **9910446-10490354** | ~550KB | DEFAULT error 到命令注册层（registerAdapter 等） | **高** | 含 VS Code 命令注册、适配器注册等基础设施 |
| **10490354-EOF** | ? | 文件末尾（webpack IIFE 闭合、export 等） | 中 | 通常为模块导出和初始化代码 |

**关于最大盲区 (54415-6268469, ~6.2MB) 的特别说明**:

这个区间占据了文件的 **62% 以上**，却几乎没有被探索过。它可能包含：
- webpack 模块加载器和依赖解析逻辑
- 第三方库的打包代码（react, react-dom, zustand 等）
- Trae 自身的中间层工具函数
- 尚未被识别的业务逻辑模块

**建议的渐进式扫描方案**:

```
Phase 1 (粗筛): 每 100KB 取 200 字符样本 → 识别是否有业务逻辑特征
Phase 2 (聚焦): 对 Phase 1 中有特征的区间每 10KB 细扫
Phase 3 (深挖): 对 Phase 2 中有价值的点进行完整的双向扩展
```

### 3.4 发现置信度矩阵

每个发现都必须附带置信度评级。以下是评级标准和含义：

| confidence | verified_by | 含义 | 可用于补丁开发？ | 需要进一步动作？ |
|-----------|-------------|------|----------------|----------------|
| **high** | ≥2 independent agents, consistent results; or single agent with reproducible search template + code evidence | 高度可信，多个独立证据交叉验证 | ✅ 可以直接使用 | 无需额外验证，但欢迎进一步确认 |
| **medium** | 1 agent with reproducible search template + reasonable inference | 较可信，有搜索模板支持但未经独立验证 | ⚠️ 可以参考，但建议自行验证后再用于补丁 | 建议用至少一条独立路径验证 |
| **low** | 1 agent only, based on limited context or inference without full verification | 初步发现，基于有限信息或推断 | ❌ 必须验证后才能使用 | 必须用独立路径验证，或补充更多证据 |
| **conflicting** | ≥2 agents report different results for the same feature | 有争议，至少两个来源不一致 | ⚠️ 需仲裁后决定 | 需要第三个 Agent 用独立路径仲裁 |

**置信度升级规则**:
- low → medium: 增加一条独立验证路径或补充代码证据
- medium → high: 增加第二条独立验证路径，结果一致
- high → 保持: 定期检查 Trae 更新后锚点是否仍然有效

**置信度降级规则**:
- 任何级别 → conflicting: 如果新的独立验证与现有发现矛盾
- high → medium: 如果发现搜索模板在新版本中偏移超过预期范围

---

## 第4章: 搜索方法论 (Search Methodology)

### 4.1 锚点选择策略 — 稳定性金字塔

在选择搜索起点时，必须按照稳定性金字塔从顶层到底层依次尝试：

```
Level 5 (⭐⭐⭐⭐⭐): Symbol.for("...") 字符串
  示例: Symbol.for("IPlanItemStreamParser"), Symbol.for("aiAgent.ILogService")
  特征: 全局符号注册表，跨模块共享，webpack 构建不会改变字符串内容
  适用: 作为首选搜索锚点，尤其是跨版本兼容的搜索模板

Level 4 (⭐⭐⭐⭐): Symbol("...") 字符串
  示例: Symbol("ISessionStore"), Symbol("IAgentService")
  特征: 局部符号，模块内唯一，构建时不改变字符串内容
  适用: 模块内部的搜索锚点

Level 3 (⭐⭐⭐): API 方法名
  示例: resumeChat, sendChatMessage, provideUserResponse, getRunCommandCardBranch
  特征: 业务逻辑层的公共方法名，除非重构否则不变
  适用: 当 Symbol 锚点不可用时（如方法可能在多处定义）

Level 2 (⭐⭐): 枚举/协议常量字符串
  示例: "redlist", "unconfirmed", "planItem", "error", "done"
  特征: 协议级的字符串常量，与服务端契约绑定
  适用: 用于确认发现（辅助验证），不建议作为唯一搜索起点

Level 1 (⭐): 混淆变量名
  示例: uj, xC, zU, zL, Bs, Bo, D7, Ot
  特征: terser/webpack 每次构建都可能重命名
  适用: 仅用于在同一版本的上下文中做短距离导航
  禁止: 跨版本搜索模板中使用 Level 1 锚点
```

**强制规则**: 搜索模板中必须包含至少一个 Level 3+ 锚点。Level 1-2 锚点只能作为辅助上下文。

### 4.2 双向扩展策略

从锚点到达初始位置后的标准探索流程：

```
Step 1: 定位锚点
  $c = [IO.File]::ReadAllText($path)
  idx = $c.IndexOf(anchor_string)
  if (idx < 0) { 锚点不存在! 版本可能变了，报告失败 }

Step 2: 向前扩展 (看调用者/上下文)
  $preCtx = $c.Substring([Math]::Max(0, idx - N), Math.Min(N * 2, idx))
  分析: 这个锚点前面是什么代码？谁调用了它？它在哪个函数/类里？

Step 3: 向后扩展 (看实现/被调用者)
  $postCtx = $c.Substring(idx, Math.Min(N * 2, $c.Length - idx))
  分析: 这个锚点后面是什么代码？它的实现体？它调用了什么？

Step 4: 识别边界 (确定函数/类的完整范围)
  用括号计数法 (见 4.5) 找到包含锚点的最小完整代码单元
  记录 start_offset ~ end_offset

Step 5: 提取关键信息
  注入了哪些服务 (this._xxx = ...)?
  调用了哪些方法 (.resolve(X), .parse(), .handle())?
  返回了什么数据?
  有哪些条件分支?

Step 6: 记录发现
  按照 Chapter 7 的标准格式写入 discoveries.md
```

**N 值 (上下文窗口大小) 建议**:

| 场景 | N 值 | 说明 |
|------|------|------|
| 初始扫描/粗定位 | 200 | 快速判断锚点周围是否为目标代码 |
| 一般分析 | 500-1000 | 足以看到完整的函数签名和几个语句 |
| 边界检测/完整函数提取 | 2000-5000 | 确保捕获完整的函数体（压缩代码中函数可能很长） |
| 类定义提取 | 5000-10000 | 类通常包含多个方法和 DI 注入 |

### 4.3 变体搜索策略

同一功能在压缩代码中可能有多种写法。**必须搜索所有变体以确保不遗漏**：

#### 4.3.1 DI Token 变体

| 功能 | 变体 1 (最稳定) | 变体 2 | 变体 3 | 变体 4 |
|------|----------------|--------|--------|--------|
| ISessionStore 引用 | `Symbol("ISessionStore")` | `Symbol.for("ISessionStore")` (EMPTY!) | `xC` (变量名) | `uX(xC)` (注入调用) |
| IPlanItemStreamParser 引用 | `Symbol("IPlanItemStreamParser")` | `Symbol.for("IPlanItemStreamParser")` (EMPTY!) | `zL` (变量名) | `uJ({identifier:zL})` |
| ISessionServiceV2 引用 | `Symbol("ISessionServiceV2")` | `Symbol.for("ISessionServiceV2")` | `BO` (变量名) | `resolve(BO)` |

#### 4.3.2 Store 操作变体

| 功能 | 变体 1 | 变体 2 | 变体 3 | 变体 4 |
|------|--------|--------|--------|--------|
| 更新消息 | `.setCurrentSession({...i,` | `.updateMessage(` | `.updateLastMessage(` | `store.setState({currentSession:` |
| 读取消息 | `.getState().currentSession` | `N.useStore(e=>e.currentSession)` | `JP.Sz(Jj,e=>e.` | `G?.messages` |
| 订阅变化 | `.subscribe((e,t)=>{` | `.subscribe(function(e,t){` | `useSyncExternalStore(` | `(curr, prev)=>` |

#### 4.3.3 错误处理变体

| 功能 | 变体 1 | 变体 2 | 变体 3 | 变体 4 |
|------|--------|--------|--------|--------|
| 思考上限检查 | `kg.TASK_TURN_EXCEEDED_ERROR` | `4000002` | `exception.code===4000002` | `"exceeded maximum"` |
| 错误分类 | `getErrorInfo(t,{...})` | `getErrorInfoWithError(e)` | `handleCommonError(code)` | `bQ.Error` / `bQ.Warning` |
| 可恢复判断 | `[...efh].includes(_)` | `!![kg.XXX,...].includes(_)` | `J=true` | `agentProcess==="v3"` |

#### 4.3.4 确认/执行操作变体

| 功能 | 变体 1 | 变体 2 | 变体 3 | 变体 4 |
|------|--------|--------|--------|--------|
| 用户确认 | `provideUserResponse({task_id,...` | `tool_confirm` | `confirm_status="confirmed"` | `eE(Ck.Confirmed)` |
| 用户拒绝 | `decision:"reject"` | `confirm_status="canceled"` | `eE(Ck.Rejected)` | `Ck.Canceled` |
| 自动确认 | `auto_confirm:true` | `confirm_status:"confirmed"` (直接设) | `provideUserResponse(..."confirm")` | skip confirmation entirely |

#### 4.3.5 事件分发变体

| 功能 | 变体 1 | 变体 2 | 变体 3 | 变体 4 |
|------|--------|--------|--------|--------|
| SSE 事件处理 | `eventHandlerFactory.handle(` | `handleSteamingResult(` | `Br.register(Ot.` | `Bt.handle(D7.` |
| Parser 解析 | `.parse(e, t)` | `parse(payload, context)` | `_handlePlanItem()` | `handleHistoryResult()` |
| 错误上报 | `teaEventChatFail(` | `_teaService.event(` | `chatStreamBizReporter.teaEventChatFail(` | `_codeCompEventService.teaEventChatFail(` |

### 4.4 关联搜索策略

找到一个关键代码点后，必须系统地搜索其关联点。这是确保发现完整性的核心策略：

```
找到一个类/函数/变量 X 后，按以下 5 个维度搜索关联:

维度 1: 定义 (Definition)
  搜索: "class X" / "function X" / "const X=" / "var X=" / "let X="
  目的: 找到 X 的完整定义，理解它的全部能力

维度 2: 方法集 (Methods)
  搜索: "X.prototype." / "X." 后跟方法名模式
  或者: 从定义位置向后扩展，找所有属于 X 的方法
  目的: 理解 X 能做什么

维度 3: 注入点 (Injection)
  搜索: "uX(token_X)" — 谁注入了 X？
  搜索: "uJ({identifier:token_X}" — X 被注册在哪里？
  目的: 理解 X 在 DI 系统中的角色

维度 4: 依赖 (Dependencies)
  在 X 的定义体内搜索:
    - ".resolve(Y)" — X 依赖哪些其他服务？
    - "this._yyy" — X 注入了哪些服务？
  目的: 理解 X 的工作需要哪些协作方

维度 5: 调用者 (Callers)
  搜索: "X.methodName(" — 谁调用了 X 的方法？
  搜索: "new X(" — 谁创建了 X 的实例？
  目的: 理解 X 在系统中的使用场景
```

**示例 — 从 PlanItemStreamParser 出发的关联搜索**:

```
锚点: Symbol("IPlanItemStreamParser") @~7510931

维度 1 (定义):
  向后搜索 "class" 或函数定义 → 找到 Parser 类定义
  结果: zL 类 (PlanItemStreamParser), 包含 _handlePlanItem 方法

维度 2 (方法):
  从类定义扩展 → _handlePlanItem, parse, 以及其他方法
  结果: _handlePlanItem 是核心方法, 处理 confirm_status 逻辑

维度 3 (注入):
  搜索 uJ({identifier:zL} 或 uX(zL)
  结果: 在 EventHandlerFactory 中被注册为 PlanItem 事件的处理器

维度 4 (依赖):
  在类定义中找 this._xxx → _taskService, _logService, storeService 等
  结果: 依赖 taskService 提供 provideUserResponse

维度 5 (调用者):
  搜索 eventHandlerFactory.handle(Ot.PlanItem → 找到分发点
  结果: SSE PlanItem 事件 → EventHandlerFactory → PlanItemStreamParser._handlePlanItem
```

### 4.5 边界检测策略

准确判断一个函数或类的完整范围是探索的基础技能。对于压缩单行文件，使用括号计数法：

```powershell
function Find-CodeBoundary {
    param(
        [string]$Content,
        [int]$StartOffset,
        [string]$OpenChar = "{",
        [string]$CloseChar = "}"
    )

    $openIdx = $Content.IndexOf($OpenChar, $StartOffset)
    if ($openIdx -lt 0) { return @{Start=-1; End=-1} }

    $depth = 1
    $pos = $openIdx + 1
    $inString = $false
    $stringChar = ""

    while ($pos -lt $Content.Length -and $depth -gt 0) {
        $ch = $Content[$pos]

        if (-not $inString) {
            if ($ch -eq '"' -or $ch -eq "'" -or $ch -eq "`") {
                $inString = $true
                $stringChar = $ch
            }
            elseif ($ch -eq $OpenChar) { $depth++ }
            elseif ($ch -eq $CloseChar) { $depth-- }
        }
        else {
            if ($ch -eq $stringChar -and $Content[$pos-1] -ne '\') {
                $inString = $false
            }
        }
        $pos++
    }

    return @{
        Start = $StartOffset
        OpenBrace = $openIdx
        CloseBrace = $pos - 1
        DepthAtEnd = $depth
    }
}
```

**使用注意事项**:

1. **字符串内的花括号必须跳过** — 否则 `"{" + "}"` 会被误认为代码块
2. **正则表达式内的花括号** — `/{n,m}/` 中的花括号也需要特殊处理
3. **模板字面量** — `` `${expr}` `` 中的花括号同理
4. **箭头函数简写** — `x => ({a:1})` 的花括号是对象字面量不是代码块
5. **对于 class 定义**, 还需要找到 class 关键字本身的位置（可能在 `{` 之前很远的地方）

**简化版（适用于大多数场景）**:

如果只需要大致范围（不需要精确到字符级），可以用以下启发式方法：

```
1. 从锚点向前找最近的 "function " 或 "class " 关键字 → 函数/类起始
2. 从锚点向后找匹配深度的 "}" → 函数/类结束
3. 如果函数内有嵌套函数/类，深度会 > 1，需要递归处理
4. 对于压缩代码，单个函数体通常在 500-5000 字符范围内
```

### 4.6 工具选择决策树

```
开始探索任务
  │
  ├─ 任务类型？
  │   ├─ 快速定位单个字符串 → Layer 0: IndexOf / Select-String (<1秒)
  │   ├─ 理解代码结构（函数/类边界）→ Layer 1: js-beautify + ast-search.ps1 (1-5min)
  │   ├─ 理解业务逻辑（变量含义）→ Layer 2: reverse-machine AI 模式 (10-30min)
  │   └─ 大规模扫描（盲区/全文件）→ Layer 3: Extract-AllFunctions + module-search.ps1 (5-15min)
  │
  ├─ 文件状态？
  │   ├─ 原始压缩文件（~10MB 单行）→ 先运行 Unpack-TraeIndex 美化
  │   ├─ 已美化（unpacked/beautified.js, 347244行）→ 直接用 AST/模块搜索
  │   └─ 已提取索引（functions-index.json）→ 用查询接口快速定位
  │
  └─ 时间约束？
      ├─ < 1 分钟 → 仅用 Layer 0（PowerShell 原生 IndexOf）
      ├─ 1-10 分钟 → Layer 0 + Layer 1（美化 + AST 搜索）
      └─ > 10 分钟 → 完整工具链（含批量提取和 AI 增强）
```

### 4.7 工具组合模式

| 模式 | 工具组合 | 适用场景 | 预期耗时 |
|------|---------|---------|---------|
| **Quick Look** | IndexOf only | 验证锚点是否存在 | <10s |
| **Standard** | Unpack-TraeIndex → Search-UnpackedModules | 常规探索任务 | 1-5min |
| **Deep Dive** | beautify → Search-AST → Extract-AllClasses → 人工审读 | 复杂代码理解 | 10-30min |
| **Full Scan** | Extract-AllFunctions + Get-ModuleOverview | 盲区扫描 | 5-15min |
| **Migration** | Unpack-TraeIndex → batch anchor re-search | 版本适配 | 10-20min |

#### 当前环境工具状态（2026-04-25）

| 工具 | 版本 | 状态 | 说明 |
|------|------|------|------|
| js-beautify | 1.15.4 | ✅ 可用 | **主要美化工具**，已验证可处理 10MB 文件 |
| @babel/parser | 7.x | ✅ 可用 | AST 解析，需 errorRecovery + decorators 插件 |
| webcrack | 2.15.1 | ⚠️ 受限 | 不兼容 TypeScript 装饰器语法 |
| reverse-machine | 2.1.5 | ✅ 已安装 | 需要 API key 才能使用 AI 模式 |
| ast-search-js | 1.10.2 | ✅ 可用 | 结构化搜索（备选） |

#### 关键成果（首次运行）

- **beautified.js**: 347,244 行可读代码（从 10.25MB 单行转换）
- **函数索引**: 38,630 个函数定义
- **类索引**: 1,009 个类定义
- **webpack 模块**: 待 Get-ModuleOverview 统计

---

## 第5章: 交叉验证协议 (Cross-Validation Protocol)

### 5.1 独立路径要求

**核心原则**: 验证 Agent 不得使用与发现 Agent 相同的搜索起点。这确保了验证的独立性。

**什么是"独立路径"?**

两条路径独立当且仅当它们的**起始锚点类型不同**（属于稳定性金字塔的不同层级），或者**起始锚点的功能语义不同**（即使同一层级）。

**示例 — 验证 "PlanItemStreamParser._handlePlanItem 在 @7502500 附近"**:

| Agent | 角色 | 搜索起点 (锚点) | 锚点层级 | 路径描述 |
|-------|------|-----------------|---------|---------|
| A | 发现者 | `Symbol("IPlanItemStreamParser")` | L4 (Symbol) | DI token → uJ register → class definition → method |
| B | 验证者 1 | `"confirm_status==='unconfirmed'"` | L2 (业务字符串) | 业务逻辑字符串 → 反向追踪到 Parser 方法 |
| C | 验证者 2 | `provideUserResponse` | L3 (API 方法名) | API 方法名 → 找到所有调用点 → 定位 Parser |
| D | 验证者 3 | `handleSteamingResult` | L3 (API 方法名) | 分发方法名 → 找到 PlanItem handler → 定位 Parser |

**判定**: 如果 B、C、D 三条独立路径都定位到了 @7502500 ±200 字符范围内的相同代码 → **high confidence ✓**

### 5.2 一致性判定标准

两个发现"指向同一代码"当且仅当满足以下**至少 2 条**条件：

| 条件编号 | 条件描述 | 判定方法 |
|---------|---------|---------|
| C1 | **偏移量接近**: \|offset_A - offset_B\| < 200 字符 | 数值比较 |
| C2 | **上下文重叠**: 两者的 Substring 输出包含相同的特征字符串 | 字符串交集检测 |
| C3 | **功能一致**: 两者描述的是同一个功能（即使使用的术语不同） | 语义比对 |
| C4 | **依赖关系一致**: 两者引用了相同的外部服务/模块 | DI token / import 比较 |

**不一致的判定**:

| 情况 | 偏移量差 | 共同上下文 | 结论 | 处置 |
|------|---------|-----------|------|------|
| 可能是同名不同函数 | > 2000 | 无 | **不一致** | 报告为 conflict，需第三方仲裁 |
| 同一函数的不同版本 | 200-2000 | 部分 | **弱一致** | 标记为 medium confidence，建议进一步验证 |
| 测量精度差异 | < 200 | 充分 | **一致** | 合并为 high confidence |
| 一个说是 class 一个说是 function | 任意 | — | **严重不一致** | 其中一方可能误读了代码（常见：把 IIFE 当成 class） |

### 5.3 冲突解决流程

当两个或多个 Agent 对同一发现报告不一致的结果时：

```
Step 1: 交换原始数据
  Agent A 和 Agent B 交换各自的:
    - 搜索起点 (anchor)
    - 偏移量 (offset)
    - Substring 上下文 (原始输出, 不是摘要)
    - 推理链 (如何从锚点到结论)

Step 2: 独立复核
  双方各自重新审查对方的数据:
    - 对方的 Substring 是否确实包含声称的特征?
    - 对方的推理链是否有逻辑跳跃?
    - 是否有一方把 IIFE / 闭包 / 箭头函数误识别为 class/function?

Step 3: 常见误识别检查清单
  □ 是否把 var x = function(){...} 当成了 function x(){...} ?
  □ 是否把 (function(){...})() (IIFE) 当成了 class 定义?
  □ 是否把 object literal {...} 中的方法简写当成了独立函数?
  □ 是否把 destructuring 赋值中的属性当成了变量声明?
  □ 是否被 shadowed 变量误导 (如 let t=e.error.code 遮蔽了外部 t)?

Step 4: 如仍不一致 → 引入第三方 Agent C
  Agent C 使用第三条完全独立的路径进行仲裁
  Agent C 的搜索起点不得与 A 或 B 相同

Step 5: 最终裁决
  Agent C 的结论为最终结果
  将冲突和裁决记录到 discoveries.md 的 conflict_notes 字段
```

### 5.4 验证矩阵模板

每个重要发现（Major 级别及以上）都必须附带验证矩阵：

```
┌─────────────────────────────────────────────────────────────┐
│ 验证矩阵: PlanItemStreamParser._handlePlanItem              │
├──────────┬──────────────┬──────────────┬────────┬─────────┤
│ Agent    │ 搜索起点      │ 定位偏移量    │ 结论   │ 一致?   │
├──────────┼──────────────┼──────────────┼────────┼─────────┤
│ A (发现) │ Symbol(IPlanItemStreamParser) │ @7502500 │ Parser方法 │ —    │
│ B (验证1) │ confirm_status==="unconfirmed" │ @7502498 │ 同一方法 │ ✓    │
│ C (验证2) │ provideUserResponse          │ @7502574 │ 调用方   │ ✓    │
│ D (验证3) │ handleSteamingResult         │ @7502600 │ 分发方   │ ✓    │
└──────────┴──────────────┴──────────────┴────────┴─────────┘
置信度: HIGH (4/4 一致)
verified_by: A, B, C, D
last_verified: 2026-04-25
```

**填写要求**:

| 字段 | 要求 |
|------|------|
| 标题 | 发现的简短描述，包含关键的类/方法名 |
| Agent 列 | 至少包含发现者 + 1 个验证者（2 路验证为最低要求） |
| 搜索起点 | 必须写出实际的搜索关键词，不能省略 |
| 定位偏移量 | 必须是实际测量的数值，不能是估算 |
| 结论 | 简短描述该 Agent 确认了什么 |
| 一致? | ✓/✗/—（—表示基准线） |
| 置信度 | HIGH/MEDIUM/LOW/CONFLICTING |
| verified_by | Agent ID 列表 |
| last_verified | YYYY-MM-DD |

---

## 第6章: 盲区扫描规范 (Blind Spot Scanning)

### 6.1 相邻区间扫描 (Adjacent Zone Scanning)

对每个已有的高质量发现点（confidence ≥ medium），在其固定半径内进行二次扫描，寻找被忽略的相邻代码：

```powershell
# 对每个已知发现点 offset:
$radius = 500
$start = [Math]::Max(0, $offset - $radius)
$end = [Math]::Min($c.Length, $offset + $radius)
$zone = $c.Substring($start, $end - $start)

# 在 zone 内搜索以下模式:

$patterns = @{
    "FunctionDef"       = "(?:function\s+[A-Z]\w*\s*\(|(?:const|let|var)\s+[A-Z]\w*=\s*(?:async\s+)?function)"
    "ClassDef"          = "class\s+[A-Z]\w*(?:\s+extends\s+\w+)?"
    "DI_Injection"      = "uX\(\w+\)"
    "DI_Registration"   = "uJ\(\{identifier:"
    "EventHandler"      = "(?:addEventListener|\.on\(|\.emit\()"
    "StoreOperation"    = "(?:subscribe|setState|getState|setCurrentSession|updateMessage)"
    "VisibleString_ZH"  = "[\u4e00-\u9fff]"  # 中文字符
    "VisibleString_EN"  = "(?:Failed to|Unable to|Error:|Please|Confirm|Cancel)"
    "URL_Pattern"       = "https?://[^\s\"'`]+"
    "LogPattern"        = "(?:console\.(?:log|warn|error)|\[INFO\]|\[WARN\]|\[ERROR\])"
}

foreach ($key in $patterns.Keys) {
    $matches = [regex]::Matches($zone, $patterns[$key])
    if ($matches.Count -gt 0) {
        foreach ($m in $matches) {
            $absPos = $start + $m.Index
            Write-Host "[$key] at @$absPos : $($m.Value.Substring(0, [Math]::Min(60, $m.Value.Length)))"
        }
    }
}
```

**扫描结果的处置**:

| 结果类型 | 处置方式 |
|---------|---------|
| 属于已知发现的一部分 | 记录为"确认性发现"(Trivial)，追加到原条目 |
| 属于已知发现的相关但未记录的部分 | 升级原条目或新增 Minor 条目 |
| 完全不属于任何已知域的新代码 | 按 Chapter 8 评估是否为新域候选 |
| 明显是第三方库代码（react/zustand 等） | 标记为"非目标区域"，不记录 |

### 6.2 未覆盖区间扫描 (Gap Scanning)

利用 discoveries.md 中的偏移量索引，识别已知覆盖点之间的空隙：

```powershell
# 已知覆盖点按偏移量排序:
$knownPoints = @(54000, 41400, 46816, 6268469, 7087490, 7135785, 7300000,
                 7458679, 7502500, 7508572, 7588518, 7610443, 7615777,
                 8069382, 8635000, 8696378, 8700000, 8930000, 9910446,
                 10490354)

# 计算空隙:
for ($i = 0; $i -lt $knownPoints.Count - 1; $i++) {
    $gapStart = $knownPoints[$i]
    $gapEnd = $knownPoints[$i + 1]
    $gapSize = $gapEnd - $gapStart

    if ($gapSize -gt 10000) {
        $midpoint = [Math]::Floor(($gapStart + $gapEnd) / 2)
        Write-Host "GAP: @$gapStart - @$gapEnd ($gapSize chars, midpoint @$midpoint)"

        # 在中点取样:
        $sampleStart = [Math]::Max(0, $midpoint - 200)
        $sample = $c.Substring($sampleStart, [Math]::Min(400, $c.Length - $sampleStart))

        # 分析样本特征:
        $hasFunction = $sample -match '(?:function|class)\s+[A-Z]'
        $hasDI = $sample -match 'u[XJ]\('
        $hasString = $sample -match '"[a-zA-Z]{10,}"'
        $hasCompressed = $sample -match 'var\s+\w{1,3}=\w{1,3}\([^)]*\),?'

        Write-Host "  Features: fn=$hasFunction di=$hasDI str=$hasString compressed=$hasCompressed"
        Write-Host "  Sample: $($sample.Substring(0, [Math]::Min(120, $sample.Length)))..."
    }
}
```

**重点关注的大空隙**（按优先级排列）:

| 优先级 | 空隙范围 | 大小 | 初步评估 | 建议行动 |
|--------|---------|------|---------|---------|
| P0 | 54415-6268469 | **~6.2MB** | 最大盲区，可能含大量中间层代码 | Phase 1 粗筛 → Phase 2 聚焦 → Phase 3 深挖 |
| P1 | 8930000-9910446 | ~1MB | UI 层下半部分 | 重点扫描组件定义和事件处理 |
| P1 | 9910446-10490354 | ~550KB | 命令注册/扩展层 | 扫描 registerAdapter / command 注册 |
| P2 | 0-41400 | ~41KB | webpack bootstrap | 低优先级，快速采样确认 |
| P2 | 10490354-EOF | ? | 文件末尾 | 中优先级，检查 export/init 代码 |

### 6.3 模式变体扫描 (Pattern Variant Scanning)

对每个已知的搜索模式，生成并执行其变体，确保不因写法差异而遗漏：

| 原始模式 | 变体 1 (替代语法) | 变体 2 (变量间接引用) | 变体 3 (数字/字面量) | 变体 4 (缩写/别名) |
|---------|------------------|-------------------|-------------------|------------------|
| `uj.getInstance()` | `getInstance()` | `uj.instance` | `new uj` | `hX()` |
| `uX(xC)` | `uX(Symbol("ISessionStore"))` | `{identifier:xC}` | `this._sessionStore` | `uB(xC)` (Hook形式) |
| `.subscribe(` | `.subscribe(function` | `n.subscribe((e,t)` | `useSyncExternalStore(` | `store.subscribe` |
| `teaEventChatFail` | `teaEventChatFail(e,` | `chatStreamBizReporter.teaEventChatFail` | `_codeCompEventService.teaEventChatFail` | `_teaService.event(...fail)` |
| `kg.TASK_TURN_EXCEEDED_ERROR` | `4000002` | `"TASK_TURN_EXCEEDED"` | `task_turn_exceeded` | `exception.code===4000002` |
| `confirm_status==="unconfirmed"` | `'unconfirmed'===confirm_status` | `.confirm_status=="unconfirmed"` | `!"confirmed"...confirm_status` | `getRunCommandCardBranch(...)` |
| `class Bs` | `Bs extends` | `var Bs=` | `Bs.prototype.` | new Bs( |
| `Symbol("IPlanItemStreamParser")` ⚠️Symbol.for已空 | `Symbol.for("IPlanItemStreamParser")` (EMPTY!) | `zL` (变量) | `uJ({identifier:zL})` | `IPlanItemStreamParser` (字符串) |

**执行策略**: 对每个原始模式，依次执行所有变体的 IndexOf 搜索。如果变体产生了不同的偏移量，记录下来——这可能意味着同一功能的多个引用点或多个版本。

### 6.4 孤立代码扫描 (Orphan Code Scanning)

寻找不属于任何已知 10 大域的独立函数/类。这些"孤立代码"可能是：

1. **未被归类的重要功能** — 应该归入某个已知域或新建域
2. **工具函数/辅助函数** — 虽然不重要但有助于理解代码组织
3. **死代码/废弃代码** — 记录即可，无需深入研究

```powershell
# 搜索模式: 独立的顶层定义
$orphanPatterns = @(
    # Pattern 1: 独立函数定义 (大写开头 = 可能是公共API)
    'function\s+[A-Z][a-zA-Z0-9]*\s*\(',

    # Pattern 2: 独立类定义
    'class\s+[A-Z][a-zA-Z0-9]*',

    # Pattern 3: 箭头函数赋值给大写变量 (可能是类工厂)
    '(?:const|let|var)\s+[A-Z][a-zA-Z0-9]*=\s*(?:async\s+)?(?:function|\()=',

    # Pattern 4: async 函数定义
    'async function\s+[A-Za-z][a-zA-Z0-9]*\s*\('
)

foreach ($pattern in $orphanPatterns) {
    $matches = [regex]::Matches($c, $pattern)
    foreach ($m in $matches) {
        $pos = $m.Index
        $name = $m.Value -replace '(?:function|class|const|let|var|async|=|\s|\()*', ''

        # 检查是否属于已知域:
        $isKnown = $false
        foreach ($domain in @('uj','xBs','xI','zL','zU','zJ','z2','z3','z8','zW','zV','za','DV','DQ')) {
            if ($name -eq $domain) { $isKnown = $true; break }
        }

        if (-not $isKnown) {
            Write-Host "ORPHAN: [$name] at @$pos"
        }
    }
}
```

**对每个孤立命中的后续分析**:

1. **检查 DI 注入**: 它是否被任何 `uX(token)` 注入？（如果是 → 它是一个服务）
2. **检查 DI 注册**: 它是否有 `uJ({identifier:token})`？（如果是 → 它是一个注册的服务）
3. **检查 Parser 关联**: 它是否出现在 EventHandlerFactory 的注册表中？（如果是 → 它是一个 Parser）
4. **检查 Store 关联**: 它是否使用了 `.getState()` / `.setState()` / `.subscribe()`？（如果是 → 它与 Store 交互）
5. **检查调用关系**: 它是否被任何已知域的代码调用？

**如果以上全部为否**: 这可能是真正的孤立代码，值得记录为新域候选（见 Chapter 8）。

### 6.5 字符串字面量扫描 (String Literal Scanning)

用户可见的字符串字面量是指向 UI/错误/提示逻辑的"路标"。它们往往存在于未被发现的代码区域中：

```powershell
# 中文消息 (用户界面相关)
$zhPatterns = @(
    '确认', '取消', '重试', '继续', '失败', '错误',
    '请', '正在', '完成', '等待', '发送', '接收',
    '聊天', '对话', '消息', '助手', '代理',
    '命令', '执行', '终端', '文件', '编辑',
    '限额', '配额', '付费', '会员', '升级',
    '安全', '风险', '警告', '阻止', '禁止'
)

# 英文错误/提示 (国际化备用)
$enPatterns = @(
    'Failed to', 'Unable to', 'Error:', 'Please ',
    'Confirm', 'Cancel', 'Retry', 'Continue',
    'quota', 'limit', 'exceeded', 'forbidden',
    'unauthorized', 'permission', 'denied'
)

# URL / endpoint (网络请求)
$urlPattern = 'https?://[^\s"''`]+'

# 日志标记 (调试/遥测)
$logPatterns = @(
    '[INFO]', '[WARN]', '[ERROR]', '[DEBUG]',
    'console.log', 'console.warn', 'console.error',
    '\[.*?\]'  # 方括号格式的日志标记
)

foreach ($p in $zhPatterns + $enPatterns) {
    $idx = $c.IndexOf($p)
    while ($idx -ge 0) {
        $ctx = $c.Substring([Math]::Max(0,$idx-50), [Math]::Min(100, $c.Length-$idx+50))
        Write-Host "STR [`$p`] at @$idx : ...$ctx..."
        $idx = $c.IndexOf($p, $idx + 1)
    }
}
```

**字符串扫描的价值评估**:

| 字符串类型 | 价值 | 典型指向 |
|-----------|------|---------|
| 中文错误消息 | ⭐⭐⭐⭐⭐ | 错误处理/UI 提示代码 |
| 中文按钮文字 | ⭐⭐⭐⭐ | React 组件渲染代码 |
| 英文错误常量 | ⭐⭐⭐⭐ | 错误码映射/异常类 |
| URL/endpoint | ⭐⭐⭐ | API 调用/网络请求代码 |
| 日志标记 | ⭐⭐⭐ | 遥测/调试代码（可能指向关键路径） |
| CSS 类名 | ⭐⭐ | 样式相关（低优先级） |
| HTML 标签 | ⭐ | JSX/模板代码（可能指向组件） |

---

## 第7章: 发现记录标准 (Discovery Recording Standard)

### 7.1 单条发现标准格式

每条发现必须严格按照以下格式记录到 `shared/discoveries.md`：

```
### [YYYY-MM-DD HH:mm] 短标题 ⭐稳定性评级

> 一句话概述这个发现是什么、为什么重要

#### 详细描述
[2-5 句话解释机制的运作方式、关键参与者、数据流向]

#### 位置信息
- **偏移量**: @XXXXXXXX (±误差范围)
- **所在函数/类**: ClassName.methodName()
- **所属层级**: L1 (UI) / L2 (Service) / L3 (Data)
- **所属域标签**: [DI] / [SSE] / [Store] / [Error] / [React] / [Event] / [IPC] / [Setting] / [Sandbox] / [MCP]

#### 数据/证据
[关键代码片段（从 Substring 提取的实际代码，不是猜测）]
[或数据表格]
[或 ASCII 架构图]

#### 搜索模板
| 目标 | 搜索关键词 | 稳定性 (⭐) | 备注 |
|------|-----------|-------------|------|
| 主锚点 | `Symbol.for("...")` | ⭐⭐⭐⭐⭐ | 跨版本稳定 |
| 辅助锚点 | `methodName` | ⭐⭐⭐ | 业务方法名 |
| 确认锚点 | `"enum_string"` | ⭐⭐ | 枚举值 |

#### 验证状态
- **confidence**: high / medium / low / conflicting
- **verified_by**: [Agent ID 列表, 如 "Agent-A-0423, Agent-B-0425"]
- **last_verified**: [YYYY-MM-DD]
- **conflict_notes**: [如有冲突记录在此，否则省略]
```

**格式要求详解**:

| 字段 | 是否必须 | 格式约束 |
|------|---------|---------|
| 标题行 (`### [...]`) | 必须 | 以日期时间开头，包含简短描述，以空格+⭐评级结尾 |
| 概述段落 (`>`) | 必须 | 一句话，不超过 80 字符 |
| 详细描述 | 必须 | 2-5 句话，解释"是什么→怎么做→为什么重要" |
| 位置信息 | 必须 | 偏移量为实测值，注明误差范围 |
| 数据/证据 | 强烈建议 | 代码片段必须是实际提取的，标注来源偏移量 |
| 搜索模板 | 必须 | 至少包含 1 个 ⭐⭐⭐+ 锚点 |
| 验证状态 | 必须 | confidence 必须填写 |

### 7.2 去重规则

新发现与前序发现的关系判定：

| 情况 | 判定标准 | 处置方式 |
|------|---------|---------|
| **完全重复** | 域标签 + 偏移量 + 内容三者都相同 | **丢弃**，不记录 |
| **部分重复（偏移量同，内容有新增）** | 偏移量相同但新发现包含更多信息 | **合并**到已有条目，在原条目下方追加新信息 |
| **同义重复（不同偏移量，同一机制）** | 不同偏移量但描述的是同一个功能/机制 | **合并**，记录多个偏移量，注明"多位置" |
| **深化发现（前序只有偏移量，新发现有完整机制）** | 前序发现只有坐标，新发现补充了完整的工作原理 | **替换**原有条目的详细描述部分，保留偏移量 |
| **矛盾发现（同一事物，不同结论）** | 对同一代码位置给出了矛盾的描述 | **不合并**，标记为 conflicting，启动冲突解决流程 (Chapter 5.3) |
| **全新发现** | 不符合上述任何情况 | **新增**独立条目 |

### 7.3 分级规则

| 级别 | 标准 | 示例 | 记录方式 |
|------|------|------|---------|
| **Major** | 改变补丁设计方向的理解；或发现全新的代码域 | "思考上限错误走 IPC 非 SSE 路径"；"发现 Network 域" | 独立条目，⭐⭐⭐⭐⭐ |
| **Minor** | 补充已有理解的细节；或发现次要但有用的信息 | "subscribe 参数顺序是 (curr, prev)"；"Bs 有 field X" | 追加到对应域章节 |
| **Trivial** | 确认性信息；或批量发现中的单个条目 | "某处确实存在字符串 X"；"偏移量 Y 附近是 Z 库代码" | 批量列出或省略（仅在批量发现时单独列出） |

**默认报告 Major 和 Minor 级别的发现。Trivial 级别只在以下情况记录**:
- 批量扫描时的汇总统计（如"在 0-41400 区间发现 15 个 Trivial 命中，均为 webpack bootstrap 代码"）
- 填补重要空白（如"确认 54415-6268469 区间的前 100KB 为 react-dom 压缩代码"）

### 7.4 追加位置规则

`discoveries.md` 采用**永远追加**的策略。根据发现类型选择正确的追加位置：

| 发现类型 | 追加位置 | 格式 |
|---------|---------|------|
| **全新域** | 文件末尾，创建新的顶级 `### [域标签] ...` 章节 | `### [YYYY-MM-DD HH:mm] [新城标签] 域名 ⭐⭐⭐⭐⭐` |
| **已有域的新 Major 发现** | 对应域章节的最后一条之后 | `### [YYYY-MM-DD HH:mm] 发现标题 ⭐⭐⭐⭐` |
| **已有域的新 Minor 发现** | 对应域章节内最相关的条目下方（作为子节） | `#### 子标题` 或追加到最近条目的详细描述中 |
| **更正/纠正** | 原条目下方 | `> **更正 [YYYY-MM-DD HH:mm]:** 正确内容` |
| **验证更新** | 原条目末尾的验证状态区域 | `- verified_by: AgentX [YYYY-MM-DD]` |
| **冲突记录** | 原条目末尾 | `- conflict_notes: AgentY 报告 ... [YYYY-MM-DD]` |

**禁止操作**:
- ❌ 重写整个 discoveries.md 文件
- ❌ 删除或修改已有条目（除了更正格式）
- ❌ 改变已有条目的偏移量（只能追加更正）
- ❌ 在文件中间插入内容（打乱后续偏移量的参照系）

---

## 第8章: 新域发现协议 (New Domain Discovery Protocol)

### 8.1 新域判定标准

当探索过程中发现一组紧密相关的代码实体时，考虑是否需要创建新的探索域。

**必须同时满足以下 ≥3 个条件**才能成立新域：

| # | 判定问题 | Yes/No | 权重 |
|---|---------|--------|------|
| 1 | 这组代码是否有**明确的功能主题**？（如网络请求、认证、缓存、模型选择等） | ☐ | 高 |
| 2 | 是否有 **≥3 个独立**的代码实体（函数/类/枚举/数据结构）？ | ☐ | 高 |
| 3 | 这些实体之间是否有**明确的调用/引用关系**？（而非只是恰好相邻） | ☐ | 中 |
| 4 | 这个领域是否对**补丁开发有潜在价值**？（即使是间接的） | ☐ | 中 |
| 5 | 是否**无法归入现有的 10 个域**？（或强行归入会破坏该域的内聚性） | ☐ | 高 |

**评分**: 满足问题 1+2+5 即可成立（3/5）。满足 4 个以上为强候选。

### 8.2 新域命名规范

格式: `[EnglishName]` — 大写英文单词开头，简洁明了（2-4 个单词）

**命名原则**:
- 名字应反映该域的**核心功能**，而非实现细节
- 使用行业通用术语优先
- 避免与其他域名字过于相似

**已有域命名参考**:

| 域标签 | 全称 | 命名理由 |
|--------|------|---------|
| `[DI]` | Dependency Injection | 依赖注入容器系统 |
| `[SSE]` | Server-Sent Events Stream | SSE 流管道 |
| `[Store]` | Zustand State Management | 状态管理 |
| `[Error]` | Error Handling | 错误处理系统 |
| `[React]` | React Components | React UI 组件 |
| `[Event]` | Event Bus & Telemetry | 事件总线与遥测 |
| `[IPC]` | Inter-Process Communication | 进程间通信 |
| `[Setting]` | Configuration & Settings | 配置与设置 |
| `[Sandbox]` | Sandbox & Command Execution | 沙箱与命令执行 |
| `[MCP]` | MCP & Tool Call System | MCP 与工具调用 |

**潜在新域候选**（基于盲区分析推测）:

| 候选域名 | 推测依据 | 可能的偏移量范围 | 成立可能性 |
|---------|---------|-----------------|-----------|
| `[Network]` HTTP Client / Request Layer | AI 聊天必然有网络请求；resumeChat/sendChatMessage 底层应该是 HTTP | 54415-6268469 (部分) | 中高 |
| `[Auth]` Authentication / Credential | 已有 ICredentialFacade (Ei); 可能有独立的认证流程 | 54415-6268469 (部分) | 中 |
| `[Cache]` Caching Strategy | 聊天历史可能缓存；模型响应可能有缓存层 | 未知 | 低中 |
| `[History]` Chat History Management | 已有 IPastChatExporter (B3)；可能有完整的历史管理系统 | 7566970 附近 | 中 |
| `[Context]` AI Context Window Management | AI 对话需要上下文管理；可能有 context window 相关逻辑 | 未知 | 中 |
| `[Model]` Model Selection / Routing | 已有 IModelService (kv) / IModelStorageService (kb)；模型选择逻辑可能复杂 | 7177093 附近 | 中高 |
| `[FileWatch]` File Watching / Workspace Events | 编辑器类 IDE 需要文件监视；可能有 workspace event 系统 | 未知 | 低中 |
| `[Telemetry]` Telemetry & Analytics | 已有 ITeFacade (Ma) / ISlardarFacade (Mr); 可能有完整的遥测管道 | 7134895 / 7134171 附近 | 中 |

### 8.3 新域初始探索深度要求

新域建立后，必须回答以下 **≥5 个基本问题**才算"初步完成"（Initial Mapping）：

#### 问题 1: 入口点 (Entry Point)

**问题**: 这个域的代码从哪里开始被调用？

**需要记录**:
- 入口函数/方法的名称和偏移量
- 调用者是谁（哪个域的哪段代码）
- 触发条件（用户操作？定时器？事件？）

**示例格式**:
```
入口点: async function chat(t, i, r) @~7540953
调用者: Bs.createStream() → this._aiAgentChatService.chat(t, n, o)
触发条件: 用户发送消息 / resumeChat 续接
```

#### 问题 2: 核心实体 (Core Entities)

**问题**: 主要有哪些类或函数？

**需要记录**:
- 核心类/函数列表（名称 + 混淆名 + 偏移量）
- 每个实体的简要职责（一句话）
- DI Token（如果有）

**示例格式**:
```
核心实体:
1. _aiAgentChatService (Di token) — AI 聊天服务，管理对话生命周期
2. resumeChat(message_id) — 续接对话方法 @7540933
3. chat(request, client, info) — 发起新对话方法 @7540933
4. appendChat(data) — 追加消息方法
5. cancel(session_id, user_msg_id) — 取消对话方法
```

#### 问题 3: 数据流 (Data Flow)

**问题**: 数据在这个域中如何流动？

**需要记录**: ASCII 数据流图

**示例格式**:
```
数据流:
  用户输入 → chat(request) → 构建 HTTP 请求 → 发送到 API endpoint
    ↓ 响应
  SSE Stream → onMessage 回调 → 解析响应 → 更新 Store
    ↓ 错误
  HTTP Error → onError 回调 → 错误分类 → 上报 TEA / 更新 UI
```

#### 问题 4: 域间关系 (Cross-Domain Relations)

**问题**: 它注入/被注入了哪些服务？它与哪些已知域交互？

**需要记录**:
- **向上依赖** (它用了谁): DI resolve 的 token 列表
- **向下服务** (谁用了它): 被 uX 注入到的类列表
- **平级交互** (它与谁通信): 事件/回调/SSE 的交互对象

**示例格式**:
```
域间关系:
  ↑ 注入 (uses): LogService(bY), StorageFacade(Eh), EnvironmentFacade(ED)
  ↓ 被注入到 (used by): Bs(ChatStreamService), zb(某组件), G6(某服务)
  ↔ 交互: EventHandlerFactory(SSE域), SessionStore(Store域), TeaFacade(Event域)
```

#### 问题 5: 补丁相关性 (Patch Relevance)

**问题**: 这个域是否可能需要打补丁？

**需要记录**: Yes/No + 原因

**示例格式**:
```
补丁相关性: YES — 中等优先级
原因:
1. resumeChat() 是 auto-continue 补丁的核心调用
2. chat() 的参数构造可能影响续接的成功率
3. cancel() 可能需要在停止时清理状态
风险: 此域在 L2 层，不受 React 冻结影响（有利）
```

#### 可选深入问题 (Optional Deep Dive):

| # | 问题 | 何时需要回答 |
|---|------|------------|
| 6 | 配置/设置: 有没有相关的设置 key？ | 如果域行为受设置影响 |
| 7 | 错误处理: 这个域的错误如何传播？ | 如果域可能产生错误 |
| 8 | 性能特征: 有没有明显的性能热点？ | 如果域涉及大量数据处理 |
| 9 | 安全考量: 有没有敏感数据（token/credential）？ | 如果域涉及认证/授权 |
| 10 | 版本敏感性: 哪些部分最容易随 Trae 更新而变化？ | 始终建议回答 |

### 8.4 新域发现报告模板

当完成初步探索后，使用以下模板在 discoveries.md 末尾追加新域报告：

```
## [YYYY-MM-DD HH:mm] [NewDomain] 域名完整映射 ⭐⭐⭐⭐⭐

> 一句话概述这个新域是什么、为什么值得独立探索

### 1. 域判定
- 判定得分: X/5 (满足问题 1,2,3,4,5 中的 X 个)
- 不能归入现有域的原因: ...

### 2. 入口点
[问题 1 的答案]

### 3. 核心实体
[问题 2 的答案 — 表格或列表]

### 4. 数据流
[问题 3 的答案 — ASCII 图]

### 5. 域间关系
[问题 4 的答案]

### 6. 补丁相关性
[问题 5 的答案]

### 7. 搜索模板
| 目标 | 搜索关键词 | 稳定性 |
|------|-----------|--------|

### 8. 盲区
[此域内部的已知盲区列表]

### 9. 与现有发现的关系
[此域与哪些已有发现重叠或互补]
```

---

## 附录 A: 搜索模板速查表

### A.1 DI 相关模板

| 模板 ID | 搜索关键词 | 命令/方法 | 用途 | 稳定性 |
|---------|-----------|----------|------|--------|
| DI-01 | `uX(` | Search-Generic / IndexOf | 所有 DI 注入装饰器调用 (817次) | ⭐⭐ |
| DI-02 | `uJ({identifier:` | Search-Generic / IndexOf | 所有 DI 服务注册 (186次) | ⭐⭐ |
| DI-03 | `Symbol.for("` | Search-Generic / IndexOf | 全局 DI Token (Symbol.for) | ⭐⭐⭐⭐⭐ |
| DI-04 | `Symbol("` | Search-Generic / IndexOf | 局部 DI Token (Symbol) | ⭐⭐⭐⭐ |
| DI-05 | `uj.getInstance()` | IndexOf | DI 容器访问点 (45处resolve) | ⭐⭐ |
| DI-06 | `hX=()=>uj.getInstance()` | IndexOf | 容器快捷方式定义 | ⭐⭐⭐ |
| DI-07 | `uB=(hX=` | IndexOf | React useInject Hook 定义 | ⭐⭐⭐ |
| DI-08 | `class uj` | IndexOf | DI Container 类定义 | ⭐⭐ |
| DI-09 | `new uP` | IndexOf | DependencyRegistry 实例化 | ⭐⭐ |
| DI-10 | `S2.I` | Search-Generic / IndexOf | VS Code 服务标识 (IEditorService 等) | ⭐⭐⭐ |

### A.2 SSE 相关模板

| 模板 ID | 搜索关键词 | 命令/方法 | 用途 | 稳定性 |
|---------|-----------|----------|------|--------|
| SSE-01 | `eventHandlerFactory` | Search-Generic / IndexOf | SSE 事件中央调度器 | ⭐⭐⭐ |
| SSE-02 | `Symbol("IPlanItemStreamParser")` | IndexOf | PlanItem Parser Token (migrated from Symbol.for) | ⭐⭐⭐⭐ |
| SSE-03 | `Symbol.for("IErrorStreamParser")` | IndexOf | Error Parser Token | ⭐⭐⭐⭐⭐ |
| SSE-04 | `Symbol.for("INotificationStreamParser")` | IndexOf | Notification Parser Token | ⭐⭐⭐⭐⭐ |
| SSE-05 | `Symbol.for("ITextMessageChatStreamParser")` | IndexOf | TextMessage Parser Token | ⭐⭐⭐⭐⭐ |
| SSE-06 | `.parse(e,t` | Search-Generic / IndexOf | 所有 Parser 的 parse 方法 (minified无空格) | ⭐⭐⭐ |
| SSE-07 | `handleSteamingResult` | IndexOf | SSE 结果分发方法 | ⭐⭐⭐ |
| SSE-08 | `_onMessage` | IndexOf | SSE 消息回调 | ⭐⭐ |
| SSE-09 | `_onError` | IndexOf | SSE 错误回调 | ⭐⭐ |
| SSE-10 | `onComplete` | IndexOf | SSE 完成回调 | ⭐⭐ |
| SSE-11 | `ChatStreamService` | IndexOf | ChatStreamService 基类 (log字符串锚点) | ⭐⭐⭐ |
| SSE-12 | `Symbol.for("ISideChatStreamService")` | IndexOf | SideChatStreamService Token | ⭐⭐⭐⭐⭐ |
| SSE-13 | `Symbol.for("IInlineChatStreamService")` | IndexOf | InlineChatStreamService Token | ⭐⭐⭐⭐⭐ |
| SSE-14 | `Symbol("IMetadataParser")` | IndexOf | L3 数据层解析入口 (MetadataParser Token) | ⭐⭐⭐⭐ |

### A.3 Store 相关模板

| 模板 ID | 搜索关键词 | 命令/方法 | 用途 | 稳定性 |
|---------|-----------|----------|------|--------|
| STO-01 | `Symbol("ISessionStore")` | IndexOf | SessionStore Token (主聊天) | ⭐⭐⭐⭐ |
| STO-02 | `Symbol("IInlineSessionStore")` | IndexOf | InlineSessionStore Token | ⭐⭐⭐⭐ |
| STO-03 | `Symbol("IModelStore")` | IndexOf | ModelStore Token | ⭐⭐⭐⭐ |
| STO-04 | `.subscribe(` | Search-Generic / IndexOf | 所有 Store 订阅 | ⭐⭐⭐ |
| STO-05 | `.getState()` | Search-Generic / IndexOf | Store 状态读取 | ⭐⭐⭐ |
| STO-06 | `setState(` | Search-Generic / IndexOf | Store 状态写入 | ⭐⭐⭐ |
| STO-07 | `setCurrentSession` | IndexOf | SessionStore 主 mutation | ⭐⭐⭐ |
| STO-08 | `updateMessage(` | IndexOf | 消息更新 mutation | ⭐⭐⭐ |
| STO-09 | `updateLastMessage(` | IndexOf | 最后消息更新 mutation | ⭐⭐⭐ |
| STO-10 | `N.useStore` | IndexOf | React Hook Store 访问 | ⭐⭐ |

### A.4 错误相关模板

| 模板 ID | 搜索关键词 | 命令/方法 | 用途 | 稳定性 |
|---------|-----------|----------|------|--------|
| ERR-01 | `4000002` | IndexOf | TASK_TURN_EXCEEDED_ERROR (数字) | ⭐⭐⭐⭐⭐ |
| ERR-02 | `4000009` | IndexOf | LLM_STOP_DUP_TOOL_CALL (数字) | ⭐⭐⭐⭐⭐ |
| ERR-03 | `4000012` | IndexOf | LLM_STOP_CONTENT_LOOP (数字) | ⭐⭐⭐⭐⭐ |
| ERR-04 | `2000000` | IndexOf | DEFAULT error code (数字) | ⭐⭐⭐⭐⭐ |
| ERR-05 | `kg.TASK_TURN_EXCEEDED_ERROR` | IndexOf | 思考上限 (枚举名) | ⭐⭐⭐ |
| ERR-06 | `getErrorInfo` | IndexOf | 错误码→消息映射函数 | ⭐⭐⭐ |
| ERR-07 | `handleCommonError` | IndexOf | 通用错误处理函数 | ⭐⭐⭐ |
| ERR-08 | `exception` | Search-Generic / IndexOf | exception 字段 (谨慎: 命中很多) | ⭐⭐ |
| ERR-09 | `_stopStreaming` | IndexOf | 流停止/覆盖函数 | ⭐⭐ |
| ERR-10 | `bQ.Error` / `bQ.Warning` | IndexOf | 状态枚举值 | ⭐⭐⭐ |
| ERR-11 | `teaEventChatFail` | IndexOf | TEA 聊天失败上报 | ⭐⭐⭐⭐ |
| ERR-12 | `resumeChat` | IndexOf | 对话续接方法 | ⭐⭐⭐ |

### A.5 React 相关模板

| 模板 ID | 搜索关键词 | 命令/方法 | 用途 | 稳定性 |
|---------|-----------|----------|------|--------|
| RCT-01 | `sX().memo(` | IndexOf | React.memo 包装 | ⭐⭐ |
| RCT-02 | `sX().createElement(` | Search-Generic / IndexOf | React 元素创建 | ⭐⭐ |
| RCT-03 | `Cr.Alert` | IndexOf | Alert 渲染组件 | ⭐⭐⭐ |
| RCT-04 | `if(V&&J)` | IndexOf | auto-continue 条件分支 | ⭐ |
| RCT-05 | `useCallback` | Search-Generic / IndexOf | React useCallback Hook | ⭐⭐ |
| RCT-06 | `useMemo` | Search-Generic / IndexOf | React useMemo Hook | ⭐⭐ |
| RCT-07 | `useEffect` | Search-Generic / IndexOf | React useEffect Hook | ⭐⭐ |
| RCT-08 | `getRunCommandCardBranch` | IndexOf | UI 分支决策函数 | ⭐⭐⭐ |
| RCT-09 | `egR` | IndexOf | RunCommandCard 组件 | ⭐⭐ |
| RCT-10 | `"unconfirmed"` | IndexOf | 确认状态字符串 | ⭐⭐⭐⭐ |
| RCT-11 | `"redlist"` | IndexOf | BlockLevel 枚举值 | ⭐⭐⭐⭐ |
| RCT-12 | `ConfirmPopover` | IndexOf | 确认弹窗组件 | ⭐⭐⭐ |

### A.6 事件/IPC 相关模板

| 模板 ID | 搜索关键词 | 命令/方法 | 用途 | 稳定性 |
|---------|-----------|----------|------|--------|
| EVT-01 | `Symbol.for("ITeaFacade")` | IndexOf | TEA 服务 Token | ⭐⭐⭐⭐⭐ |
| EVT-02 | `visibilitychange` | IndexOf | DOM 可见性变化事件 | ⭐⭐⭐⭐⭐ |
| EVT-03 | `MessageChannel` | IndexOf | MessageChannel API | ⭐⭐⭐⭐⭐ |
| EVT-04 | `addEventListener` | Search-Generic / IndexOf | DOM 事件监听器 | ⭐⭐⭐ |
| EVT-05 | `IICubeShellExecService` | IndexOf | Shell 执行 DI 服务标识 (原 icube.shellExec 已迁移) | ⭐⭐⭐⭐ |
| EVT-06 | `registerCommand` | IndexOf | VS Code 命令注册 | ⭐⭐⭐ |
| EVT-07 | `registerAdapter` | IndexOf | 适配器注册 (@10476897) | ⭐⭐⭐ |
| EVT-08 | `ipcRenderer` | IndexOf | VS Code IPC 渲染进程桥接 (原 YTr 已迁移) | ⭐⭐⭐ |
| EVT-09 | `queueMicrotask` | IndexOf | 微任务调度 (不受后台节流) | ⭐⭐⭐⭐⭐ |

### A.7 商业权限相关模板

| 模板 ID | 搜索关键词 | 命令/方法 | 用途 | 稳定性 |
|---------|-----------|----------|------|--------|
| COM-01 | `ICommercialPermissionService` | Search-Generic / IndexOf | 商业权限服务接口字符串 | ⭐⭐⭐⭐⭐ |
| COM-02 | `isCommercialUser` | Search-Generic / IndexOf | 商业用户判断方法 | ⭐⭐⭐ |
| COM-03 | `IEntitlementStore` | Search-Generic / IndexOf | 权益存储接口字符串 | ⭐⭐⭐⭐ |
| COM-04 | `entitlementInfo` | Search-Generic / IndexOf | 权益信息字段 | ⭐⭐⭐ |
| COM-05 | `isFreeUser` | Search-Generic / IndexOf | 免费用户判断（React Hook efi()） | ⭐⭐⭐ |

### A.8 通用模板

| 模板 ID | 搜索关键词 | 命令/方法 | 用途 | 稳定性 |
|---------|-----------|----------|------|--------|
| GEN-01 | `<any string>` | Search-Generic | 自由文本搜索 | 取决于关键词 |
| GEN-02 | `class ` + 大写字母 | 正则/手动 | 所有类定义 | ⭐ |
| GEN-03 | `function ` + 大写字母 | 正则/手动 | 所有顶层函数定义 | ⭐ |
| GEN-04 | `https://` | IndexOf | URL/endpoint | ⭐⭐⭐ |
| GEN-05 | `console.log` | IndexOf | 日志输出点 | ⭐⭐ |
| GEN-06 | `provideUserResponse` | IndexOf | 工具调用确认 API | ⭐⭐⭐ |
| GEN-07 | `ToolCallName` | IndexOf | 工具调用名称枚举 | ⭐⭐⭐ |
| GEN-08 | `BlockLevel` | IndexOf | 命令阻塞级别 | ⭐⭐⭐⭐ |
| GEN-09 | `AutoRunMode` | IndexOf | 自动运行模式 | ⭐⭐⭐⭐ |
| GEN-10 | `AI.toolcall.confirmMode` | IndexOf | 确认模式设置键 (原 ConfirmMode 已迁移) | ⭐⭐⭐⭐ |

### A.8 搜索脚本参考

项目中提供的 `scripts/search-templates.ps1` 包含可复用的搜索函数。使用前确认其可用性：

```powershell
# 加载搜索模板
. .\scripts\search-templates.ps1

# 使用预定义函数
Search-DIToken                    # 搜索所有 DI 注入
Search-ServiceProperty             # 搜索所有 this._ 服务属性
Search-Subscribe                   # 搜索所有 Store 订阅
Search-StoreAction                 # 搜索所有 Store 写操作
Search-ErrorEnum                   # 搜索所有错误枚举
Search-ReactHook                   # 搜索所有 React Hooks
Search-Generic -Keyword "anchor"   # 自由搜索任意关键词
Search-All                         # 全量组合扫描
```

---

## 附录 B: 常见陷阱与反模式 (Common Pitfalls & Anti-Patterns)

### 反模式 1: 偏移量依赖 (Offset Dependency)

❌ **错误做法**: "前序探险家说 PlanItemStreamParser 在 @7502500，我去那里看看"

✅ **正确做法**: "我要找 PlanItemStreamParser，我用 `Symbol("IPlanItemStreamParser")` 自己定位，然后从定位点向外扩展"

**为什么错**: 偏移量在 Trae 更新后会变化。依赖前序报告的偏移量 = 在过时的地图上航行。偏移量应该作为**验证参考**而不是**搜索起点**。

**例外**: 当你需要验证前序发现是否仍然有效时，可以去报告的偏移量附近检查——但要用自己的锚点重新确认。

---

### 反模式 2: 单向搜索 (Unidirectional Search)

❌ **错误做法**: 找到锚点后只向后（增大偏移量方向）搜索

✅ **正确做法**: 从锚点**双向**扩展——向前看调用者和上下文，向后看实现和被调用者

**为什么错**:
- 向后只能看到"这个函数做了什么"，看不到"谁调用了它"、"在什么条件下调用"
- 函数的定义（class/function 关键字、参数列表、DI 注入）通常在锚点**前方**
- 很多关键信息（如父类、接口实现、装饰器）都在锚点前方

**标准双向扩展比例**: 向前 50% + 向后 50%（即前后各取 N/2 的上下文）

---

### 反模式 3: 信任混淆变量名 (Trusting Mangled Names)

❌ **错误做法**: "uj 是 DI 容器因为它的名字叫 uj"

✅ **正确做法**: "uj 是 DI 容器因为它有 `getInstance()` / `resolve()` / `provide()` 方法，并且包含 `bindings` Map 和 `singletons` Map"

**为什么错**:
- 混淆变量名（如 uj, xC, zU, Bs, Bo）每次 webpack/terser 构建都会改变
- 前一个版本叫 `uj` 的东西，下一个版本可能叫 `uC` 或 `uK`
- 但**方法名、字符串字面量、API 签名**通常保持不变（业务逻辑不变）

**判断依据优先级**: 行为特征 > 方法签名 > 命名惯例 > 变量名

---

### 反模式 4: 忽略括号计数 (Ignoring Brace Counting)

❌ **错误做法**: 看到 `{` 就认为是函数开始，看到第一个 `}` 就认为是函数结束

✅ **正确做法**: 用括号计数法确认函数体的真实边界，注意跳过字符串和正则表达式内的花括号

**为什么错**:
- 压缩代码中经常出现: `if(x){return{a:1}}else{return{b:2}}` —— 多层嵌套的对象字面量
- `()=>({a:1})` —— 箭头函数返回对象，花括号是对象不是函数体
- `` `template ${expr}` `` —— 模板字面量中的插值
- IIFE: `(function(){...})()` —— 外层还有圆括号

**后果**: 边界判断错误 → 提取的代码不完整或不正确 → 基于错误代码的理解产生错误结论

---

### 反模式 5: 假设版本一致性 (Assuming Version Consistency)

❌ **错误做法**: "上次看到的代码应该还在那，Trae 应该没更新"

✅ **正确做法**: 每次开始前检查文件大小和修改时间，确认版本一致性；搜索时始终用锚点而非偏移量定位

**为什么错**:
- Trae 可能自动更新（尤其在启动时）
- 文件大小变化: 10.73MB → 10.24MB（已观测到）
- 变量重命名: `efh` → `efg`, `P8` → `P7`（已观测到）
- 即使小版本更新也可能导致显著偏移量漂移

**检查清单**:
- [ ] 文件大小是否在预期范围内 (9-11MB)?
- [ ] 已知锚点 (如 `Symbol("IPlanItemStreamParser")`) 的偏移量是否在预期范围 (±5000)?
- [ ] 至少抽取 3 个已知代码片段确认内容一致?

---

### 反模式 6: 只报告成功案例 (Reporting Only Successes)

❌ **错误做法**: "我找到了 X 在 @12345"（不提搜索过程中看到的异常情况）

✅ **正确做法**: "我找到了 X 在 @12345（通过路径 A）。但在 @56789 也看到了类似代码（可能是另一个版本或另一个调用点），需要进一步验证"

**为什么错**:
- "另一个版本"可能意味着有多个代码路径处理同一功能（重要架构信息）
- 异常情况可能是 bug、废弃代码、或尚未理解的特性
- 不报告负面结果会让后续 Agent 重复同样的无效搜索
- 科学探索的精神是记录所有观察，而不只是符合预期的那些

**应该报告的"异常"**:
- 同一功能出现在多个偏移量位置
- 搜索到了但无法归类的代码
- 预期存在的锚点找不到（版本变化信号）
- 代码结构与预期不符

---

### 反模式 7: 不记录推理链 (Not Recording Reasoning Chain)

❌ **错误做法**: "PlanItemStreamParser._handlePlanItem 在 @7502500"

✅ **正确做法**: "从 `Symbol('IPlanItemStreamParser')` 出发(@7330000)，找到 `Br.register(Ot.PlanItem, ...)` (@7325000)，跟踪到 `.parse()` 方法 (@7503299)，在 parse 内部定位到 `_handlePlanItem()` (@7502500)。确认依据: 该方法内包含 `confirm_status==='unconditional'` 字符串"

**为什么错**:
- 没有推理链 = 无法复现 = 无法验证 = 对后续 Agent 无价值
- 推理链中的每一步都是一个可独立验证的断言
- 如果最终结论错了，推理链可以帮助定位哪一步出了问题
- 推理链本身就是搜索模板的雏形——告诉别人"怎么找到这里"

---

### 反模式 8: 忽略不确定性 (Ignoring Uncertainty)

❌ **错误做法**: "这肯定是 X 函数" / "这里的逻辑一定是 Y"

✅ **正确做法**: "根据上下文推断这可能是 X 函数（置信度: medium）。依据: (1) 它接收参数 pattern 与 X 的签名一致; (2) 它在 Y 类中被调用, 而 Y 已知与 X 相关。建议通过 Z 路径验证: 搜索 `X.prototype.method` 确认方法签名"

**为什么错**:
- 过度自信导致后续 Agent 把推断当作事实使用
- 在压缩代码中，推断的错误率远高于正常代码
- 明确标注不确定性可以让后续 Agent 知道哪里需要重点验证
- uncertainty 不是 weakness —— 它是 scientific honesty

**不确定性的正确表达方式**:

| 确定程度 | 表达方式 | 示例 |
|---------|---------|------|
| 高度确定 | 直接陈述 | "这是 PlanItemStreamParser._handlePlanItem 方法" |
| 较有把握 | 加"推断" | "这很可能是 _handlePlanItem 方法" |
| 有一定依据 | 加置信度和依据 | "推断这可能是 _handlePlanItem (medium), 依据: 包含 confirm_status 检查" |
| 猜测 | 明确标注 | "猜测这可能与 X 相关 (low), 需要验证" |
| 完全不知 | 诚实承认 | "无法确定这段代码的功能, 需要更多上下文" |

---

## 附录 C: 验证矩阵模板

以下是可直接复制使用的 Markdown 验证矩阵模板：

### C.1 标准验证矩阵

```
┌─────────────────────────────────────────────────────────────┐
│ 验证矩阵: [发现标题]                                        │
├──────────┬──────────────┬──────────────┬────────┬─────────┤
│ Agent    │ 搜索起点      │ 定位偏移量    │ 结论   │ 一致?   │
├──────────┼──────────────┼──────────────┼────────┼─────────┤
│ (发现者) │              │              │        │ —       │
│ (验证1)  │              │              │        │         │
│ (验证2)  │              │              │        │         │
│ (验证3)  │              │              │        │         │
└──────────┴──────────────┴──────────────┴────────┴─────────┘
置信度: [HIGH / MEDIUM / LOW / CONFLICTING]
verified_by: [Agent IDs]
last_verified: [YYYY-MM-DD]
conflict_notes: [如有冲突记录在此，否则删除此行]
```

### C.2 轻量验证矩阵 (用于 Minor 发现)

```
验证: [发现标题]
  路径1 ([锚点类型]): [锚点] → @[偏移量] ✓
  路径2 ([锚点类型]): [锚点] → @[偏移量] ✓
  confidence: [HIGH/MEDIUM]
  verified_by: [Agent ID], [YYYY-MM-DD]
```

### C.3 冲突记录模板

```
⚠️ CONFLICT: [发现标题]
  Agent A (@[日期]): [A 的结论] — 基于 [A 的锚点] @[A 的偏移量]
  Agent B (@[日期]): [B 的结论] — 基于 [B 的锚点] @[B 的偏移量]
  分歧点: [描述双方不一致的具体地方]
  仲裁: [待第三方 Agent C 仲裁 / 已由 Agent C 仲裁: C 的结论]
  resolution: [PENDING / RESOLVED on YYYY-MM-DD]
```

---

## 附录 D: 快速参考卡 (Quick Reference Card)

### D.1 启动检查清单 (一页版)

```
□ 1. 读 handoff.md                          (1-2 min)
□ 2. 运行 auto-heal -DiagnoseOnly           (30 sec)
□ 3. 读 discoveries.md (重点: 偏移量索引)    (5-10 min)
□ 4. 读 context.md                           (2-3 min)
□ 5. 读 docs/architecture/*.md               (10-15 min)
□ 6. 验证目标文件 (size/date/readable)        (<10 sec)
□ 7. 验证搜索工具 (test IndexOf)              (<30 sec)
总计: ~20-30 分钟
```

### D.2 稳定性金字塔 (一栏版)

```
⭐⭐⭐⭐⭐ Symbol.for("...")      → 搜索首选
⭐⭐⭐⭐   Symbol("...")          → 模块内搜索
⭐⭐⭐     API 方法名             → 备选锚点
⭐⭐       枚举字符串             → 确认用
⭐         混淆变量名             → 仅限同版本导航
```

### D.3 关键纠正速记

```
BR = path 模块 (非 DI Token!)
FX = findTargetAgent (非 DI 解构!)
Bs = ChatParserContext (非 ChatStreamService!)
Bo = ChatStreamService (基类!)
思考上限 = IPC 路径 (非 SSE!)
ew.confirm = telemetry (非执行!)
subscribe 参数 = (curr, prev) 非 (prev, curr)!
exception = IPC 携带 (非 index.js 内赋值!)
L1 = 后台冻结 (补丁放 L2/L3!)
ICommercialPermissionService = aiAgent.前缀 (非Symbol.for!)
DI = 186注册/817注入 (非51/101!)
kg = 56错误码 (非~30!)
ToolCallName = 38个 (非~12!)
beautified.js = 347244行 (非347099!)
```

### D.4 Top 3 Hook 点

```
1. PlanItemStreamParser._handlePlanItem  (~7502500)  综合 4.75
   → 命令确认最佳点, L2 层, 不受 React 冻结影响

2. teaEventChatFail                  (~7458679)  综合 4.5
   → 后台错误检测最佳点, 最早错误信号

3. DI Container resolve               (任意位置)  综合 4.0
   → 服务访问最佳点, uj.getInstance().resolve(Token)
```

### D.5 最大盲区优先级

```
P0: 54415-6268469  (~6.2MB!)  → Phase 1 粗筛 (每 100KB 采样)
P1: 8930000-9910446 (~1MB)    → UI 下半部分
P1: 9910446-10490354 (~550KB)  → 命令注册层
P2: 0-41400        (~41KB)    → webpack bootstrap (低优先)
P2: 10490354-EOF   (?)        → 文件末尾
```

### D.6 常用 PowerShell 搜索模式

```powershell
# 基础搜索
$c = [IO.File]::ReadAllText($path)
$idx = $c.IndexOf("keyword")
$ctx = $c.Substring([Math]::Max(0,$idx-200), 400)

# 双向扩展
$pre = $c.Substring([Math]::Max(0,$idx-N), N)
$post = $c.Substring($idx, N)

# 变体搜索
$variants = @("Symbol.for('X')", "Symbol('X')", "xVar", "methodName")
foreach ($v in $variants) { $c.IndexOf($v) }

# Gap 扫描
$points = @(0, 54000, 6268469, 7087490, 7502500, 8930000, 10490354)
# 计算 points[i] 到 points[i+1] 的 gap, 对 >10000 的 gap 取样
```

---

> **文档维护说明**: 本协议文档应在以下情况下更新:
> 1. 发现新的重要纠正事实 → 追加到 Chapter 1.6
> 2. 发现新的域 → 追加到 Chapter 3.1 和 3.2
> 3. 验证方法论有改进 → 更新对应章节
> 4. Trae 重大更新导致搜索策略变化 → 更新附录
>
> **永远追加，不要重写。**
