# 补丁自愈系统 Spec

## Why

Trae 更新后补丁静默失效，用户遇到问题才发现。现有 `verify.ps1` 只检测不修复，`apply-patches.ps1` 不处理模式变化且静默跳过失败补丁。需要一个自动化的"检测→诊断→修复"闭环脚本。

## What Changes

- **新增 `scripts/auto-heal.ps1`**: 四步闭环自愈脚本（验证→诊断→修复→再验证）
- **修改 `AGENTS.md`**: 添加 AI 会话自检规则（每次会话先运行 auto-heal）
- **修改 `scripts/verify.ps1`**: 输出结构化 JSON 供 auto-heal 消费

## Impact

- Affected code: `scripts/auto-heal.ps1`（新增）、`scripts/verify.ps1`（小幅修改）、`AGENTS.md`（添加规则）
- Affected specs: 无破坏性变更，verify.ps1 保持向后兼容

## ADDED Requirements

### Requirement: auto-heal 四步闭环

系统 SHALL 提供 `auto-heal.ps1` 脚本，执行以下四步闭环：

#### Scenario: 全部补丁通过，无需修复
- **WHEN** 运行 `auto-heal.ps1`
- **AND** 所有补丁指纹验证通过
- **THEN** 输出 "All N patches verified ✅" 并以 exit code 0 退出

#### Scenario: 补丁失效但代码未变，自动修复
- **WHEN** 运行 `auto-heal.ps1`
- **AND** 某补丁指纹未找到
- **AND** 该补丁的 find_original 在文件中存在（偏移漂移）
- **THEN** 自动重新 apply 该补丁，更新 offset_hint，输出修复报告

#### Scenario: 补丁失效且代码已变，生成诊断报告
- **WHEN** 运行 `auto-heal.ps1`
- **AND** 某补丁指纹未找到
- **AND** 该补丁的 find_original 也不存在
- **THEN** 用 find_original 前 30 字符做模糊搜索
- **AND** 输出诊断信息：搜索结果、上下文片段、建议操作
- **AND** 以 exit code 1 退出

### Requirement: 诊断输出格式

auto-heal SHALL 为每个失败补丁输出结构化诊断信息：

```
[DIAGNOSE] <patch-id> (<patch-name>)
  Expected offset: ~XXXXXXX
  Fingerprint: NOT FOUND
  find_original: FOUND at YYYY / NOT FOUND
  Fuzzy search: FOUND at ZZZZ / NOT FOUND
  Context: ...<50 chars>...
  Action: AUTO-FIX / MANUAL-NEEDED
```

### Requirement: -DiagnoseOnly 模式

`auto-heal.ps1 -DiagnoseOnly` SHALL 只执行 Step 1 + Step 2，不修改任何文件。

### Requirement: definitions.json 偏移自动更新

auto-heal 修复补丁后 SHALL 自动更新 `definitions.json` 中对应补丁的 `offset_hint` 为实际偏移值（加 `~` 前缀）。

### Requirement: AI 会话自检协议

AGENTS.md SHALL 添加规则：AI 每次新会话开始时，先运行 `auto-heal.ps1 -DiagnoseOnly` 检查补丁状态。如果有失败项，立即执行修复流程。

## MODIFIED Requirements

### Requirement: verify.ps1 输出

verify.ps1 SHALL 在末尾输出一行 JSON 摘要，供 auto-heal 解析：
```json
{"active":5,"inactive":0,"unknown":2,"failed_ids":["bypass-loop-detection","efh-resume-list"]}
```

## REMOVED Requirements

无。
