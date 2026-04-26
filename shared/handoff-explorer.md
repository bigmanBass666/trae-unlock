---
module: handoff-explorer
description: Explorer 交接单 — 源码探索成果和待探索方向
read_priority: P1
read_when: Explorer 角色开始工作时
write_when: Explorer 会话结束时
format: log
role: explorer
sync_with:
  - shared/discoveries.md (唯一权威数据源)
  - docs/architecture/explorer-protocol.md (SOP 协议)
  - docs/architecture/exploration-toolkit.md (工具链指南)
last_reviewed: 2026-04-26
---

# 探索家交接单 (Explorer Handoff)

> 本文件由 Explorer Agent 写入，Developer Agent 按需参考
> 路由入口：[handoff.md](./handoff.md) → 本文件

---

## [2026-04-26 18:39] 交接拆分完成 — 手动拆分为角色专属文件

> 本次操作：将单一 `handoff.md` 拆分为 `handoff-explorer.md` + `handoff-developer.md` + 路由入口

---

## [2026-04-26 18:00] Grand Exploration & Documentation Overhaul 完成 — 8 Phase 全面查漏补缺+9模板修复+2新域文档+25+处一致性修正

### 核心发现（10 个 Major）

> 📊 **完整四维索引**: → [详见 discoveries.md](shared/discoveries.md) （+44KB/878行）

1. **DI 注册表 51→186 完整更新** ⭐⭐⭐⭐⭐ — 5种注册模式, ILogService 注入之王(66次)
2. **Model 域架构文档创建** ⭐⭐⭐⭐⭐ — computeSelectedModelAndMode 6步决策链，force-max-mode 补丁潜力 5/5
3. **Docset 域架构文档创建** ⭐⭐⭐⭐ — 三层服务架构，ent_knowledge_base 门控 bypass 可行性 4/5
4. **9 个搜索模板修复** ⭐⭐⭐⭐⭐ — SSE-02/SSE-06/SSE-11~14/EVT-05/EVT-08/GEN-10
5. **78 个搜索模板全量验证** ⭐⭐⭐⭐ — 69通过, 8失败(已修复), 2预期空
6. **13 个文档交叉一致性审计** ⭐⭐⭐⭐ — 25+处修正
7. **P0 盲区完全探明** ⭐⭐⭐⭐ — ContactType@55561, API端点@5870417, ChatError@54993
8. **Symbol.for→Symbol 迁移模式完整映射** ⭐⭐⭐⭐ — 4已迁移 / 6+未迁移
9. **基线偏移量重测量** ⭐⭐⭐ — 文件大小10490721(+306)
10. **discoveries.md 四维索引构建** ⭐⭐⭐⭐⭐ — 17域/~170条, 5区间偏移量, 6类功能, 4级置信度

### 关键代码位置

| 发现 | 偏移量 | 对补丁的影响 |
|------|--------|-------------|
| computeSelectedModelAndMode | @7215828 | force-max-mode 补丁核心目标，5/5 可行性 |
| ContactType 枚举 | @55561 | bypass-usage-limit 补丁核心数据 |
| ent_knowledge_base | @7727418 | Docset 域权限门控，bypass 可行性 4/5 |
| force_close_auto | @7282940 | 控制 Auto 模式开关 |
| ChatError | @54993 | efh-resume-list 可扩展新错误码 |

### 对开发者的建议

1. **高优**: 基于 computeSelectedModelAndMode 开发 force-max-mode 补丁（5/5 可行性）
2. **高优**: 基于 ContactType 枚举开发 bypass-usage-limit 补丁
3. **高优**: 基于 IStuckDetectionService 开发 bypass-loop-detection 服务层替代方案
4. **高优**: 基于 IAutoAcceptService 开发自动确认服务层方案
5. **中优**: 将 ChatError 新错误码(4000005/4000009) 加入 efh-resume-list
6. **中优**: 基于 ent_knowledge_base 门控开发 Docset bypass 补丁

---

## [2026-04-26 16:05] Model + Docset 域架构文档创建完成

### 核心发现（4 个 Major）

1. **computeSelectedModelAndMode 完整逻辑** ⭐⭐⭐⭐⭐ — 6 步决策链，商业用户 Solo Agent 强制 Max 模式
2. **5 个 ai.* DI Token 完整映射** ⭐⭐⭐⭐⭐ — 全部使用 Symbol.for（未迁移）
3. **Docset 三层服务架构** ⭐⭐⭐⭐ — 编排层(Gd) → 数据层(WY/Wq) → 采集层(Gs)
4. **ent_knowledge_base 权限门控** ⭐⭐⭐⭐ — SaaS 功能开关控制企业文档集访问

### 关键偏移量（实测）

**Model 域**: computeSelectedModelAndMode(7213492/7215828/7223323), ID class(7209355), NR class(7271527), k2(7191708), force_close_auto(7282940)

**Docset 域**: ai.IDocsetService(3546321/7749472), ai.IDocsetStore(7244792), ent_knowledge_base(7727418)

---

## [2026-04-25 23:50] v2 探索远征完成 — 版本适配 + 商业权限 + 新补丁目标

### 核心发现（6 个 Major）

1. **J→K 重命名未发生** ⭐⭐⭐⭐⭐ — 纠正 handoff 中的错误报告，现有补丁仍有效
2. **Symbol.for→Symbol 部分迁移** ⭐⭐⭐⭐⭐ — Store/Parser 类已迁移，Model/Error/Tea 未迁移
3. **ICommercialPermissionService 完整方法映射** ⭐⭐⭐⭐⭐ — NS 类 6 方法，无 isFreeUser()
4. **IEntitlementStore 完整状态映射** ⭐⭐⭐⭐ — Nu 类，{entitlementInfo, saasEntitlementInfo}
5. **付费限制错误码纠正** ⭐⭐⭐⭐⭐ — PREMIUM_MODE_USAGE_LIMIT=4008, STANDARD_MODE_USAGE_LIMIT=4009, FIREWALL_BLOCKED=700
6. **6 个新补丁目标候选** ⭐⭐⭐⭐ — bypass-commercial-permission(推荐) 等

### 关键代码位置

| 代码 | 位置 | 说明 |
|------|------|------|
| NS class (ICommercialPermissionService) | @7267682 | 6个方法，无 isFreeUser |
| efi() Hook (isFreeUser) | @8687513 | React Hook 中计算: !entitlementInfo?.identity |
| bJ enum (用户身份) | @6479431 | Free=0, Pro=1, ProPlus=2, Ultra=3, Trial=4, Lite=5, Express=100 |
| ee 变量 (配额限制) | @8707858 | 配额限制标志 |

---

## [2026-04-25 23:30] 盲区远征完成 — Trae 版本更新检测 + 完整 DI token 映射

### 核心发现（8 个 Major）

1. **Symbol.for→Symbol 迁移** ⭐⭐⭐⭐⭐ — Store/Parser 类 DI token 迁移，旧搜索失效
2. **ConfirmMode 枚举已移除** — 改为纯配置驱动
3. **kg 错误码完整枚举** — 30+ 错误码，含新错误码
4. **IEntitlementStore** ⭐⭐⭐⭐⭐ — 订阅/权益管理 Store
5. **ICommercialPermissionService** ⭐⭐⭐⭐⭐ — 商业权限判断集中点
6. **P0 盲区组成** — ~90% 第三方库, ~5% i18n, ~3% TEA SDK, ~2% 业务逻辑
7. **P1 盲区组成** — registerCommand 集中区（26 个命令）

### 新域候选

- **[Entitlement]** — 订阅/权益管理域（影响 Pro/Free 分层逻辑）
- **[i18n]** — 本地化域（对补丁影响较低）

---

## [2026-04-25 21:30] 源码全景地图绘制完成

### 10 大探索域全景

| # | 域 | 核心发现 |
|---|-----|---------|
| 1 | [DI] 依赖注入 | 30+ Symbol.for + 20+ Symbol；BR 不是 DI token |
| 2 | [SSE] 流管道 | 13 个事件类型，15 个 Parser |
| 3 | [Store] 状态架构 | 8 个 Zustand Store，无 Immer |
| 4 | [Error] 错误系统 | 完整错误码枚举，3 条传播路径 |
| 5 | [React] 组件层级 | 三层架构（L1/L2/L3），17+ Alert 渲染点 |
| 6 | [Event] 事件总线 | TEA 遥测系统 |
| 7 | [IPC] 进程间通信 | 三层 IPC 架构，无 ipcRenderer |
| 8 | [Setting] 设置系统 | 完整设置 key 列表 |
| 9 | [Sandbox] 沙箱 | BlockLevel/AutoRunMode/ConfirmMode 枚举 |
| 10 | [MCP] 工具调用 | 80+ ToolCallName |

### Top 3 Hook 点

1. **PlanItemStreamParser._handlePlanItem** (~7502500) — 综合 4.75，命令确认最佳点
2. **teaEventChatFail** (~7458679) — 综合 4.5，后台错误检测最佳点
3. **DI Container resolve** (任意) — 综合 4.0，服务访问最佳点

### 关键纠正

- BR 不是 DI token（BR=path模块）
- FX 不是 DI 解构（FX=findTargetAgent）
- 无 ipcRenderer（VS Code 命令系统）
- 无 Immer（展开运算符）

---

## [2026-04-25 22:30] 探索工具箱部署完成

### 工具链部署（4 层级）

| 层级 | 工具 | 状态 | 核心能力 |
|------|------|------|---------|
| L0 | PowerShell IndexOf/Select-String | ✅ 内置 | 毫秒级字符串定位 |
| L1 | js-beautify 1.15.4 | ✅ **主要工具** | 代码美化（**347,099 行**） |
| L1 | @babel/parser + traverse 7.x | ✅ 已安装 | AST 分析（**38,630 函数** + **1,009 类**） |
| L2 | reverse-machine 2.1.5 | ⚠️ 需 API key | AI 驱动变量重命名 |
| L3 | ast-search-js 1.10.2 | ✅ 备选 | 结构化代码搜索 |

### 性能基准

js-beautify: ~20s → 347,099行 | Extract-AllFunctions: ~90s → 38,630条 | Select-String: <1s

---

## P0/P1 盲区深度探索记录

### P0 盲区 Phase 2+3 探索成果

**核心发现（6 个 Major）**:

1. **ai.* DI Token 家族 (5个新发现)** ⭐⭐⭐⭐⭐ — IDocsetService/IDocsetStore/IDocsetCkgLocalApiService/IDocsetOnlineApiService/IWebCrawlerFacade
2. **31 个 I*Service DI Token 完整映射** ⭐⭐⭐⭐⭐ — 包括 IStuckDetectionService/IAutoAcceptService/IPrivacyModeService/ICommercialApiService
3. **VS Code DI 注入机制** ⭐⭐⭐⭐⭐ — Inject 装饰器使用 Symbol("__instance__")
4. **API 端点映射** ⭐⭐⭐⭐ — a0ai-api.byteintlapi.com, bytegate-sg, pc-mon-sg
5. **HaltChainable 事件链机制** ⭐⭐⭐⭐ — VS Code Event.chain()

### deep-exploration 补充发现

1. **DI 注册数 51→186，注入数 101→816**
2. **25 个 VS Code 命令注册** — 在 bootstrapApplicationContainer(@10477819)
3. **38 个 ToolCallName 完整枚举** — @40836
4. **kg 错误码从 ~30 扩展到 56**

### 四维索引概览

| 索引类型 | 条目数 | 说明 |
|---------|--------|------|
| 按域搜索 | ~170 | 17 个域分类 |
| 按偏移量范围 | ~130 | 4 个区间 |
| 按功能 | ~80 | 6-7 个功能分类 |
| 按 confidence | ~120 | 3-4 个级别 |

---

## Symbol.for→Symbol 迁移完整映射

### 已迁移（4 个）

IPlanItemStreamParser, ISessionStore, IInlineSessionStore, IModelStore → 全部改用 Symbol("...")

### 未迁移（6+ 个）

IErrorStreamParser, INotificationStreamParser, ITextMessageChatStreamParser, ITeaFacade, ISideChatStreamService, IInlineChatStreamService, IDocsetService (及4个ai.*) → 仍使用 Symbol.for("...")

### 统计

Symbol.for 仍使用: ~185 个 | Symbol() 新形式: ~97 个 | 字符串/属性访问/自引用: 7 个

---

## 🔄 闭环检查点 (Loop Closure Checklist)

> **Agent 完成工作后必须自动执行以下步骤，无需人类干预。**
> 这是 Explorer Agent 的自治闭环协议的一部分。详见 [AGENTS.md](../AGENTS.md) §闭环保障。

### 必做项（每次会话结束前）

- [ ] **核心产出已写入权威文件**
  - `shared/discoveries.md` 已更新（新增发现或修正记录）
  - 文件非空、格式合法（Markdown 可解析）
- [ ] **运行 Prompt 同步**
  ```powershell
  powershell scripts/sync-prompts.ps1 -Zone "domain-overview-table,correction-facts,blindspot-table,correction-shortcut" -Prompt explorer
  ```
  - 只同步 Explorer 相关的 zone（不触碰 Developer 的数据）
  - 确认退出码为 0 且无 FAIL
- [ ] **最终报告包含同步状态**
  - 报告末尾有 "🔄 闭环状态: ✓ synced N zones" 或类似摘要
  - 如果同步失败，报告中有明确的警告说明

### 可选项（增强模式）

- [ ] **源文件新鲜度检测**
  - 检查 `shared/discoveries.md` 的 LastWriteTime 是否比 `prompts/explorer-agent-prompt.md` 新
  - 如果是，说明你的写入尚未被同步 → 强制执行 sync
- [ ] **运行 auto-heal 验证系统健康**
  ```powershell
  powershell scripts/auto-heal.ps1 -DiagnoseOnly
  ```
  - 虽然这是 Developer 的主要职责，但 Explorer 也应在重大变更后确认未破坏现有补丁
- [ ] **清理临时产物**
  - 删除本次会话创建的 T3/T4 级别临时文件（如有）
  - 不归档到 .archive/（按 AGENTS.md 规则）

### 闭环失败时的降级策略

| 失败场景 | 处理方式 | 报告要求 |
|---------|---------|---------|
| discoveries.md 写入失败 | 重试一次；仍失败则将发现直接附在报告中 | 标注 "⚠ discoveries 未持久化" |
| sync-prompts 脚本不存在 | 跳过；在报告中标注 "⚠ 闭环跳过(无脚本)" | 不影响主任务完成 |
| sync 执行但部分 zone 失败 | 记录失败的 zone 名称；继续交付 | 标注 "⚠ 部分同步失败: zone-x, zone-y" |
| 所有操作成功 | 正常结束；报告中包含 ✓ 状态 | 标准交付 |
