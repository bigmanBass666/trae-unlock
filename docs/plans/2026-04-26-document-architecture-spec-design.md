---
module: plans
description: Document Architecture Specification (DAS) v1.0 设计方案 — 文档系统自我纠错能力规范
read_priority: P2
format: reference
last_reviewed: 2026-04-26
---

# Document Architecture Specification (DAS) v1.0

> **目标**: 让文档系统具备自我纠错能力，从根源上防止"找到一点往里塞一点"
> **原则**: 信息唯一来源 + 强制模板 + AI 友好元数据 + 自动化校验

---

## 一、问题根因分析

### 为什么会出现"随意塞入"？

```
❌ 当前模式:
  Agent A 发现信息 X → 写到文件 F1（因为手边开着 F1）
  Agent B 发现信息 Y → 写到文件 F2（因为觉得 F2 相关）
  Agent C 更新信息 X → 只改了 F1，忘记 F2/F3 也有
  → 结果：碎片化、矛盾、不可维护

✅ 目标模式:
  Agent A 发现信息 X → 查 DAS 规范 → X 属于 Domain D → 写到 D 的唯一文件
  Agent B 发现信息 Y → 查 DAS 规范 → Y 属于 Domain D → 追加到同一个文件
  Agent C 更新信息 X → 只有一个地方需要改
  → 结果：集中、一致、可维护
```

### 根本原因

1. **缺乏信息分类体系** — 不知道该往哪里写
2. **缺乏强制模板** — 不知道该怎么写
3. **缺乏唯一性约束** — 同类信息可以出现在多处
4. **缺乏自动化校验** — 写错了没人提醒

---

## 二、解决方案：四层防护体系

### Layer 1: 信息域分类（Information Domain Taxonomy）

定义项目中所有信息的**唯一归属域**，每个域对应**唯一一个文件**：

```
┌─────────────────────────────────────────────────────┐
│                  信息域分类图                         │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Domain 1: 项目元数据 (Meta)                         │
│    └─ 唯一文件: AGENTS.md                            │
│    内容: 项目名称/定位/目标文件/三层导航/核心原则       │
│                                                     │
│  Domain 2: 运行时状态 (Runtime State)                 │
│    └─ 唯一文件: shared/status.md                     │
│    内容: 补丁状态表/待办事项/健康度指标/会话日志        │
│    ⚠️ 其他文件只能引用，不能重复！                     │
│                                                     │
│  Domain 3: 源码发现 (Discoveries)                     │
│    └─ 唯一文件: shared/discoveries.md                │
│    内容: 代码位置/偏移量/枚举值/架构关系               │
│    格式: 四维索引 (按时间追加)                        │
│                                                     │
│  Domain 4: 技术决策 (Decisions)                       │
│    └─ 唯一文件: shared/decisions.md                   │
│    内容: 决策记录/选择理由/否决选项                    │
│    格式: 每个决策一个 ### 章节                        │
│                                                     │
│  Domain 5: 交接协议 (Handoff)                         │
│    ├─ shared/handoff.md        ← 路由入口            │
│    ├─ handoff-explorer.md     ← Explorer 专属         │
│    └─ handoff-developer.md    ← Developer 专属        │
│    规则: 只能引用 Domain 2/3 的数据，不能复制！        │
│                                                     │
│  Domain 6: 架构知识 (Architecture)                     │
│    ├─ docs/architecture/source-architecture.md  (索引)│
│    ├─ docs/architecture/*.md              (13个详细)   │
│    └─ docs/architecture/reference/          (3个参考)  │
│    规则: 详细文档只能引用 discoveries 的数据           │
│                                                     │
│  Domain 7: 协作规则 (Rules)                           │
│    └─ shared/_registry.md                             │
│    内容: 脚本生命周期/写入格式/时间戳规范              │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**关键约束**：
- ✅ 每个 Domain 有**且仅有**一个权威文件
- ✅ 权威文件之外的文件**只能引用**，不能**复制**
- ✅ 引用时必须使用 `` [text](path#anchor) `` 格式

---

### Layer 2: 强制文档模板（Mandatory Templates）

为每种文档类型定义**必须遵守的结构**：

#### Template A: 共享知识文件（shared/*.md）

```markdown
---
module: <模块名>
description: <一句话说明>
read_priority: P0|P1|P2
read_when: <何时读>
write_when: <何时写>
format: registry|log|reference
last_reviewed: <YYYY-MM-DD>
---

# <文件标题>

> **这是第几重要的文件？新Agent是否必读？**
> **更新频率？谁负责更新？**

## 核心内容区

<!-- 此区域的内容类型和结构由 format 字段决定 -->

## 交叉引用

- 相关域: `` [Domain X](path/to/file) ``
- 数据来源: [discoveries.md](../../shared/discoveries.md) （如适用）
```

#### Template B: 架构文档（docs/architecture/*.md）

```markdown
---
domain: architecture
sub_domain: <sse-pipeline|model-domain|command-confirm|...>
focus: <本文档聚焦的具体方面>
dependencies: <依赖哪些 discoveries 或其他架构文档>
consumers: <谁会读这个文档>
created: <YYYY-MM-DD>
---

# <域名> 架构文档

## 1. 概述（必需）

> 3-5句话：这个域是什么？为什么重要？在整体架构中的位置？

## 2. 关键实体（必需）

| 实体名 | 类型 | 位置(偏移量) | 职责 |
|--------|------|-------------|------|
| ... | ... | ~XXXXXXX | ... |

## 3. 关系图（可选）

<!-- Mermaid 或 ASCII 图 -->

## 4. 与其他域的关系（必需）

| 相关域 | 关系类型 | 交叉点 |
|--------|---------|--------|
| Domain X | 调用/依赖/包含 | 具体位置 |

## 5. 探索指引（对Explorer有用）

- 如何验证此域的信息仍有效？
- 版本更新时哪些偏移量可能变化？
- 相关的搜索模板编号？
```

#### Template C: Handoff 文件（handoff*.md）

```markdown
---
role: explorer|developer|reviewer
target_audience: <哪个角色的Agent>
sync_with: status.md, discoveries.md
---

# <角色>交接单

## 📍 当前焦点

> 本次会话最重要的 1-3 件事

## 📋 待办清单

### 高优先级
- [ ] ...

### 中优先级
- [ ] ...

## 🔗 关键引用

> ⚠️ 以下信息来自权威源，不要在此复制！

- 补丁状态: → [status.md §已完成功能](shared/status.md)
- 最新发现: → [discoveries.md](shared/discoveries.md)

## 📝 会话记录

### [<时间戳>] <标题>
...
```

---

### Layer 3: 元数据标准（Metadata Standard）

#### 必须字段（所有 .md 文件）

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `module` | string | 所属模块名 | `status`, `discoveries`, `rules` |
| `description` | string | 一句话说明 | `"当前状态+补丁表"` |
| `read_priority` | enum | P0/P1/P2 | `P1` |
| `format` | enum | `registry`\|`log`\|`reference` | `registry` |

#### 可选字段

| 字段 | 适用场景 | 说明 |
|------|---------|------|
| `domain` | 架构文档 | 所属架构域 |
| `sub_domain` | 架构文档 | 子域名称 |
| `role` | handoff 文件 | 目标角色 |
| `single_source_of_truth_for` | 权威文件 | 本文件是哪些信息的唯一来源 |
| `dependencies` | 架构文档 | 依赖的其他文件 |
| `last_reviewed` | 所有文件 | 最后审查日期 |

#### 元数据示例

```yaml
---
module: status
description: 当前状态和待办事项
read_priority: P1
read_when: 每次会话开始
write_when: 每次会话结束
format: registry
single_source_of_truth_for:
  - 补丁状态表
  - 已完成功能列表
  - 待办事项
  - 项目健康度指标
last_reviewed: 2026-04-26
---
```

---

### Layer 4: 自动化校验（Automated Validation）

创建 `scripts/validate-docs.ps1` 脚本，每次 auto-cleanup 时自动运行：

#### 校验规则

##### Rule 1: 元数据完整性
```powershell
# 所有 .md 文件必须有 YAML front matter
# 必须包含: module, description, read_priority
foreach ($file in $allMdFiles) {
    $content = Get-Content $file -Raw
    if (-not $content.StartsWith("---")) {
        Write-Error "[$file] 缺少 YAML front matter!"
    }
}
```

##### Rule 2: 信息唯一性（防重复）
```powershell
# 检查：status.md 的内容不应在其他文件中完整重复
$statusContent = Get-Content "shared/status.md" -Raw

foreach ($otherFile in $otherSharedFiles) {
    $overlap = Measure-Overlap $statusContent $otherFile
    if ($overlap.Percent -gt 30) {
        Write-Warning "[$otherFile] 与 status.md 重叠 ${overlap.Percent}%！应改为引用"
    }
}
```

##### Rule 3: 交叉引用有效性
```powershell
# 所有 `` [text](path) `` 链接的目标必须存在
$links = Extract-MarkdownLinks $file
foreach ($link in $links) {
    $target = Resolve-Path $link.Target
    if (-not $target) {
        Write-Error "[$file] 死链: $($link.Text) -> $($link.Target)"
    }
}
```

##### Rule 4: 结构合规性
```powershell
# 根据 format 字段检查结构
if ($metadata.format -eq "registry") {
    # 必须有表格
    if (-not $content.Contains("|")) {
        Write-Error "[$file] format=registry 但无表格！"
    }
}

if ($metadata.format -eq "log") {
    # 必须有时间戳章节
    if (-not $content.Contains("### [20")) {
        Write-Error "[$file] format=log 但无时间戳章节！"
    }
}
```

##### Rule 5: AI 友好性
```powershell
# Section 标题必须是固定的关键词
$allowedSections = @(
    "概述", "核心内容", "关键实体", "关系",
    "待办", "交叉引用", "会话记录"
)

$h1Count = ($content -match "^# ").Count
if ($h1Count -gt 1) {
    Write-Warning "[$file] 有多个 H1，建议只用一个作为标题"
}
```

---

## 三、实施路线图

### Phase 1: 基础设施（1-2小时）

- [ ] 创建 `scripts/validate-docs.ps1` 校验脚本
- [ ] 定义完整的元数据 schema（YAML）
- [ ] 创建文档模板文件（`.templates/` 目录）

### Phase 2: 迁移现有文档（2-3小时）

按优先级迁移：

**P0 — 核心共享文件（立即修复）**
1. `shared/status.md`
   - 添加 front matter
   - 标注 `single_source_of_truth_for`
   - 删除与其他文件的重复内容（改用引用）

2. `shared/discoveries.md`
   - 添加 front matter
   - 统一时间戳格式
   - 建立四维索引规范

3. `AGENTS.md`
   - 添加 front matter
   - 明确标注"这是入口导航，不含详细数据"

**P1 — Handoff 文件**
4. `shared/handoff.md`
5. `shared/handoff-developer.md`
6. `shared/handoff-explorer.md`

**P2 — 架构文档**
7. `docs/architecture/source-architecture.md`（作为索引模板）
8. 其余 12 个架构文档（批量处理）

### Phase 3: 集成到工作流（30分钟）

- [ ] 将 `validate-docs.ps1` 集成到 `auto-cleanup.ps1`
- [ ] 在 `auto-heal.ps1` 成功后自动运行校验
- [ ] 校验失败时输出 WARNING（不阻塞，但提醒）

### Phase 4: 长期治理（持续）

- [ ] 每次 Git commit 前运行校验（可选：pre-commit hook）
- [ ] 定期审查（每月）：检查是否有新文件违反 DAS
- [ ] 文档质量趋势追踪：记录评分变化

---

## 四、成功标准

### 量化目标（实施后 1 周）

| 指标 | 当前值 | 目标值 | 测量方式 |
|------|--------|--------|---------|
| 有 front matter 的文件比例 | ~10% | **100%** | validate-docs.ps1 |
| 信息重叠率（两文件 >30% 相似） | 多处 | **0 处** | overlap detection |
| 死链数量 | 未知 | **0** | link checker |
| 新 Agent 找到关键信息的时间 | 30+ 分钟 | **< 10 分钟** | 人工测试 |
| 架构合理性评分 | 1.4/5 | **≥ 4.0/5** | 复评 |

### 质量目标（长期维持）

- ✅ **零重复**: 同一事实只在一个地方定义
- ✅ **零死链**: 所有交叉引用有效
- ✅ **零随意**: 所有文档遵循模板
- ✅ **完全可发现**: 通过域分类图 30 秒内定位任何信息
- ✅ **AI 可解析**: 程序化提取关键信息无需人工干预

---

## 五、风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| 迁移工作量太大 | Agent 抵触 | 分阶段实施，先做 P0 |
| 模板过于僵化 | 限制表达自由 | 仅要求结构，不限制内容风格 |
| 校验脚本误报 | 干扰正常工作 | WARNING 不阻塞，仅提醒 |
| Agent 不遵守规范 | 新文档又乱写 | pre-commit hook 强制校验 |

---

## 六、与现有系统的关系

### 与 Auto-Cleanup 的关系

```
auto-heal.ps1
    ↓
auto-cleanup.ps1  ← 文件数量清理
    ↓ (新增)
validate-docs.ps1  ← 文件质量校验 (新增)
    ↓
输出: 健康度报告 (增强版，含文档质量评分)
```

### 与 _registry.md 的关系

- `_registry.md` 定义**脚本生命周期**
- DAS 定义**文档生命周期**
- 两者互补，共同构成项目的治理框架

---

## 七、下一步行动

**如果你同意这个方案**，我将：

1. **创建** `scripts/validate-docs.ps1`（5 条校验规则）
2. **创建** `.templates/` 目录（3 个模板文件）
3. **迁移** P0 的 3 个核心文件（status/discoveries/AGENTS）
4. **集成** 到 auto-cleanup 工作流
5. **输出** 第一份文档质量报告

**预计总耗时**: 3-4 小时
**长期收益**: **永远告别"随意塞入"，建立可持续的文档架构** 🏗️
