# 补丁崩溃根因调查与系统性防护 Spec

## Why

用户报告：**重启 Trae 后 AI 聊天界面直接消失，且历史上多次出现此现象**。

这不是偶发事件——从 `fix-patch-crash-restore` spec 可知，之前已经因 `this` 绑定问题和控制流改变导致过一次完整崩溃。现在的崩溃可能由新的或遗留的原因导致。

**已发现的确定性风险**：
1. **definitions.json 版本不一致**：auto-continue-thinking 的 `replace_with` 是干净 v6（无 console.log），但 `check_fingerprint` 检测的是 v6-debug（有 console.log）。上次会话 #21 用 SearchReplace 直接把 debug 版写入目标文件但没更新 definitions.json。
2. **Trae 更新后补丁部分失效**：目标文件被 Trae 更新覆盖后，部分补丁字符串可能不再匹配，导致半应用状态（部分旧补丁残留 + 部分新代码），极易产生语法错误。
3. **缺少应用前语法验证**：apply-patches 在写入修改后的内容前不检查 JavaScript 语法正确性，一个括号错误就能让整个 10MB 文件变成不可解析的废料。

## What Changes

- **诊断当前目标文件状态**：确认哪些补丁实际存在、哪些残留、哪些缺失
- **修复 definitions.json 不一致**：统一 auto-continue-thinking 的 replace_with 和 fingerprint
- **建立应用前语法安全网**：apply-patches 写入文件前先用 Node.js 验证语法
- **建立崩溃自动检测机制**：auto-heal 或启动脚本能检测到"聊天界面消失"并自动回滚
- **清理历史遗留的半应用补丁残留**

## Impact

- Affected code: patches/definitions.json, scripts/apply-patches.ps1, scripts/auto-heal.ps1, 目标文件 index.js
- Affected specs: verify-pause-button-hypothesis（依赖 v6-debug 的调试功能）
- Affected agents: 所有未来会话（崩溃恢复是基础生存需求）

## ADDED Requirements

### Requirement: definitions.json 版本一致性强制

`replace_with` 和 `check_fingerprint` 必须描述**同一版本**的代码。如果 check_fingerprint 包含的子串不在 replace_with 中，系统 SHALL 报错。

#### Scenario: fingerprint 检测到 replace_with 中不存在的代码
- **WHEN** check_fingerprint 的值不是 replace_with 的子串
- **THEN** apply-patches.ps1 启动时输出警告
- **AND** 不阻止执行（向后兼容），但明确提示风险

### Requirement: 补丁应用前语法验证

apply-patches.ps1 在将修改后的内容写入目标文件之前，SHALL 先验证 JavaScript 语法正确性。

#### Scenario: 写入前语法检查
- **WHEN** 所有补丁替换完成、准备 WriteAllText 之前
- **THEN** 将内容写入临时文件 → 用 `node --check` 验证语法
- **AND** 如果语法错误 → 回滚到原始内容 → 报告具体错误位置 → exit 1（不写入破坏性内容）

### Requirement: 崩溃自动回滚机制

当检测到目标文件可能导致崩溃时，系统 SHALL 能自动回滚到最后一个已知的良好备份。

#### Scenario: 语法验证失败或指纹全失败
- **WHEN** apply-patches 检测到语法错误或所有补丁指纹不匹配且无法修复
- **THEN** 自动从 backups/ 目录恢复最新的 clean-*.ext 备份
- **AND** 输出清晰的回滚信息

### Requirement: 目标文件健康诊断

提供一种快速诊断当前目标文件状态的能力。

#### Scenario: 用户报告"聊天界面消失了"
- **WHEN** 运行诊断命令
- **THEN** 报告：
  1. 每个 enabled 补丁的 fingerprint 是否匹配
  2. 文件整体 JavaScript 语法是否合法（node --check）
  3. 是否有明显的半应用残留（find_original 存在但 fingerprint 不存在）
  4. 文件大小是否正常（~10.73MB 范围内）
  5. 备份目录中有多少个可用备份

## MODIFIED Requirements

### Requirement: auto-continue-thinking 补丁定义

需要决定：保留 v6-debug（带 console.log）还是回到干净 v6。

**建议**：既然我们还没收集到 debug 日志（Task 3 待用户测试），暂时回到**干净 v6**（去掉 console.log），同时保持 fingerprint 与 replace_with 一致。等真正需要调试时再加回 console.log。

### Requirement: apply-patches.ps1 主流程

在现有流程中插入语法验证步骤：

```
现有: 替换循环 → WriteAllText → Summary → Auto-backup
新增: 替换循环 → [语法验证] → WriteAllText → Summary → Auto-backup → Auto-commit
```

### Requirement: auto-heal.ps1 主流程

同样插入语法验证步骤，在 Step 3 写入前验证。
