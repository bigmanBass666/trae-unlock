# Checklist (v2: 黑名单模式)

- [ ] Task 3: 修改 3 个补丁为黑名单模式
  - [ ] service-layer-runcommand-confirm: fingerprint 含 `!==`response_to_user"` ✅
  - [ ] service-layer-confirm-status-update: fingerprint 含 `!==`response_to_user"` ✅
  - [ ] auto-confirm-commands: fingerprint 含 `!==`response_to_user"` ✅

- [ ] Task 4: 应用并验证
  - [ ] apply-patches.ps1 成功
  - [ ] 文件中验证黑名单模式生效

- [ ] Task 5: 主动性全面扫描
  - [ ] Alert/弹窗扫描完成，列出所有发现
  - [ ] block_level 扫描完成
  - [ ] auto_confirm 扫描完成
  - [ ] 错误码扫描完成
  - [ ] 汇总报告写入 progress.txt / source-architecture.md
  - [ ] Git commit & push
