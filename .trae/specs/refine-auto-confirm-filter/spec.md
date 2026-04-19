# 文档重构: 扫描报告独立化 Spec

## Why

progress.txt 应只记录简短进展，但当前包含了大量扫描结果表格（30 个 Alert、7 个错误码、5 个 BlockLevel），导致文件膨胀且难以快速浏览。

## What Changes

- **新建** `docs/reports/scan-report-2026-04-19.md` — 存放完整扫描报告
- **精简** `progress.txt` — 删除详细表格，保留一行摘要 + 链接

## Impact

- Affected files: progress.txt (精简), 新建 scan-report-2026-04-19.md
