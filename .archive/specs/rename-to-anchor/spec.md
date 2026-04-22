# Anchor 命名统一 Spec

## Why

系统已正式命名为 **Anchor**，但现有文档中仍使用旧命名（"跨会话通信系统"、"动态规则系统"等），需要统一更新以避免混淆。

## What Changes

- 将所有作为**系统名称**出现的旧命名替换为 "Anchor"
- 不替换作为**功能描述**的"跨会话通信"、"规则引擎"等词汇
- 共 48 处替换，涉及 19 个文件

### 替换规则

| 旧命名（作为系统名） | 新命名 |
|---------------------|--------|
| 跨会话通信系统 | Anchor |
| 跨会话通信声明 | Anchor 声明 |
| 跨会话共享知识库 | Anchor 共享知识库 |
| 动态规则系统 | Anchor 规则子系统 |
| 动态规则遵守系统 | Anchor 规则子系统 |
| 跨会话 Agent 动态规则遵守系统 | Anchor 规则子系统 |
| 动态模块化通信系统 | Anchor 模块化通信系统 |

### 不替换的词汇（功能描述）

- "跨会话通信"（功能描述）
- "规则引擎"（组件功能描述）
- "跨会话系统"（功能描述）
- "跨会话协作"（功能描述）

## Impact

- Affected files: 19 个文件（AGENTS.md, shared/*.md, README.md, progress.txt, docs/, .trae/specs/）
- Affected specs: cross-session-communication, modular-communication-system, dynamic-agent-rules-system, ai-reference-doc

## ADDED Requirements

### Requirement: 命名统一

所有项目文档中作为系统名称出现的旧命名 SHALL 替换为 "Anchor" 及其衍生名称。

#### Scenario: AI 读取 AGENTS.md
- **WHEN** AI 读取 AGENTS.md
- **THEN** 看到系统名称为 "Anchor" 而非 "跨会话通信系统"

#### Scenario: AI 读取 shared/ 文件
- **WHEN** AI 读取 shared/_registry.md 或其他 shared/ 文件
- **THEN** 看到知识库名称为 "Anchor 共享知识库"

#### Scenario: 人类阅读 README.md
- **WHEN** 人类阅读 README.md
- **THEN** 看到系统名称为 "Anchor 规则子系统"

## MODIFIED Requirements

无

## REMOVED Requirements

无
