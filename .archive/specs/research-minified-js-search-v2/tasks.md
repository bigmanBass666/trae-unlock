# Tasks

- [x] Task 1: 深度调研 — 搜索现有工具和方案
  - [x] 搜索 minified JS search/analysis tools → 发现 ast-grep
  - [x] 搜索 source map 生成方案 → reverse-sourcemap, shuji（需 .map 文件，不适用）
  - [x] 搜索代码索引工具（ctags, AST parsers）→ ast-grep (tree-sitter), semgrep, CodeQue
  - [x] 搜索 VS Code 扩展 → CodeQue（不支持 100KB+文件）
  - [x] 搜索 Node.js 生态 → js-beautify, grasp（已停维）
  - [x] 搜索 ripgrep 长行处理 → --max-columns + -o 组合
  - [x] 汇总调研结果，评估每个方案的适用性

- [x] Task 2: 安装 ast-grep 并验证
  - [x] 安装 ast-grep（npm install -g @ast-grep/cli）→ v0.42.1
  - [x] 用 ast-grep 搜索目标文件中的已知代码模式（D.resumeChat → 1 match, offset 8953710）
  - [x] 验证 JSON 输出包含 byteOffset ✅
  - [x] 测试中文文本搜索的替代方案 → 用 -Pattern 参数（PowerShell 文本搜索）

- [x] Task 3: 创建统一搜索脚本
  - [x] 创建 `scripts/tools/search-target.ps1`
  - [x] 支持 `-Pattern` 纯文本搜索（PowerShell）
  - [x] 支持 `-AstPattern` AST 搜索（ast-grep）
  - [x] 支持 `-Context`、`-AllMatches`、`-MaxMatches` 参数
  - [x] 测试验证：文本搜索和 AST 搜索均正常

- [ ] Task 4: 可选 — 生成格式化副本（跳过，ast-grep 已满足核心需求）

# Task Dependencies
- Task 2 depends on Task 1
- Task 3 depends on Task 2
- Task 4 depends on Task 2 (可选，已跳过)
