# Agent Rules for Trae Mod Project

## ⚠️⚠️⚠️ Anchor 声明

**你不是一个孤立的会话。用户会在不同时间开启多个 AI 会话。**
- 工作成果可能需被未来会话继承 → 持久化到 `shared/` 目录
- 需要的信息可能已记录在 `shared/` 中 → 先读取再工作
- **AGENTS.md 是锚点**：每次 AI 回复时自动读取

---

## 🚀 会话开始必做（3 步）

**Step 1**: 读 `shared/_registry.md` → 按 **P0→P1→P2** 优先级读模块
**Step 2**: 补丁自检 → `powershell scripts/auto-heal.ps1 -DiagnoseOnly`
  - ✅ 全PASS → 继续 | ❌ FAIL → `auto-heal.ps1` 修复 | ⚠️ MANUAL → 告知用户+记status.md
**Step 3**: 按需读模块（见下方路由表）
> 不自检 = 在破损基础上构建

---

## ✍️ 写入责任

| 时机 | 文件 | 内容 |
|------|------|------|
| 发现关键代码 | `shared/discoveries.md` | 位置、作用、影响 |
| 做出技术决策 | `shared/decisions.md` | 决策、原因、替代方案 |
| 完成工作后 | `shared/status.md` | 完成了什么、待做什么、问题 |
| 修改规则 | 规则引擎命令 | 更新 `shared/rules.md` |

格式约定 → 见 `_registry.md`

---

## 🗺️ 路由表 & Critical 规则

| 需求 | 文件 |
|------|------|
| 协作规则（完整） | `shared/rules.md` |
| 方法论速查（🔍索引） | `shared/discoveries.md` 末尾 |
| 状态 & 效率数据 | `shared/status.md` |
| 技术决策历史 | `shared/decisions.md` |
| 项目上下文 | `shared/context.md` |

**Critical 规则**: rule-005(搜索优先) | rule-010(推理搜索验证) | rule-011(假设搜索) | rule-012(中间层陷阱) | rule-013(复盘协议) | rule-018(效率追踪)

---

## 🔄 核心协议

### 🔍 搜索优先（强制）
写代码前搜 3 轮：工具→方案→生态。工具：`ast-grep` / `search-target.ps1` / `WebSearch` → 详见 rule-005/011
### 🔄 复盘协议（强制）
⚠️ **复盘 = Return 前置条件。不复盘 = 任务未完成。**
触发：补丁PASS/问题修复/功能完成/TodoWrite completed/用户反馈处理完毕
禁止：❌全勾直接Return | ❌等提醒才复盘 | ❌"下次再做" → 详见 rule-013
### 📋 会话结束检查
1. 有发现？→ discoveries.md | 2. 有决策？→ decisions.md | 3. 写日志 → status.md | 4. 安全检查 → git commit?
> 详细格式 + 规则更新命令 → `_registry.md`
