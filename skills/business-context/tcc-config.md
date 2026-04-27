---
name: tcc-config-driven-behavior
description: 通过 TCC 配置中心控制功能开关、降级和灰度策略的行为
layer: business-context
---

# TCC 配置驱动行为

> 代码可读 ≠ 业务理解。本文件记录代码中"看不见"的配置驱动逻辑。

## 核心概念

Trae IDE 的许多行为不是硬编码的，而是通过 TCC（Tag-based Configuration Center）动态控制的。这意味着：
- 同一份代码在不同用户/地区/版本下可能表现不同
- 代码中的条件分支可能由远程配置决定，而非本地逻辑
- 功能开关、降级策略、灰度发布都通过 TCC 控制

## 已知的 TCC 配置项

| 配置 Key | 位置 | 控制行为 |
|----------|------|----------|
| AI.toolcall.confirmMode | @7438613 | 命令确认模式（已改为纯配置驱动，ConfirmMode 枚举已移除） |
| AI.toolcall.v2.command.* | @7438600 | v2 命令配置 |
| chat.tools.* | @7438613 | 聊天工具设置（3个key） |
| GlobalAutoApprove | @7438613 | 全局自动批准 |
| force_close_auto | @7282952 | 强制关闭 Auto 模式 |
| autoDefaultConfig.forceAuto | — | 强制启用 Auto 模式 |

## 对补丁开发的影响

1. **配置驱动 ≠ 代码逻辑** — 修改代码逻辑可能被 TCC 配置覆盖
2. **服务层 > 配置层** — L2 服务层补丁不受 TCC 配置变化影响
3. **测试时注意** — 同一补丁在不同 TCC 配置下可能表现不同
4. **ConfirmMode 已移除** — 确认逻辑改为纯配置驱动，不再有枚举值

## 历史教训

- v8 补丁失败原因之一：假设 ConfirmMode 枚举存在，但实际已移除
- auto-continue-thinking 迭代 22 次：部分失败因未考虑 TCC 配置对行为的影响
