# Anchor 目录重组评估 Spec

## Why

用户提出是否应将所有 Anchor 系统文件集中到 `/anchor` 目录下。需要评估这是否能解决实际问题，还是多此一举。

## 当前结构

```
d:\Test\trae-unlock\
├── AGENTS.md              ← Anchor 入口（必须在根目录）
├── shared/                ← Anchor 知识模块
│   ├── _registry.md       ← 模块注册表
│   ├── context.md
│   ├── status.md
│   ├── discoveries.md
│   ├── decisions.md
│   └── rules.md           ← 规则引擎输出
├── rules/                 ← 规则定义（YAML）
│   ├── core.yaml
│   ├── anchor.yaml
│   ├── workflow.yaml
│   ├── git.yaml
│   └── safety.yaml
├── scripts/
│   └── rules-engine.ps1   ← 规则引擎脚本
└── docs/
    └── dynamic-rules-system.md
```

## 方案对比

### 方案 A: 维持现状

不移动任何文件。Anchor 系统的文件分布在 `shared/`、`rules/`、`scripts/` 三个目录中，由 AGENTS.md 作为入口统一路由。

**优点**:
- 零迁移成本
- `shared/` 是功能性命名（描述"共享知识"的用途），比品牌名 `anchor/` 更自描述
- `rules/` 和 `scripts/` 也是功能性命名，项目中的非 Anchor 脚本也可以放 `scripts/`
- 符合我们自己的设计原则——**去品牌化**：目录名应该描述功能，而非品牌

**缺点**:
- Anchor 相关文件分散在多个目录
- 移植到新项目时需要复制多个目录

### 方案 B: 全部移到 `/anchor/`

```
├── AGENTS.md              ← 仍在根目录（无法移动）
├── anchor/
│   ├── shared/            ← 知识模块
│   ├── rules/             ← 规则定义
│   └── scripts/           ← 规则引擎
```

**优点**:
- 一目了然哪些文件属于 Anchor
- 移植时复制一个目录即可

**缺点**:
- **AGENTS.md 无法移动** — Trae IDE 固定读取根目录的 AGENTS.md，这意味着入口文件永远在 anchor/ 之外
- 违反**去品牌化原则** — 目录名用品牌名而非功能名
- `shared/` 变成 `anchor/shared/` — 路径变长，所有引用都要改
- `scripts/` 中可能有非 Anchor 脚本（如 apply-patches.ps1, rollback.ps1），强行归入 anchor/ 不合理
- 大量文件引用需要更新（rules-engine.ps1 中的路径、_registry.md 中的路径、所有规则中的路径）
- 增加了一层不必要的嵌套

### 方案 C: 仅移动 Anchor 专属文件

```
├── AGENTS.md              ← 仍在根目录
├── anchor/
│   ├── _registry.md       ← 注册表
│   ├── context.md
│   ├── status.md
│   ├── discoveries.md
│   ├── decisions.md
│   ├── rules.md
│   └── rules/             ← 规则定义
├── scripts/               ← 保留（含非 Anchor 脚本）
```

**优点**:
- Anchor 知识模块和规则集中管理
- 移植时复制 anchor/ 目录

**缺点**:
- AGENTS.md 仍在根目录，入口和内容分离
- `shared/` 改名为 `anchor/` — 丢失了"共享"的功能语义
- 所有路径引用需要更新
- rules-engine.ps1 的输出路径需要改
- 违反去品牌化原则

## 核心判断

### 判断 1: AGENTS.md 无法移动是决定性因素

无论怎么重组，AGENTS.md 必须在根目录。这意味着 Anchor 的入口和内容**永远不可能完全在同一个目录下**。既然入口必然在外，把内容强行收进一个目录并不能真正实现"集中"。

### 判断 2: 功能性命名优于品牌性命名

我们自己的设计原则就是"去品牌化"——shared/*.md 不含品牌名，因为功能描述比品牌名更有价值。同样的逻辑适用于目录名：

| 目录名 | 性质 | 自描述程度 |
|--------|------|-----------|
| `shared/` | 功能性 | 高 — 一看就知道是"共享的东西" |
| `anchor/` | 品牌性 | 低 — 不知道里面是什么，只知道它叫 Anchor |
| `rules/` | 功能性 | 高 — 一看就知道是"规则" |
| `anchor/rules/` | 品牌+功能 | 中 — 多了一层无意义嵌套 |

### 判断 3: 移植问题有更好的解法

移植 Anchor 到新项目的真正痛点不是"文件分散"，而是"不知道哪些文件需要复制"。这个问题的正确解法是**移植清单**（在 _registry.md 或 bootstrap.md 中记录），而非物理合并目录。

### 判断 4: 重组的迁移成本不可忽视

当前 `shared/`、`rules/`、`scripts/` 的路径被引用了 100+ 处（见 grep 结果）。重组意味着更新所有引用，风险高、收益低。

## 结论

**维持现状（方案 A）**。移动到 `/anchor` 是多此一举，原因：

1. AGENTS.md 无法移动 → 入口和内容永远分离 → 重组无法实现真正的"集中"
2. 品牌性目录名违反我们自己的去品牌化原则
3. 功能性目录名（shared/rules/scripts）比品牌性目录名（anchor）更自描述
4. 迁移成本高（100+ 处引用），收益低（只是"看起来更整齐"）
5. 移植问题应该用移植清单解决，而非物理合并目录

## What Changes

无代码变更。本 spec 的结论是**不做重组**。

但应补充一个低成本改进：在 _registry.md 中增加"移植清单"章节，列出 Anchor 系统涉及的所有文件和目录，方便移植时参考。

## ADDED Requirements

### Requirement: Anchor 移植清单

_registry.md SHALL 包含"移植清单"章节，列出将 Anchor 系统移植到新项目时需要复制的所有文件和目录。

#### Scenario: 将 Anchor 移植到新项目
- **WHEN** 用户想把 Anchor 系统移植到另一个项目
- **THEN** 从 _registry.md 的移植清单中得知需要复制哪些文件
- **AND** 不需要猜测或搜索哪些文件属于 Anchor

## MODIFIED Requirements

无

## REMOVED Requirements

无
