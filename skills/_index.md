---
module: skills-index
description: 渐进式知识索引 — Layer 1 元数据 + Layer 2 路径
read_priority: P0
read_when: 每次 AI 会话开始（与 handoff.md 一起加载）
write_when: 新增/删除 Skill 或业务上下文时
format: index
---

# 知识索引

> 渐进式索引协议：启动时只加载本索引（Layer 1），需要详情时按 location 路径加载 Layer 2。
> 原则：代码优先、只补充缺失、做索引不做百科。

## Skills（领域专长封装）

| name | description | location |
|------|-------------|----------|
| explore-source | 在 ~10MB 压缩 JS 源码中进行系统性、可重复、可验证的代码测绘 | skills/explore-source.md |
| develop-patch | 接收问题报告/需求，在 definitions.json 中创建或更新补丁 | skills/develop-patch.md |
| verify-patch | 验证补丁正确应用且不引入新问题，执行 apply + verify 流程 | skills/verify-patch.md |
| spec-rfc | 需求工程：需求获取 → 需求分析 → 需求规格 → 技术设计(RFC) → 验证 | skills/spec-rfc.md |

## 业务上下文（代码"看不见"的知识）

| name | description | location |
|------|-------------|----------|
| tcc-config-driven-behavior | 通过 TCC 配置中心控制功能开关、降级和灰度策略的行为 | skills/business-context/tcc-config.md |
| di-token-migration | Symbol.for→Symbol 迁移模式：Store/Parser 类已迁移，Facade/Service 类保留 Symbol.for | shared/discoveries.md §Symbol.for→Symbol 迁移完整映射 |
| commercial-permission-chain | ICommercialPermissionService(NS)→IEntitlementStore(Nu)→ICredentialStore(MX) 付费限制判断链 | shared/discoveries.md §[Commercial] 商业权限域 |
| error-code-system | kg 枚举(56个) + eA 枚举(客户端) + efg 可恢复列表(14个) + J/ee/X 标志变量 | shared/discoveries.md §[Error] 错误处理系统 |
| sse-pipeline | EventHandlerFactory(Bt)→15 Parser 类，SSE 事件分发与流解析 | shared/discoveries.md §[SSE] 流管道 |

## 源码发现（11 域完整映射）

| name | description | location |
|------|-------------|----------|
| DI 依赖注入 | uj 容器 + 186 注册 + 817 注入 + 106 DI Token | shared/discoveries.md §[DI] 依赖注入容器 |
| SSE 流管道 | EventHandlerFactory + 15 Parser + 13 事件类型 | shared/discoveries.md §[SSE] 流管道 |
| Store 状态架构 | 8 个 Zustand Store + Aq 基类 + uB Hook | shared/discoveries.md §[Store] Zustand 状态架构 |
| Error 错误处理 | kg 枚举 56 个 + efg 可恢复 14 个 + 3 条传播路径 | shared/discoveries.md §[Error] 错误处理系统 |
| React UI 组件 | 三层架构 L1/L2/L3 + 16 组件导出 + 冻结行为 | shared/discoveries.md §[React] UI 组件层 |
| Event 事件总线 | TEA 遥测 + Zustand subscribe + DOM 事件 | shared/discoveries.md §[Event] 事件总线与遥测 |
| IPC 进程间通信 | 三层架构 Server→Main→Renderer + 25 命令注册 | shared/discoveries.md §[IPC] 进程间通信 |
| Setting 设置系统 | AI.toolcall.* 配置 + ConfirmMode 已移除 | shared/discoveries.md §[Setting] 设置系统 |
| Sandbox 沙箱 | BlockLevel 6 值 + AutoRunMode 5 值 + 决策矩阵 | shared/discoveries.md §[Sandbox] 沙箱与命令执行 |
| MCP 工具调用 | ToolCallName 38 个 + 8 步生命周期 + confirm_info | shared/discoveries.md §[MCP] 工具调用系统 |
| Commercial 商业权限 | NS 类 6 方法 + efi() Hook + bJ/bK 枚举 | shared/discoveries.md §[Commercial] 商业权限域 |
| Docset 文档集 | 5 个 ai.* DI Token + 三层服务架构 | shared/discoveries.md §[Docset] 文档集域 |
| Model 模型选择 | computeSelectedModelAndMode + kG/kH 枚举 | shared/discoveries.md §[Model] 模型选择域 |

## 使用流程

```
1. 加载本索引 → 匹配需求到 description
2. 读取相关 Layer 2 文件 → 生成有依据的方案
3. 引用验证 → 确保方案与已有发现一致
```
