# Agent Rules for Trae Mod Project

## ⚠️⚠️⚠️ Anchor 声明

**你不是一个孤立的会话。用户会在不同时间开启多个 AI 会话。**

这意味着：
1. 你当前的工作成果可能需要被未来的会话继承
2. 你需要的信息可能已经由前序会话记录在 `shared/` 目录中
3. 你有责任将重要信息持久化到 `shared/` 目录，否则它们会随会话结束而丢失
4. 你不能假设用户一直在当前会话中 — 跨会话协作是常态

**在开始任何工作之前，你必须先读取 Anchor 共享知识库：**
→ 读取 `shared/_registry.md` 了解所有可用模块
→ 按 P0 → P1 → P2 优先级读取所需模块

## 🔑 关于本文件的关键洞察

**AGENTS.md 会被 AI 每次回复时自动读取。**

这意味着：
1. 它是跨会话通信的天然入口 — AI 不需要"记住"去读它，因为每次都会读
2. 写在这里的指令具有最高执行力 — 比 README、progress 等文件的优先级更高
3. 它应该保持精简 — 只做路由/跳板，不存储具体内容
4. 如果你想设计跨会话系统，利用这个文件的"每次必读"特性是最巧妙的方式

如果你是未来想改进跨会话通信的 AI，请记住：**AGENTS.md 是你的锚点。**

## ✍️ 你的写入责任

在工作过程中，你应该将重要信息持久化到 `shared/` 目录：

| 时机 | 写入文件 | 内容 |
|------|---------|------|
| 发现关键代码/架构 | `shared/discoveries.md` | 位置、作用、影响 |
| 做出技术决策 | `shared/decisions.md` | 决策、原因、替代方案 |
| 完成工作后 | `shared/status.md` | 完成了什么、待做什么、遇到什么问题 |
| 修改了规则 | 运行下方命令 | 自动更新 `shared/rules.md` |

**写入格式**: 遵循 `shared/_registry.md` 中的写入格式约定

## 🔧 规则更新

协作规则存储在 `rules/*.yaml`，通过引擎生成到 `shared/rules.md`：

```powershell
powershell scripts/rules-engine.ps1 --output shared/rules.md   # 更新规则文件
powershell scripts/rules-engine.ps1 --check                     # 验证规则语法
```
