# Anchor 命名集中化 Spec

## Why

系统已正式命名为 "Anchor"，但改名涉及 19 个文件 48 处修改——这恰恰是我们设计 Anchor 要解决的"牵一发动全身"问题。系统名称散布在所有文件中，每次改名都要全项目搜索替换。需要设计一种集中化命名策略，让未来改名只需改 1-2 个文件。

## 核心分析

### 为什么改名会"牵一发动全身"？

系统名称被**硬编码**在以下位置：

| 位置 | 当前名称 | 性质 |
|------|---------|------|
| AGENTS.md | "Anchor 声明", "Anchor 共享知识库" | AI 每次必读 |
| shared/_registry.md | "Anchor 共享知识库" | 模块注册表 |
| shared/context.md | "Anchor 共享知识库 — ..." | 自描述头部 |
| shared/status.md | "Anchor 共享知识库 — ...", "Anchor 规则子系统" | 自描述头部 + 内容 |
| shared/discoveries.md | "Anchor 共享知识库 — ..." | 自描述头部 |
| shared/decisions.md | "Anchor 共享知识库 — ..." | 自描述头部 |
| README.md | "Anchor 规则子系统" | 人类文档 |
| docs/dynamic-rules-system.md | "Anchor 规则子系统" | 人类文档 |
| progress.txt | "Anchor", "Anchor 共享知识库", "Anchor 规则子系统" | 历史记录 |
| .trae/specs/ (6个spec) | 各种旧名 | 历史记录 |

### 关键洞察：文件分三类，处理策略应不同

1. **活文件**（AI 每次会话都读）— 必须改名，且应避免硬编码系统名
2. **人文档**（人类参考）— 应该改名，但改名频率低，可接受手动维护
3. **历史记录**（记录过去发生了什么）— **不应改名**，改名等于篡改历史

### 为什么历史文件不应改名？

- `progress.txt` 记录 "2026-04-19 动态规则系统上线" — 这在当时就叫这个名字
- `.trae/specs/cross-session-communication/` — 这个 spec 设计时就叫"跨会话通信系统"
- 改名后，读者会困惑："为什么 4 月 19 日的记录提到了 Anchor？当时还没这个名字"
- **历史记录应该忠实于当时的事实**

## What Changes

### 1. 集中化命名：系统名只在 2 个文件中定义

- **AGENTS.md** — "Anchor 声明"（入口声明）
- **shared/_registry.md** — "Anchor 共享知识库"（注册表标题）

这两个文件是改名的**唯二必改点**。其他文件不应硬编码系统名。

### 2. shared/*.md 去品牌化：描述功能而非品牌

**现状**（每个文件都硬编码了系统名）：
```
> Anchor 共享知识库 — 每个新会话 AI 必读的项目核心信息
```

**改为**（只描述功能，不提系统名）：
```
> 每个新会话 AI 必读的项目核心信息
```

这样改名时只需改 AGENTS.md 和 _registry.md，shared/*.md 不需要动。

### 3. 历史文件不改名

- `progress.txt` — 保持原样，它是历史记录
- `.trae/specs/` 下所有文件 — 保持原样，它们是设计决策的历史记录
- 如果需要，可以在历史条目后追加注释：`(现称 Anchor)`

### 4. 人类文档适度改名

- `README.md` — 应该用当前名称（人类入口文档）
- `docs/dynamic-rules-system.md` — 应该用当前名称（使用指南）

但人类文档改名频率极低（系统名不会经常变），手动维护可接受。

## Impact

- Affected files: shared/*.md（去品牌化）, progress.txt 和 specs/（回退改名）
- Affected specs: rename-to-anchor（需要重新定义范围）

## ADDED Requirements

### Requirement: 系统名集中定义

系统名称 SHALL 只在以下 2 个文件中硬编码：

1. **AGENTS.md** — "Anchor 声明"部分
2. **shared/_registry.md** — 注册表标题

其他所有文件不应硬编码系统品牌名。

#### Scenario: 未来系统改名
- **WHEN** 系统需要从 "Anchor" 改名为其他名称
- **THEN** 只需修改 AGENTS.md 和 _registry.md 两个文件
- **AND** shared/*.md 文件不需要任何修改
- **AND** 历史文件保持原样

### Requirement: shared/*.md 去品牌化

每个 shared/*.md 文件的描述行 SHALL 只描述功能，不包含系统品牌名。

**替换规则**：

| 文件 | 现状 | 改为 |
|------|------|------|
| context.md | `> Anchor 共享知识库 — 每个新会话 AI 必读的项目核心信息` | `> 每个新会话 AI 必读的项目核心信息` |
| status.md | `> Anchor 共享知识库 — 每次会话结束时更新，下一个会话读取` | `> 每次会话结束时更新，下一个会话读取` |
| discoveries.md | `> Anchor 共享知识库 — 关键代码位置、架构关系、枚举值等` | `> 关键代码位置、架构关系、枚举值等` |
| decisions.md | `> Anchor 共享知识库 — 记录"为什么选择 X 而不是 Y"` | `> 记录"为什么选择 X 而不是 Y"` |
| context.md 目录树 | `├── shared/  # Anchor 共享知识库` | `├── shared/  # 跨会话共享模块` |
| status.md 表格 | `Anchor 规则子系统` | `规则子系统` |
| status.md 表格 | `Anchor 共享知识库` | `共享知识库` |

#### Scenario: AI 读取 shared/*.md
- **WHEN** AI 读取 shared/context.md
- **THEN** 从描述行了解文件功能（"每个新会话 AI 必读的项目核心信息"）
- **AND** 不需要从描述行知道系统品牌名
- **AND** 系统品牌名从 AGENTS.md 和 _registry.md 获取

### Requirement: 历史文件保持原名

`progress.txt` 和 `.trae/specs/` 下的文件 SHALL 保持创建时的原始名称，不随系统改名而修改。

**理由**：
- 历史记录应忠实于当时的事实
- 改名等于篡改历史，会让读者困惑时序
- 如需标注当前名称，可在条目末尾追加 `(现称 Anchor)`

#### Scenario: 读者查看历史记录
- **WHEN** 读者查看 progress.txt 中 2026-04-19 的记录
- **THEN** 看到 "动态规则系统上线" — 这是当时的真实名称
- **AND** 如果有标注，看到 `(现称 Anchor 规则子系统)`

### Requirement: _registry.md 增加系统元数据

`shared/_registry.md` SHALL 在文件开头增加系统品牌元数据：

```markdown
# Anchor 共享知识库 — 模块注册表

> 系统名称: Anchor
> 本注册表集中管理所有 shared/ 模块的元数据...
```

这样系统名在 _registry.md 中有明确的定义点。

## MODIFIED Requirements

### Requirement: rename-to-anchor 的范围缩小

**原范围**：19 个文件 48 处替换
**修改后**：
- ✅ AGENTS.md（2 处）— 已完成
- ✅ shared/_registry.md（1 处）— 已完成
- 🔄 shared/*.md — 去品牌化（移除系统名，而非替换为新名）
- ✅ README.md（3 处）— 已完成
- 🔄 docs/dynamic-rules-system.md — 适度改名
- ❌ progress.txt — **回退改名**，保持历史原名
- ❌ .trae/specs/ — **不做改名**，保持历史原名

## REMOVED Requirements

### Requirement: 全项目统一替换系统名

**原因**：全项目替换是"牵一发动全身"的做法，与 Anchor 系统的设计理念矛盾。应改为集中化命名 + 历史文件保持原样。
