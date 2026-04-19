# Tasks (v2: 黑名单模式)

- [x] Task 1: 确认 toolName 值 ✅ (已完成)
- [x] Task 2: 设计过滤函数 ✅ (已完成，现改为黑名单模式)
- [ ] Task 3: 修改 3 个补丁为黑名单模式
  - [ ] SubTask 3.1: service-layer-runcommand-confirm: `==="run_command"` → `!=="response_to_user"`
  - [ ] SubTask 3.2: service-layer-confirm-status-update: 同步修改
  - [ ] SubTask 3.3: auto-confirm-commands: `===` → `!==`
- [ ] Task 4: 应用补丁并验证
- [ ] Task 5: 主动性全面扫描 — 系统性找出所有限制点
  - [ ] SubTask 5.1: 扫描所有 Alert/弹窗渲染逻辑
  - [ ] SubTask 5.2: 扫描所有 block_level 分支
  - [ ] SubTask 5.3: 扫描所有 auto_confirm === false 场景
  - [ ] SubTask 5.4: 扫描所有错误码处理路径
  - [ ] SubTask 5.5: 汇总发现，批量设计补丁
