---
domain: architecture
sub_domain: permission
focus: 商业权限域——ICommercialPermissionService 6方法、用户身份枚举（bJ）、配额限制机制和补丁候选分析
dependencies: [model-domain.md, limitation-map.md, store-architecture.md]
consumers: Developer, Reviewer
created: 2026-04-26
updated: 2026-04-26
format: reference
---

# 商业权限域架构文档

> Trae AI 聊天模块中商业权限判断系统的完整逆向工程

> last_verified: 2026-04-26 | 兼容版本: Trae v3.3.x (10490721 chars)

## §1 概述

> **定位**: 商业权限域——用户身份判断、配额控制和功能访问限制的完整逆向工程
>
> **为什么重要**: ICommercialPermissionService 的 6 个方法控制免费/付费/内部用户的权限边界，是 bypass-usage-limit 和 bypass-premium-model-notice 补丁的目标域。
>
> **在整体中的位置**: 被 Model 域（model-domain）调用以判断模式限制，被 Limitation Map（limitation-map）引用以解释 4008/4009 错误码，依赖 Store 架构（store-architecture）的数据源。

### 核心架构特征

| 维度 | 描述 |
|------|------|
| 判断层级 | 服务层（NS 类方法） → React 层（efi Hook 计算派生状态） |
| 数据来源 | IEntitlementStore（订阅信息）+ ICredentialStore（凭证信息） |
| 判断方式 | 枚举值比对（bJ identity）+ 布尔方法返回值 |
| 限制执行 | 错误码阻断（4008/4009/700）+ UI 提示（Alert 渲染点） |

## 2. 核心实体

### 2.1 服务/Store 一览

| 实体 | 混淆名 | DI Token | Token 类型 | 偏移量 | 职责 |
|------|--------|----------|-----------|--------|------|
| ICommercialPermissionService | NS | `Il` = aiAgent.ICommercialPermissionService (aiAgent.命名空间前缀, @7197027) | aiAgent.前缀 | ~7267682 | 商业权限判断（6个方法） |
| IEntitlementStore | Nu | `Nc` = Symbol("IEntitlementStore") | Symbol | ~7259427 | 订阅/权益数据存储 |
| ICredentialStore | MX | (推断 Symbol("ICredentialStore")) | Symbol | ~7154491 | 凭证/用户信息存储 |

### 2.2 ICommercialPermissionService (NS) 方法表

| 方法 | 返回类型 | 推断逻辑 | 补丁可行性 |
|------|---------|---------|-----------|
| `isDollarUsageBilling()` | boolean | 判断是否按美元计费 | ⭐⭐⭐⭐⭐ 直接返回 false |
| `isCommercialUser()` | boolean | 判断是否为付费用户 | ⭐⭐⭐⭐⭐ 直接返回 true |
| `isOlderCommercialUser()` | boolean | 判断是否为老付费用户 | ⭐⭐⭐⭐⭐ 直接返回 true |
| `isNewerCommercialUser()` | boolean | 判断是否为新付费用户 | ⭐⭐⭐⭐⭐ 直接返回 true |
| `isSaas()` | boolean | 判断是否为 SaaS 用户 | ⭐⭐⭐⭐⭐ 直接返回 true |
| `isInternal()` | boolean | 判断是否为内部用户 | ⭐⭐⭐ 视需求返回 |

> **关键发现**: NS 类**没有** `isFreeUser()` 方法。`isFreeUser` 是在 React Hook `efi()` @8687513 中通过 `!entitlementInfo?.identity` 计算的派生状态，不属于服务层方法。

### 2.3 IEntitlementStore (Nu) 状态结构

```javascript
{
  entitlementInfo: {
    identity: bJ.Free | bJ.Pro | bJ.ProPlus | bJ.Ultra | bJ.Trial | bJ.Lite | bJ.Express,
    // ... 其他订阅信息字段
  },
  saasEntitlementInfo: {
    // SaaS 相关权益信息
  }
}
```

### 2.4 bJ 枚举（用户身份类型）@6479431

| 枚举值 | 数值 | 含义 | 权限等级 |
|--------|------|------|---------|
| Free | 0 | 免费用户 | 最低 |
| Pro | 1 | Pro 付费用户 | 标准 |
| ProPlus | 2 | ProPlus 付费用户 | 增强 |
| Ultra | 3 | Ultra 付费用户 | 最高 |
| Trial | 4 | 试用用户 | 临时 |
| Lite | 5 | Lite 用户 | 受限 |
| Express | 100 | Express 用户 | 特殊 |

### 2.5 kG 枚举（模式类型）@7185314

| 枚举值 | 含义 | 权限要求 |
|--------|------|---------|
| Manual | 手动模式 | 免费可用 |
| Auto | 自动模式 | 需付费 |
| Max | 最大模式 | 需高级付费 |

## 3. 数据流

### 3.1 权限判断服务链

```
┌─────────────────────────────────────────────────────────────────┐
│                    DI Container (uj)                             │
│                                                                  │
│  ┌──────────────────┐     ┌──────────────────┐                  │
│  │ IEntitlementStore│     │ ICredentialStore │                  │
│  │      (Nu)        │     │      (MX)        │                  │
│  │  @7259427        │     │  @7154491        │                  │
│  │                  │     │                  │                  │
│  │ entitlementInfo  │     │ credential data  │                  │
│  │  .identity (bJ)  │     │                  │                  │
│  └────────┬─────────┘     └────────┬─────────┘                  │
│           │                        │                             │
│           │    读取数据             │  读取数据                    │
│           ▼                        ▼                             │
│  ┌──────────────────────────────────────────┐                   │
│  │    ICommercialPermissionService (NS)      │                   │
│  │              @7267682                     │                   │
│  │                                           │                   │
│  │  isCommercialUser()    ──→ boolean        │                   │
│  │  isOlderCommercialUser()──→ boolean       │                   │
│  │  isNewerCommercialUser()──→ boolean       │                   │
│  │  isDollarUsageBilling()──→ boolean        │                   │
│  │  isSaas()              ──→ boolean        │                   │
│  │  isInternal()          ──→ boolean        │                   │
│  └──────────────────┬───────────────────────┘                   │
│                     │                                            │
│                     │ 方法返回值被以下消费者使用                    │
│                     ▼                                            │
│  ┌──────────────────────────────────────────┐                   │
│  │  React Hook efi() @8687513               │                   │
│  │                                           │                   │
│  │  isFreeUser = !entitlementInfo?.identity  │                   │
│  │  (派生计算，非 NS 类方法)                   │                   │
│  └──────────────────┬───────────────────────┘                   │
│                     │                                            │
│                     ▼                                            │
│  ┌──────────────────────────────────────────┐                   │
│  │  UI 组件 / Alert 渲染 / 错误码阻断         │                   │
│  │                                           │                   │
│  │  · 配额限制提示 (4008/4009)               │                   │
│  │  · 模型访问限制 (CLAUDE_MODEL_FORBIDDEN)  │                   │
│  │  · 模式限制 (Manual/Auto/Max)             │                   │
│  │  · 免费用户模型通知                        │                   │
│  └──────────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 配额限制判断流

```
SSE 流返回错误码 (kg)
       │
       ▼
ee = !![kg.PREMIUM_MODE_USAGE_LIMIT, kg.STANDARD_MODE_USAGE_LIMIT].includes(_)
       │                                    @8707858
       │
       ├── ee = true (4008 或 4009)
       │       │
       │       ▼
       │   efr 枚举判断免费用户配额状态 @55561 (ContactType, 30+ quota states)
       │       │
       │       ▼
       │   Alert 渲染: 配额限制提示
       │
       └── ee = false (其他错误码)
               │
               ▼
           正常错误处理流程
```

### 3.3 模式选择流

```
computeSelectedModelAndMode @7215828
       │
       ├── 读取 kG 枚举 (Manual/Auto/Max)
       │
       ├── 调用 NS.isCommercialUser() 等方法
       │
       ├── 判断用户是否有权使用 Auto/Max 模式
       │
       └── 返回 { model, mode } 或触发限制
```

## 4. 跨域关系

### 4.1 与 SSE 管道域的关系

| 交互点 | 描述 |
|--------|------|
| ErrorStreamParser (zU) | 解析 4008/4009/700 错误码，触发配额限制提示 |
| PlanItemStreamParser | 确认逻辑中可能读取权限状态 |
| Alert 渲染点 @8700000-8930000 | 根据权限状态渲染不同提示（CLAUDE_MODEL_FORBIDDEN、PREMIUM_USAGE_LIMIT 等） |

### 4.2 与 Store 域的关系

| 交互点 | 描述 |
|--------|------|
| EntitlementStore (Nu) | NS 类的直接数据源，提供 identity 字段 |
| SessionStore (xI) | 会话中可能缓存权限状态 |
| ModelStore (k2) | 模型配置受权限影响 |

### 4.3 与命令确认域的关系

| 交互点 | 描述 |
|--------|------|
| BlockLevel 判定 | 企业策略（Blacklist）可能受商业权限影响 |
| AutoRunMode | 不同权限等级可能有不同的默认运行模式 |

### 4.4 与 DI 容器域的关系

| 交互点 | 描述 |
|--------|------|
| Token 注册 | Il (aiAgent.前缀)、Nc (Symbol)、MX (Symbol) 均在 DI 容器注册 |
| 服务注入 | NS 通过 uX(Il) 注入到消费者类中 |
| Symbol 迁移 | IEntitlementStore 和 ICredentialStore 已迁移到 Symbol（非 Symbol.for） |

## 5. 补丁相关性

### 5.1 补丁候选清单

| # | 补丁名 | 推荐度 | 目标 | 原理 | 可行性 |
|---|--------|-------|------|------|--------|
| 1 | bypass-commercial-permission | ★★★★★ | NS 类方法返回值 | 修改 isCommercialUser 等方法直接返回 true/false | ⭐⭐⭐⭐⭐ 服务层修改，不受 React 冻结影响 |
| 2 | bypass-usage-limit | ★★★★ | ee 变量 @8707858 | 将 ee 强制设为 false，跳过配额限制判断 | ⭐⭐⭐⭐ 单点修改，但可能被其他逻辑覆盖 |
| 3 | bypass-firewall-blocked | ★★ | 网络层 700 错误 | 前端无法绕过网络层防火墙拦截 | ⭐ 不可行，服务端限制 |
| 4 | bypass-claude-model-forbidden | ★★★★ | CLAUDE_MODEL_FORBIDDEN Alert | 修改模型访问限制逻辑 | ⭐⭐⭐⭐ 需定位具体判断点 |
| 5 | force-max-mode | ★★★ | computeSelectedModelAndMode @7215828 | 强制返回 Max 模式 | ⭐⭐⭐ 可能触发服务端校验 |
| 6 | bypass-free-user-model-notice | ★★★ | 免费用户模型限制通知 | 修改 efi() Hook 中的 isFreeUser 计算 | ⭐⭐⭐ React 层修改，受窗口冻结影响 |

### 5.2 推荐实施顺序

```
1. bypass-commercial-permission (★★★★★)
   │  修改 NS 类 6 个方法 → 从根源解决权限判断
   │  所有下游限制（配额/模式/模型）均依赖此服务
   │
   ▼
2. bypass-usage-limit (★★★★)
   │  修改 ee 变量 → 消除配额限制提示
   │  作为第 1 步的补充保险
   │
   ▼
3. bypass-claude-model-forbidden (★★★★)
   │  修改模型访问限制 → 解锁 Claude 模型
   │  独立于权限判断的模型级限制
   │
   ▼
4. force-max-mode (★★★)
   │  修改模式选择 → 强制 Max 模式
   │  需配合第 1 步，否则服务端可能拒绝
   │
   ▼
5. bypass-free-user-model-notice (★★★)
      修改 UI 通知 → 消除免费用户提示
      纯 UI 层，优先级最低
```

### 5.3 不可行补丁

| 补丁 | 原因 |
|------|------|
| bypass-firewall-blocked | 700 错误码由网络层/服务端防火墙产生，前端无法绕过。即使前端忽略此错误，服务端已拒绝请求，无法恢复。 |

## 6. 搜索模板

### COM-01: 定位 ICommercialPermissionService

```
搜索词: aiAgent.ICommercialPermissionService
层级: L0 IndexOf
稳定性: ⭐⭐⭐⭐⭐ (aiAgent.命名空间前缀，全局唯一)
预期: 找到 DI Token Il 定义 + NS 类注册点 (@7197027)
注意: 该服务使用 aiAgent. 命名空间前缀注册，非 Symbol.for() 或 Symbol()
```

### COM-02: 定位 NS 类方法

```
搜索词: isCommercialUser
层级: L1 AST 搜索
稳定性: ⭐⭐⭐⭐ (方法名未混淆)
预期: 找到 NS 类定义 + 所有调用点
注意: isFreeUser 不在 NS 类中，在 efi() Hook 中
```

### COM-03: 定位 IEntitlementStore

```
搜索词: Symbol("IEntitlementStore")
层级: L0 IndexOf
稳定性: ⭐⭐⭐⭐ (Symbol 字符串稳定)
预期: 找到 DI Token Nc 定义 + Nu Store 注册点
```

### COM-04: 定位配额限制标志

```
搜索词: PREMIUM_MODE_USAGE_LIMIT
层级: L0 IndexOf
稳定性: ⭐⭐⭐ (枚举名未混淆但偏移可能变化)
预期: 找到 ee 变量定义 @8707858 + kg 错误码枚举
```

### COM-05: 定位免费用户判断

```
搜索词: entitlementInfo?.identity
层级: L1 AST 搜索
稳定性: ⭐⭐⭐ (属性名可能变化)
预期: 找到 efi() Hook @8687513 + isFreeUser 计算逻辑
```

## 7. 盲区

| # | 盲区 | 影响 | 探索建议 |
|---|------|------|---------|
| 1 | NS 类 6 个方法的完整实现代码 | 无法确定每个方法具体读取哪些字段、如何计算返回值 | AST 搜索 NS 类定义，提取方法体 |
| 2 | ICredentialStore 的完整状态结构 | 不清楚凭证数据包含哪些字段，如何影响权限判断 | AST 搜索 MX 类定义 |
| 3 | efr 枚举/ContactType（免费用户配额状态）的完整值 | 只知道偏移量 @55561 (ContactType, 30+ quota states)，不知道具体枚举值和含义 | L1 AST 搜索 efr/ContactType 定义 |
| 4 | computeSelectedModelAndMode 的完整逻辑 | 只知道偏移量 @7215828，不知道模式选择的完整分支 | AST 搜索方法定义 |
| 5 | 服务端校验机制 | 前端绕过后服务端是否二次校验，返回什么错误 | 需实际测试验证 |
| 6 | saasEntitlementInfo 的完整结构 | 只知道存在此字段，不知道具体内容和使用场景 | AST 搜索 Nu Store 定义 |
| 7 | 权限状态变更的实时更新机制 | 权限变更（如订阅过期）如何通知前端更新 | 搜索 subscribe/轮询逻辑 |

## 8. 错误码纠正

v2 探索发现 v1 记录中的部分错误码有误，以下为纠正后的正确值：

| 错误码 | 枚举名 | v1 错误值 | v2 正确值 | 验证依据 |
|--------|--------|----------|----------|---------|
| PREMIUM_MODE_USAGE_LIMIT | kg.PREMIUM_MODE_USAGE_LIMIT | 1016 | **4008** | kg 枚举定义 @54000 + Alert 渲染点 @8707858 |
| STANDARD_MODE_USAGE_LIMIT | kg.STANDARD_MODE_USAGE_LIMIT | 1017 | **4009** | kg 枚举定义 @54000 + Alert 渲染点 @8707858 |
| FIREWALL_BLOCKED | kg.FIREWALL_BLOCKED | 1023 | **700** | Alert 渲染点 @8705889 |

> **影响范围**: 所有引用 1016/1017/1023 错误码的补丁定义和文档均需更新为 4008/4009/700。

## 9. P0 新发现与跨域关联

| 发现 | 偏移量 | 与商业权限域的关系 | 重要性 |
|------|--------|-------------------|--------|
| ContactType 枚举 | @55561 | 30+ 配额状态枚举，直接影响 efr 配额判断逻辑 | ⭐⭐⭐⭐⭐ |
| ChatError 枚举 | @54993 | 聊天错误码补充枚举，可能包含权限相关错误码 | ⭐⭐⭐⭐ |
| API endpoints config | @5870417 | API 端点配置，包含权限验证接口地址 | ⭐⭐⭐⭐ |
| computeSelectedModelAndMode | @7215828 | Model 域核心，受商业权限影响（Auto/Max 模式需付费） | ⭐⭐⭐⭐⭐ |
