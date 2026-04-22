# 知识系统重构 Spec — 从"写了但没用"到"不用想就能用"

## Why

会话 #23 暴露了一个系统性问题：**我们写了大量规则和知识沉淀，但 AI 在实际工作中没有利用它们。**

具体表现：
- rule-005（搜索优先）、rule-011（假设优先搜索）都写了"先搜再动手"，但 AI 直接开调查
- `discoveries.md` 有 38 个发现条目、涵盖 ec() 分析/暂停按钮/错误码分类等，但 AI 重新做了全部
- **写了一条新规则(rule-014)来补救旧规则没被遵守的问题** — 这本身就在证明"写规则"这条路有天花板

**根因分析**：

```
问题层级:
  L1 表象: AI 没遵守规则
  L2 原因: 规则是文档，依赖"读后自觉执行"
  L3 根因: 知识组织形式不适合快速检索和使用
    → discoveries.md 是时间线格式，靠 Grep 碰运气
    → AGENTS.md ~200 行信息过载，重点被淹没
    → 没有任何机制在"正确的时间"把"正确的知识"推给 AI
```

**类比**: 这就像一个图书馆只有按时间排序的入库日志，没有分类索引、没有目录、没有推荐系统。读者要找一本关于"resumeChat 为什么不工作"的书，只能从第一页翻到最后一页。

## What Changes

### 改动 1: discoveries.md 新增结构化索引（**BREAKING** 格式变更）

在现有时间线内容**末尾**追加三个查询索引，不影响已有内容：

```markdown
---
# 🔍 知识索引

## 按函数/API 索引
| 函数/API | 已知行为 | 相关发现 | 关键决策 |
|----------|---------|---------|---------|
| D.resumeChat() | no-op: 被调用但不抛异常也不产生效果 | #v7-debug | v7: 加2秒监控fallback |
| ec() | 有 `"v3"===p && efg.includes(_)` 双重条件 | #pause-button | 手动点击失败根因 |
| D.sendChatMessage() | 可靠的 fallback 方案 | #v7 | resumeChat 无效时的替代 |
| ... | ... | ... | ... |

## 按错误码/现象索引
| 错误码/现象 | 已知行为 | 处理方式 | 补丁 |
|------------|---------|---------|------|
| repeated tool call | J+efg覆盖, resumeChat无效 | sendChatMessage fallback | auto-continue v7 |
| 循环检测(4000009) | J+efg覆盖 | 同上 | 同上 |
| DEFAULT(2000000) | 二次覆盖需入J | bypass-loop-detection v4 | v4 |
| 聊天界面消失 | Trae更新还原+语法错误 | diagnose-patch-health.ps1 | crash-prevention |
| ... | ... | ... | ... |

## 按补丁索引
| 补丁名 | 当前版本 | 状态 | 最后修改原因 |
|-------|---------|------|------------|
| auto-continue-thinking | v7 | ⚠️ 待验证 | resumeChat no-op |
| data-source-auto-confirm | v3 | ✅ 稳定 | - |
| ... | ... | ... | ... |
```

### 改动 2: AGENTS.md 瘦身为路由表

将当前 ~200 行的 AGENTS.md 精简为 ~50 行的路由表，详细内容分流到各模块：

```markdown
# AGENTS.md (~50行)
## Anchor 系统
→ shared/_registry.md (完整模块列表和写入规范)

## 会话开始必做
1. 读 _registry.md → 按 P0/P1/P2 读取所需模块
2. 运行补丁自检: powershell scripts/auto-heal.ps1 -DiagnoseOnly

## 工作流核心规则
→ shared/rules.md (完整 14 条规则)

## 方法论速查
→ shared/discoveries.md (末尾含 🔍 知识索引)

## 安全网
→ shared/status.md (安全状态仪表盘)
```

### 改动 3: 创建 `shared/diagnosis-playbook.md` 诊断操作手册

新建文件，作为 rule-014 的**可执行操作手册**（不是规则文本，而是步骤化流程）：

```markdown
# 诊断操作手册

## 场景 A: 补丁失效/界面异常
Step 1: 运行 diagnose-patch-health.ps1 → 获取健康评分
Step 2: 如果评分 < 30 → 从备份恢复 → apply-patches
Step 3: 如果评分 30-70 → 搜索 discoveries.md 索引中的相关函数/现象
Step 4: 基于发现构建假设 → 验证 → 修复

## 场景 B: auto-continue-thinking 不工作
Step 1: 搜索 discoveries.md "resumeChat" / "ec()" / "暂停按钮"
Step 2: 已知: resumeChat 可能是 no-op, ec() 有 v3 条件限制
Step 3: 检查控制台 [v7] 日志确认当前失败点
Step 4: 按 v7 fallback 链路排查
...
```

## Impact

- Affected files: shared/discoveries.md (追加索引), AGENTS.md (精简), shared/diagnosis-playbook.md (新建), shared/_registry.md (可能微调)
- Affected agents: 所有未来 AI 会话（知识获取方式改变）
- Affected specs: 无（这是基础设施改进）
- **BREAKING**: discoveries.md 格式扩展（追加非破坏）

## ADDED Requirements

### Requirement: discoveries 必须包含三维度索引

discoveries.md 文件末尾必须包含按函数/API、错误码/现象、补丁名三个维度组织的索引表。

#### Scenario: AI 需要查找 resumeChat 相关知识

- **WHEN** AI 在诊断中遇到 resumeChat 相关问题
- **THEN** 在 discoveries.md 的"按函数/API 索引"表中能找到所有相关条目
- **AND** 每个条目包含：已知行为摘要、相关发现编号、关键决策引用

### Requirement: AGENTS.md 精简为路由表

AGENTS.md SHALL 只包含路由指引和最高优先级操作，不超过 60 行。详细内容通过链接指向各共享模块。

#### Scenario: 新 AI 会话启动时读取 AGENTS.md

- **WHEN** AI 首次读取 AGENTS.md
- **THEN** 能在 10 秒内理解整个系统的入口点和关键路径
- **AND** 不需要阅读超过 60 行文字

### Requirement: diagnosis-playbook.md 提供场景化操作步骤

新建的 diagnosis-playbook.md SHALL 按常见诊断场景组织，每个场景包含明确的 Step-by-step 操作。

#### Scenario: AI 遇到"聊天界面消失"

- **WHEN** AI 打开 diagnosis-playbook.md 搜索"界面消失"或"崩溃"
- **THEN** 找到对应场景的操作步骤
- **AND** 第一步就是运行 diagnose-patch-health.ps1（不是去猜）

## MODIFIED Requirements

### Requirement: _registry.md 模块注册表

在现有模块列表中新增 `diagnosis-playbook.md` 条目，描述其用途和适用场景。

### Requirement: rules.md 自动重新生成

rules/workflow.yaml 变更后需重新生成 shared/rules.md。
