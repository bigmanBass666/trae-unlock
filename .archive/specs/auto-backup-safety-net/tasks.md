# Tasks

- [x] Task 1: 修改 apply-patches.ps1，添加自动备份功能
  - [x] 1.1 在所有补丁应用成功后（指纹全通过），自动复制目标文件到 `backups/clean-YYYYMMDD-HHmmss.ext`
  - [x] 1.2 备份文件名包含时间戳
  - [x] 1.3 同时保留最近 N 个备份（如 5 个），自动清理旧备份

- [x] Task 2: 修改 auto-heal.ps1，添加自动备份功能
  - [x] 2.1 在 auto-fix 成功后同样触发备份
  - [x] 2.2 确保与 apply-patches 的备份逻辑一致

- [x] Task 3: 在 _registry.md 中添加安全检查项
  - [x] 3.1 会话结束检查清单增加第 4 项："安全检查：备份是否新鲜？是否需要 git commit？"
  - [x] 3.2 添加 git commit 格式约定（用于多 AI 场景下的 commit message 规范）

- [x] Task 4: 在 status.md 中添加安全状态区域
  - [x] 4.1 添加"最后备份时间"字段
  - [x] 4.2 添加"最后提交时间"字段
  - [x] 4.3 任一值超过阈值时显示警告

- [x] Task 5: 更新 rule-002 和 rules.md
  - [x] 5.1 rule-002 操作步骤增加安全检查环节
  - [x] 5.2 重新生成 shared/rules.md

- [x] Task 6: 创建初始备份和提交
  - [x] 6.1 运行一次完整备份（当前状态）→ clean-20260422-093605.js (10.7MB)
  - [x] 6.2 执行 git add + git commit → a0142c1 (59 files changed)

- [x] Task 7: 🆕 多AI场景增强 — apply-patches/auto-heal 成功后自动 git commit
  - [x] 7.1 在 apply-patches.ps1 的成功路径末尾添加 `git add -A` + `git commit`
  - [x] 7.2 在 auto-heal.ps1 的成功路径末尾添加同样的自动提交逻辑
  - [x] 7.3 commit message 格式：`chore: auto-snapshot [时间戳] — N patches OK`
  - [x] 7.4 如果没有变更则静默跳过（不报错）

- [x] Task 8: 🆕 创建 scripts/snapshot.ps1 一键快照脚本
  - [x] 8.1 备份目标文件到 backups/（与 apply-patches 同样的逻辑）
  - [x] 8.2 执行 git add -A + git commit
  - [x] 8.3 输出备份文件名、commit hash、变更文件列表
  - [x] 8.4 支持 `-Message` 参数自定义 commit message

# Task Dependencies
- [Task 1] 和 [Task 2] ✅ 已完成
- [Task 3] ✅ 已完成
- [Task 4] ✅ 已完成
- [Task 5] ✅ 已完成
- [Task 6] ✅ 已完成（依赖 Task 1/2 ✅）
- [Task 7] ✅ 已完成
- [Task 8] ✅ 已完成
- **全部 8 个任务已完成 ✅**
