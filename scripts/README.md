# scripts/ — 脚本目录

> **清理后保留 12 个核心文件**（2026-04-25 更新）
>
> 其余 85 个一次性探索/调试/旧版脚本已加入 `.gitignore`。

## 核心生产脚本（12 个）

### 补丁操作

| 脚本 | 用途 |
|------|------|
| `apply-patches.ps1` | 补丁主入口，应用/验证所有补丁 |
| `rollback.ps1` | 回滚到最近备份 |
| `snapshot.ps1` | 创建备份 + git commit |

### 诊断与修复

| 脚本 | 用途 |
|------|------|
| `auto-heal.ps1` | 自动诊断 + 修复（启动必做 Step 2） |
| `diagnose-patch-health.ps1` | 深度补丁健康检查 |
| `verify.ps1` | 补丁验证 |
| `verify-v13.ps1` | v13 版本专用验证 |

### 探索工具链（新增 2026-04-25）

| 脚本 | 用途 |
|------|------|
| `unpack.ps1` | 解包 Trae index.js → beautified.js（347K 行） |
| `ast-search.ps1` | AST 结构化搜索 + 批量提取（38K 函数 / 1K 类） |
| `module-search.ps1` | webpack 模块级搜索 + 概览统计 |
| `search-templates.ps1` | 原始 PowerShell 搜索模板库（L0 快速定位） |

## 使用方式

```powershell
# 启动时加载
. "scripts/unpack.ps1"
. "scripts/ast-search.ps1"
. "scripts/module-search.ps1"

# 常用操作
Test-ToolAvailability          # 检查工具可用性
Unpack-TraeIndex -Force        # 解包（Trae 更新后）
Search-UnpackedModules -Keyword "Parser"   # 模块搜索
Search-AST -NodeType "ClassDeclaration"     # AST 搜索
Get-ModuleOverview             # 全模块概览
```

## 已忽略的文件类别

以下文件已被 `.gitignore` 忽略（可从 git 历史恢复）：

- `explore-*.txt / explore-*.ps1` — 探索输出和脚本（~82 MB）
- `apply-v*.js / create-correct-v*.js` — 历史版本注入器
- `check-v*.* / inject-v*-fix.ps1` — 旧版诊断脚本
- `analyze-*.ps1 / find-* / search-*.ps1` — 一次性分析/查找
- `test-*.js / debug-*.js / fix-*.js` — 调试/测试
- `v5-*.ps1 / v*-inject.ps1` 等 — v5 旧版脚本
