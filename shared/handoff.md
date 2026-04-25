# 会话交接单

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
