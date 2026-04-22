# Scripts 目录结构

## 根目录（正式脚本）

| 脚本 | 用途 |
|------|------|
| apply-patches.ps1 | 主补丁应用脚本 |
| rollback.ps1 | 回滚到备份 |
| rules-engine.ps1 | 规则引擎 |
| verify.ps1 | 补丁验证脚本 |

## tools/ — 搜索和分析工具

搜索、分析、验证工具脚本，用于代码查找和补丁状态检查。

| 脚本 | 用途 |
|------|------|
| find-*.ps1 | 查找特定代码模式 |
| search-*.ps1 | 搜索文件内容和上下文 |
| quick-check.ps1 | 快速检查所有补丁状态 |
| verify-efh.ps1 | 验证 efh 错误恢复列表 |
| check-calls.ps1 | 检查函数调用次数 |

## archive/ — 临时和已废弃脚本

历史修复、测试、旧版脚本，保留供参考但不再使用。

| 脚本 | 用途 |
|------|------|
| apply-all-patches-v3.ps1 | 旧版批量补丁脚本 |
| apply-loop-detection-bypass.ps1 | 循环检测绕过（旧版） |
| apply-remaining-patches.ps1 | 剩余补丁应用（旧版） |
| apply-ui-patch.ps1 | UI 层补丁（已废弃） |
| fix-*.ps1 | 各种临时修复脚本 |
| revert-and-fix.ps1 | 回滚+修复脚本（旧版） |
