# Tasks

- [x] Task 1: 创建 `scripts/auto-heal.ps1` 核心脚本
  - [x] Step 1: 验证阶段 — 读取 definitions.json，对每个 enabled 补丁检查 fingerprint
  - [x] Step 2: 诊断阶段 — 对失败补丁：检查 find_original 是否存在、模糊搜索前 30 字符
  - [x] Step 3: 修复阶段 — 对可自动修复的补丁重新 apply + 更新 definitions.json offset_hint
  - [x] Step 4: 再验证 — 重新检查所有 fingerprint，确认修复成功
  - [x] 支持 `-DiagnoseOnly` 参数：只执行 Step 1+2，不修改文件
  - [x] 支持 `-SkipDefUpdate` 参数：修复后不更新 definitions.json
  - [x] 正确的 exit code：0=全部通过，1=有失败项

- [x] Task 2: 修改 `scripts/verify.ps1` 添加 JSON 摘要输出
  - [x] 在末尾添加一行 JSON：`{"active":N,"inactive":N,"unknown":N,"failed_ids":[...]}`
  - [x] 保持原有输出格式不变（向后兼容）

- [x] Task 3: 修改 `AGENTS.md` 添加 AI 会话自检规则
  - [x] 添加规则：AI 每次新会话开始时先运行 `auto-heal.ps1 -DiagnoseOnly`
  - [x] 如果有失败项，立即执行修复流程

- [x] Task 4: 测试验证
  - [x] 运行 `auto-heal.ps1` 确认当前 7/7 补丁全部通过
  - [x] 运行 `auto-heal.ps1 -DiagnoseOnly` 确认只读模式正常
  - [x] 运行 `verify.ps1` 确认 JSON 摘要输出正常

# Task Dependencies
- Task 2 depends on Task 1 (auto-heal 可能消费 verify 的 JSON 输出)
- Task 4 depends on Task 1, Task 2, Task 3
