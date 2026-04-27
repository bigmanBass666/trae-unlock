---
name: explore-source
description: >
  在 ~10MB 压缩 JS 源码中进行系统性、可重复、可验证的代码测绘。
  当用户说"探索源码""找到 XX 功能在哪""测绘 XX 域""搜索 XX 代码"时使用。
  当需要定位代码位置、验证偏移量、评估补丁可行性时使用。
---

# 源码探索 Skill

## When（触发条件）

**使用**：
- 用户要求探索/搜索/定位源码中的功能
- 需要验证已知偏移量是否漂移
- 需要评估新补丁的可行性
- 需要发现未知代码域

**不使用**：
- 用户要求开发/修改补丁（→ develop-patch）
- 用户要求验证补丁是否生效（→ verify-patch）
- 用户要求写需求文档（→ spec-rfc）

## Input（输入）

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| target | string | 是 | 探索目标（域名/功能名/代码特征） |
| search_method | enum | 否 | 搜索方法：ast\|text\|offset\|hybrid（默认 hybrid） |
| depth | enum | 否 | 探索深度：scan\|deep\|exhaustive（默认 deep） |
| verify_existing | boolean | 否 | 是否验证已有发现（默认 true） |

## Output（输出）

| 字段 | 类型 | 说明 |
|------|------|------|
| findings | array | 发现列表（位置+描述+置信度） |
| search_templates | array | 可复用搜索模板（关键词+稳定性评级） |
| offset_map | object | 偏移量映射（旧→新，含漂移量） |
| blindspots | array | 未覆盖区域列表 |
| patch_candidates | array | 补丁候选点（位置+可行性+风险） |

## Steps（执行步骤）

1. 读取 `skills/_index.md` 匹配目标到已有知识
2. 读取 `shared/discoveries.md` 中相关域的已有发现
3. 读取 `shared/failure-modes.md` 避免已知陷阱
4. 列出 2-4 个假设（遵循 L2-007 假设优先搜索法）
5. 按假设顺序执行搜索（PowerShell 子串 / ast-search.ps1）
6. 验证已有偏移量是否漂移（如 verify_existing=true）
7. 记录发现到 `shared/discoveries.md`（追加，不重写）
8. 更新 `shared/handoff-explorer.md`
9. 更新 `shared/status.md` 会话日志

## Failure Strategies（失败策略）

| 失败场景 | 处理方式 |
|----------|----------|
| 搜索无结果 | 扩大搜索范围或换搜索方法（text→ast→offset） |
| 偏移量漂移 >5000 | 标注为高风险，建议 Developer 重新验证 fingerprint |
| 多个匹配点 | 结合 offset_hint 选择最接近的，记录所有候选 |
| 源码版本变更 | 运行 remeasure-anchors.ps1 全量重测 |
| 上下文窗口不足 | 只记录索引条目，详情留待下次会话 |

## Quality Standards（质量标准）

- 每个发现必须包含偏移量 + 描述 + 置信度（⭐1-5）
- 搜索模板必须标注稳定性评级
- 偏移量漂移必须记录变化量
- 盲区必须标注优先级（P0/P1/P2）
