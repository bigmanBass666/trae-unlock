---
module: registry
description: 资产注册表 + 模块索引 + 写入规范 + 脚本生命周期
read_priority: P1
read_when: 了解文件用途和写入格式时
write_when: 新增/删除模块或变更写入规范时
format: registry
single_source_of_truth_for:
  - 模块列表及优先级
  - 写入格式约定
  - 时间戳规范
  - 脚本生命周期管理
sync_with:
  - AGENTS.md (导航入口)
last_reviewed: 2026-04-26
---

# 共享知识库 — 模块索引

## 模块列表

| 文件 | 优先级 | 用途 | 何时读 | 何时写 |
|------|--------|------|--------|--------|
| `handoff.md` | **P0** | 交接**路由入口**（指向 explorer/developer） | 每次启动（最先） | Explorer/Developer 各写各的 |
| `handoff-explorer.md` | **P0 (Explorer)** | 探索家交接单（域测绘/源码发现/搜索模板） | Explorer 启动时 | Explorer 会话结束时 |
| `handoff-developer.md` | **P0 (Developer)** | 开发者交接单（补丁状态/版本适配/待处理问题） | Developer 启动时 | Developer 会话结束时 |
| `skills/_index.md` | **P0** | 渐进式知识索引（Layer 1 元数据 + Layer 2 路径） | 每次启动 | 新增/删除 Skill 或业务上下文时 |
| `status.md` | P1 | 当前状态+补丁表 | 每次启动 | 每次会话结束 |
| `discoveries.md` | P1 | **源码发现+代码定位**（含渐进式索引层） | 需要查代码时 | 发现关键信息时 |
| `failure-modes.md` | P1 | **已知失败模式库**（15 条可预防错误及应对策略） | 遇到问题时（诊断前必读） | 发现新的失败模式时 |
| `rules.md` | P1 | 协作规则（L0-L3 四层体系） | 每次启动 | 规则变更时 |
| `context.md` | P1 | 项目上下文+架构洞察 | 首次接触项目 | 项目重大变更时 |
| `work-log.md` | P2 | **Agent 工作日志**（过程性内容的唯一归宿） | 审计工作过程时 | 每次操作后（只追加） |
| `evolution-log.md` | P2 | **自我进化日志**（任务结果/失败模式/规则变更） | 回顾进化历史时 | 每次重要任务完成后 |
| `decisions.md` | P2 | 技术决策记录 | 需要理解决策背景时 | 做出技术决策时 |
| `diagnosis-playbook.md` | P2 | 诊断手册 | 遇到已知问题时 | 发现新的诊断模式时 |

### Rules 文件（L0-L3 四层体系）

| 文件 | 层级 | 激活方式 | 规则数 |
|------|------|----------|--------|
| rules/L0-always.yaml | L0 | Always Apply | 5 |
| rules/L1-techstack.yaml | L1 | File-Specific | 6 |
| rules/L2-domain.yaml | L2 | Intelligent | 8 |
| rules/L3-sop.yaml | L3 | Manual/Smart | 4 |

## 写入格式

追加到文件末尾，格式：

```markdown
### [YYYY-MM-DD HH:mm] 简短标题

**关键字**: 值
详细描述...
---
```

**⚠️ 追加而非重写** — 重写会丢失其他会话的条目。只允许更新 status.md 的结构性表格内容。

### 进化日志模板

追加到 `shared/evolution-log.md` 末尾，格式：

```markdown
### [日期] 任务：{任务描述}

**执行结果**：成功/部分成功/失败
**遵守的规则**：{本文档中的哪些规则起作用了}
**违反/不足的规则**：{哪些规则没能遵守，为什么}
**新发现的失败模式**：
- {描述}
**建议的规则变更**：
- 新增：{规则内容}
- 修改：{原规则 → 新规则}
- 删除：{规则内容，原因}
**效能数据**：
- 耗时：{估计 vs 实际}
- 错误次数：{N 次}
- 人工介入次数：{N 次}
```

## ⏰ 时间戳规范（强制）

> **必须使用系统真实时间，禁止编造时间戳**

### 正确做法

```powershell
# 写入前先获取精确时间
$ts = (Get-Date -Format "yyyy-MM-dd HH:mm")
# 然后使用 $ts 变量作为时间戳
```

### 禁止模式

| 禁止 | 原因 | 替代方案 |
|------|------|---------|
| `[2026-04-26 06:00]` 硬编码 | 时间不可信 | 用 `Get-Date` 获取 |
| 复制上一条的时间戳 | 造成时间线混乱 | 每条独立获取 |
| "约 18:00" / "下午6点" | 不精确 | 用精确格式 |
| 多条目用相同分钟数 | 明显是编造的 | 每条独立获取 |

### 适用文件

本规则适用于所有共享知识文件的写入：`handoff*.md`, `status.md`, `discoveries.md`, `decisions.md`

## 📂 脚本生命周期（v2 — Auto-Cleanup 时代）

> **2026-04-26 改革**: 从"先堆积后清理"改为"边产生边清理"
> **自动化**: `auto-cleanup.ps1` 在每次 `auto-heal.ps1` 后自动运行

| 层级 | 生命周期 | ✅ 新清理策略 | 清理时机 |
|------|---------|--------------|---------|
| **T1: 核心工具** (10个) | 永久保留 | 不清理 | — |
| **T2: 可复用工具** (2个) | 保留到下个版本更新 | 版本更新时重新评估 | 版本更新时 |
| **T3: 一次性产出** | ~~归档到 `.archive/`~~ | **✅ 会话结束时直接删除** | Explorer Agent 结束时 |
| **T4: 临时垃圾** | 直接删除 | 立即删除 | 产生时 |

### 🔄 Specs 生命周期

| 状态 | 旧行为 | ✅ 新行为 | 清理时机 |
|------|--------|----------|---------|
| 进行中 | 保留在 `.trae/specs/` | 保留在 `.trae/specs/` | — |
| 已完成 | 移动到 `.archive/specs/` | **✅ 直接删除** | Agent 会话结束时 |

### 📦 Backups 滚动窗口

| 类型 | 配额 | 说明 |
|------|------|------|
| Clean Backups | 最新 5 个 | 超出配额自动删除最旧的 |
| 普通 Backups | 最新 10 个 | 含特殊标记文件(v14/v15/v16等) |

### 🛡️ 自动化机制

**脚本**: `scripts/auto-cleanup.ps1`
**触发**: 每次 `auto-heal.ps1` 运行后自动调用
**功能**:
- Layer 1: Archive 目录配额 enforcement (< 20 文件)
- Layer 2: Backups 滚动窗口
- Layer 3: 健康度监控 + 报告

**使用方式**:
```powershell
# 正常运行（集成在 auto-heal 中，无需手动调用）
# 手动运行：
powershell scripts/auto-cleanup.ps1

# 预览模式（只看不删）：
powershell scripts/auto-cleanup.ps1 -WhatIf
```

## 📊 项目健康度（2026-04-26 清理后）

| 指标 | 清理前 | 清理后 | 目标 |
|------|--------|--------|------|
| `.archive/` 文件数 | 200+ | < 20 | ✅ 达成 |
| `backups/` 文件数 | 95 | 14 | ✅ 达成 |
| `docs/architecture/` 主目录 | 13 | 10 | ✅ 达成 |
| `docs/architecture/reference/` | 0 | 3 | 新增 |
| `AGENTS.md` 行数 | 151 | 80 | ✅ 达成 |
| **估计总文件数** | **300+** | **~120** | **✅ 改善** |

### 清理记录

- [2026-04-26] Phase 1: 删除 .archive/scripts/ (178 文件) + .archive/specs/ (47 spec) + .archive/archive/ (8 文件) = 233 文件
- [2026-04-26] Phase 2: backups/ 从 95 精简到 14 (删除 81 文件, 释放 ~700MB)
- [2026-04-26] Phase 3: 共享文件瘦身 (context.md -90行, handoff-developer.md -120行)
- [2026-04-26] Phase 4: 架构文档分级 (主目录 10个, reference/ 子目录 3个)
- [2026-04-26] Phase 5: AGENTS.md 重写 (151行 → 80行, ↓47%)
