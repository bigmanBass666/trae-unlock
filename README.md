# Trae Mod - Trae IDE 定制框架

> 让 Trae IDE 更强大：自动化确认、突破限制、无限可能

[![Trae Version](https://img.shields.io/badge/Trae-v3.3.x-blue)](https://www.trae.com)
[![License](https://img.shields.io/badge/license-MIT-green)]()

## 项目简介

**Trae Mod** 是一个 Trae IDE 定制框架，专注于通过源码修改解锁 Trae IDE 的更多能力。

本项目不是插件，而是对 Trae 源码的直接定制修改。通过补丁系统，可以安全、可逆地应用各种增强功能。

### 我们的理念

- 🔧 **深度定制** — 直接修改源码，解锁原生功能
- 🛡️ **安全可控** — 补丁系统支持回滚，随时可恢复
- 📦 **模块化** — 每个功能独立，可按需启用
- 🚀 **持续拓展** — 更多定制功能陆续推出

---

## 首批成果

### 成果 1: 命令自动确认

危险命令（删除/复制/移动文件）无需手动确认，AI 可自主执行。

**效果**: Copy/Remove/Move/Rename/Git 等命令零弹窗自动执行

📖 [详细文档](docs/achievements/auto-command-confirm.md)

---

### 成果 2: 突破思考上限

模型思考次数超限时自动续接，无需手动点击"继续"。

**效果**: 超长任务无缝续接，用户无感知

⚠️ **状态**: 补丁已应用，**尚未实际测试**

📖 [详细文档](docs/achievements/auto-continue-thinking.md)

---

## 快速开始

### 前置要求

- Trae IDE v3.3.x
- Windows 系统
- 解包状态的 Trae（未使用 app.asar 打包）

### 应用补丁

```powershell
# 查看当前状态
.\scripts\verify.ps1

# 应用所有补丁
.\scripts\apply-patches.ps1

# 只预览不修改
.\scripts\apply-patches.ps1 -DryRun

# 应用指定补丁
.\scripts\apply-patches.ps1 -PatchIds "auto-command-confirm"
```

### 回滚

```powershell
# 列出所有备份
.\scripts\rollback.ps1 --list

# 回滚到最新备份
.\scripts\rollback.ps1 --latest

# 回滚到指定日期
.\scripts\rollback.ps1 --date 20260418
```

---

## 目录结构

```
trae-unlock/
├── docs/
│   ├── achievements/              # 定制成果
│   │   ├── auto-command-confirm.md
│   │   └── auto-continue-thinking.md
│   ├── architecture/             # 架构文档
│   │   └── source-architecture.md
│   └── guides/                    # 使用指南
│       └── getting-started.md
├── patches/
│   └── definitions.json           # 补丁定义
├── scripts/
│   ├── apply-patches.ps1          # 应用补丁
│   ├── rollback.ps1                # 回滚补丁
│   └── verify.ps1                  # 验证状态
├── AGENTS.md                      # AI 协作规则
├── progress.txt                   # 项目进度
└── README.md                      # 本文件
```

---

## 技术原理

### 为什么修改源码而不是写插件？

Trae 的很多限制是在前端代码中硬编码的，无法通过设置或插件修改。通过源码定制，可以：

- 移除不必要的确认弹窗
- 修改内部逻辑行为
- 突破前端限制

### 补丁系统

```
Trae 源码 (87MB minified JS)
    ↓
检测当前状态 (verify.ps1)
    ↓
应用补丁 (apply-patches.ps1)
    ↓
自动备份 (backups/*.js)
```

每个补丁包含：
- `find_original`: 原始代码（用于定位）
- `replace_with`: 替换后的代码
- `check_fingerprint`: 短字符串验证是否已应用

---

## 安全建议

1. **仅在信任的环境使用** — 修改源码后，所有命令都会自动执行
2. **善用沙箱模式** — Trae 的沙箱仍可保护项目外文件
3. **保持备份习惯** — 回滚脚本可以随时恢复
4. **关注 Trae 更新** — 大版本更新后需要重新应用补丁

---

## 参与贡献

本项目是探索 Trae 源码的成果记录。如果你也发现了有趣的定制点，欢迎提交 Issue 或 PR。

### 给后续探索者的提示

> ⚠️ **修改源码后必须立即 push 到 GitHub！**
>
> 本项目的所有发现都记录在 `docs/architecture/source-architecture.md` 里。
> 开始工作前先读一遍，可以避免重复探索。

---

## 相关链接

- [Trae IDE](https://www.trae.com)
- [Trae Mod GitHub](https://github.com/bigmanBass666/trae-unlock)

---

## 更新日志

### 2026-04-18
- 🗃️ 初始化 Trae Mod 项目
- ✅ 完成命令自动确认功能
- ✅ 完成思考上限自动续接功能
- ✅ 建立补丁系统框架
