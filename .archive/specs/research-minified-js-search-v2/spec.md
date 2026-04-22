# 压缩 JS 搜索方案研究 Spec

## Why

目标文件是 ~10.73MB 的单行压缩 JS，所有现有搜索工具（Grep、Read、SearchCodebase）都无法有效工作。每次搜索都需要手写 PowerShell 脚本，效率极低。需要找到现有工具或方法来解决这个问题，避免重复造轮子。

## 调研结果

### 🔥 方案 E（新发现）: ast-grep — 最佳方案！

**[ast-grep](https://github.com/ast-grep/ast-grep)** 是一个基于 AST 的代码结构搜索/替换工具，用 Rust 编写，支持 JavaScript。

**核心优势**：
- **直接搜索压缩文件**：不需要预处理，ast-grep 用 tree-sitter 解析 AST，单行文件也能搜索
- **结构化搜索**：不是文本匹配，而是语法匹配，比 grep 更精确
- **支持通配符**：`$VAR` 匹配任意 AST 节点，`$$$ARGS` 匹配零或多个节点
- **JSON 输出**：`--json` 输出包含 byteOffset（原始偏移！），完美对接我们的补丁系统
- **Windows 支持**：`scoop install ast-grep` 或 `npm install -g @ast-grep/cli`

**示例用法**：
```bash
# 搜索所有 if 语句
ast-grep -p 'if ($COND) { $$$ }' --lang js target.js

# 搜索特定函数调用
ast-grep -p 'D.resumeChat($$$)' --lang js target.js

# JSON 输出（含 byteOffset）
ast-grep -p 'setTimeout(()=>{$CB()},50)' --lang js --json target.js

# 搜索变量赋值
ast-grep -p 'J = $VALUE' --lang js target.js
```

**JSON 输出格式**（关键！）：
```json
[{
  "text": "J=!![kg.MODEL_OUTPUT_TOO_LONG,...].includes(_)",
  "range": {
    "byteOffset": { "start": 8701180, "end": 8701280 }
  },
  "file": "index.js"
}]
```

**局限**：
- 压缩代码的 AST 解析可能比正常代码慢（10MB 文件）
- 模式必须是合法的 JS 语法（不能用纯文本搜索中文）
- 对于搜索中文 NLS 字符串，仍需文本搜索

### 方案 F: js-beautify + 格式化副本

**[js-beautify](https://www.npmjs.com/package/js-beautify)** 可以将压缩 JS 格式化为可读版本。

**用法**：
```bash
npm install -g js-beautify
js-beautify -f index.js -o index.formatted.js --indent-size 2
```

**优势**：
- 格式化后 Grep/Read 直接可用
- 可读性极强，方便人工阅读理解

**局限**：
- **不保留偏移映射**：格式化后行号和列号与原始文件不同
- 需要额外维护映射表
- 格式化 10MB 文件可能很慢

### 方案 G: ripgrep --max-columns + -o 组合

ripgrep 本身有处理长行的选项：

```bash
# 截断长行显示
rg --max-columns 200 --max-columns-preview "manuallyStop" index.js

# 只显示匹配部分+上下文
rg -o '.{0,30}manuallyStop.{0,30}' index.js
```

**优势**：
- 无需安装额外工具
- ripgrep 已内置

**局限**：
- 偏移信息缺失
- 中文搜索可能有问题
- 仍然不如 ast-grep 精确

### 方案 H: Grasp.js — AST 搜索老牌工具

**[grasp](https://www.graspjs.com/)** 是最早的 JS AST 搜索工具，但：
- 最后更新 2016 年，已停止维护
- 不支持现代 JS 语法
- **不推荐使用**

### 方案 I: Source Map 逆向

如果有 .map 文件，可以用 `reverse-sourcemap` 或 `shuji` 还原原始代码。
但我们的目标文件**没有 .map 文件**，所以此方案不适用。

### 方案 J: CodeQue VS Code 扩展

**[CodeQue](https://marketplace.visualstudio.com/items?itemName=CodeQue.codeque)** 是 VS Code 扩展，支持结构化代码搜索。
但**不支持 100KB 以上文件**，我们的 10.73MB 文件远超限制。

## 推荐方案

**组合方案：ast-grep + PowerShell 文本搜索**

| 搜索类型 | 工具 | 原因 |
|---------|------|------|
| JS 语法结构搜索 | ast-grep | AST 级别精确匹配，含 byteOffset |
| 中文/纯文本搜索 | PowerShell 脚本 | ast-grep 不支持非语法搜索 |
| 代码阅读理解 | js-beautify 格式化副本 | 可读性最强 |

## What Changes

- **安装 ast-grep**：`scoop install ast-grep` 或 `npm install -g @ast-grep/cli`
- **创建 `scripts/tools/search-target.ps1`**：统一搜索接口，整合 ast-grep + PowerShell
- **可选：生成格式化副本**：`js-beautify` 生成可读版本供人工阅读

## ADDED Requirements

### Requirement: ast-grep 集成

系统 SHALL 支持 ast-grep 进行 JS 结构搜索，输出包含 byteOffset 的 JSON 结果。

#### Scenario: 用 ast-grep 搜索特定代码模式
- **WHEN** 运行 `ast-grep -p 'D.resumeChat($$$)' --lang js --json target.js`
- **THEN** 输出包含匹配文本、byteOffset 起止位置、文件名

### Requirement: 统一搜索接口

`scripts/tools/search-target.ps1` SHALL 提供统一搜索接口：
- `-Pattern "text"` — 纯文本搜索（PowerShell）
- `-AstPattern "D.resumeChat($$$)"` — AST 搜索（ast-grep）
- `-Context 200` — 上下文长度
- `-AllMatches` — 所有匹配

## REMOVED Requirements

无。
