# Agent Rules for Trae Mod Project

## ⚠️ 新会话开始前必读

**在开始任何工作之前，必须先阅读以下文档：**

1. **[README.md](README.md)** — 了解项目整体情况
2. **[docs/architecture/source-architecture.md](docs/architecture/source-architecture.md)** — 源码架构和关键代码位置
3. **[progress.txt](progress.txt)** — 当前进度和待解决问题

**禁止在不了解项目背景的情况下直接开始修改代码！**

## 核心规则

每次完成以下操作后，**必须**立即更新文档并提交：

1. **新发现** - 找到关键代码、拦截点、修改位置、架构信息
2. **修改代码** - 任何对 Trae 源码的修改
3. **测试结果** - 验证修改是否成功
4. **问题排查** - 发现问题原因或解决方案

## ⚠️ 最重要：新发现必须写入共享文档！

**发现新东西时（代码位置、架构关系、调用链等），第一时间更新以下文档：**

### docs/architecture/source-architecture.md — 源码架构探索记录
这是给**所有后续 AI 看的共享知识库**。任何源码探索发现都要写进去：
- 新发现的关键位置（文件名 + 偏移量 + 作用）
- 模块之间的关系和调用链
- 枚举值、设置 ID、NLS key 等元数据
- 排除的错误方向（哪些路走不通）

### docs/bypass-security.md — 功能实现文档
如果发现了与当前功能相关的：
- 新的有效/无效修改方案
- 测试结果变化
- 安全相关发现

### progress.txt — 进度摘要
简要记录做了什么，方便快速了解项目状态。

**原则：不要让后面的 AI 重复你已经做过的探索工作！**

## 文档更新要求

### progress.txt（简要进度）
- 写一行简短的进度描述
- 包含：修改了什么文件、关键位置、测试结果
- 示例：`[位置] 修改 ai-modules-chat:7502574 - 自动确认 provideUserResponse`

### docs/source-architecture.md（架构知识）
- 发现了哪个文件/模块的什么功能
- 关键代码位置（带偏移量）
- 与其他模块的关系
- 搜索过程和排除的方向

### README.md（项目总览）
- 新增完成的探索成果
- 更新文档索引表

## Git 提交规则

```
git add .
git commit -m "[类型] 简要说明"
git push                              # ⚠️ 每次 commit 后必须立即 push！
```

提交信息格式：
- `[发现] 找到 xxx 在 yyy:zzzz`
- `[功能] 实现了 xxx`
- `[修复] 解决了 xxx 问题`
- `[文档] 更新了 xxx`
- `[测试] 验证了 xxx`

## ⚠️⚠️⚠️ 强制 Push 规则

**每次 commit 后必须立即 push 到 GitHub！**

原因：本地 Git 仓库可能在 merge/rebase 操作中损坏（.git 目录消失），导致所有历史丢失。
已有的血的教训：merge 失败导致 .git 损坏 → 所有 commit 历史丢失。

```
正确流程:
  git add .
  git commit -m "..."
  git push          ← 立即! 不要等到"最后一起push"

禁止:
  git add . && git commit -m "..."  ← 没有 push 就做其他操作
  git merge ...  ← merge 失败可能损坏 .git
```

## 目录结构

```
trae-unlock/
├── docs/
│   ├── achievements/              # 定制成果文档
│   │   ├── auto-command-confirm.md
│   │   └── auto-continue-thinking.md
│   ├── architecture/             # 架构文档
│   │   ├── source-architecture.md
│   │   └── trae-confirm-system.md
│   └── guides/                   # 使用指南
├── patches/                      # 补丁定义
│   └── definitions.json
├── scripts/                      # 工具脚本
│   ├── apply-patches.ps1
│   ├── rollback.ps1
│   └── verify.ps1
├── progress.txt                  # 进度摘要
├── AGENTS.md                     # AI 协作规则（本文档）
└── README.md                     # 项目总览
```

## 工作流程

```
1. 读 README.md 了解项目整体情况
2. 读 docs/architecture/source-architecture.md 了解已有知识
3. 读 progress.txt 了解当前进度
4. 开始探索/修改
5. 有新发现 → 立即写进对应文档
6. 有代码修改 → 备份 + 记录到对应文档
7. git add . && git commit && git push
8. 继续下一步
```
