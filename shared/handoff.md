# 会话交接单

## [2026-04-26 06:00] 深度探索与文档强化完成 — P0深挖+P1全扫+11域交叉验证+43处文档修正+四维索引

### 本次完成

执行了 deep-exploration-and-docs-strengthening spec，8 个 Phase 全部完成。这是目前最全面的一次源码探索，覆盖了 P0 盲区深挖、P1 盲区全扫、11 域交叉验证、架构文档审计、索引构建、新域探索和搜索模板验证。

### 核心发现（8 个 Major）

1. **DI 注册数 51→186，注入数 101→816** ⭐⭐⭐⭐⭐ — 交叉验证揭示 DI 系统远比文档记录的庞大，di-service-registry.md 需要大幅更新
2. **5 个新 ai.* DI Token** ⭐⭐⭐⭐⭐ — ai.IDocsetService/IDocsetStore/IDocsetCkgLocalApiService/IDocsetOnlineApiService/IWebCrawlerFacade，构成完整文档集管理域
3. **31 个 I*Service DI Token 完整映射** ⭐⭐⭐⭐⭐ — 包括 IStuckDetectionService(@7537021)/IAutoAcceptService(@8039940)/IPrivacyModeService(@8036543)/ICommercialApiService(@7559975) 等关键服务
4. **ICommercialPermissionService 不使用 Symbol 模式** ⭐⭐⭐⭐⭐ — 通过 `aiAgent.ICommercialPermissionService` 命名空间前缀注册(@7197027)，不是 Symbol 或 Symbol.for
5. **25 个 VS Code 命令注册** ⭐⭐⭐⭐ — 在 bootstrapApplicationContainer(@10477819) 中通过 CommandsRegistry 注册，含 send.internal/codeReview/forkSession/knowledges.*
6. **38 个 ToolCallName 完整枚举** ⭐⭐⭐⭐ — @40836，包含所有 Agent 工具名
7. **kg 错误码从 ~30 扩展到 56** ⭐⭐⭐⭐ — 交叉验证穷举确认，含新增 MODEL_OUTPUT_TOO_LONG/MODEL_NOT_EXISTED
8. **Model 域应优先建立** ⭐⭐⭐⭐ — computeSelectedModelAndMode @7215828，补丁潜力 5/5

### 文档修正（43 处）

- ICommercialPermissionService Token 类型：Symbol.for → aiAgent.命名空间前缀（4 处）
- DI 统计：51→186 注册、101→816 注入（5 个文档 10 处）
- 文件统计：10490354→10490415 chars、347099→347244 行（17 处）
- 枚举数量：kg 错误码 56 个、ToolCallName 38 个（4 处）
- 新增信息：4 个新服务、5 个 ai.* Token、eY0 入口对象、Model 域锚点（3 个文档追加）

### 四维索引

| 索引类型 | 条目数 | 说明 |
|---------|--------|------|
| 按域搜索 | ~150 | 13 个域分类 |
| 按偏移量范围 | ~130 | 4 个区间 |
| 按功能 | ~80 | 7 个功能分类 |
| 按 confidence | ~120 | 3 个级别 |

### 搜索模板验证

- 24/26 OK，2 个 EMPTY
- SSE-02 `Symbol.for("IPlanItemStreamParser")` → 已迁移为 Symbol()
- EVT-05 `icube.shellExec` → 命名空间可能已变更

### 新域候选

- **[Docset]** — 文档集管理域 (5个ai.* DI token + 6个Knowledges服务)
- **[Model]** — 模型选择域 (computeSelectedModelAndMode @7215828, 补丁潜力 5/5)

### 关键补丁影响

| 发现 | 对现有补丁的影响 |
|------|-----------------|
| IStuckDetectionService @7537021 | bypass-loop-detection 补丁的服务层替代方案 |
| IAutoAcceptService @8039940 | 自动确认补丁的服务层替代方案 |
| ICommercialApiService @7559975 | 商业权限域的 API 层入口 |
| icubeStore.serviceCollection | DI 容器全局入口，可用于任何服务获取 |
| computeSelectedModelAndMode @7215828 | force-max-mode 补丁核心目标 |

### 产出文件

| 文件 | 内容 |
|------|------|
| `shared/discoveries.md` | +P0/P1 深度探索 + 交叉验证 + 四维索引 + 模板验证报告 |
| `docs/architecture/*.md` | 43 处过时信息修正 |
| `scripts/explore-deep-p0-phase2.ps1` | P0 Phase 2 聚焦扫描脚本 |
| `scripts/explore-deep-p1-scan.ps1` | P1 盲区扫描脚本 |
| `scripts/explore-deep-cross-validate.ps1` | 11 域交叉验证脚本 |
| `scripts/verify-search-templates.ps1` | 搜索模板可用性验证脚本 |

### 下一步建议

1. **高优**: 基于 IStuckDetectionService 开发 bypass-loop-detection 服务层替代方案
2. **高优**: 基于 IAutoAcceptService 开发自动确认服务层方案
3. **高优**: 将 186 个 DI 注册更新到 di-service-registry.md（当前仅记录 51 个）
4. **高优**: 建立 Model 域架构文档（computeSelectedModelAndMode @7215828）
5. **中优**: 更新 SSE-02 和 EVT-05 搜索模板（Symbol.for→Symbol, icube.shellExec→?）
6. **中优**: 探索 ICommercialApiService 与 ICommercialPermissionService 的关系
7. **中优**: 基于 icubeStore.serviceCollection 开发通用服务获取补丁
8. **低优**: 探索 [Docset] 域的完整服务链

---

### 本次完成

对 P0 盲区 (54415-6268469, ~6.2MB) 执行了 Phase 2 (10KB级细扫) + Phase 3 (双向扩展深挖) + Phase 3++ (精确搜索)，完成了该区间的系统性探索。

### 核心发现（6 个 Major）

1. **ai.* DI Token 家族 (5个新发现)** ⭐⭐⭐⭐⭐ — IDocsetService/IDocsetStore/IDocsetCkgLocalApiService/IDocsetOnlineApiService/IWebCrawlerFacade，构成完整的文档集管理域
2. **31 个 I*Service DI Token 完整映射** ⭐⭐⭐⭐⭐ — 包括 IStuckDetectionService/IAutoAcceptService/IPrivacyModeService/ICommercialApiService 等关键服务
3. **VS Code DI 注入机制** ⭐⭐⭐⭐⭐ — Inject 装饰器使用 Symbol("__instance__")，icubeStore.serviceCollection 是 DI 容器入口，SyncDescriptor 用于单例延迟解析
4. **API 端点映射** ⭐⭐⭐⭐ — a0ai-api.byteintlapi.com (AI API), bytegate-sg (网关), pc-mon-sg (监控), mcs-nontt (TEA), libraweb-va (AB实验)
5. **HaltChainable 事件链机制** ⭐⭐⭐⭐ — VS Code Event.chain() 实现可中断事件链，filter 返回 HaltChainable 即中断传播
6. **P0 盲区组成确认** ⭐⭐⭐⭐ — ~90% 第三方库，~5% i18n，~3% TEA SDK，~2% 业务逻辑。核心业务方法（resumeChat 等）均不在 P0 区间

### 新域候选

- **[Docset]** — 文档集管理域 (5个ai.* DI token + 6个Knowledges服务)
- **[DI-Inject]** — VS Code DI 注入机制 (__instance__ Symbol, Inject 装饰器)

### 关键补丁影响

| 发现 | 对现有补丁的影响 |
|------|-----------------|
| IStuckDetectionService @7537021 | 可用于 bypass-loop-detection 补丁的服务层替代 |
| IAutoAcceptService @8039940 | 可用于自动确认补丁的服务层替代 |
| IPrivacyModeService @8036543 | 可用于隐私模式绕过 |
| ICommercialApiService @7559975 | 商业权限域的 API 层入口 |
| icubeStore.serviceCollection | DI 容器全局入口，可用于任何服务获取 |

### 产出文件

| 文件 | 内容 |
|------|------|
| `shared/discoveries.md` | +P0盲区深度探索完整记录 |
| `scripts/explore-deep-p0-phase2.ps1` | Phase 2 聚焦扫描脚本 |
| `scripts/explore-deep-p0-phase3.ps1` | Phase 3 双向扩展脚本 |
| `scripts/explore-deep-p0-phase3plus.ps1` | Phase 3++ 精确搜索脚本 |
| `scripts/explore-deep-p0-phase3plus2.ps1` | Phase 3++ DI token 精确搜索脚本 |
| `scripts/explore-deep-p0-phase2-results.txt` | Phase 2 扫描结果 |
| `scripts/explore-deep-p0-phase3-results.txt` | Phase 3 深挖结果 |
| `scripts/explore-deep-p0-phase3plus-results.txt` | Phase 3++ 结果 |
| `scripts/explore-deep-p0-phase3plus2-results.txt` | Phase 3++ DI token 结果 |

### 下一步建议

1. **高优**: 基于 IStuckDetectionService 开发 bypass-loop-detection 服务层替代方案
2. **高优**: 基于 IAutoAcceptService 开发自动确认服务层方案
3. **高优**: 将 31 个 I*Service DI token 更新到 di-service-registry.md
4. **中优**: 探索 ICommercialApiService 与 ICommercialPermissionService 的关系
5. **中优**: 基于 icubeStore.serviceCollection 开发通用服务获取补丁
6. **低优**: 探索 [Docset] 域的完整服务链

---

## [2026-04-25 23:50] v2 探索远征完成 — 版本适配 + 商业权限 + 新补丁目标

### 本次完成

执行了 v2 探索远征 spec，对 Trae 新版本进行系统性版本适配审计和商业权限域深度映射。

### 核心发现（6 个 Major）

1. **J→K 重命名未发生** ⭐⭐⭐⭐⭐ — 纠正 handoff 中的错误报告。J 仍是"显示继续按钮"变量，K=!![ 未找到。现有补丁中引用 J 的代码仍然有效。
2. **Symbol.for→Symbol 部分迁移** ⭐⭐⭐⭐⭐ — 54 个 Symbol.for 保留，40+ 个 Symbol 新增。IPlanItemStreamParser/ISessionStore/ISessionServiceV2 已迁移，IModelService/IErrorStreamParser/ITeaFacade 未迁移。
3. **ICommercialPermissionService 完整方法映射** ⭐⭐⭐⭐⭐ — NS 类 6 个方法，无 isFreeUser()。isFreeUser 在 React Hook efi() 中计算。
4. **IEntitlementStore 完整状态映射** ⭐⭐⭐⭐ — Nu 类，{entitlementInfo, saasEntitlementInfo}，identity 为 bJ 枚举。
5. **付费限制错误码纠正** ⭐⭐⭐⭐⭐ — PREMIUM_MODE_USAGE_LIMIT=4008(非1016), STANDARD_MODE_USAGE_LIMIT=4009(非1017), FIREWALL_BLOCKED=700(非1023)。
6. **6 个新补丁目标候选** ⭐⭐⭐⭐ — bypass-commercial-permission(推荐)、bypass-usage-limit、bypass-free-user-model-notice 等。

### 对现有补丁的影响

| 补丁 | 影响 | 必须操作 |
|------|------|---------|
| 所有引用 J 变量的补丁 | **无影响** | J→K 重命名未发生，无需修改 |
| auto-continue-l2-parse | **需验证** | 引用 Di token，Di 仍存在 |
| auto-continue-v11-store-subscribe | **需验证** | 引用 BR/xC token，均仍存在 |
| bypass-whitelist-sandbox-blocks | **可能失效** | P8.Default 未找到，可能已重命名 |
| ec-debug-log | **fingerprint 不匹配** | find_original 找到但 fingerprint 失效 |

### 补丁适配状态摘要

- 6 个补丁已应用且运行正常（偏移量漂移 +4000~+7000）
- 5 个补丁 find_original 精确匹配，可直接应用
- 3 个 BROKEN 补丁均为已禁用状态，不影响当前功能

### 下一步建议

1. **高优**: 开发 bypass-commercial-permission 补丁（NS 类方法返回值修改，L2 层，可行性 5/5）
2. **高优**: 开发 bypass-usage-limit 补丁（ee 变量修改，L1 层，可行性 4/5）
3. **中优**: 验证 P8.Default 变量名变化，更新 bypass-whitelist-sandbox-blocks
4. **中优**: 交叉验证商业权限域发现（当前为单路径验证）
5. **低优**: 探索 force-max-mode 补丁（computeSelectedModelAndMode @7216438）

### 产出文件

| 文件 | 内容 |
|------|------|
| `shared/discoveries.md` | +6 个新发现条目 |
| `scripts/explore-v2-verify.ps1` | Phase 0 验证脚本 |
| `scripts/explore-v2-jk-symbol.ps1` | Phase 2+3 评估脚本 |
| `scripts/explore-v2-results.txt` | 搜索结果数据 |

---

## [2026-04-25 23:50] Phase 4+5 完成 — 商业权限域深度映射 + 新补丁目标候选发现

### 本次完成

执行了 Phase 4 (商业权限域深度映射) 和 Phase 5 (新补丁目标候选发现)，对 Trae 商业权限系统进行了完整的源码级分析。

### 核心发现（6 个 Major）

1. **NS 类完整方法映射** ⭐⭐⭐⭐⭐ — ICommercialPermissionService 有 6 个方法（isDollarUsageBilling/isCommercialUser/isOlderCommercialUser/isNewerCommercialUser/isSaas/isInternal），**没有 isFreeUser 方法**
2. **isFreeUser 是 React Hook** ⭐⭐⭐⭐⭐ — isFreeUser 在 efi() Hook 中计算：`!entitlementInfo?.identity`，不是服务层方法
3. **错误码数值纠正** ⭐⭐⭐⭐ — PREMIUM_MODE_USAGE_LIMIT 实际值是 4008（不是 1016），STANDARD_MODE_USAGE_LIMIT 是 4009（不是 1017），FIREWALL_BLOCKED 是 700
4. **bJ 枚举完整映射** ⭐⭐⭐⭐ — 用户身份类型：Free=0, Pro=1, ProPlus=2, Ultra=3, Trial=4, Lite=5, Express=100
5. **6 个新补丁候选** ⭐⭐⭐⭐⭐ — bypass-commercial-permission (推荐⭐⭐⭐⭐⭐) + bypass-usage-limit + bypass-firewall-blocked + bypass-claude-model-forbidden + force-max-mode + bypass-free-user-model-notice
6. **"跳过付费限制"可行性评估** ⭐⭐⭐⭐ — 总体可行性高 (4/5)，推荐 bypass-commercial-permission + bypass-usage-limit 组合

### 关键代码位置

| 代码 | 位置 | 说明 |
|------|------|------|
| NS class | @7267682 | ICommercialPermissionService 实现 |
| efi() Hook | @8687513 | isFreeUser 计算 |
| Nu class | @7264682 | IEntitlementStore 实现 |
| MX class | @7154491 | ICredentialStore 实现 |
| NR class | @7271527 | IModelService (ModelService) 实现 |
| k2 class | @7191708 | IModelStore 实现 |
| bJ enum | @6479431 | 用户身份类型枚举 |
| kG enum | @7185314 | 模式类型枚举 (Manual/Auto/Max) |
| ee 变量 | @8707858 | 配额限制标志 |
| efr enum | @55610 | 免费用户配额状态枚举 |

### 对现有补丁的影响

| 补丁 | 影响 | 必须操作 |
|------|------|---------|
| efh-resume-list | efg 需扩展 | 加入 PREMIUM_MODE_USAGE_LIMIT(4008) 和 STANDARD_MODE_USAGE_LIMIT(4009) |
| bypass-loop-detection | J→K 已知 | 无新影响 |

### 产出文件

| 文件 | 内容 |
|------|------|
| `shared/discoveries.md` | +8 个新发现条目（NS类/efi()/EntitlementStore/CredentialStore/错误码纠正/配额代码/模型限制/候选清单） |
| `scripts/explore-v2-commercial.ps1` | Phase 4+5 主探索脚本 |
| `scripts/explore-v2-detail.ps1` | NS 类/efi()/枚举详细提取脚本 |
| `scripts/explore-v2-enums.ps1` | bJ/kG/bK 枚举搜索脚本 |
| `scripts/explore-v2-detail2.ps1` | 错误服务/模型服务详细提取脚本 |
| `scripts/explore-v2-commercial-results.txt` | 完整搜索结果 (2.7MB) |

### 下一步建议

1. **高优**: 开发 bypass-commercial-permission 补丁 — 修改 NS 类方法返回值
2. **高优**: 开发 bypass-usage-limit 补丁 — 修改 ee 变量为 false
3. **中优**: 将 4008/4009 加入 efg 可恢复列表
4. **低优**: bypass-claude-model-forbidden 补丁
5. **不建议**: bypass-firewall-blocked — 网络层限制无法前端绕过

---

## [2026-04-25 23:30] 盲区远征完成 — Trae 版本更新检测 + 完整 DI token 映射

### 本次完成

执行了盲区远征 spec，对 Trae 源码三大盲区进行系统性探索，发现 **Trae 已更新**（文件从 ~10463462 增长到 10489266 chars），多个关键 DI token 发生迁移。

### 核心发现（8 个 Major）

1. **Symbol.for→Symbol 迁移** ⭐⭐⭐⭐⭐ — Store/Parser 类 DI token 从 Symbol.for 迁移到 Symbol，旧搜索模式失效
2. **变量重命名 J→K** ⭐⭐⭐⭐⭐ — 可恢复错误标志从 J 改名为 K，J 现在是思考上限+循环标志
3. **ConfirmMode 枚举已移除** — 命令确认逻辑改为纯配置驱动
4. **kg 错误码完整枚举** — 30+ 错误码，新增 PREMIUM_MODE_USAGE_LIMIT(1016), STANDARD_MODE_USAGE_LIMIT(1017), FIREWALL_BLOCKED(1023) 等
5. **IEntitlementStore** ⭐⭐⭐⭐⭐ — 订阅/权益管理 Store，ICommercialPermissionService 的数据源
6. **ICommercialPermissionService** ⭐⭐⭐⭐⭐ — 商业权限判断集中点，6 个方法全部基于 EntitlementStore+CredentialStore
7. **P0 盲区组成** — ~6.2MB 中大部分为第三方库（React/D3/Mermaid/Chevrotain），业务逻辑集中在少数区域
8. **P1 盲区组成** — registerCommand 集中区（26 个命令）+ registerAdapter 实现

### 对现有补丁的影响

| 补丁 | 影响 | 必须操作 |
|------|------|---------|
| auto-continue-thinking | **J→K 重命名** | find_original 中引用 J 的代码必须改为 K |
| efh-resume-list | **efh→efg 重命名** | 搜索模式必须更新 |
| bypass-loop-detection | **J 含义变化** | J 现在包含思考上限+循环，逻辑可能需调整 |
| 所有含 Symbol.for 搜索的补丁 | **Token 迁移** | Symbol.for("IPlanItemStreamParser") → Symbol("IPlanItemStreamParser") |
| ConfirmMode 相关 | **枚举已移除** | 需要重写为配置驱动方式 |

### 新域候选

- **[Entitlement]** — 订阅/权益管理域（IEntitlementStore + ICommercialPermissionService），影响 Pro/Free 分层逻辑
- **[i18n]** — 本地化域（6096015+ 大量中/日/英字符串），对补丁影响较低

### 产出文件

| 文件 | 内容 |
|------|------|
| `shared/discoveries.md` | +8 个新发现条目（Symbol 迁移、J→K 重命名、kg 枚举、EntitlementStore、CommercialPermissionService、P0/P1 盲区分析、负面结果） |
| `scripts/explore-*.ps1` | 6 个探索脚本（anchor-check, p0-scan, p0-focus, p1-scan, cross-validate, entitlement） |
| `scripts/explore-*-results.txt` | 探索结果数据文件 |

### 下一步建议

1. **紧急**: 更新 definitions.json 中所有 Symbol.for 搜索模式为 Symbol（针对已迁移的 token）
2. **紧急**: 更新 auto-continue-thinking 补丁中的 J→K 变量引用
3. **高优**: 基于 ICommercialPermissionService 开发"跳过付费限制"补丁
4. **中优**: 验证所有 14 个补丁在新版本上的可用性
5. **低优**: 探索 IEntitlementStore 的完整状态结构

---

## [2026-04-25 21:30] 源码全景地图绘制完成

### 本次完成

完成了 Trae 源码全景地图绘制项目（trae-source-code-cartography spec），覆盖 10 大探索域：

1. **[DI] 依赖注入** — 完整 DI token 列表（30+ Symbol.for + 20+ Symbol），关键纠正：BR 不是 DI token
2. **[SSE] 流管道** — 13 个事件类型，15 个 Parser，EventHandlerFactory 调度器
3. **[Store] 状态架构** — 8 个 Zustand Store，两种 currentSession 模式，无 Immer
4. **[Error] 错误系统** — 完整错误码枚举，3 条传播路径（IPC/SSE/通用），stopStreaming "沉默杀手"
5. **[React] 组件层级** — 三层架构（L1/L2/L3），17+ Alert 渲染点，冻结行为分析
6. **[Event] 事件总线** — TEA 遥测系统，无 Node.js EventEmitter，Hook 点可行性评估
7. **[IPC] 进程间通信** — 三层 IPC 架构，无 ipcRenderer，VS Code 命令系统
8. **[Setting] 设置系统** — 完整设置 key 列表，无 onDidChangeConfiguration
9. **[Sandbox] 沙箱** — BlockLevel/AutoRunMode/ConfirmMode 枚举，SAFE_RM 安全规则
10. **[MCP] 工具调用** — 80+ ToolCallName，工具调用生命周期，confirm_info 数据结构

### 产出文件

| 文件 | 内容 | 行数变化 |
|------|------|---------|
| `shared/discoveries.md` | 10 大域探索结果 + 偏移量索引 + 交叉引用 | 1700→3000+ |
| `scripts/search-templates.ps1` | 10+ 可复用搜索函数 | 新增 |
| `docs/architecture/di-service-registry.md` | DI 服务注册表完整文档 | 新增 |
| `docs/architecture/sse-pipeline-topology.md` | SSE 管道完整拓扑 | 新增 |
| `docs/architecture/store-architecture.md` | Store 架构完整文档 | 新增 |

### 关键发现

1. **BR 不是 DI token** — `BR` = `s(72103)` = Node.js `path` 模块，正确 token 是 `BO` 或 `M0`
2. **FX 不是 DI 解构** — `FX` = `findTargetAgent` 辅助函数
3. **Bs 不是 ChatStreamService** — `Bs` 是 ChatParserContext（数据类），`Bo` 才是 ChatStreamService
4. **思考上限错误走 IPC 路径** — 不经过 SSE ErrorStreamParser，这就是 v10/v12 零输出的原因
5. **无 ipcRenderer** — 所有主进程通信通过 VS Code 命令系统
6. **无 Immer** — 使用展开运算符进行不可变更新
7. **ALWAYS_RUN + RedList 仍弹窗** — getRunCommandCardBranch 的决策矩阵

### Top 3 Hook 点

1. **PlanItemStreamParser._handlePlanItem** (~7502500) — 综合 4.75，命令确认最佳点
2. **teaEventChatFail** (~7458679) — 综合 4.5，后台错误检测最佳点
3. **DI Container resolve** (任意) — 综合 4.0，服务访问最佳点

### 下一步

- 基于地图开发新补丁（如"自动跳过付费限制弹窗"）
- Trae 更新后使用搜索模板重新定位代码
- 验证搜索模板在新版本上的可用性

---

## [2026-04-25 22:30] 探索工具箱部署完成 ⭐⭐⭐⭐⭐

### 本次完成

完成了 **探索工具箱 (Exploration Toolkit)** 项目（exploration-toolkit spec），为 trae-unlock 项目建立完整的分层级探索工具链：

### 核心成果

#### 工具链部署（4 层级）

| 层级 | 工具 | 状态 | 核心能力 |
|------|------|------|---------|
| L0 | PowerShell IndexOf/Select-String | ✅ 内置 | 毫秒级字符串定位 |
| L1 | js-beautify 1.15.4 | ✅ **主要工具** | 代码美化（10MB→21MB, **347,099 行**） |
| L1 | @babel/parser + traverse 7.x | ✅ 已安装 | AST 结构化分析（**38,630 函数** + **1,009 类**） |
| L2 | reverse-machine 2.1.5 | ⚠️ 需 API key | AI 驱动变量重命名 |
| L3 | ast-search-js 1.10.2 | ✅ 备选 | 结构化代码搜索 |
| - | webcrack 2.15.1 | ❌ 不兼容 TS 装饰器 | webpack 解包（未来可能修复） |

#### 新增脚本文件（3 个）

| 脚本 | 函数列表 | 用途 |
|------|---------|------|
| [unpack.ps1](../scripts/unpack.ps1) | Unpack-TraeIndex, Test-ToolAvailability, Get-UnpackStats | 解包和工具检测 |
| [ast-search.ps1](../scripts/ast-search.ps1) | Search-AST, Search-ASTFast, Extract-AllFunctions, Extract-AllClasses | AST 搜索和批量提取 |
| [module-search.ps1](../scripts/module-search.ps1) | Search-UnpackedModules, Get-ModuleOverview, Find-ModuleByContent | webpack 模块级搜索 |

#### 文档更新

| 文件 | 变更内容 |
|------|---------|
| [explorer-protocol.md](../docs/architecture/explorer-protocol.md) | +Step 8 (工具检查), +4.6 (决策树), +4.7 (组合模式) |
| [exploration-toolkit.md](../docs/architecture/exploration-toolkit.md) | **新建** — 完整使用指南（7 章 + 附录） |
| [discoveries.md](../discoveries.md) | +120 行工具链发现记录 |

### 关键技术发现

1. **webcrack 不兼容原因**: Trae index.js 包含 TypeScript 装饰器语法 (`@7474399`)，Babel parser 默认配置无法解析
   - 错误: `SyntaxError: Unexpected token, expected ","`
   - 解决方案: 使用 js-beastify（纯文本格式化，不依赖 AST）

2. **IPlanItemStreamParser 的 Symbol 类型纠正**:
   - 预期: `Symbol.for("IPlanItemStreamParser")` (Level 5 ⭐⭐⭐⭐⭐)
   - 实际: `Symbol("IPlanItemStreamParser")` (Level 4 ⭐⭐⭐⭐)
   - 影响: 稳定性评级需下调一级

3. **性能基准数据**:
   - js-beautify 美化: ~20s, ~200MB 内存
   - Extract-AllFunctions: ~90s, ~500MB 内存, 输出 38,630 条
   - Extract-AllClasses: ~45s, ~400MB 内存, 输出 1,009 条
   - Select-String 搜索: <1s

### 数据资产

| 资产 | 大小 | 说明 |
|------|------|------|
| `unpacked/beautified.js` | 21.18 MB / 347,099 行 | 美化后的完整源码 |
| `functions-index.json` | 待生成 | 38,630 个函数索引 |
| `classes-index.json` | 待生成 | 1,009 个类索引 |

### 快速开始命令

```powershell
# 加载所有脚本
. "D:\Test\trae-unlock\scripts\unpack.ps1"
. "D:\Test\trae-unlock\scripts\ast-search.ps1"
. "D:\Test\trae-unlock\scripts\module-search.ps1"

# 美化（Trae 更新后执行一次）
Unpack-TraeIndex -Force

# 搜索关键词
Search-UnpackedModules -Keyword "PlanItemStreamParser"

# AST 结构搜索
Search-AST -FilePath "unpacked/beautified.js" -NodeType "ClassDeclaration" -NamePattern ".*Parser"

# 批量提取索引
Extract-AllFunctions -FilePath "unpacked/beautified.js"
Extract-AllClasses -FilePath "unpacked/beautified.js"
```

### 下一步建议

1. 运行 `Get-ModuleOverview` 获取完整的 webpack 模块统计
2. 将 functions-index.json 和 classes-index.json 加入版本控制
3. 基于 AST 索引重新验证已知发现点的偏移量
4. 使用 Workflow A 对最大盲区 (54415-6268469) 进行系统化扫描
5. （可选）如果需要 AI 增强反混淆，配置 reverse-machine 的 API key
