# Trae Unlock — Trae IDE 源码定制框架

> 通过修改 Trae IDE 源码，解锁 AI Agent 能力：命令自动确认、思考上限续接、循环检测绕过等。

## 当前状态

| 功能 | 状态 |
|------|------|
| 命令自动确认（Copy/Remove/Move/Rename 零弹窗） | ✅ v4 已验证 |
| 思考上限自动续接 | ⚠️ **v8 测试中**（L1展示 + L2轮询双架构） |
| 循环检测自动绕过 | ✅ v4 已验证 |
| 数据源层 auto_confirm | ✅ v3 最可靠方案 |

## 快速开始

```powershell
# 查看补丁健康状态
.\scripts\auto-heal.ps1 -DiagnoseOnly

# 应用所有补丁
.\scripts\apply-patches.ps1

# 回滚到最新备份
.\scripts\rollback.ps1 --latest
```

## 项目结构

```
trae-unlock/
├── patches/
│   └── definitions.json       # 9 个补丁定义（唯一真实来源）
├── scripts/                    # 核心脚本（仅 6 个）
│   ├── apply-patches.ps1       # 应用/验证补丁（主入口）
│   ├── auto-heal.ps1           # 自动诊断+修复
│   ├── snapshot.ps1            # 备份+提交
│   ├── rollback.ps1            # 紧急回滚
│   ├── verify.ps1              # 验证状态
│   └── diagnose-patch-health.ps1
├── shared/                     # 共享知识库（AI 协作核心）
│   ├── handoff.md              # 会话交接单（每次覆盖）
│   ├── discoveries.md          # 源码探索经验（**核心资产**）
│   ├── status.md               # 当前状态+补丁表
│   ├── decisions.md            # 技术决策记录
│   ├── context.md              # 项目上下文
│   ├── diagnosis-playbook.md   # 诊断操作手册
│   ├── _registry.md            # 模块索引
│   └── rules.md                # 协作规则
├── rules/                      # 规则定义（5 个 YAML）
├── AGENTS.md                   # AI 协作指南（新会话必读）
├── docs/architecture/          # 架构文档
└── .archive/                   # 历史材料（已归档的 spec/脚本）
```

## 核心架构

目标文件: `@byted-icube/ai-modules-chat/dist/index.js`（单行 10.7MB 压缩 JS）

```
L3 数据层 (~7318521)  →  auto_confirm 标志（最可靠，不受 React 影响）
L2 服务层 (~7502574)  →  PlanItemStreamParser provideUserResponse（不受窗口冻结影响）
L1 UI 层 (~8640000)    →  React 组件（⚠️ 切走窗口后冻结！仅适合纯视觉修改）
```

**关键发现 — L1 冻结原则**: Chromium 后台标签页停止 rAF → React Scheduler 暂停 → L1 补丁代码不执行。这就是 auto-continue 历史迭代 6 次（v3→v7）的根因。

v8 架构解决方案: L1 负责检测+展示+捕获服务引用到 `window.__traeSvc`，L2（setInterval 3000ms 轮询器）负责实际发送续接消息，完全不受窗口焦点影响。

## 给未来 AI 同事

1. **读 `shared/handoff.md`** — 上一个会话留下了什么
2. **运行 `auto-heal.ps1 -DiagnoseOnly`** — 补丁是否健康
3. **搜 `shared/discoveries.md`** — 90% 的代码问题前人已分析过（索引在文末）
4. 搜索用 PowerShell 子串搜索（`$c=[IO.File]::ReadAllText($path); $c.IndexOf("keyword")`），Grep/ast-grep 对压缩文件无效

详细协议见 [AGENTS.md](AGENTS.md)。

## 安全

- 仅在信任环境使用（修改源码后所有命令自动执行）
- apply-patches/auto-heal 成功后**自动备份**到 `backups/`
- 自动 git commit 防止丢失
- 写入前 `node --check` 语法验证

## 相关链接

- [Trae IDE](https://www.trae.com)
