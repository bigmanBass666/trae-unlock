---
domain: architecture
sub_domain: docset
module: architecture-reference
description: Docset 域架构文档 — 文档集与知识库系统完整逆向工程
read_priority: P2
format: reference
focus: DI Token、DocsetServiceImpl、CKG API、Knowledges 子系统
last_verified: 2026-04-26
---

# Docset 域架构文档

> Trae AI 聊天模块中文档集（Docset）与知识库（Knowledges）系统的完整逆向工程

> last_verified: 2026-04-26 | 兼容版本: Trae v3.3.x (10490721 chars)

## 1. 概述

Docset 域是 Trae 管理文档集和知识库的核心子系统，负责为 AI 聊天提供上下文增强能力。它包含两套独立但互补的子系统：

1. **Docset 子系统** — 文档集管理（内置文档集 + 自定义 URL 文档集 + 企业文档集），通过 CKG（Code Knowledge Graph）进行索引和检索
2. **Knowledges 子系统** — 项目知识库（自动从历史会话蒸馏知识），后台任务驱动

该域通过 5 个 `ai.*` DI Token 和 6 个 Knowledges 服务组成完整的服务链。

### 核心架构特征

| 维度 | 描述 |
|------|------|
| DI Token 模式 | 全部使用 `Symbol.for("ai.*")` 前缀，与 ICommercialPermissionService 的 `aiAgent.*` 前缀不同 |
| 服务分层 | DocsetService（编排层）→ CkgLocalApiService/CkgOnlineApiService（数据层）→ WebCrawlerFacade（采集层） |
| 存储分层 | DocsetStore（Zustand 内存状态）+ StateStorage2（持久化，按 userId 隔离） |
| 权限门控 | `ent_knowledge_base` SaaS 功能开关，控制企业文档集访问 |
| 任务模型 | Knowledges 使用后台任务（FE 枚举：Init/Update/Rebuild），支持暂停/恢复/关机 veto |

### 补丁潜力评估

| 补丁 | 可行性 | 说明 |
|------|--------|------|
| bypass-ent-knowledge-base-gating | ⭐⭐⭐⭐ | 修改 isSaaSFeatureEnabled("ent_knowledge_base") 返回值 |
| force-knowledges-enable | ⭐⭐⭐ | 修改 Knowledges 功能开关检查 |
| unlock-enterprise-docsets | ⭐⭐⭐⭐ | 绕过 SaaS 用户身份检查，允许非 SaaS 用户访问企业文档集 |

## 2. 核心实体

### 2.1 DI Token 一览

| Token | 变量 | 偏移量 | Token 类型 | 注册方式 | 实现类 |
|-------|------|--------|-----------|---------|--------|
| ai.IDocsetService | WK | 3546321 (定义) / 7749472 (注册) | Symbol.for | `uJ({identifier:WK.IDocsetService})` | Gd (DocsetServiceImpl) |
| ai.IDocsetStore | TM | 7244792 | Symbol.for | 类内定义 | TD (DocsetStore) |
| ai.IDocsetCkgLocalApiService | Wj | 7715126 | Symbol.for | `uJ({identifier:Wj})` | WY (CkgLocalApiService) |
| ai.IDocsetOnlineApiService | WV | 7720282 | Symbol.for | `uJ({identifier:WV})` | Wq (DocsetOnlineApiService) |
| ai.IWebCrawlerFacade | Ga | 7725219 | Symbol.for | `uJ({identifier:Ga})` | Gs (WebCrawlerFacade) |

> **关键发现**: 所有 5 个 Token 均使用 `Symbol.for`（未迁移到 Symbol），与 Model 域的 IModelStore（已迁移）不同。Token 定义在 webpack 模块 36518 中导出。

### 2.2 DocsetServiceImpl (Gd) @7726546

**职责**: 文档集编排层，协调 Store、CKG API、WebCrawler 三层服务

**关键属性**:
```javascript
{
  _docsetListUpdated: false,           // 内置文档集列表是否已更新
  _projectIdToCrawlerStub: Map,        // projectId → crawlerStubId 映射
  _crawlerInProgressProjectIds: Set,   // 正在爬取的 projectId 集合
  watchCustomDocsetStateInstance: Map,  // 自定义文档集状态监听实例
  _enterpriseDocsetPollingTimer: null,  // 企业文档集轮询定时器
  _credentialSubscriber: null,         // 凭证变更订阅
  _lastEnterpriseDocsetFetchTimestamp: 0, // 上次企业文档集获取时间
  _entitlementChangeDisposable: null    // 权益变更订阅
}
```

**DI 注册**: `Gd = Gl([uJ({identifier:WK.IDocsetService})], Gd)` @7749472

**DI 注入**:
| 注入属性 | Token | 说明 |
|----------|-------|------|
| _docsetStore | TM (ai.IDocsetStore) | 文档集状态存储 |
| _docsetCkgLocalApiService | Wj (ai.IDocsetCkgLocalApiService) | CKG 本地 API |
| _docsetOnlineApiService | WV (ai.IDocsetOnlineApiService) | CKG 在线 API |
| _webCrawlerInfra | Ga (ai.IWebCrawlerFacade) | 网页爬虫 |
| _credentialStore | ICredentialStore | 凭证存储 |
| _entitlementService | IICubeEntitlementService | 权益服务 |
| _logService | ILogService | 日志服务 |

**关键方法**:

| 方法 | 功能 |
|------|------|
| `createCustomUrlDocset(tag, url, prefix, options)` | 创建自定义 URL 文档集（爬取+索引） |
| `createLocalFileDocset(tag, uris, options)` | 创建本地文件文档集 |
| `deleteDocset(projectId)` | 删除文档集（中止爬取+删除 CKG 索引） |
| `reindexDocset(docset)` | 重建文档集索引 |
| `retrieveDocsets(query, options)` | 检索文档集 RAG |
| `getAllBuiltinDocsetsListAndUpdateDocsetStore(force)` | 获取内置文档集列表并更新 Store |
| `setVisibleBuiltinDocsets(tags)` | 设置可见内置文档集 |
| `searchDocsetsByName(query)` | 按名称搜索自定义文档集 |
| `searchBuiltinDocsetsByName(query)` | 按名称搜索内置文档集 |
| `getDocsetStatus(projectId)` | 获取文档集索引状态 |
| `cancelDocsetBuild(projectId)` | 取消文档集构建 |
| `startEnterpriseDocsetPolling()` | 启动企业文档集轮询 |
| `stopEnterpriseDocsetPolling()` | 停止企业文档集轮询 |

### 2.3 DocsetStore (TD) @7244792

**职责**: 文档集状态管理（Zustand Store，Aq 基类）

**状态结构**:
```javascript
{
  builtinDocsets: [],                  // 内置文档集列表
  builtinDocsetVersion: "",            // 内置文档集版本号
  customDocsets: [],                   // 自定义文档集列表
  searchableBuiltinDocsets: [],        // 可搜索的内置文档集 tag 列表
  enterpriseDocsetIdsToRefresh: []     // 需要刷新的企业文档集 ID 列表
}
```

**存储键**:
| 键 | 常量 | 说明 |
|----|------|------|
| `{userId}::docset-list::v1.1` | — | 持久化存储键（按 userId 隔离） |
| `builtin_list` | Tk | 内置文档集列表 |
| `builtin_version` | TI | 内置文档集版本 |
| `searchable_builtin_list` | TT | 可搜索内置文档集 |
| `custom_list` | TN | 自定义文档集 |

**关键 Actions**:
| Action | 功能 |
|--------|------|
| `setBuiltinDocsets(list)` | 设置内置文档集 |
| `setBuiltinDocsetVersion(ver)` | 设置内置文档集版本 |
| `setCustomDocsets(list)` | 设置自定义文档集 |
| `setSearchableBuiltinDocsets(tags)` | 设置可搜索内置文档集 |
| `removeCustomDocset(projectId)` | 删除自定义文档集 |
| `partialUpdateCustomDocset(projectId, partial)` | 部分更新自定义文档集 |
| `setEnterpriseDocsetIdsToRefresh(ids)` | 设置企业文档集刷新列表 |

**关键方法**:
| 方法 | 功能 |
|------|------|
| `getSearchableFullList()` | 获取可搜索完整列表（内置+自定义，按时间排序） |
| `initializeStorage(force?)` | 初始化持久化存储（按 userId 创建） |
| `dispose()` | 释放凭证订阅 |

### 2.4 DocsetCkgLocalApiService (WY) @7717236

**职责**: CKG 本地 API 通信（文档集索引管理）

**API 定义**:
```javascript
static SERVICE = "docset"
static METHODS = {
  InitCkgDocsetProject: "init_ckg_docset_project",
  InitCkgLocalDocsetProject: "init_ckg_localfile_docset_project",
  AddCkgDocsetIndex: "add_ckg_docset_index",
  GetCkgDocsetIndexStatus: "get_ckg_docset_index_status",
  CancelCkgDocsetIndex: "cancel_ckg_docset_index_build",
  DeleteCkgDocsetProject: "delete_ckg_docset_index",
  RetrieveCkgDocsetRag: "retrieve_ckg_docset_rag"
}
```

**DI 注入**:
| 注入属性 | Token | 说明 |
|----------|-------|------|
| _logService | bY (ILogService) | 日志服务 |
| _aiClientManagerService | M5 | AI 客户端管理 |
| _ckgFacade | S2.ICKGService | CKG 核心 facade |

**关键方法**:
| 方法 | API Method | 功能 |
|------|-----------|------|
| `createCkgUrlVirtualProject(projectId, url)` | init_ckg_docset_project | 创建 URL 虚拟项目 |
| `createCkgLocalFileVirtualProject(projectId, uri, globs)` | init_ckg_localfile_docset_project | 创建本地文件虚拟项目 |
| `createIndexForDocuments(docs, projectId)` | add_ckg_docset_index | 添加文档索引 |
| `getCkgVirtualProjectStatus(projectId)` | get_ckg_docset_index_status | 获取索引状态 |
| `cancelCkgVirtualProjectIndex(projectId)` | cancel_ckg_docset_index_build | 取消索引构建 |
| `deleteCkgVirtualProject(projectId)` | delete_ckg_docset_index | 删除虚拟项目 |
| `retrieveCkgDocsetRag(query, options)` | retrieve_ckg_docset_rag | RAG 检索 |

### 2.5 DocsetOnlineApiService (Wq) @7720282

**职责**: CKG 在线 API 通信（官方文档集更新和在线检索）

**API 定义**:
```javascript
static SERVER_NAME = "docset"
static METHODS = {
  ShouldOfficialDocsetUpdate: "should_official_docset_update",
  PullLatestOfficialDocset: "pull_latest_official_docset",
  RetrieveRemoteDocsetRag: "retrieve_remote_docset_rag",
  FetchOnlineDocsetDetails: "fetch_online_docset_details"
}
```

**关键方法**:
| 方法 | API Method | 功能 |
|------|-----------|------|
| `isLatestOfficialDocsetVersion(version)` | should_official_docset_update | 检查是否最新版本 |
| `pullLatestOfficialDocset()` | pull_latest_official_docset | 拉取最新官方文档集 |
| `retrieveRemoteDocsetRag(query, options)` | retrieve_remote_docset_rag | 远程 RAG 检索 |
| `fetchOnlineDocsetDetails(details)` | fetch_online_docset_details | 获取在线文档集详情 |

### 2.6 WebCrawlerFacade (Gs) @7725219

**职责**: 网页爬虫 facade，封装 IICubeCrawlerService

**DI 注入**:
| 注入属性 | Token | 说明 |
|----------|-------|------|
| _logService | S2.ILogService | 日志服务 |
| _crawlerService | S2.IICubeCrawlerService | 爬虫服务 |

**关键方法**:
| 方法 | 功能 |
|------|------|
| `crawlForPages(entryPoint, prefix)` | 爬取页面（递归，linkType=DOCSET） |
| `getCrawlStatus(stubId)` | 获取爬取状态 |
| `abortCrawl(stubId)` | 中止爬取 |
| `onCrawlProgress(stubId, callback)` | 监听爬取进度 |

### 2.7 Knowledges 子系统

#### 任务类型枚举 (FE)

| 枚举值 | 含义 |
|--------|------|
| Init | 初始化知识库 |
| Update | 更新知识库（从历史会话蒸馏） |
| Rebuild | 重建知识库 |

#### 任务状态枚举 (FA)

| 枚举值 | 含义 |
|--------|------|
| Pending | 等待中 |
| Running | 运行中 |
| Committing | 提交中 |
| (其他) | 已完成/已失败 |

#### VS Code 命令注册

| 命令 | 功能 |
|------|------|
| `icube.knowledges.rebuild` | 重建知识库 |
| `icube.knowledges.update` | 更新知识库 |
| `icube.knowledges.pause` | 暂停当前任务 |
| `icube.knowledges.statusClick` | 状态栏点击 |

#### Knowledges 关键服务

| 服务 | DI Token | 说明 |
|------|---------|------|
| KnowledgesTaskService | FC | 后台任务管理（Init/Update/Rebuild） |
| KnowledgesPersistenceService | — | 知识库持久化（.trae/knowledges 目录） |
| KnowledgesNotificationService | — | 知识库通知（更新成功/失败/部分成功） |

#### Knowledges 功能开关

| 开关 | 说明 |
|------|------|
| ABTest / Beta switch | 控制功能是否启用 |
| `knowledges-debug-switch` | 调试面板开关 |
| `AI.knowledges.debugPanelEnabled` | 调试面板配置项 |

### 2.8 枚举

#### DocsetCkgIndexStatus @2786148

| 枚举值 | 含义 |
|--------|------|
| Building | 正在构建 |
| Finished | 构建完成 |
| Failed | 构建失败 |

#### DocsetCKGStatus @2787212

| 枚举值 | 含义 |
|--------|------|
| Building | 正在构建 |
| Finished | 构建完成 |
| Failed | 构建失败 |

#### 爬取状态 (Gt)

| 枚举值 | 含义 |
|--------|------|
| COMPLETED | 爬取完成 |
| FAILED | 爬取失败 |
| BLOCKED | 被阻止 |
| LOGIN_REQUIRED | 需要登录 |

### 2.9 文档集数据结构

```javascript
// 内置/自定义文档集通用结构
{
  tag: "react-docs",                    // 文档集标签
  doc_type: "builtin" | "custom" | "enterprise",  // 类型
  project_id: "custom-v1-xxx",          // CKG 项目 ID
  entry_point: "https://react.dev",     // 入口 URL（自定义）
  prefix: "https://react.dev",          // URL 前缀（自定义）
  type: "doc",                          // 固定值
  docId: "custom-v1-xxx",              // 文档 ID
  status: DocsetCkgIndexStatus,         // 索引状态
  index_time: 1234567890,              // 索引时间
  doc_detail: [{url, title, status}],   // 文档详情
  failed_doc_detail: [{url, title, status, update_time}],  // 失败文档
  createdAt: 1234567890,               // 创建时间
  recentUsedAt: 1234567890,            // 最近使用时间
  relative_globs_to_load: ["*.txt"],   // 相对 glob（本地文件）
  is_internal_usage_limit: false,       // 是否内部使用限制
  display_name: "React Docs"           // 显示名称
}
```

## 3. 数据流

### 3.1 自定义 URL 文档集创建流程

```
用户输入 URL + 前缀
    │
    ▼
Gd.createCustomUrlDocset(tag, url, prefix, options) @7733429
    │
    ├─ 1. 生成 projectId: `custom-v1-${C_()}`
    ├─ 2. WY.createCkgUrlVirtualProject(projectId, url)
    │      → API: init_ckg_docset_project
    │
    ├─ 3. Gs.crawlForPages(url, prefix)
    │      → IICubeCrawlerService.crawlByEntrypoint({entryPoint, prefix, recursive:true, linkType:DOCSET})
    │      → 返回 {stubId}
    │
    ├─ 4. 创建 Docset 对象 (status=Building)
    │
    └─ 5. Gs.onCrawlProgress(stubId, callback)
           │
           ├─ 页面完成 (COMPLETED):
           │   ├─ WY.createIndexForDocuments([{uri, name, content}], projectId)
           │   │   → API: add_ckg_docset_index
           │   └─ 更新 doc_detail
           │
           ├─ 页面失败 (FAILED/BLOCKED/LOGIN_REQUIRED):
           │   └─ 更新 failed_doc_detail
           │
           └─ 任务完成 (Gi.COMPLETED):
               ├─ WY.getCkgVirtualProjectStatus(projectId)
               │   → API: get_ckg_docset_index_status
               └─ 监听 CKG 索引状态直到 Finished/Failed
```

### 3.2 本地文件文档集创建流程

```
用户选择本地文件/文件夹
    │
    ▼
Gd.createLocalFileDocset(tag, uris, options)
    │
    ├─ 1. 生成 projectId
    ├─ 2. 计算公共父目录 (WF 函数)
    ├─ 3. 生成 glob 模式 (WU 函数): *.txt, *.md
    ├─ 4. WY.createCkgLocalFileVirtualProject(projectId, uri, globs)
    │      → API: init_ckg_localfile_docset_project
    └─ 5. 监听 CKG 索引状态
```

### 3.3 内置文档集更新流程

```
应用启动 / 凭证变更
    │
    ▼
Gd.getAllBuiltinDocsetsListAndUpdateDocsetStore(force) @7738129
    │
    ├─ 首次调用或 force:
    │   └─ Wq.pullLatestOfficialDocset()
    │       → API: pull_latest_official_docset
    │       → 返回 {list, version}
    │       → TD.actions.setBuiltinDocsets(list)
    │       → TD.actions.setBuiltinDocsetVersion(version)
    │
    └─ 非首次且版本未变:
        └─ 返回 TD.getState().builtinDocsets（缓存）
```

### 3.4 企业文档集轮询流程

```
用户登录 (SaaS 用户)
    │
    ▼
Gd._initEnterpriseDocsetPollingOnLogin() @7727418
    │
    ├─ 检查用户身份: userProfile.scope === bK.SAAS
    ├─ 检查功能开关: _entitlementService.isSaaSFeatureEnabled("ent_knowledge_base")
    │
    ├─ 开关开启:
    │   └─ startEnterpriseDocsetPolling()
    │       → 间隔: ENTERPRISE_DOCSET_POLLING_INTERVAL = 600000 (10分钟)
    │       → 获取企业文档集差异
    │       → 更新 TD.actions.setBuiltinDocsets
    │
    └─ 开关关闭:
        └─ TD.actions.setBuiltinDocsets([]) // 清空内置列表
    │
    ▼
凭证变更监听:
    ├─ userId 或 scope 变化 → 重新评估
    └─ SaaS 权益变更 → isSaaSFeatureEnabled 重新检查
```

### 3.5 RAG 检索流程

```
AI 聊天请求上下文增强
    │
    ▼
sendToAgent (FF 函数 @7594424)
    │  uj.getInstance().resolve(WK.IDocsetService)
    │
    ▼
Gd.retrieveDocsets(query, options)
    │
    ▼
WY.retrieveCkgDocsetRag(query, options)
    │  → API: retrieve_ckg_docset_rag
    │
    ▼
返回 RAG 结果（用于 AI 上下文增强）
```

### 3.6 Knowledges 后台任务流程

```
触发源: 首次打开项目 / 命令 / 定时
    │
    ▼
KnowledgesTaskService.executeTask(type, options)
    │  type: FE.Init | FE.Update | FE.Rebuild
    │
    ├─ 检查功能是否启用 (ABTest / Beta switch)
    ├─ 检查是否有正在运行的任务
    ├─ 关机 veto: 如果任务运行中，阻止 IDE 关闭
    │
    ▼
执行知识蒸馏:
    ├─ 收集历史会话
    ├─ 调用 AI 生成知识文件
    ├─ 写入 .trae/knowledges/ 目录
    └─ 安全检查: 确保只写入 .trae/knowledges/ 内
    │
    ▼
通知:
    ├─ 成功: knowledges_update_notification_success
    ├─ 部分成功: knowledges_update_notification_partial
    ├─ 失败: knowledges_update_notification_failed
    └─ 空: knowledges_update_notification_empty
```

### 3.7 Docset-Chat 集成流程

```
FX 函数 @7612211 (服务工厂)
    │  返回: {
    │    logService, sessionService, agentService,
    │    docsetService, sessionServiceV2,
    │    commandService, stripeService,
    │    sessionStore, sessionsStoreService,
    │    sessionRelationStore, contextKeyFacade
    │  }
    │
    ▼
sendToAgent (FF 函数 @7594424)
    │  resolve(WK.IDocsetService) → docsetService
    │  用于: 文档集上下文注入 AI 请求
    │
    ▼
parseInputs @7608073
    │  debugFetchEnterpriseDocsets:
    │    uj.getInstance().resolve(WK.IDocsetService).debugFetchEnterpriseDocsets()
    │
    ▼
initializeKnowledgesService @7608073
    │  resolve(etO) → Knowledges 功能检查
    │  resolve(FC) → KnowledgesTaskService
    │  await i.initialize()
```

## 4. 域间关系

### 4.1 与 DI 域的关系

| 关系 | 说明 |
|------|------|
| 5 个 ai.* DI Token | 全部使用 Symbol.for（未迁移），定义在 webpack 模块 36518 |
| DI 注册模式 | `uJ({identifier:WK.IDocsetService})` — 使用模块导出引用而非变量 |
| DI 注入模式 | `uX(TM)`, `uX(Wj)`, `uX(WV)`, `uX(Ga)` — 使用变量引用 |

### 4.2 与 Store 域的关系

| Store | 关系 |
|-------|------|
| DocsetStore (TD) | Zustand Store，Aq 基类，管理文档集列表状态 |
| ICredentialStore | 提供用户身份信息，影响存储键和权限门控 |
| IEntitlementStore | 提供 SaaS 权益信息，控制企业文档集访问 |

### 4.3 与商业权限域的关系

| 交叉点 | 说明 |
|--------|------|
| `isSaaSFeatureEnabled("ent_knowledge_base")` | 企业文档集功能开关，SaaS 用户专属 |
| `userProfile.scope === bK.SAAS` | SaaS 用户身份检查 |
| `onDidSaaSEntitlementInfoChange` | SaaS 权益变更监听，触发企业文档集轮询重启 |

### 4.4 与 SSE 域的关系

| 交叉点 | 说明 |
|--------|------|
| `chat/start_ckg_indexing` | 客户端请求开始 CKG 索引 |
| `chat/cancel_ckg_indexing` | 客户端请求取消 CKG 索引 |
| `chat/clear_ckg_indexing` | 客户端请求清除 CKG 索引 |
| `chat/get_ckg_running_status` | 客户端查询 CKG 运行状态 |
| `chat/model_list` | 服务端推送模型列表（含文档集相关模型） |

### 4.5 与 Model 域的关系

| 交叉点 | 说明 |
|--------|------|
| Knowledges 使用模型 | 知识蒸馏任务使用 AI 模型生成知识文件 |
| Docset RAG 注入 | 文档集检索结果作为 AI 聊天上下文 |

### 4.6 与命令确认域的关系

| 交叉点 | 说明 |
|--------|------|
| Docset API 通信 | 通过 `wrapRequestWithCredential` 包装请求，携带凭证 |

## 5. 补丁相关性

### 5.1 bypass-ent-knowledge-base-gating ⭐⭐⭐⭐

**目标**: 允许非 SaaS 用户访问企业文档集

**方案 A — 修改 isSaaSFeatureEnabled 返回值**

- 位置: `Gd._initEnterpriseDocsetPollingOnLogin` @7727418
- 修改: 将 `isSaaSFeatureEnabled("ent_knowledge_base")` 的结果强制为 true
- 优点: 精确控制，不影响其他 SaaS 功能
- 风险: 企业文档集 API 可能验证服务端身份

**方案 B — 修改 SaaS 身份检查**

- 位置: `userProfile.scope === bK.SAAS` 检查
- 修改: 跳过 scope 检查，直接进入轮询逻辑
- 缺点: 影响范围较大

### 5.2 force-knowledges-enable ⭐⭐⭐

**目标**: 强制启用 Knowledges 功能

- 位置: Knowledges 功能开关检查
- 修改: 绕过 ABTest/Beta switch 检查
- 限制: 功能可能依赖服务端 API，前端绕过可能无效

### 5.3 unlock-enterprise-docsets ⭐⭐⭐⭐

**目标**: 解锁企业文档集功能

- 位置: Gd 类的企业文档集轮询逻辑
- 修改: 强制 `startEnterpriseDocsetPolling()`，跳过 SaaS 检查
- 注意: 需要配合 bypass-ent-knowledge-base-gating

### 5.4 docset-unlimited-crawl ⭐⭐

**目标**: 移除爬取限制

- 位置: WebCrawlerFacade
- 限制: 爬取由 IICubeCrawlerService 控制，可能无法前端绕过

## 6. 搜索模板

### DOC-01: IDocsetService Token
```
IndexOf("ai.IDocsetService") → @3546321 (定义), @7594424 (sendToAgent 注入), @7608073 (parseInputs), @7612211 (FX 工厂), @7749472 (uJ 注册)
```

### DOC-02: IDocsetStore Token
```
IndexOf("ai.IDocsetStore") → @7244792
```

### DOC-03: IDocsetCkgLocalApiService Token
```
IndexOf("ai.IDocsetCkgLocalApiService") → @7715126
```

### DOC-04: IDocsetOnlineApiService Token
```
IndexOf("ai.IDocsetOnlineApiService") → @7720282
```

### DOC-05: IWebCrawlerFacade Token
```
IndexOf("ai.IWebCrawlerFacade") → @7725219
```

### DOC-06: DocsetServiceImpl
```
IndexOf("class Gd") → @7726546
IndexOf("uJ({identifier:WK.IDocsetService})") → @7749472
```

### DOC-07: DocsetStore
```
IndexOf("class TD extends Aq") → @7244792 (附近)
IndexOf("builtinDocsets") → 多处
```

### DOC-08: CKG API Methods
```
IndexOf("init_ckg_docset_project") → @7717236
IndexOf("retrieve_ckg_docset_rag") → 多处
IndexOf("cancel_ckg_docset_index_build") → 多处
```

### DOC-09: 企业文档集门控
```
IndexOf("ent_knowledge_base") → @7727418, @7728221, @7728791
IndexOf("startEnterpriseDocsetPolling") → 多处
```

### DOC-10: Knowledges 命令
```
IndexOf("icube.knowledges") → @8191984+
IndexOf("icube.knowledges.rebuild") → @10488238
IndexOf("icube.knowledges.update") → @10488238+
IndexOf("icube.knowledges.pause") → @10488238+
```

### DOC-11: Knowledges 任务类型
```
IndexOf("knowledges_committing") → i18n 键
IndexOf("knowledges_debug_panel") → i18n 键
IndexOf("FE.Init") / "FE.Update" / "FE.Rebuild" → 任务类型引用
```

### DOC-12: CKG IPC 通道
```
IndexOf("chat/start_ckg_indexing") → @13644
IndexOf("chat/cancel_ckg_indexing") → @11405
IndexOf("chat/clear_ckg_indexing") → @11722
```

## 7. 盲区

### 7.1 已知盲区

| 盲区 | 说明 | 优先级 |
|------|------|--------|
| KnowledgesTaskService 完整实现 | FC 类未找到（class FC 返回 -1），可能使用不同命名或在不同模块 | P1 |
| KnowledgesPersistenceService | 知识库持久化服务的完整实现未定位 | P1 |
| IICubeCrawlerService | WebCrawlerFacade 的底层爬虫服务，实现类未定位 | P2 |
| CKG 核心 facade | S2.ICKGService / ICKGCoreService 的实现未追踪 | P2 |
| DocsetServiceImpl 完整方法列表 | Gd 类超过 5000 chars，部分方法未完整提取 | P2 |
| 企业文档集轮询细节 | startEnterpriseDocsetPolling 的完整实现和 API 调用 | P2 |
| Knowledges 蒸馏 AI 模型 | 知识蒸馏使用的具体模型和 prompt 未定位 | P3 |
| 文档集与 #mention 集成 | 文档集在聊天输入中的 #mention 选择器逻辑 | P3 |
| DocsetCkgIndexStatus 完整枚举 | 枚举值可能不止 Building/Finished/Failed | P3 |
| 自定义文档集存储限制 | 是否有数量/大小限制未确认 | P3 |

### 7.2 待验证项

| 项目 | 验证方法 |
|------|---------|
| bypass-ent-knowledge-base-gating 是否有效 | 修改后测试非 SaaS 用户能否获取企业文档集 |
| CKG API 是否验证用户身份 | 抓包检查 API 请求中的身份信息 |
| Knowledges 功能开关的具体位置 | 搜索 ABTest/Beta switch 的配置键 |
| FC 类的实际混淆名 | 通过 uJ 注册或 DI 注入反查 |
| 文档集 RAG 检索结果如何注入 AI 请求 | 追踪 sendToAgent 中 docsetService 的调用路径 |
