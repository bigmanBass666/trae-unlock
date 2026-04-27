---
name: spec-rfc
description: >
  需求工程：从一句话需求到高质量交付。
  当用户说"我想做 XX""帮我规划一下""写个需求""设计一下"时使用。
  当需要将模糊需求转化为清晰技术方案时使用。
---

# 需求工程 Skill（Spec-RFC）

## When（触发条件）

**使用**：
- 用户提出新需求（一句话或一段描述）
- 需要将模糊需求转化为清晰技术方案
- 需要评估需求可行性和影响范围
- 需要制定开发计划

**不使用**：
- 用户要求直接修改代码（→ develop-patch）
- 用户要求探索源码（→ explore-source）
- 需求已经明确，只需执行

## Input（输入）

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| requirement | string | 是 | 用户需求描述 |
| context | string | 否 | 补充上下文（背景/约束/偏好） |
| priority | enum | 否 | 优先级：high\|medium\|low |
| scope | enum | 否 | 范围：patch\|feature\|refactor |

## Output（输出）

| 字段 | 类型 | 说明 |
|------|------|------|
| spec | object | 需求规格（Why/What/Impact/Requirements） |
| rfc | object | 技术方案（方案选择/实现细节/风险评估） |
| tasks | array | 任务分解（有序、可验证、有依赖关系） |
| checklist | array | 验证清单 |

## Steps（执行步骤）

1. **需求获取** — 理解用户真实意图（而非字面要求）
2. **需求分析** — 检索 `skills/_index.md` 和 `shared/discoveries.md` 评估可行性
3. **需求规格** — 生成 spec.md（Why/What/Impact/ADDED/MODIFIED/REMOVED Requirements）
4. **技术设计(RFC)** — 生成技术方案，包含方案选择和风险评估
5. **验证** — 与用户确认规格和技术方案后再进入开发

**关键规则**：
- 用用户的语言输出
- 必须按顺序执行，不可跳步
- 先分析已提供的任务信息，再进行代码探索
- 使用 finish 在开发前暂停等待用户确认
- 开发过程中绝不暂停

## Failure Strategies（失败策略）

| 失败场景 | 处理方式 |
|----------|----------|
| 需求不明确 | 向用户提问澄清，列出 2-4 个理解选项 |
| 技术不可行 | 报告限制，提供替代方案 |
| 影响范围过大 | 拆分为多个迭代，先做核心功能 |
| 与现有补丁冲突 | 标注冲突点，建议合并或重构 |
| 用户否决方案 | 回到需求分析阶段，重新理解意图 |

## Quality Standards（质量标准）

- Spec 必须包含 Why/What/Impact 三个维度
- RFC 必须包含至少 2 个方案对比
- 任务分解必须有序、可验证、有依赖标注
- 验证清单必须覆盖所有需求场景
