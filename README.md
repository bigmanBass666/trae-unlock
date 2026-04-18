# Trae Mod - 让 AI 在项目里自由驰骋

让 Trae IDE 的 AI Agent 真正实现"零打扰"工作：危险命令自动确认、思考超限自动续接、切换窗口不卡死。

**参考 Issue**: [GUI mode lacks permission configuration equivalent to CLI's bypass_permissions mode](https://github.com/Trae-AI/TRAE/issues/2485)

---

## 解决了什么问题

Trae 默认行为下，AI 执行危险命令（删除/复制/移动文件）时会弹出确认框，长思考时会卡住等你点"继续"，切换 AI 会话窗口后命令会冻住。

本项目通过 4 行源码修改，彻底解除这些限制。

---

## 4 个核心补丁

| # | 补丁 ID | 位置 | 功能 |
|---|---------|------|------|
| **核心 1** | `auto-confirm-commands` | ~7502574 | **knowledge 类命令**自动确认 |
| **核心 2** | `service-layer-runcommand-confirm` | ~7503319 | **删除/复制/移动等命令**自动确认 |
| **核心 3** | `auto-continue-thinking` | ~8702342 | **思考次数超限**自动点"继续" |
| **核心 4** | `efh-resume-list` | ~8695303 | 备用恢复列表（#3 的保险） |

### 最终效果

- ✅ 所有危险命令零弹窗自动执行
- ✅ 切换 AI 会话窗口后命令继续自动执行（不冻住）
- ✅ AI 思考超限后无感自动续接
- ✅ 沙箱保护仍然生效（项目外文件操作被拦截）
- ✅ Trae 更新后可用脚本一键重打补丁

---

## 快速开始

### 1. 验证当前状态

```powershell
.\scripts\verify.ps1
```

输出应为：
```
[ACTIVE]   auto-confirm-commands             ✅ knowledge 命令自动确认
[ACTIVE]   service-layer-runcommand-confirm ✅ 其他命令自动确认
[ACTIVE]   auto-continue-thinking          ✅ 思考上限自动续接
[ACTIVE]   efh-resume-list                ✅ 备用恢复列表
```

### 2. Trae 更新后重新打补丁

```powershell
.\scripts\apply-patches.ps1
```

### 3. 出问题了？回滚

```powershell
.\scripts\rollback.ps1 -List        # 列出所有备份
.\scripts\rollback.ps1 --date 20260418  # 回滚到指定日期
.\scripts\rollback.ps1 --latest     # 回滚到最新备份
```

### 4. 手动打单个补丁

```powershell
.\scripts\apply-patches.ps1 -PatchIds "service-layer-runcommand-confirm"
```

---

## 目录结构

```
trae-unlock/
├── docs/
│   ├── source-architecture.md      # 源码架构探索记录（⭐所有AI必读）
│   └── bypass-security.md          # 安全模式绕过实现文档
├── patches/
│   └── definitions.json             # 4个核心补丁的结构化定义
├── scripts/
│   ├── apply-patches.ps1          # 一键打补丁（支持 -DryRun / -PatchIds）
│   ├── rollback.ps1                # 一键回滚（支持 -List / --date / --latest）
│   └── verify.ps1                 # 验证补丁状态（ACTIVE / INACTIVE / UNKNOWN）
├── AGENTS.md                       # AI 协作规则（强制 push 等）
├── progress.txt                    # 项目进度摘要
└── README.md                       # 本文件
```

---

## 技术原理

### 为什么只需修改源码而不改配置？

Trae 的命令确认机制是这样的：

```
AI 执行命令 → 服务端返回"需要确认" → 前端弹出确认框 → 用户点"运行" → 命令执行
```

我们修改的是**数据解析层**（PlanItemStreamParser），在确认数据到达 UI 之前就自动"点"了确认按钮，所以完全不需要改配置、不需要沙箱白名单。

### 切换窗口为什么不冻住？

修改点在 **SSE 流解析器**（服务层代码），不依赖任何 React 组件。React 组件在窗口不可见时会冻结，但服务层代码照常运行。

### 沙箱还在保护吗？

是的。沙箱的文件系统限制（禁止访问项目外文件）仍然生效。4 个补丁只负责"跳过确认弹窗"，不改变沙箱的安全策略。

---

## 已验证可零弹窗的命令

| 命令类型 | 示例 |
|---------|------|
| 文件删除 | `Remove-Item`, `rm`, `del` |
| 文件复制 | `Copy-Item`, `cp`, `copy` |
| 文件移动 | `Move-Item`, `mv`, `move` |
| 文件重命名 | `Rename-Item`, `ren` |
| 文件创建/写入 | `New-Item`, `Set-Content`, `echo >` |
| Git 操作 | `git add`, `git commit`, `git push` |
| 包管理 | `npm install`, `pip install` |

---

## 安全建议

1. **只让 AI 在信任的项目里跑** — 沙箱限制它不能碰项目外的文件
2. **AI 犯错时你可以随时回滚** — `./scripts/rollback.ps1 --latest`
3. **重要操作前先问 AI** — 虽然零弹窗了，但 AI 还是会把操作结果告诉你

---

## 相关链接

- [Issue #2485](https://github.com/Trae-AI/TRAE/issues/2485) - GUI mode lacks permission configuration
- [Trae 官方文档](https://www.volcengine.com/docs/86677/2227872) - CLI bypass_permissions 说明
- [Trae Mod GitHub](https://github.com/bigmanBass666/trae-unlock)

---

## 给后续 AI 的提示

> ⚠️ **修改源码后必须立即 push 到 GitHub！**
>
> 本项目的所有发现都记录在 `docs/source-architecture.md` 里。
> 开始工作前先读一遍，可以避免重复探索。
>
> 每次 commit 后立即 `git push`，本地 Git 仓库在 merge 操作中可能损坏。
