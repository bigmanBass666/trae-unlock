# Model 域架构文档

> Trae AI 聊天模块中模型选择与模式路由系统的完整逆向工程

> last_verified: 2026-04-26 | 兼容版本: Trae v3.3.x (10490721 chars)

## 1. 概述

Model 域是 Trae 控制 AI 模型选择、模式切换和付费限制的核心子系统。它决定了用户在聊天时使用哪个模型（GPT-5、Claude、Doubao 等）以及以什么模式运行（Manual/Auto/Max）。该域通过 DI 容器注入，形成从用户选择到模型路由到 API 调用的完整链路。

### 核心架构特征

| 维度 | 描述 |
|------|------|
| 决策层级 | 静态计算（`computeSelectedModelAndMode`） → 服务层（NR 方法） → React 层（Hook 消费） |
| 数据来源 | IModelStore（模型列表+模式列表）+ SessionRelationStore（会话/全局映射）+ IEntitlementStore（用户身份） |
| 模式控制 | kG 枚举（Manual=0/Auto=1/Max=2），商业用户强制 Max，免费用户限制 Manual |
| 付费限制 | 错误码阻断（4008/4009/4113）+ UI 提示（Max Mode 通知/付费模型通知） |

### 补丁潜力评估

| 补丁 | 可行性 | 说明 |
|------|--------|------|
| force-max-mode | ⭐⭐⭐⭐⭐ | 修改 `computeSelectedModelAndMode` 返回值，强制 Max 模式 |
| bypass-premium-model-notice | ⭐⭐⭐⭐ | 修改 NR 类 `_freeUserPremiumModelNoticeHasShown` 标志 |
| bypass-usage-limit | ⭐⭐⭐⭐ | 修改 4008/4009 错误码处理逻辑 |
| force-auto-mode | ⭐⭐⭐ | 修改 `_shouldForceEnableAutoMode` 或 `calculateAutoModeDefaultStatus` |

## 2. 核心实体

### 2.1 服务/Store 一览

| 实体 | 混淆名 | DI Token | Token 类型 | 偏移量 | 职责 |
|------|--------|----------|-----------|--------|------|
| IModelService | NR | `kv` = Symbol.for("IModelService") @7182315 | Symbol.for | ~7271527 | 模型服务（切换/刷新/模式管理） |
| IModelStore | k2 | `k1` = Symbol("IModelStore") @7191686 | Symbol | ~7191708 | 模型列表+模式列表状态 |
| ISessionRelationStoreInternal | ID | `IN` = Symbol("ISessionRelationStoreInternal") | Symbol | ~7209355 | 会话模型/模式映射（含 computeSelectedModelAndMode） |
| IModelStorageService | — | `kb` = Symbol.for("IModelStorageService") @7182322 | Symbol.for | — | 模型列表持久化 |
| IAiNativeModelService | Wd | TJ (推断) | — | ~7049692 | 原生模型 API 通信 |

> **关键发现**: IModelService 使用 `Symbol.for`（未迁移到 Symbol），IModelStore 使用 `Symbol`（已迁移）。DI 注册使用 `uJ({identifier:NE})` 装饰器模式（NR 类通过 NT 中间类注册）。

### 2.2 IModelService (NR) 方法表

| 方法 | 偏移量范围 | 功能 | 补丁相关性 |
|------|-----------|------|-----------|
| `constructor()` | 7271527+ | 初始化：maxModeNotice、dollarUsageBillingNotice、freeUserPremiumModelNotice 标志 | ⭐⭐⭐⭐ |
| `initializeActions()` | — | 初始化模型列表配置、模式列表、Auto 模式通知 | — |
| `switchSelectedModel(e)` | — | 切换当前选中模型 | — |
| `setSelectedMode(sessionId, agentType, mode)` | — | 设置会话模式 | ⭐⭐⭐⭐⭐ |
| `refreshModelListConfig({forceRefresh, source})` | — | 刷新模型列表配置 | — |
| `refreshModeList()` | — | 刷新模式列表 | — |
| `calculateAutoModeDefaultStatus(...)` | ~7282866 | 计算 Auto 模式默认状态，检查 `AI.chat.force_close_auto` 配置 | ⭐⭐⭐ |
| `_shouldForceEnableAutoMode()` | ~7210677 | 根据动态配置决定是否强制启用 Auto 模式 | ⭐⭐⭐⭐ |
| `reportModeSwitchClick(e)` | ~7276381 | TEA 埋点：模式切换点击 | — |
| `maxFeeUsageClose(sessionId, agentType)` | — | Max 模式费用提醒关闭 | — |
| `setMaxModeNoticeHasShown(v)` | — | 设置 Max 模式通知已显示标志 | ⭐⭐⭐⭐ |

### 2.3 IModelStore (k2) 状态结构

```javascript
{
  originModelListMap: {           // 按 AgentType 分组的模型列表
    [agentTypeKey]: [modelConfig, ...]
  },
  originModelListConfig: [],      // 原始模型配置列表
  modelConfigReadyPromise: M3,    // 模型配置就绪 Promise
  modeListMap: {                  // 按 AgentType 分组的模式列表
    [agentTypeKey]: [{type, status, isUnimodal, ...}, ...]
  },
  modelConfigHasNew: false,       // 模型配置是否有更新
  addModelButtonHasSeen: false,   // 添加模型按钮是否已查看
  autoModeNoticeHasSeen: false,   // Auto 模式通知是否已查看
  showMaxModeNotice: false,       // 是否显示 Max 模式通知
  showDollarUsageBillingNotice: false,  // 是否显示美元计费通知
  showFreeUserPremiumModelNotice: false, // 是否显示免费用户付费模型通知
  disableCustomModel: false,      // 是否禁用自定义模型
  isGetLatestModelListFailed: false,    // 获取最新模型列表是否失败
  modelListFailedSource: "",      // 失败来源
  isUsingFallbackModelList: false // 是否使用回退模型列表
}
```

### 2.4 IModelStore (k2) 关键 Actions

| Action | 功能 |
|--------|------|
| `setOriginModelListMap(map)` | 设置模型列表映射（合并策略） |
| `getModelListByAgentType(agentType)` | 按 AgentType 获取可用模型列表（过滤 status=false） |
| `getDefaultModelByAgentType(agentType)` | 获取默认模型（is_default 或第一个） |
| `setModeListMap(map)` | 设置模式列表映射 |
| `getModeListByAgentType(agentType)` | 按 AgentType 获取模式列表 |
| `setShowMaxModeNotice(v)` | 设置 Max 模式通知显示 |
| `setShowFreeUserPremiumModelNotice(v)` | 设置免费用户付费模型通知 |
| `updateModelSelectedMaxContextWindowSize(model, size)` | 更新模型选中上下文窗口大小 |

### 2.5 SessionRelationStore (ID) 状态结构

```javascript
IT = {
  planModeMap: {},                 // sessionId → agentType → isPlanMode
  specModeMap: {},                 // sessionId → agentType → isSpecMode
  revertDiffListMap: new Map(),    // sessionId → revertDiffList
  reasoningContentVisibleListMap: new Map(),
  sessionModelMap: {},             // sessionId → agentType → modelKey
  sessionModeMap: {},              // sessionId → agentType → kG mode
  globalModelMap: {},              // agentType → modelKey
  globalModeMap: {},               // agentType → kG mode
  modelMaxModeMap: {}              // "agentType_modelKey" → boolean
}
```

### 2.6 枚举

#### kG — 模式类型 @7185310

| 枚举值 | 数值 | 含义 | 权限要求 |
|--------|------|------|---------|
| Manual | 0 | 手动模式 | 免费可用 |
| Auto | 1 | 自动模式 | 默认模式 |
| Max | 2 | 最大模式 | 需付费（isOlderCommercialUser 或 isSaas） |

#### kH — 模型费用级别 @7185310

| 枚举值 | 数值 | 含义 |
|--------|------|------|
| AdvancedModel | 1 | 高级模型 |
| PremiumModel | 2 | 超级模型 |
| SuperModel | 3 | 超级模型（更高） |

#### kY — 配置来源 @7185310

| 枚举值 | 数值 | 含义 |
|--------|------|------|
| Trae | 1 | Trae 内置模型 |
| Enterprise | 2 | 企业自定义模型 |
| Personal | 3 | 个人自定义模型 |

#### kZ — 刷新来源 @7185900

| 枚举值 | 含义 |
|--------|------|
| COMMERCIAL | 商业权限变更触发 |
| INIT | 初始化触发 |
| REFRESH_STORE | Store 刷新触发 |
| MODEL_OFFLINE | 模型下线触发 |
| API_UPDATE | API 更新触发 |
| MODEL_MANAGEMENT_INIT | 模型管理初始化 |
| MODEL_CONFIG_CHANGE | 模型配置变更 |
| ADD_MODEL | 添加模型 |
| UPDATE_MODEL | 更新模型 |
| DELETE_MODEL | 删除模型 |
| TOGGLE_MODEL_STATUS | 切换模型状态 |
| RESET_PPE_CONFIG | 重置 PPE 配置 |
| CLAUDE_FORBIDDEN | Claude 模型被禁 |
| ENTERPRISE_NOT_ALLOWED | 企业不允许 |

#### bJ — 用户身份类型 @6479431

| 枚举值 | 数值 | 含义 | 对模型域影响 |
|--------|------|------|-------------|
| Free | 0 | 免费用户 | 仅 Manual 模式 |
| Pro | 1 | Pro 付费用户 | Auto + Max |
| ProPlus | 2 | ProPlus 付费用户 | 全部模式 |
| Ultra | 3 | Ultra 付费用户 | 全部模式 |
| Trial | 4 | 试用用户 | 受限 |
| Lite | 5 | Lite 用户 | 受限 |
| Express | 100 | Express 用户 | 特殊 |

### 2.7 模型配置数据结构

```javascript
{
  name: "gpt-5",                    // 模型内部名
  display_name: "GPT-5-Responses",  // 显示名
  multimodal: true,                 // 是否多模态
  is_default: true,                 // 是否默认
  config_source: kY.Trae,           // 配置来源
  model_type: kn.Reasoning,         // 模型类型 (Chat/Reasoning)
  max_mode: true,                   // 是否支持 Max 模式
  fee_model_level: kH.PremiumModel, // 费用级别
  is_dollar_max: false,             // 是否美元计费 Max
  is_max_default: false,            // 是否 Max 模式默认
  status: true,                     // 是否可用
  icon: {dark, light},              // 图标
  selectable: true,                 // 是否可选
  selected_max_context_window_size: 0 // 选中上下文窗口大小
}
```

## 3. 数据流

### 3.1 模型选择完整链路

```
用户点击模型选择器
    │
    ▼
React Component (eSK "ModelSelect" @9231523)
    │  使用 uB(k1) 获取 IModelStore
    │  使用 uB(IN) 获取 SessionRelationStore
    │  使用 uB(Il) 获取 ICommercialPermissionService
    │
    ▼
ID.computeSelectedModelAndMode() @7215828 (静态方法)
    │  输入: {sessionId, agentType, sessionModelMap, globalModelMap,
    │         modelList, sessionModeMap, globalModeMap,
    │         isOlderCommercialUser, isSaas, modeListMap, modelOfflineBehavior}
    │
    ├─ Step 1: 查找 session 级模型映射 (sessionModelMap[sessionId][agentType])
    ├─ Step 2: 查找 global 级模型映射 (globalModelMap[agentType])
    ├─ Step 3: 回退到默认模型 (is_default || first)
    ├─ Step 4: 检查模式列表可用性 (modeListMap[agentType])
    ├─ Step 5: 判断模型回退 (isModelFallback)
    ├─ Step 6: 商业用户 Solo Agent → 强制 kG.Max
    ├─ Step 7: 回退+auto_mode行为 → kG.Auto
    ├─ Step 8: 回退其他 → kG.Manual
    └─ Step 9: 正常路径 → session/global 模式映射，默认 kG.Auto
    │
    ▼
返回 {model, mode, isModelFallback}
    │
    ▼
React Hook 消费 (IB 函数 @7223323)
    │  useMemo 计算，依赖 [sessionId, agentType, modelList, ...]
    │
    ▼
UI 渲染: 模型名 + 模式标签 (Manual/Auto/Max)
```

### 3.2 computeSelectedModelAndMode 核心逻辑 @7215828

```javascript
static computeSelectedModelAndMode(e) {
  let t; // selected model
  let {
    sessionId: i, agentType: r,
    sessionModelMap: n, globalModelMap: o,
    modelList: a, sessionModeMap: s, globalModeMap: l,
    isOlderCommercialUser: u, isSaas: d,
    modeListMap: h, modelOfflineBehavior: p = "default_model"
  } = e;

  // 无 agentType 或空模型列表 → Manual
  if (!r || !a.length) return {model: undefined, mode: kG.Manual, isModelFallback: false};

  // 查找 session 级选中模型
  let g = Iu(r), f = n[i]?.[g];
  if (f) { let e = kK(a, f); e && kX(e) && (t = e); }

  // 查找 global 级选中模型
  if (!t) { let e = o[g]; if (e) { let i = kK(a, e); i && kX(i) && (t = i); } }

  // 模式列表检查
  let _ = k0(r), y = h[_] ?? [];
  let v = e => y.length !== 0 && y.some(t => t.type === e);
  let b = !!(f || o[g]) && !t; // isModelFallback

  // 默认模型
  let w = t ?? a.find(e => e.is_default) ?? a[0];

  // ★ 关键决策点 1: 商业用户 Solo Agent → 强制 Max
  if ((u || d) && (_ === ki.solo_coder || _ === ki.solo_builder))
    return {model: w, mode: kG.Max, isModelFallback: b};

  // ★ 关键决策点 2: 回退 + auto_mode 行为 → Auto
  if (b && "auto_mode" === p && v(kG.Auto))
    return {model: w, mode: kG.Auto, isModelFallback: true};

  // ★ 关键决策点 3: 回退其他 → Manual
  if (b) return {model: w, mode: kG.Manual, isModelFallback: true};

  // ★ 关键决策点 4: 正常路径，从映射获取模式，默认 Auto
  let S = s[i]?.[g] ?? l[g] ?? kG.Auto;
  return v(S) ? {model: w, mode: S, isModelFallback: false}
              : {model: w, mode: kG.Manual, isModelFallback: false};
}
```

### 3.3 模式切换链路

```
用户点击模式切换按钮
    │
    ▼
NR.setSelectedMode(sessionId, agentType, modeType) @7274597
    │  TEA 埋点: auto_mode_switch_click / max_mode_switch_click
    │  存储 modeOpVersion
    │  CN 外部用户 Solo Agent Auto 关闭时记录
    │
    ├─ mode ON:
    │   ├─ setSelectedMode(sessionId, agentType, modeType)
    │   └─ if kG.Max: 检查 max_mode，切换到 is_max_default 模型
    │
    └─ mode OFF:
        └─ setSelectedMode(sessionId, agentType, kG.Manual)
    │
    ▼
ID.store.setState({sessionModeMap, globalModeMap})
    │
    ▼
React Hook 重新计算 computeSelectedModelAndMode
    │
    ▼
UI 更新模式标签
```

### 3.4 Auto 模式强制启用链路

```
ID._shouldForceEnableAutoMode() @7210677
    │  读取 dynamicConfig.iCubeApp.aiModelConfig.autoDefaultConfig
    │  检查 initial/repeat 配置
    │  判断 forceAuto 标志
    │
    ▼
ID.initFromCache() @7209355
    │  如果 _shouldForceEnableAutoMode() 返回 true
    │  → sessionModeMap[sessionId][agentType] = kG.Auto
    │
    ▼
NR.calculateAutoModeDefaultStatus() @7282866
    │  检查 AI.chat.force_close_auto 配置
    │  如果 force_close_auto → 返回 false
    │  遍历 autoModeDefaultConfig 优先级:
    │    local_workspace > local_app > server
    │
    ▼
决定是否默认启用 Auto 模式
```

### 3.5 模型列表获取链路

```
NR.initialize() @7271527+
    │  connectToAdapter → hasLoggedIn → initializeActions
    │
    ▼
NR.initializeActions()
    ├─ initialModelListConfig()     // 从服务端拉取模型配置
    ├─ refreshModeList()            // 刷新模式列表
    ├─ initialAutoModelNoticeHasSeen()
    └─ initialNewModelNoticeState()
    │
    ▼
NR.pollModelListConfig()            // 轮询模型配置 (dynamicPullModelListDuration, 默认 6e5=10分钟)
NR.pollModeList()                   // 轮询模式列表
    │
    ▼
Wd (AiNativeModelService) API 调用:
    ├─ model_list                   // 获取模型列表
    ├─ providers                    // 获取模型提供商列表
    ├─ connect                      // 测试模型连接
    ├─ add_custom_model             // 添加自定义模型
    ├─ update_custom_model          // 更新自定义模型
    ├─ get_model_selection_modes    // 获取模式选择列表
    ├─ model_list_by_function       // 按功能获取模型列表
    └─ prefetch_for_auto_mode       // Auto 模式预取
```

### 3.6 付费限制阻断链路

```
API 返回错误码
    │
    ▼
SSE ErrorStreamParser 解析
    │
    ├─ 4008 PREMIUM_MODE_USAGE_LIMIT → Max 模式用量限制
    ├─ 4009 STANDARD_MODE_USAGE_LIMIT → 标准/高级模式用量限制
    ├─ 4113 CLAUDE_MODEL_FORBIDDEN → Claude 模型地区限制
    ├─ 4120 CAN_NOT_USE_SOLO_MODE → Solo 模式不可用
    ├─ 4023 MODEL_NOT_EXISTED → 模型不存在
    └─ 987 MODEL_OUTPUT_TOO_LONG → 模型输出过长
    │
    ▼
UI 层 Alert 渲染:
    ├─ Max Mode 付费提醒 (showMaxModeNotice)
    ├─ 美元计费提醒 (showDollarUsageBillingNotice)
    ├─ 免费用户付费模型提醒 (showFreeUserPremiumModelNotice)
    └─ Claude 地区限制提示 (claude_model_forbidden_*)
```

## 4. 域间关系

### 4.1 与 DI 域的关系

| 关系 | 说明 |
|------|------|
| IModelService 注册 | `kv = Symbol.for("IModelService")` @7182315，通过 `uJ({identifier:NE})` 装饰器注册 |
| IModelStore 注册 | `k1 = Symbol("IModelStore")` @7191686，类直接定义 |
| SessionRelationStore 注册 | `IN = Symbol("ISessionRelationStoreInternal")` @7222646 |
| DI 注入模式 | NR 类通过 `uX(token)` 注入所有依赖服务 |

### 4.2 与 Store 域的关系

| Store | 关系 |
|-------|------|
| IModelStore (k2) | Zustand Store，Aq 基类，管理模型列表和模式列表状态 |
| SessionRelationStore (ID) | Zustand Store，管理会话级模型/模式映射 |
| IEntitlementStore (Nu) | 提供用户身份信息（bJ 枚举），影响模式决策 |
| ICredentialStore (MX) | 提供凭证信息，影响模型列表获取 |

### 4.3 与商业权限域的关系

| 交叉点 | 说明 |
|--------|------|
| isOlderCommercialUser | `computeSelectedModelAndMode` 的关键输入，商业用户 Solo Agent 强制 Max |
| isSaas | 同上，SaaS 用户也强制 Max |
| isSaaSFeatureEnabled | 控制 enterprise 模型列表访问 |
| PREMIUM_MODE_USAGE_LIMIT (4008) | Max 模式用量限制错误码 |
| STANDARD_MODE_USAGE_LIMIT (4009) | 标准模式用量限制错误码 |
| CLAUDE_MODEL_FORBIDDEN (4113) | Claude 模型地区限制错误码 |

### 4.4 与 SSE 域的关系

| 交叉点 | 说明 |
|--------|------|
| chat/model_list | 服务端推送模型列表更新通知 |
| chat/load_model_config | 客户端请求加载模型配置 |
| chat/update_model_config | 服务端推送模型配置更新 |

### 4.5 与命令确认域的关系

| 交叉点 | 说明 |
|--------|------|
| model_list API | 通过 Wd (AiNativeModelService) 的 SERVER_NAME="model" 通信 |

## 5. 补丁相关性

### 5.1 force-max-mode 补丁 ⭐⭐⭐⭐⭐

**目标**: 强制所有 Agent 使用 Max 模式，绕过付费限制

**方案 A — 修改 computeSelectedModelAndMode 返回值** (推荐)

- 位置: `ID.computeSelectedModelAndMode` @7215828
- 修改: 在函数末尾，将返回的 `mode` 替换为 `kG.Max` (即 2)
- 优点: 纯计算逻辑，不涉及 UI 渲染，不受 L1 冻结影响
- 风险: 服务端可能拒绝 Max 模式请求（4008 错误），需配合 bypass-usage-limit

**方案 B — 修改 isOlderCommercialUser/isSaas 输入**

- 位置: 调用 `computeSelectedModelAndMode` 的两个位置 @7213492 和 @7223323
- 修改: 将 `isOlderCommercialUser` 和 `isSaas` 都设为 true
- 优点: 利用已有逻辑（商业用户 Solo → Max），改动小
- 缺点: 只对 Solo Agent 生效，Builder Agent 不受影响

**方案 C — 修改 sessionModeMap/globalModeMap**

- 位置: ID.store 的 sessionModeMap 和 globalModeMap
- 修改: 将所有会话的模式设为 kG.Max
- 缺点: 需要持续维护，每次 initFromCache 会覆盖

### 5.2 bypass-premium-model-notice 补丁 ⭐⭐⭐⭐

**目标**: 消除免费用户使用付费模型时的弹窗通知

- 位置: NR 类 `_freeUserPremiumModelNoticeHasShown` @7271527+
- 修改: 初始化时设为 true，跳过通知
- 或: 修改 k2 store 的 `showFreeUserPremiumModelNotice` 始终为 false

### 5.3 bypass-usage-limit 补丁 ⭐⭐⭐⭐

**目标**: 绕过 4008/4009 用量限制错误

- 位置: 错误码处理逻辑
- 修改: 将 4008/4009 加入可恢复错误列表（J 变量扩展）
- 或: 修改 ee 变量（配额限制标志 @8707858）为 false

### 5.4 force-auto-mode 补丁 ⭐⭐⭐

**目标**: 强制启用 Auto 模式

- 位置: `NR.calculateAutoModeDefaultStatus` @7282866
- 修改: 直接返回 true
- 或: 修改 `_shouldForceEnableAutoMode` @7210677 返回 true
- 注意: 已有 `AI.chat.force_close_auto` 配置项可关闭 Auto，但无对应开启项

### 5.5 bypass-claude-model-forbidden 补丁 ⭐⭐

**目标**: 绕过 Claude 模型地区限制

- 位置: CLAUDE_MODEL_FORBIDDEN (4113) 错误码处理
- 限制: 这是服务端限制，前端无法绕过 API 层面的地区封锁
- 可行: 仅可消除 UI 提示弹窗，无法实际使用被禁模型

## 6. 搜索模板

### MOD-01: computeSelectedModelAndMode
```
IndexOf("computeSelectedModelAndMode") → @7213492 (首次引用), @7215828 (定义), @7223323 (React Hook)
```

### MOD-02: IModelService Token
```
IndexOf("Symbol.for(\"IModelService\")") → @7182315 (kv 变量定义)
IndexOf("identifier:NE") → @7271041 (uJ 注册)
```

### MOD-03: IModelStore Token
```
IndexOf("Symbol(\"IModelStore\")") → @7191686 (k1 变量定义)
```

### MOD-04: SessionRelationStore
```
IndexOf("class ID extends Aq") → @7209355
IndexOf("Symbol(\"ISessionRelationStoreInternal\")") → IN 变量
```

### MOD-05: kG 枚举
```
IndexOf("kG.Manual") → 首次 @7204478
IndexOf("kG.Auto") → 首次 @7210677
IndexOf("kG.Max") → 首次 @7216438
```

### MOD-06: 模式切换方法
```
IndexOf("setSelectedMode") → NR 类方法
IndexOf("calculateAutoModeDefaultStatus") → @7282866
IndexOf("force_close_auto") → @7282940
```

### MOD-07: 付费限制错误码
```
IndexOf("PREMIUM_MODE_USAGE_LIMIT") → @51947 (枚举定义), @7163027 (重复定义)
IndexOf("CLAUDE_MODEL_FORBIDDEN") → @54754 (枚举定义), @7167303 (重复定义)
```

### MOD-08: 模型属性
```
IndexOf("max_mode") → @6577625 (i18n), @7186673 (模型配置)
IndexOf("is_dollar_max") → @7224419
IndexOf("fee_model_level") → @7186897
```

### MOD-09: NR 类 (IModelService)
```
IndexOf("class NR extends bV.Disposable") → @7271527
```

### MOD-10: k2 类 (IModelStore)
```
IndexOf("class k2 extends Aq") → @7191708
```

## 7. 盲区

### 7.1 已知盲区

| 盲区 | 说明 | 优先级 |
|------|------|--------|
| NT 类 | NR 通过 NT 中间类注册（`uJ({identifier:NE})` 在 NT 上），NT 的完整定义未提取 | P1 |
| NE 变量 | NR 的 DI identifier，具体值和定义位置未确认 | P1 |
| modelMaxModeMap 更新逻辑 | ID.store 中 modelMaxModeMap 的写入时机和条件未完全追踪 | P2 |
| 模型下线行为 | `modelOfflineBehavior` 的 "auto_mode" 和 "default_model" 两种策略的完整差异 | P2 |
| IModelStorageService | kb=Symbol.for("IModelStorageService") 的实现类未定位 | P2 |
| IAiNativeModelService | Wd 类的完整方法列表和 API 通信协议 | P3 |
| 模型选择器 UI 组件 | eSK (ModelSelect) 的完整渲染逻辑和交互流程 | P3 |
| Auto 模式预取 | `prefetchForAutoMode` 的完整请求/响应结构 | P3 |

### 7.2 待验证项

| 项目 | 验证方法 |
|------|---------|
| force-max-mode 是否被服务端拒绝 | 实际测试：修改 computeSelectedModelAndMode 返回 Max，观察 API 响应 |
| 4008 错误是否可恢复 | 将 4008 加入 J 变量后测试续接行为 |
| Solo Agent Max 强制逻辑是否可扩展到 Builder | 修改 computeSelectedModelAndMode 中的 Agent 类型判断 |
| modelMaxModeMap 对 Max 模式的实际影响 | 追踪 modelMaxModeMap 写入和读取路径 |
