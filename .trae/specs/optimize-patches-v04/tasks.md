# Tasks

- [ ] Task 1: 标记稳定版 v0.4
  - [ ] SubTask 1.1: git tag v0.4
  - [ ] SubTask 1.2: git push --tags

- [ ] Task 2: 更新补丁定义
  - [ ] SubTask 2.1: 重新启用 `bypass-runcommandcard-redlist`
  - [ ] SubTask 2.2: 禁用 `bypass-whitelist-sandbox-blocks`
  - [ ] SubTask 2.3: `auto-continue-thinking` 改用箭头函数

- [ ] Task 3: 应用补丁并验证
  - [ ] SubTask 3.1: 先回滚目标文件到干净状态（当前已应用的 bypass-whitelist-sandbox-blocks 需要撤销）
  - [ ] SubTask 3.2: 运行 apply-patches.ps1
  - [ ] SubTask 3.3: 验证所有补丁指纹

- [ ] Task 4: 提交并标记新版本
  - [ ] SubTask 4.1: git commit + push
  - [ ] SubTask 4.2: git tag v0.5-pre (新补丁版本)

# Task Dependencies
- [Task 2] depends on [Task 1] (先标记稳定版)
- [Task 3] depends on [Task 2] (补丁定义更新后才能应用)
- [Task 4] depends on [Task 3] (验证通过后再提交)
