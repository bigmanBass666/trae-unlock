---
name: develop-patch
description: >
  接收问题报告或需求，在 definitions.json 中创建或更新补丁。
  当用户说"开发补丁""修复 XX""添加 XX 功能""更新补丁"时使用。
  当需要修改 definitions.json、apply-patches、验证补丁时使用。
---

# 补丁开发 Skill

## When（触发条件）

**使用**：
- 用户提供 console 日志/错误描述，需要诊断并修复
- 用户要求开发新补丁
- 用户要求更新已有补丁（版本适配）
- 用户要求优化补丁性能

**不使用**：
- 用户只要求探索源码（→ explore-source）
- 用户只要求验证补丁（→ verify-patch）
- 用户要求写需求文档（→ spec-rfc）

## Input（输入）

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| problem | string | 是 | 问题描述（日志/错误/需求） |
| patch_id | string | 否 | 补丁 ID（更新时必填） |
| injection_point | string | 否 | 注入点偏移量 |
| layer | enum | 否 | 补丁层级：L1(React)/L2(Service)/L3(Data) |
| approach | enum | 否 | 方案选择：conservative\|aggressive\|experimental |

## Output（输出）

| 字段 | 类型 | 说明 |
|------|------|------|
| patch_definition | object | 补丁定义（anchor/replace_with/fingerprint） |
| apply_result | object | 应用结果（成功/失败/警告） |
| verify_result | object | 验证结果（fingerprint 匹配/不匹配） |
| risk_assessment | object | 风险评估（层级/影响范围/回滚方案） |

## Steps（执行步骤）

1. 读取 `shared/discoveries.md` 检索已有发现（遵循 L0-005）
2. 读取 `shared/failure-modes.md` 避免已知陷阱
3. 读取 `patches/definitions.json` 检查是否已有相关补丁
4. 诊断根因（遵循 L2-007 假设优先搜索法）
5. 选择注入点（遵循 L1-003 服务层优先原则）
6. 编写补丁代码（遵循 L1-001 箭头函数规则）
7. 更新 `patches/definitions.json`
8. 运行 `scripts/core/apply-patches.ps1`
9. 运行 `scripts/core/verify.ps1`
10. 更新 `shared/status.md` 和 `shared/handoff-developer.md`

## Failure Strategies（失败策略）

| 失败场景 | 处理方式 |
|----------|----------|
| anchor 匹配失败 | 尝试 fuzzy 匹配或扩大搜索范围 |
| apply 失败 | rollback 并检查 find_original 是否过时 |
| verify 失败 | 检查 fingerprint 是否匹配，可能需要重新定位 |
| 补丁冲突 | 检查是否有其他补丁修改了同一区域 |
| 后台冻结 | L1 补丁切窗口后失效，需迁移到 L2 |

## Quality Standards（质量标准）

- 补丁必须使用箭头函数（L1-001）
- anchor 长度 20-50 字符，必须唯一
- 必须包含 check_fingerprint
- 必须标注层级（L1/L2/L3）和风险等级
- apply 后必须 verify
