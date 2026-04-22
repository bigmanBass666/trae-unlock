# 自动备份与安全网 Spec — "差点丢失一切"事件响应 (v2: 多AI增强)

## Why

用户重启 Trae 后发现所有补丁失效（正常），尝试恢复时发现：
1. **backups/ 目录为空** — 无备份可回滚
2. **最近 git commit 在 2 天前** — 所有今天的工作（v6 修复、暂停按钮调查、调试日志、多个 spec）全部未提交
3. **最终靠 Trae 手动更新才恢复原文件** — 纯运气，不可控

**核心问题：整个项目没有任何自动化的"安全网"。** 补丁修改的是编译后的 JS 文件（不在 git 中），backup 不存在或不新鲜，git commit 依赖人工记忆。用户同时跟多个 AI 聊天，每个会话都可能修改文件但无人负责提交。

**v2 增强**: 用户强调多 AI 场景——清单式的"你应该commit"在多 Agent 环境下会遭遇**旁观者效应**，每个 AI 都假设其他会话会提交。解决方案必须从"文档提醒"升级为"脚本强制执行"。

这次是"警钟"——下次可能就没这么幸运了。

## What Changes

- 建立**四层安全网**：自动备份 → 自动提交 → 一键快照 → 跨会话感知
- 每次 apply-patches 成功后自动创建带时间戳的干净备份 ✅ (Tasks 1-2 已完成)
- 每次 apply-patches/auto-heal 成功后**自动 git add + commit** 🆕 (Task 7)
- 创建 `scripts/snapshot.ps1` 一键快照脚本（backup + commit）🆕 (Task 8)
- shared/status.md 中增加"最后备份时间"和"最后提交时间"字段 ✅ (Task 4 已完成)
- 会话结束检查清单中增加"是否需要提交"步骤 ✅ (Task 3 已完成)
- rule-002 操作步骤增加安全检查环节 ⏳ (Task 5 待完成)
- 执行初始备份 + git commit 救命操作 ⏳ (Task 6 待完成)

## Impact

- Affected code: scripts/apply-patches.ps1, scripts/auto-heal.ps1, rules/core.yaml (rule-002), scripts/snapshot.ps1 (新建)
- Affected files: shared/_registry.md, shared/status.md
- Affected agents: 所有未来会话（多 AI 场景下尤其重要）

## ADDED Requirements

### Requirement: 补丁应用后必须自动备份

系统 SHALL 在每次 apply-patches 成功后自动创建目标文件的带时间戳干净备份。

#### Scenario: 补丁应用成功后

- **WHEN** auto-heal.ps1 或手动 apply-patches 执行完毕且所有指纹通过
- **THEN** 系统 SHALL 自动复制目标文件到 `backups/clean-YYYYMMDD-HHmmss.ext`
- **AND** 备份文件名包含时间戳以便识别最新版本

### Requirement: 补丁应用后必须自动提交 (🆕 v2 核心)

系统 SHALL 在每次 apply-patches 或 auto-heal 成功后**自动执行 git add + git commit**。

**理由**: 多 AI 场景下的旁观者效应——每个 AI 都读了"应该提交"的规则，但每个都假设别的会话会做。只有嵌入脚本的自动化才能保证执行。

#### Scenario: 补丁全通过或自愈成功后

- **WHEN** apply-patches.ps1 执行完毕且 failedCount=0
- **OR** WHEN auto-heal.ps1 自愈成功且 allPass=true
- **THEN** 系统 SHALL 自动执行:
  ```
  git add -A
  git commit -m "chore: auto-snapshot [YYYY-MM-DD HH:mm] — N patches OK"
  ```
- **AND** 如果没有变更则跳过（nothing to commit）
- **AND** commit message 包含时间戳和补丁状态摘要

### Requirement: 一键快照脚本 (🆕)

系统 SHALL 提供 `scripts/snapshot.ps1` 脚本，允许在任何时候手动触发完整快照。

#### Scenario: 用户手动触发快照

- **WHEN** 用户运行 `powershell scripts/snapshot.ps1`
- **THEN** 脚本 SHALL:
  1. 备份目标文件到 backups/
  2. 执行 git add -A
  3. 执行 git commit（含时间戳和变更摘要）
  4. 报告备份文件名和 commit hash

### Requirement: 安全状态可视化

系统 SHALL 在 status.md 中显示备份和提交的时间戳，让任何会话都能快速判断"当前状态有多危险"。

#### Scenario: 查看 project safety status

- **WHEN** 读取 status.md
- **THEN** 能看到 `最后备份时间` 和 `最后提交时间`
- **AND** 如果任一值超过阈值（如 1 小时），显示警告

## MODIFIED Requirements

### Requirement: rule-002 操作后写入 Anchor 共享模块

扩展 rule-002 的第 5 条操作步骤，在写会话日志之前增加安全检查：

```
5. 会话结束前 → 执行检查清单：
   ① 有发现？→ discoveries.md
   ② 有决策？→ decisions.md
   ③ 安全检查：备份是否新鲜？是否需要 git commit？
   ④ 写会话日志（含 P2 写入字段）→ status.md
```

### Requirement: _registry.md 会话结束检查清单

在现有检查清单后追加第 4 项安全检查。
