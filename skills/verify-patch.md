---
name: verify-patch
description: >
  验证补丁正确应用且不引入新问题。
  当用户说"验证补丁""测试补丁""检查补丁状态"时使用。
  当需要运行 apply+verify 流程、检查健康度时使用。
---

# 补丁验证 Skill

## When（触发条件）

**使用**：
- 用户要求验证补丁是否生效
- 补丁应用后需要确认
- Trae 更新后需要重新验证
- 定期健康检查

**不使用**：
- 用户要求开发新补丁（→ develop-patch）
- 用户要求探索源码（→ explore-source）

## Input（输入）

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| patch_ids | array | 否 | 要验证的补丁 ID 列表（空=全部） |
| verify_depth | enum | 否 | 验证深度：fingerprint\|functional\|e2e（默认 fingerprint） |
| auto_heal | boolean | 否 | 是否自动修复问题（默认 true） |

## Output（输出）

| 字段 | 类型 | 说明 |
|------|------|------|
| results | array | 每个补丁的验证结果 |
| health_score | number | 整体健康度评分（0-100） |
| issues | array | 发现的问题列表 |
| fixes_applied | array | 自动修复的问题列表 |

## Steps（执行步骤）

1. 读取 `patches/definitions.json` 获取补丁列表
2. 读取 `shared/status.md` 获取当前状态
3. 运行 `scripts/core/verify.ps1` 检查 fingerprint
4. 如有失败，运行 `scripts/core/auto-heal.ps1 -DiagnoseOnly`
5. 如 auto_heal=true，运行 `scripts/core/auto-heal.ps1` 自动修复
6. 检查目标文件语法（无断行/括号不匹配）
7. 更新 `shared/status.md` 验证结果
8. 如有新发现，更新 `shared/discoveries.md`

## Failure Strategies（失败策略）

| 失败场景 | 处理方式 |
|----------|----------|
| fingerprint 不匹配 | 报告偏移量漂移，建议 remeasure-anchors |
| 语法错误 | rollback 问题补丁，报告错误位置 |
| 补丁冲突 | 按优先级排序，逐个应用并验证 |
| auto-heal 失败 | 报告给用户，建议手动干预 |
| 目标文件不存在 | 检查路径配置，可能需要 unpack |

## Quality Standards（质量标准）

- 验证结果必须包含每个补丁的状态
- 健康度评分必须基于客观数据
- 自动修复必须记录修复内容
- 所有失败必须有可操作的后续步骤
