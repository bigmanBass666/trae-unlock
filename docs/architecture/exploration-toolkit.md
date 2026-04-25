# 探索工具箱使用指南 (Exploration Toolkit Guide)

> **版本**: 1.0 | **创建日期**: 2026-04-25 | **适用项目**: trae-unlock
>
> 本文档是 trae-unlock 项目探索工具链的完整使用手册。所有参与源码探索的 Agent 应在开始深度探索前阅读本文档。

## 1. 工具链概览

### 1.1 问题背景

trae-unlock 的目标文件是 Trae IDE 的 `@byted-icube/ai-modules-chat/dist/index.js`——一个**单行 ~10MB 的压缩 JavaScript 文件**（实际约 9.5-10.5MB）。这个文件的特点：

- **单行压缩**：整个文件可能只有 1-3 行，所有代码被 webpack 打包压缩为一行
- **无 source map**：无法通过 reverse-sourcemap 还原原始源码
- **体积巨大**：解包后膨胀至 **21.18 MB / 347,099 行**
- **含 TypeScript 装饰器**：使用了 `@babel/parser` 才能正确解析的装饰器语法

传统搜索工具在此场景下完全失效：
- `Grep`/`ripgrep`：依赖行号，单行文件无意义
- `ast-grep`：不支持压缩 JS 的 AST 搜索
- VS Code 搜索：对 >10MB 单行文件性能极差

因此项目构建了一套**4 层级工具金字塔**，从原始字节偏移到语义级 AST 分析。

### 1.2 4 层级工具金字塔

| 层级 | 工具 | 输入 | 输出 | 粒度 | 用途 |
|------|------|------|------|------|------|
| **L0: 原始字节** | PowerShell `IndexOf` | 压缩 index.js (10MB) | 字节偏移 + 上下文片段 | 子串匹配 | 快速定位已知关键词，验证补丁锚点 |
| **L1: 美化文本** | `js-beautify` + `Select-String` | beautified.js (21MB, 347K行) | 行号 + 上下文 | 正则/字面量搜索 | 解包后的人类可读搜索 |
| **L2: 模块感知** | `module-search.ps1` | beautified.js | Webpack Module ID + 范围 | 模块级定位 | 按 Webpack 模块边界组织搜索结果 |
| **L3: AST 语义** | `ast-search.ps1` (@babel/parser) | beautified.js / 任意 JS | 结构化节点 (类型/名称/位置) | 语法级精确匹配 | 函数提取、类继承分析、跨作用域追踪 |

**选择原则**：

```
已知确切关键词 → L0 IndexOf (最快，秒级)
需要行号上下文 → L1 Select-String (需先解包)
需要模块归属 → L2 module-search (自动关联 Webpack module ID)
需要结构化分析 → L3 AST (最慢但最精确)
```

### 1.3 当前可用工具清单

| 工具 | 状态 | 版本 | 路径 | 说明 |
|------|------|------|------|------|
| **node** | ✅ OK | v24.9.0 | `D:\apps\nvm4w\nodejs\node.exe` | AST 引擎运行时 |
| **js-beautify** | ✅ OK | 1.15.4 | `D:\apps\nvm4w\nodejs\js-beautify.ps1` | **主要美化工具** |
| **webcrack** | ⚠️ OK | 2.15.1 | `D:\apps\nvm4w\nodejs\webcrack.ps1` | 已安装但不兼容 TS 装饰器 |
| **reverse-sourcemap** | ❌ MISSING | - | - | 未安装，Trae 不提供 source map |
| **@babel/parser** | ✅ 内置 | via tools/node_modules | `tools/node_modules/@babel/parser` | AST 解析核心 |
| **@babel/traverse** | ✅ 内置 | via tools/node_modules | `tools/node_modules/@babel/traverse` | AST 遍历核心 |

> **关键决策**: js-beautify 是唯一可靠的美化工具。webcrack 虽已安装但对 TypeScript 装饰器语法不兼容，解析会报错或丢失信息。

## 2. 快速开始

### 2.1 环境检查

每次新会话开始探索前，首先确认工具链就绪：

```powershell
cd d:\Test\trae-unlock
. .\scripts\unpack.ps1
Test-ToolAvailability
```

**预期输出**:

```
[unpack] Tool Availability Check
Tool                   Status     Version
---------------------------------------------
node                   OK         v24.9.0
js-beautify            OK         1.15.4
webcrack               OK         2.15.1
reverse-sourcemap      MISSING    -

  Summary: 3 / 4 tools available
```

最低要求：**node + js-beautify** 必须可用（2/4 即可进行基本探索）。webcrack 和 reverse-sourcemap 为可选增强。

### 2.2 首次解包

如果 `unpacked/beautified.js` 不存在或已过时，执行解包：

```powershell
cd d:\Test\trae-unlock
. .\scripts\unpack.ps1
Unpack-TraeIndex -Force
```

**完整参数说明**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `-SourcePath` | string | `D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js` | 压缩源文件路径 |
| `-OutputDir` | string | `d:\Test\trae-unlock\unpacked` | 输出目录 |
| `-Force` | switch | false | 强制覆盖已有文件 |

**预期输出**:

```
[unpack] Starting unpack process...
  Source: D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js
  Size: 9.82 MB (within expected range)

[unpack] Running js-beautify...

[unpack] File Statistics: index.beautified.js
  Size:          21.18 MB (22208802 bytes)
  Lines:         347,099
  Last Modified: 2026-04-25 21:11:49
  Created:       2026-04-25 21:09:30

[unpack] Done!
  Compression ratio: 2.26:1 (minified -> beautified)
  Time elapsed:     12.3s
  Output:           d:\Test\trae-unlock\unpacked\index.beautified.js
```

> **注意**: 实际输出文件名是 `beautified.js`（位于 `unpacked/` 目录），脚本默认名为 `index.beautified.js`。两者为同一文件的别名关系。

### 2.3 验证输出

解包完成后，验证文件完整性：

```powershell
Get-UnpackStats -Path "d:\Test\trae-unlock\unpacked\beautified.js"
```

**健康指标**：

| 指标 | 健康范围 | 当前值 | 判定 |
|------|---------|--------|------|
| 文件大小 | 18-25 MB | 21.18 MB | ✅ 正常 |
| 行数 | 300,000-400,000 | 347,099 | ✅ 正常 |
| 压缩比 | 2.0:1 - 2.5:1 | 2.26:1 | ✅ 正常 |

异常信号：
- **< 15 MB 或 < 200K 行** → js-beautify 可能截断了文件
- **> 30 MB 或 > 500K 行** → 可能是重复写入或编码问题
- **压缩比 < 1.5:1** → 源文件可能不是正确的 index.js

## 3. 核心脚本参考

### 3.1 unpack.ps1 — 解包与统计

**文件位置**: [scripts/unpack.ps1](../../scripts/unpack.ps1)

#### Unpack-TraeIndex

主函数：将压缩的 index.js 美化为可读格式。

```powershell
Unpack-TraeIndex [-SourcePath <path>] [-OutputDir <dir>] [-Force]
```

**内部流程**:
1. 验证源文件存在且大小在 9-11MB 范围内
2. 创建输出目录（如不存在）
3. 检测输出文件是否已存在（非 Force 模式下需确认）
4. 调用 `js-beautify` 带以下参数：
   - `--indent-size 4`：4 空格缩进
   - `--preserve-newlines true --max-preserve-newlines 2`：保留最多 2 个空行
   - `--space-in-paren false`：括号内不加空格
   - `--break-chained-methods false`：不拆分链式调用
5. 统计并报告结果

**js-beautify 参数调优说明**：
- `indent-size 4` 与项目现有代码风格一致
- `max-preserve-newlines 2` 防止过度膨胀（原始可能有大量空行）
- `break-chained-methods false` 对 34 万行文件至关重要——开启会导致链式调用（如 `.then(...).catch(...)`）每步换行，行数暴增 50%+

#### Test-ToolAvailability

检查 4 种工具的安装状态和版本。

```powershell
Test-ToolAvailability
# 返回: PSCustomObject[] 数组，每个元素包含 Tool/Status/Version/Path
```

#### Get-UnpackStats

读取已解包文件的统计信息。

```powershell
Get-UnpackStats [-Path <path>] [-OutputDir <dir>]
# 返回: PSCustomObject { Path, SizeBytes, SizeMB, LineCount, LastModified, Created }
```

---

### 3.2 ast-search.ps1 — AST 语义分析

**文件位置**: [scripts/ast-search.ps1](../../scripts/ast-search.ps1)

**前置依赖**: 需要 `tools/node_modules/@babel/parser` 和 `@babel/traverse`（已内置在项目中）。

**Babel Parser 配置**（所有函数共用）：

```javascript
parser.parse(src, {
    sourceType: 'module',
    plugins: [
        'decorators',              // 必须！Trae 使用 TS 装饰器
        'decoratorAutoAccessors',  // 装饰器自动访问器
        'classProperties',         // 类属性
        'classPrivateProperties',  // 私有属性
        'classPrivateMethods',     // 私有方法
        'jsx'                      // JSX 语法
    ],
    errorRecovery: true,           // 必须！容错模式，遇到错误继续解析
    tokens: false                  // 不生成 token，节省内存
})
```

> **⚠️ 关键配置**: `errorRecovery: true` 是必须的——34 万行的 beautified.js 几乎必然有 Babel 无法完美解析的边缘情况。关闭此选项会导致整个文件解析失败。`plugins: ["decorators"]` 同样必须，否则装饰器语法会被当作语法错误。

#### Search-AST — 精确 AST 节点搜索

按节点类型和名称模式搜索，返回带上下文预览的结果。

```powershell
Search-AST -FilePath <path> -NodeType <type> [-NamePattern <regex>] [-MaxResults 50]
```

**参数**:

| 参数 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `-FilePath` | ✅ | - | 目标 JS 文件路径 |
| `-NodeType` | ✅ | - | Babel 节点类型（如 `FunctionDeclaration`, `ClassDeclaration`, `CallExpression`） |
| `-NamePattern` | | `.*` | 名称正则过滤 |
| `-MaxResults` | | `50` | 最大返回数 |

**返回值**: `PSCustomObject[]`，每项包含：

```typescript
{
    type: string,            // 节点类型，如 "FunctionDeclaration"
    name: string,            // 名称，如 "PlanItemStreamParser"
    start_line: number,      // 起始行号
    end_line: number,        // 结束行号
    start_col: number,       // 起始列号
    context_preview: string  // 上下文预览（最多 500 字符）
}
```

**常用 NodeType 参考**:

| NodeType | 匹配内容 | 典型用途 |
|----------|---------|---------|
| `FunctionDeclaration` | `function name() {}` | 查找顶层函数 |
| `ClassDeclaration` | `class Name {}` | 查找类定义 |
| `ClassExpression` | `var X = class {}` | 查找匿名类赋值 |
| `MethodDefinition` | 类的方法 | 查找特定类方法 |
| `CallExpression` | `func()` | 查找函数调用 |
| `MemberExpression` | `obj.prop` | 查找成员访问 |
| `AssignmentExpression` | `x = y` | 查找赋值操作 |
| `NewExpression` | `new Class()` | 查找实例化 |
| `Identifier` | 变量名 | 查找标识符引用 |

**示例**:

```powershell
# 查找 PlanItemStreamParser 函数
. .\scripts\ast-search.ps1
Search-AST -FilePath "d:\Test\trae-unlock\unpacked\beautified.js" `
    -NodeType FunctionDeclaration `
    -NamePattern "PlanItemStreamParser"

# 查找所有包含 Stream 的类
Search-AST -FilePath "d:\Test\trae-unlock\unpacked\beautified.js" `
    -NodeType ClassDeclaration `
    -NamePattern ".*Stream.*" `
    -MaxResults 20

# 查找所有 confirm 相关调用
Search-AST -FilePath "d:\Test\trae-unlock\unpacked\beautified.js" `
    -NodeType CallExpression `
    -NamePattern ".*confirm.*"
```

#### Search-ASTFast — 快速 AST 搜索（轻量版）

与 `Search-AST` 相同的搜索能力，但不返回上下文预览，速度更快。

```powershell
Search-ASTFast -FilePath <path> -NodeType <type> [-NamePattern <regex>] [-MaxResults 200]
```

**返回值差异**: 只有 `{ type, name, line, col }`，无 `context_preview` 和 `end_line`。

**适用场景**: 大规模扫描时先用 Fast 版本筛选，再用完整版查看细节。

```powershell
# 快速扫描所有类（返回 1000+ 结果）
$classes = Search-ASTFast -FilePath "d:\Test\trae-unlock\unpacked\beautified.js" `
    -NodeType ClassDeclaration `
    -MaxResults 2000
Write-Host "Found $($classes.Count) classes"

# 再对感兴趣的类做详细查询
Search-AST -FilePath "d:\Test\trae-unlock\unpacked\beautified.js" `
    -NodeType ClassDeclaration `
    -NamePattern "RunCommandCard"
```

#### Extract-AllFunctions — 全量函数提取

提取文件中所有函数声明和表达式，输出为 JSON 索引文件。

```powershell
Extract-AllFunctions -FilePath <path> [-OutputFile "functions-index.json"]
```

**输出 JSON 结构**:

```json
[
  {
    "name": "PlanItemStreamParser",
    "type": "FunctionDeclaration",
    "params": ["e", "t", "n"],
    "async": false,
    "generator": false,
    "start": 7502574,
    "end": 7508200
  },
  {
    "name": "(anonymous)",
    "type": "ArrowFunctionExpression",
    "params": ["res"],
    "async": true,
    "generator": false,
    "start": 7508201,
    "end": 7508350
  }
]
```

**命名推断规则**:

| 父节点类型 | 推断名称来源 |
|-----------|-------------|
| `VariableDeclarator` | 变量名（`var fn = function(){}` → `fn`） |
| `AssignmentExpression` | 左侧标识符（`obj.fn = function(){}` → `fn`） |
| `MethodDefinition` | 方法键名 |
| `Property` | 属性键名 |
| `ExportDefault/NamedDeclaration` | `(exported)` |
| 其他 | `(anonymous)` |

**当前数据**: 在 beautified.js 上运行提取到 **38,630 个函数**。

**典型工作流**:

```powershell
. .\scripts\ast-search.ps1
Extract-AllFunctions -FilePath "d:\Test\trae-unlock\unpacked\beautified.js" -OutputFile "functions-index.json"

# 提取后在 JSON 中搜索
$funcs = Get-Content "functions-index.json" | ConvertFrom-Json
$funcs | Where-Object { $_.name -match "confirm" } | Format-Table name, type, async, start, end
```

#### Extract-AllClasses — 全量类提取

提取文件中所有类声明和表达式，输出为 JSON 索引文件。

```powershell
Extract-AllClasses -FilePath <path> [-OutputFile "classes-index.json"]
```

**输出 JSON 结构**:

```json
[
  {
    "name": "RunCommandCard",
    "extends": "Component",
    "decorators": ["memo(...)"],
    "methods": [
      { "kind": "method", "key": "render", "static": false },
      { "kind": "method", "key": "componentDidMount", "static": false }
    ],
    "start": 8635000,
    "end": 8642000
  }
]
```

**额外提取信息**:
- `extends`: 父类名（Identifier）或类型名（如 `CallExpression`）
- `decorators`: 装饰器列表（如 `memo`, `observer` 等）
- `methods`: 所有方法定义（kind/key/static/computed）

**当前数据**: 在 beautified.js 上运行提取到 **1,009 个类**。

---

### 3.3 module-search.ps1 — Webpack 模块级搜索

**文件位置**: [scripts/module-search.ps1](../../scripts/module-search.ps1)

**核心概念**: Trae 的 index.js 由 webpack 打包，代码按模块组织。每个模块以 `moduleId: function(params){...}` 开头。此脚本利用这一结构将搜索结果映射到具体模块。

**模块识别模式**: `^\s*(\d+):\s*function\s*\(` — 匹配形如 `12345: function(e,t,n){` 的行。

#### 三种运行模式

##### Mode 1: Search — 关键词搜索（默认）

```powershell
.\module-search.ps1 -Keyword "PlanItemStreamParser" [-Regex] [-ContextLines 3] [-MaxResults 50]
```

**参数**:

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `-Keyword` | (必填) | 搜索关键词 |
| `-Regex` | false | 启用正则模式 |
| `-ContextLines` | `3` | 上下文行数 |
| `-MaxResults` | `50` | 最大结果数 |

**输出格式**: 表格，列包括 `Module` (M+ID)、`Line`、`Preview`、`Before`、`After`

**示例**:

```powershell
# 字面量搜索
.\module-search.ps1 -Keyword "PlanItemStreamParser"

# 正则搜索
.\module-search.ps1 -Keyword "class\s+\w+Stream" -Regex -ContextLines 5
```

##### Mode 2: Overview — 全局模块概览

```powershell
.\module-search.ps1 -Mode Overview
```

**输出内容**:
1. 总模块数量
2. 模块大小分布（Tiny/Small/Medium/Large/Huge）
3. Top 20 最大模块列表
4. 业务逻辑候选（≥200 行的模块，标注 class/exports/HUGE 标签）

**大小分级标准**:

| 分级 | 行数范围 | 含义 |
|------|---------|------|
| Tiny | < 10 | 辅助函数、常量定义 |
| Small | 10-49 | 工具函数、简单组件 |
| Medium | 50-199 | 中等复杂度的逻辑单元 |
| Large | 200-999 | **业务逻辑候选**，值得深入探索 |
| Huge | ≥ 1000 | 核心模块，高价值目标 |

**业务逻辑候选标签**:
- `class`: 包含类定义
- `exports`: 包含模块导出
- `HUGE`: ≥1000 行的超大模块

##### Mode 3: Find — 按内容类型快速定位模块

```powershell
.\module-search.ps1 -Mode Find -Keyword "command" [-FileType class|function|string|all]
```

**FileType 过滤器**:

| FileType | 匹配模式 | 示例 |
|----------|---------|------|
| `class` | `class\s+\w+` | 查找类定义 |
| `function` | `function\s+\w*` / `=>\s*\{` | 查找函数定义 |
| `string` | 包含关键词的字符串字面量 | 查找 UI 文案、错误消息 |
| `all` | 任意出现 | 完全匹配 |

**输出**: 按命中次数排序的模块列表，显示模块 ID、命中数、预估行数、首条命中的行号和预览。

**示例**:

```powershell
# 找包含 "command" 的类所在模块
.\module-search.ps1 -Mode Find -Keyword "command" -FileType class

# 找包含特定字符串的模块
.\module-search.ps1 -Mode Find -Keyword "auto_confirm" -FileType string
```

#### 内部辅助函数

**Get-ModuleIdFromLine**: 给定行号，向前扫描找到所属的 Webpack Module ID。

**Get-ModuleLineRange**: 给定 Module ID，计算该模块的起止行范围。

这两个函数是所有模式的基础设施，理解它们有助于调试搜索结果异常的情况。

---

### 3.4 search-templates.ps1 — 预定义搜索模板

**文件位置**: [scripts/search-templates.ps1](../../scripts/search-templates.ps1)

**定位**: Layer 0 工具，直接在**压缩的** index.js 上操作（不需要先解包）。提供 12 个预定义搜索模板，覆盖 Trae 内部的关键架构特征。

**与其它脚本的关系**:

| 脚本 | 操作对象 | 层级 | 适用阶段 |
|------|---------|------|---------|
| `search-templates.ps1` | 压缩 index.js (~10MB) | L0 | 快速侦察、锚点验证 |
| `module-search.ps1` | beautified.js (~21MB) | L1/L2 | 深度搜索、模块归属 |
| `ast-search.ps1` | beautified.js / 任意 JS | L3 | 结构分析、全量提取 |

#### 可用模板

| 模板函数 | 搜索关键词 | 发现目标 |
|----------|-----------|---------|
| `Search-DIToken` | `uX(` | 依赖注入 Token 注入点 |
| `Search-ServiceProperty` | `this._` | 服务实例属性访问 |
| `Search-Subscribe` | `.subscribe(` | RxJS 订阅点（事件监听） |
| `Search-EventHandler` | `eventHandlerFactory.handle(` | 事件处理器分发 |
| `Search-StoreAction` | `storeService.` / `setCurrentSession` | 状态管理操作 |
| `Search-ReactHook` | `useCallback(` / `useMemo(` / `useEffect(` | React Hooks 调用 |
| `Search-ErrorEnum` | `kg.` | 错误码枚举引用 |
| `Search-TeaEvent` | `teaEvent` / `tea.` | 埋点事件上报 |
| `Search-IPC` | `postMessage` / `onmessage` / `ipcRenderer` | 进程间通信 |
| `Search-SettingKey` | `AI.toolcall.` / `chat.tools.` | 设置项键名 |
| `Search-Generic` | 自定义关键词 | 通用子串搜索 |
| `Search-All` | 以上全部 | 一键全景扫描 |

#### 使用方法

```powershell
cd d:\Test\trae-unlock
. .\scripts\search-templates.ps1

# 单个模板搜索
$results = Search-DIToken -Context 150
$results | ForEach-Object { Write-Host "$($_.Offset): $($_.Context)" }

# 通用搜索
Search-Generic -Keyword "PlanItemStreamParser" -Context 200

# 全景扫描（推荐首次探索时运行）
Search-All -Context 80
```

**Search-All 输出示例**:

```
[DIToken] 47 hits (152ms)
[ServiceProperty] 3891 hits (891ms)
[Subscribe] 156 hits (234ms)
[EventHandler] 89 hits (178ms)
[StoreAction] 234 hits (312ms)
[ReactHook] 5678 hits (1456ms)
[ErrorEnum] 234 hits (198ms)
[TeaEvent] 89 hits (167ms)
[IPC] 45 hits (145ms)
[SettingKey] 12 hits (89ms)

=== Search-All Summary ===
SearchName    HitCount  ElapsedMs
----------    --------  ---------
DIToken            47       152
ServiceProperty   3891       891
Subscribe          156       234
...
```

**Get-Context 函数**: 所有模板共用的上下文提取器，从给定偏移量前后各取 N 字符（默认 150），用 `...` 标记截断边界。

## 4. 工作流模板

### 4.1 Workflow A: 新域发现

**场景**: 你需要在 Trae 源码中发现一个全新的功能域（例如：「找到所有与文件系统操作相关的代码」）。

**步骤序列**:

```
Step 1: L0 快速侦察 (30s)
┌───────────────────────────────────────────────┐
│ . .\scripts\search-templates.ps1              │
│ Search-Generic -Keyword "fs." -Context 200    │
│ Search-Generic -Keyword "readFile" -Context 200│
│ Search-Generic -Keyword "writeFile" -Context 200│
└───────────────────────────────────────────────┘
                │
                ▼
Step 2: L1 精确定位 (1min)
┌───────────────────────────────────────────────┐
│ # 如果 beautified.js 不存在，先解包             │
│ . .\scripts\unpack.ps1                        │
│ Unpack-TraeIndex -Force                       │
│                                               │
│ # 在美化文件上搜索                             │
│ .\module-search.ps1 -Keyword "readFile"       │
│   -ContextLines 5 -MaxResults 30              │
└───────────────────────────────────────────────┘
                │
                ▼
Step 3: L2 模块归集 (2min)
┌───────────────────────────────────────────────┐
│ .\module-search.ps1 -Mode Find               │
│   -Keyword "FileSystemService"               │
│   -FileType class                            │
│                                               │
│ # 记录命中的 Module ID 和行号范围              │
└───────────────────────────────────────────────┘
                │
                ▼
Step 4: L3 结构分析 (5min)
┌───────────────────────────────────────────────┐
│ . .\scripts\ast-search.ps1                    │
│                                               │
│ # 提取相关类的完整结构                         │
│ Search-AST -FileType beautified.js            │
│   -NodeType ClassDeclaration                  │
│   -NamePattern ".*File.*Service.*"            │
│                                               │
│ # 如需全局视图                                │
│ Extract-AllClasses -FilePath beautified.js    │
│   -OutputFile classes-index.json              │
│ # 然后在 JSON 中筛选                           │
└───────────────────────────────────────────────┘
                │
                ▼
Step 5: 记录发现
┌───────────────────────────────────────────────┐
│ # 将发现追加到 shared/discoveries.md          │
│ # 格式: ### [YYYY-MM-DD HH:mm] 标题           │
│ # 内容: 类名、行号范围、方法列表、关键调用     │
└───────────────────────────────────────────────┘
```

### 4.2 Workflow B: 交叉验证

**场景**: 你用一种工具找到了一个代码位置，需要用另一种工具验证其准确性。

**典型案例**: 用 IndexOf 找到了偏移量 ~7502574，怀疑这是 PlanItemStreamParser，需要验证。

```
验证路径 A: L0 → L1 映射验证
┌────────────────────────────────────────────────┐
│ # Step 1: L0 获取偏移                          │
│ $c = [IO.File]::ReadAllText($sourcePath)       │
│ $offset = $c.IndexOf("PlanItemStreamParser")    │
│ # 结果: offset = 7502574                        │
│                                                │
│ # Step 2: 在 beautified.js 中查找同一行         │
│ Select-String -Path beautified.js              │
│   -Pattern "PlanItemStreamParser"              │
│ # 结果: Line 7502574                           │
│                                                │
│ # Step 3: 验证行号一致性                       │
│ # L0 offset ≈ L1 line number ✓                 │
└────────────────────────────────────────────────┘

验证路径 B: L1 → L3 结构验证
┌────────────────────────────────────────────────┐
│ # Step 1: L1 找到行号                          │
│ # Line 7502574 包含 "PlanItemStreamParser"      │
│                                                │
│ # Step 2: L3 确认结构                         │
│ . .\scripts\ast-search.ps1                     │
│ Search-AST -FilePath beautified.js             │
│   -NodeType FunctionDeclaration                │
│   -NamePattern "PlanItemStreamParser"          │
│                                                │
│ # 结果:                                        │
│ # {                                           │
│ #   type: "FunctionDeclaration",               │
│ #   name: "PlanItemStreamParser",              │
│ #   start_line: 7502574,                       │
│ #   end_line: 7508200,                         │
│ #   context_preview: "function PlanItem..."    │
│ # }                                            │
│                                                │
│ # Step 3: 确认这是一个完整的函数定义 ✓          │
└────────────────────────────────────────────────┘

验证路径 C: L3 → L2 模块归属验证
┌────────────────────────────────────────────────┐
│ # Step 1: L3 获取行号范围                      │
│ # start_line: 7502574, end_line: 7508200       │
│                                                │
│ # Step 2: L2 查询模块归属                     │
│ .\module-search.ps1 -Keyword "7502574"         │
│                                                │
│ # 结果: 属于 Module M2847                      │
│ # M2847 范围: L7502500-L7508500 (6000 lines)   │
│                                                │
│ # Step 3: 理解该模块的整体职责                  │
│ .\module-search.ps1 -Mode Overview             │
│ # 查看 M2847 是否出现在 Large/Huge 列表中      │
└────────────────────────────────────────────────┘
```

### 4.3 Workflow C: 版本适配

**场景**: Trae IDE 更新了，index.js 变化了，需要重新定位所有补丁锚点。

```
Phase 1: 变更检测 (5min)
┌───────────────────────────────────────────────┐
│ # 1. 备份旧版本                               │
│ Copy-Item $sourcePath backups\old-version.js  │
│                                               │
│ # 2. 对比文件大小                             │
│ $old = (Get-Item backups\old-version.js).Length│
│ $new = (Get-Item $sourcePath).Length          │
│ Write-Host "Size change: $old -> $new"        │
│                                               │
│ # 3. 重新解包                                 │
│ . .\scripts\unpack.ps1                        │
│ Unpack-TraeIndex -Force                       │
│                                               │
│ # 4. 用 Search-All 检测结构性变化              │
│ . .\scripts\search-templates.ps1              │
│ $oldScan = Search-All -Context 80              │
│ # 保存旧版扫描结果供对比                       │
└───────────────────────────────────────────────┘
                │
                ▼
Phase 2: 锚点重定位 (逐个补丁)
┌───────────────────────────────────────────────┐
│ for each patch in definitions.json:           │
│   1. 取 patch.find_original 中的关键子串       │
│   2. Search-Generic -Keyword <substring>       │
│   3. 如果找到:                                │
│      - 记录新 offset                          │
│      - 用 Get-Context 验证周围代码未变         │
│      - 更新 patch.anchor_offset               │
│   4. 如果找不到:                              │
│      - 尝试模糊搜索（取 find_original 前20字符）│
│      - 尝试搜索 fingerprint 字符串             │
│      - 标记为 BROKEN，需人工分析               │
└───────────────────────────────────────────────┘
                │
                ▼
Phase 3: 验证与回归 (10min)
┌───────────────────────────────────────────────┐
│ # 1. 应用更新后的补丁                         │
│ .\scripts\apply-patches.ps1                   │
│                                               │
│ # 2. 语法检查                                 │
│ node --check $sourcePath                      │
│                                               │
│ # 3. 启动 Trae 验证功能                       │
│ # 手动测试每个补丁的功能是否正常               │
│                                               │
│ # 4. 更新 shared/status.md                    │
└───────────────────────────────────────────────┘
```

**版本变化严重程度判断**:

| 信号 | 严重程度 | 应对策略 |
|------|---------|---------|
| 文件大小变化 < 5% | 🟢 低 | 大部分锚点只需微调偏移 |
| 文件大小变化 5-20% | 🟡 中 | 需要逐个验证，部分可能需要重新搜索 |
| 文件大小变化 > 20% | 🟠 高 | 可能有结构性重构，建议跑完整 Workflow A |
| Search-All 命中数变化 > 30% | 🔴 严重 | 架构级变更，需要全面重新探索 |
| webcrack 解析失败 | 🔴 严重 | 可能引入了新的语法特性 |

## 5. 实际案例

### 5.1 案例 1: 定位 PlanItemStreamParser

**任务**: 找到 Trae 的 SSE 流解析器 PlanItemStreamParser 的精确位置。

**背景**: PlanItemStreamParser 是 trae-unlock 最关键的代码位置之一——它是服务层 SSE 流解析器，不受 React 冻结影响（参见 [L1 冻结原则](../shared/discoveries.md)），所有实时响应型补丁都围绕它展开。

#### 方法对比: 原始 IndexOf vs 工具链

**❌ 纯手工 IndexOf 方式（早期探索阶段）**:

```powershell
# 第 1 步: 盲搜关键词
$c = [IO.File]::ReadAllText("D:\apps\...\index.js")
$idx = $c.IndexOf("PlanItemStreamParser")
# 结果: idx = 7502574

# 第 2 步: 手动取上下文（容易出错）
$ctx = $c.Substring($idx - 200, 400)
# 问题: 上下文是单行长字符串，极难阅读
# 问题: 不知道这是函数声明还是引用
# 问题: 不知道函数的范围

# 第 3 步: 猜测函数范围
# 只能靠经验估计，经常偏差数百行
```

**痛点总结**:
- 得到的是字节偏移，不是行号
- 上下文是压缩的单行，不可读
- 无法区分「定义处」和「引用处」
- 无法知道函数/类的完整范围
- 无法了解周围的代码结构

**✅ 工具链方式（当前最佳实践）**:

```powershell
# === Phase 1: L0 快速定位 (2s) ===
. .\scripts\search-templates.ps1
$result = Search-Generic -Keyword "PlanItemStreamParser" -Context 200
# 立即得到: offset=7502574, 带前后各 200 字符的可读上下文

# === Phase 2: L1 行号定位 (需先解包) ===
. .\scripts\unpack.ps1
if (-not (Test-Path "unpacked\beautified.js")) {
    Unpack-TraeIndex -Force
}
Select-String -Path "unpacked\beautified.js" -Pattern "PlanItemStreamParser" -Context 3,3
# 结果: Line 7502574, 带格式化的多行上下文

# === Phase 3: L3 结构确认 (30s) ===
. .\scripts\ast-search.ps1
$astResult = Search-AST -FilePath "unpacked\beautified.js" `
    -NodeType FunctionDeclaration `
    -NamePattern "PlanItemStreamParser"

# 完整结果:
# {
#   type: "FunctionDeclaration",
#   name: "PlanItemStreamParser",
#   start_line: 7502574,
#   end_line: 7508200,        ← 精确的函数范围！
#   start_col: 0,
#   context_preview: "function PlanItemStreamParser(e, t, n) {\n  ..."
# }

# === Phase 4: L2 模块归属 (可选) ===
.\module-search.ps1 -Keyword "PlanItemStreamParser" -ContextLines 2
# 结果: 属于 Module M2847, 该模块约 6000 行
```

**效率提升**:

| 维度 | 纯 IndexOf | 工具链 |
|------|-----------|--------|
| 定位时间 | 5-10 min（反复调整上下文大小） | 30s（一次性完成） |
| 可读性 | 压缩单行，几乎不可读 | 格式化多行 + 缩进 |
| 范围信息 | 无（纯猜测） | 精确的 start/end 行号 |
| 置信度 | 低（可能是引用而非定义） | 高（AST 确认是 FunctionDeclaration） |
| 后续操作 | 需要手动转换偏移→行号 | 直接获得行号，可用于补丁 |

### 5.2 案例 2: 盲区扫描实战

**场景**: 需要在 347,099 行代码中找出之前从未注意过的、可能与「命令执行确认」相关的未知代码。

#### Step 1: 全局模块扫描

```powershell
.\module-search.ps1 -Mode Overview
```

**输出解读重点**:

```
=== Webpack Module Overview ===
Total modules found: 2847

Size distribution:
  Tiny   (< 10 lines):    892
  Small  (10-49 lines):   1203
  Medium (50-199 lines):  567
  Large  (200-999 lines): 156
  Huge   (>= 1000 lines): 29

Top 20 largest modules:
  Module   Lines    Range           SizeKB
  -------  -------  --------------  --------
  M1847    12453    L180000-L192453  622.7 KB (est)
  M2156    8934    L210000-L218934  446.7 KB (est)
  M2847    6234    L750250-L756484  311.7 KB (est)  ← PlanItemStreamParser 所在!
  ...

--- Business Logic Candidates (>= 200 lines) ---
  M1847 [12453 lines L180000-L192453] (class, exports, HUGE)
  M2156 [8934 lines L210000-L218934] (class, exports, HUGE)
  M2847 [6234 lines L750250-L756484] (class, exports)
  M892  [2345 lines L89000-L91344] (class)           ← 新发现候选!
  M1456 [1890 lines L145000-L146889] (exports)       ← 新发现候选!
```

**行动**: M892 和 M1456 是之前未被记录的大模块，标记为待探索。

#### Step 2: 全量函数提取 + 关键词筛选

```powershell
. .\scripts\ast-search.ps1
Extract-AllFunctions -FilePath "unpacked\beautified.js" -OutputFile "functions-index.json"
# 输出: Extracted 38630 functions -> functions-index.json
```

然后在 JSON 中做多维度筛选：

```powershell
$funcs = Get-Content "functions-index.json" | ConvertFrom-Json

# 筛选 1: 名字含 confirm/runCommand/execute 的函数
$funcs | Where-Object {
    $_.name -match '(?i)(confirm|runCommand|execute|invoke)'
} | Format-Table name, type, async, start, end -AutoSize

# 筛选 2: 异步函数（可能涉及网络请求/AI 调用）
$funcs | Where-Object {
    $_.async -eq $true -and $_.start -gt 8000000
} | Format-Table name, type, params, start -AutoSize | Select-Object -First 30

# 筛选 3: 位于 M892 模块范围内的函数 (L89000-L91344)
$funcs | Where-Object {
    $_.start -ge 89000 -and $_.end -le 91344
} | Format-Table name, type, params, start, end -AutoSize
```

#### Step 3: 全量类提取 + 继承关系分析

```powershell
Extract-AllClasses -FilePath "unpacked\beautified.js" -OutputFile "classes-index.json"
# 输出: Extracted 1009 classes -> classes-index.json
```

```powershell
$classes = Get-Content "classes-index.json" | ConvertFrom-Json

# 找所有继承自 Component 的类（React 组件）
$reactComponents = $classes | Where-Object { $_.extends -eq 'Component' }
Write-Host "React Components: $($reactComponents.Count)"

# 找含有 confirm/error/handle 方法的类
$classes | Where-Object {
    ($_.methods | Where-Object { $_.key -match '(?i)(confirm|error|handle)' }).Count -gt 0
} | ForEach-Object {
    [PSCustomObject]@{
        Name = $_.Name
        Extends = $_.Extends
        Methods = ($_.methods | ForEach-Object { $_.key }) -join ', '
        Start = $_.Start
    }
} | Format-Table -AutoSize
```

**案例成果**: 通过这种盲区扫描，可能发现：
- 之前遗漏的错误处理类
- 新增的中间件层
- 未被文档覆盖的事件分发机制

## 6. 性能基准

以下数据基于当前环境实测（Windows, Node v24.9.0, SSD）。

### 6.1 各操作耗时

| 操作 | 输入规模 | 耗时 | 内存峰值 | 备注 |
|------|---------|------|---------|------|
| **Unpack-TraeIndex** (js-beautify) | 10MB → 21MB | **10-15s** | ~500MB | I/O 密集，CPU 占用中等 |
| **Test-ToolAvailability** | 4 个工具检测 | **< 1s** | ~20MB | 可忽略 |
| **Get-UnpackStats** | 21MB 文件 | **2-3s** | ~500MB | 需读全部行 |
| **Search-Generic** (单个关键词, L0) | 10MB 压缩文件 | **0.1-0.5s** | ~100MB | IndexOf 极快 |
| **Search-All** (12 模板, L0) | 10MB 压缩文件 | **3-5s** | ~100MB | 顺序执行 12 次 |
| **Search-UnpackedModules** (L1) | 21MB beautified | **5-15s** | ~600MB | 取决于匹配数 |
| **Get-ModuleOverview** (L2) | 21MB beautified | **30-60s** | ~800MB | 需扫描全部模块边界 |
| **Search-AST** (L3, 单类型) | 21MB beautified | **15-30s** | ~1.5GB | Babel 解析 + 遍历 |
| **Search-ASTFast** (L3, 单类型) | 21MB beautified | **10-20s** | ~1.2GB | 比 AST 快 30% |
| **Extract-AllFunctions** (L3) | 21MB beautified | **60-120s** | ~2GB | 全量遍历，最大操作 |
| **Extract-AllClasses** (L3) | 21MB beautified | **45-90s** | ~1.8GB | 全量遍历 |

### 6.2 内存注意事项

| 场景 | 建议 |
|------|------|
| **常规搜索 (L0/L1)** | 无特殊要求，默认 Node 内存足够 |
| **AST 操作 (L3)** | ast-search.ps1 已设置 `--max-old-space-size=4096`（4GB 上限） |
| **Extract-AllFunctions/Classes** | 确保空闲内存 ≥ 4GB；如遇 OOM，关闭其他应用后重试 |
| **同时运行多个 AST 查询** | 不建议并行——每个查询都需要独立解析整个文件（~1.5GB），并行会导致内存翻倍 |
| **32 位 Node.js** | **不支持** AST 操作——必须使用 64 位 Node.js |

### 6.3 优化技巧

1. **先用 Fast 再用 Full**: `Search-ASTFast` 筛选 → `Search-AST` 查看细节，减少 Full 调用次数
2. **缩小 MaxResults**: 默认 50 通常够用；设为 200+ 会显著增加 JSON 序列化时间
3. **缓存 AST 解析结果**: `Extract-AllFunctions/Classes` 的 JSON 输出可反复查询，避免重复解析
4. **NamePattern 尽量具体**: `.*` 会匹配所有节点；`PlanItem.*` 能减少 90%+ 的遍历
5. **L0 优先策略**: 对于已知关键词，永远先用 `Search-Generic`（毫秒级）确认存在性，再升级到 L3

## 7. 常见问题

### Q1: js-beautify 报错或输出为空？

**症状**: `Unpack-TraeIndex` 执行后输出文件为空或只有几行。

**原因排查**:

```powershell
# 1. 检查源文件是否存在且大小正常
$src = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$fi = Get-Item $src
Write-Host "Source size: $([math]::Round($fi.Length/1MB,2)) MB"
# 预期: 9-11 MB

# 2. 手动运行 js-beartify 看详细错误
js-beautify --indent-size 4 "$src" -o test-output.js 2>&1
# 注意 stderr 中的错误信息

# 3. 常见错误及解决
# "Unexpected token" → 源文件可能不是 JS（检查是否下载错误）
# "Out of memory" → 增加Node内存: node --max-old-space-size=4096
# 空输出 → 源文件编码问题，尝试: [IO.File]::ReadAllText($src)
```

### Q2: webcrack 可以替代 js-beautify 吗？

**不可以**，至少目前不行。

webcrack (v2.15.1) 虽然已安装在系统中，但它对 Trae 的 index.js 存在兼容性问题：

1. **TypeScript 装饰器**: Trae 大量使用 `@decorator` 语法，webcrack 的解析器对此支持不完善
2. **webpack 特殊格式**: 某些 webpack 生成的 IIFE 模式会导致 webcrack 进入死循环或产生错误输出
3. **输出不稳定**: 同一文件多次运行可能产生不同结果

**结论**: js-beautify 是唯一经过验证的美化工具。webcrack 仅作为备用参考。

### Q3: AST 解析报 PARSE_ERROR？

**症状**: `Search-AST` 或 `Extract-*` 函数输出 `PARSE_ERROR: ...`。

**常见原因和解决方案**:

```powershell
# 原因 1: errorRecovery 未启用（不应该发生，脚本已硬编码）
# 解决: 检查 ast-search.ps1 中的 parser 配置是否包含 errorRecovery: true

# 原因 2: @babel/parser 版本不兼容
# 解决: 检查 tools/node_modules/@babel/parser 是否存在
ls tools\node_modules\@babel\parser\lib\index.js

# 原因 3: 文件路径中有特殊字符
# 解决: 使用绝对路径，避免中文路径
$absPath = (Resolve-Path "unpacked\beautified.js").Path
Search-AST -FilePath $absPath -NodeType FunctionDeclaration

# 原因 4: Node.js 内存不足
# 解决: 检查 Invoke-ASTNode 中的 --max-old-space-size=4096
# 如仍不足，改为 8192（需要物理内存 ≥ 16GB）
```

**关于 errorRecovery 的重要说明**:

即使开启了 `errorRecovery: true`，如果错误过多（超过 Babel 的容错阈值），仍然可能抛出 PARSE_ERROR。这在 34 万行的文件中偶尔会发生。此时可以：

1. **忽略错误继续**: 部分函数/类仍会被成功提取（errorRecovery 会跳过错误区域）
2. **分段处理**: 将 beautified.js 按行范围切分，分别解析
3. **回退到 L1**: 使用 `Select-String` + 正则作为降级方案

### Q4: 347K 行的文件编辑器打不开怎么办？

**VS Code**: 可以打开，但会有性能警告。
- 安装 `Large File` 扩展优化大文件体验
- 使用 `Ctrl+G` 直接跳转到指定行号
- **不要尝试全文搜索**——用我们的工具链代替

**其他编辑器**: 大多数现代编辑器（Notepad++, Sublime Text）都能处理这个大小的文件。

**推荐做法**: 不要直接编辑 beautified.js。它的用途是**只读探索**。实际修改应通过 `definitions.json` + `apply-patches.ps1` 在压缩文件上进行。

### Q5: 如何搜索压缩文件中的多行模式？

IndexOf 只能搜索单行子串。对于需要跨行匹配的场景：

**方案 A**: 先解包再搜索（推荐）

```powershell
# 先解包
Unpack-TraeIndex -Force

# 用 Select-String 的正则模式（支持多行上下文）
Select-String -Path "unpacked\beautified.js" `
    -Pattern 'if\s*\(.*confirm.*\)\s*\{' `
    -Context 2,2
```

**方案 B**: 用 AST 替代正则（更精确）

```powershell
# 如果你要找 "if 语句中包含 confirm 调用" 这种结构
# 正则很难写，但 AST 可以精确表达
Search-AST -FilePath "unpacked\beautified.js" `
    -NodeType IfStatement
# 然后在结果中用 NamePattern 或 context_preview 过滤
```

**方案 C**: 搜两个相邻子串，验证距离

```powershell
$c = [IO.File]::ReadAllText($sourcePath)
$idx1 = $c.IndexOf("if(")
$idx2 = $c.IndexOf("confirm", $idx1)
if ($idx2 -gt $idx1 -and $idx2 - $idx1 -lt 500) {
    Write-Host "Found within 500 chars: offset=$idx1"
}
```

### Q6: module-search.ps1 报找不到 beautified.js？

**原因**: 脚本默认路径是 `unpacked/beautified.js`，而 `unpack.ps1` 的默认输出文件名是 `index.beautified.js`。

**解决**: 项目当前的实际情况是解包后的文件名为 `beautified.js`（位于 `unpacked/` 目录）。`module-search.ps1` 的 `$DefaultFilePath` 已经指向正确路径。如果仍有问题：

```powershell
# 检查实际文件名
ls unpacked\
# 如果是 index.beautified.js，创建软链接或复制
Copy-Item unpacked\index.beautified.js unpacked\beautified.js
# 或者修改 module-search.ps1 中的 $DefaultFilePath
```

### Q7: Extract-AllFunctions 输出的 anonymous 函数太多怎么办？

**现状**: 38,630 个函数中，大量是 `(anonymous)` —— 因为 webpack 打包后的回调、箭头函数大多没有名字。

**筛选策略**:

```powershell
$funcs = Get-Content "functions-index.json" | ConvertFrom-Json

# 只看有名字的函数
$named = $funcs | Where-Object { $_.name -ne '(anonymous)' }
Write-Host "Named functions: $($named.Count) / $($funcs.Count)"

# 有名字的函数通常更有价值
$named | Where-Object { $_.start -gt 7000000 } |  # 限制在感兴趣的区域
    Sort-Object start |
    Format-Table name, type, async, params, start, end -AutoSize
```

**匿名函数的价值**: 即使没有名字，匿名函数的位置信息也有价值——它可以帮助你理解某个命名函数的「邻居」是谁，从而推断代码上下文。

### Q8: Trae 更新后工具链需要更新吗？

**通常不需要更新工具链本身**，但需要：

1. **重新解包**: `Unpack-TraeIndex -Force`
2. **重新提取索引**: `Extract-AllFunctions` + `Extract-AllClasses`（如果之前生成过）
3. **重新验证补丁**: 运行 `apply-patches.ps1` + `verify.ps1`
4. **更新 discoveries.md**: 记录新的偏移量和任何结构性变化

**工具链自身需要更新的信号**:
- Babel parser 无法解析新的语法特性（极少见）
- js-beautify 对新的压缩模式失效（罕见）
- Node.js 版本不兼容（仅当 Trae 升级其内置 Node 时）

---

## 附录 A: 工具速查卡

```
┌─────────────────────────────────────────────────────────────┐
│                  EXPLORATION TOOLKIT QUICK REF               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  L0: RAW BYTES (compressed index.js, ~10MB)                │
│  ├── Search-Generic -Keyword "text" [-Context 150]          │
│  ├── Search-DIToken / Search-Subscribe / ... (12 templates) │
│  └── Search-All (full scan, all templates)                  │
│                                                             │
│  L1: BEAUTIFIED TEXT (beautified.js, ~21MB, 347K lines)    │
│  ├── Select-String -Path beautified.js -Pattern "..."       │
│  └── module-search.ps1 -Keyword "..." [-Regex]              │
│                                                             │
│  L2: MODULE-AWARE (Webpack module boundaries)               │
│  ├── module-search.ps1 -Mode Overview                       │
│  └── module-search.ps1 -Mode Find -Keyword "..."            │
│                                                             │
│  L3: AST SEMANTIC (@babel/parser + traverse)                │
│  ├── Search-AST -FilePath f -NodeType T [-NamePattern P]    │
│  ├── Search-ASTFast (lightweight, no context)               │
│  ├── Extract-AllFunctions -FilePath f [-OutputFile out]     │
│  └── Extract-AllClasses -FilePath f [-OutputFile out]       │
│                                                             │
│  UTILITIES                                                  │
│  ├── Test-ToolAvailability (check tool chain)               │
│  ├── Unpack-TraeIndex [-Force] (decompress)                 │
│  └── Get-UnpackStats (file statistics)                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 附录 B: 文件路径速查

| 路径 | 说明 |
|------|------|
| `D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js` | **目标文件**（压缩源码，~10MB） |
| `d:\Test\trae-unlock\unpacked\beautified.js` | **解包产物**（美化后，~21MB, 347K行） |
| `d:\Test\trae-unlock\scripts\unpack.ps1` | 解包脚本 |
| `d:\Test\trae-unlock\scripts\ast-search.ps1` | AST 分析脚本 |
| `d:\Test\trae-unlock\scripts\module-search.ps1` | 模块搜索脚本 |
| `d:\Test\trae-unlock\scripts\search-templates.ps1` | L0 搜索模板 |
| `d:\Test\trae-unlock\tools\node_modules\@babel\parser` | Babel Parser（AST 引擎） |
| `d:\Test\trae-unlock\shared\discoveries.md` | 发现记录（探索成果存档） |
| `d:\Test\trae-unlock\patches\definitions.json` | 补丁定义（14 个补丁） |
