---
module: context
description: 项目核心上下文
read_priority: P0
read_when: 每个新会话
write_when: 项目重大变更时
format: registry
---

# 项目核心上下文

> 每个新会话 AI 必读的项目核心信息

> 📝 写入格式遵循 `shared/_registry.md` 中的约定

## 项目基本信息

**项目名称**: Trae Mod — Trae IDE 定制框架
**定位**: 通过源码修改解锁 Trae IDE 的更多能力，不是插件，是对源码的直接定制修改
**仓库**: https://github.com/bigmanBass666/trae-unlock

## 技术栈

**目标平台**: Trae IDE v3.3.x + Windows
**核心源码**: 87MB minified JS，已解包（无 app.asar，直接编辑即可生效）
**主进程**: Electron

## 核心源码位置

```
D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js
```

这是 AI 聊天系统的核心前端组件，包含对话渲染、Tool Call 管理、命令确认流程、PlanItem 解析流。

## 目录结构概览

```
trae-unlock/
├── docs/                          # 文档
│   ├── achievements/              # 定制成果详情
│   ├── architecture/              # 架构文档（source-architecture.md 等）
│   ├── guides/                    # 使用指南
│   └── reports/                   # 扫描报告
├── patches/
│   └── definitions.json           # 补丁定义（结构化数据）
├── scripts/
│   ├── apply-patches.ps1          # 应用补丁
│   ├── rollback.ps1               # 回滚补丁
│   ├── verify.ps1                 # 验证状态
│   └── rules-engine.ps1           # 动态规则引擎
├── rules/                         # 规则仓库（YAML）
├── shared/                        # 跨会话共享模块
├── AGENTS.md                      # AI 协作规则路由器
└── progress.txt                   # 项目进度
```

## 补丁系统简介

每个补丁包含：`find_original`（原始代码定位）、`replace_with`（替换代码）、`check_fingerprint`（短字符串验证）、`enabled`（是否启用）。

操作流程：`verify.ps1` 检测状态 → `apply-patches.ps1` 应用补丁（自动备份） → `rollback.ps1` 回滚。

## 关键架构洞察

1. **服务层补丁才有效** — PlanItemStreamParser 是 SSE 流解析器，不依赖 React 渲染，切窗口不冻住
2. **React 组件会冻结** ⚠️ **已验证 (会话#24)**: 切换 AI 会话窗口后，后台组件的 hooks 全部暂停（useEffect/useMemo/useCallback）。**L1 层补丁在后台不执行。详见 discoveries.md [2026-04-22 16:00] L1 冻结原则。**
3. **双层确认系统** — 服务层(PlanItemStreamParser) + UI层(RunCommandCard) 完全独立，两层都需补丁
4. **ew.confirm() 不是执行** — 它是 telemetry/日志，真正执行函数是 eE(Confirmed)
5. **补丁安全** — 箭头函数防 this 丢失、不改变控制流、fingerprint 精确匹配
6. **🔑 L1 冻结原则 (2026-04-22 验证)** — 需要实时响应的补丁必须放在 L2/L3。auto-continue-thinking 因住在 L1 导致 6 次迭代（v3→v7）。设计新补丁时首先选择层级。

## 架构文档索引

| 文档 | 内容 | 关键发现 |
|------|------|---------|
| docs/architecture/sse-stream-parser.md | SSE 流解析系统 | PlanItemStreamParser 完整生命周期、事件分发、状态管理 |
| docs/architecture/command-confirm-system.md | 命令确认系统 | 双层确认架构、BlockLevel 完整逻辑、本地状态同步 |
| docs/architecture/limitation-map.md | 限制点地图 | 17 个 Alert 渲染点、7 个错误码、6 个 BlockLevel |
| docs/architecture/module-boundaries.md | 模块边界与依赖 | 服务注入、事件系统、模块依赖关系图 |

## 关键位置速查

> ⚠️ **最后更新**: 2026-04-21 23:00 (v5 三重加固后)

| 位置 | 内容 | 版本 | 重要性 |
|------|------|------|---------|
| ~7323241 | data-source-auto-confirm (auto_confirm=true) | v3 | ⭐⭐⭐⭐⭐ |
| ~7507671 | auto-confirm-commands (knowledge分支) | v4 | ⭐⭐⭐⭐⭐ |
| ~7508254 | service-layer-runcommand-confirm (else分支) | v8 | ⭐⭐⭐⭐⭐ |
| ~8075009 | bypass-runcommandcard-redlist | v2 | ⭐⭐⭐⭐ |
| ~8699513 | efh 可恢复错误列表 (含循环检测+DEFAULT) | **v3** | ⭐⭐⭐⭐⭐ |
| ~8701180 | J 变量（含循环检测+DEFAULT） | **v4** | ⭐⭐⭐⭐⭐ |
| ~8706067 | guard-clause-bypass (!q&&!J 放行) | **v1** | ⭐⭐⭐⭐⭐ |
| ~8706660 | auto-continue-thinking (500ms+嵌套retry) | **v5** | ⭐⭐⭐⭐⭐ |
| ~8702006 | ec() 回调定义 (resumeChat) | — | ⭐⭐⭐⭐ |
| ~8702572 | ed() 回调定义 (sendChatMessage) | — | ⭐⭐⭐ |
| ~7538139 | onStreamingStop / stopStreaming (覆盖status为Canceled) | — | ⭐⭐⭐⭐⭐ |
| ~7511389 | D7.Error 处理器 / handleSideChat | — | ⭐⭐⭐⭐ |
| ~8038360 | JV() 函数 (guard clause et条件) | — | ⭐⭐⭐⭐ |
| ~9910446 | DEFAULT 错误组件 (t===kg.DEFAULT) | — | ⭐⭐⭐⭐ |
| ~41400 | ToolCallName 枚举 | — | ⭐⭐⭐ |
| ~8069382 | BlockLevel/AutoRunMode/ConfirmMode 枚举 | — | ⭐⭐⭐⭐ |
| ~8635000 | egR (RunCommandCard) React 组件 | — | ⭐⭐⭐⭐ |

## 补丁版本总览 (8/8, 2026-04-21 23:00)

| # | 补丁 ID | 版本 | 偏移 | 核心作用 |
|---|---------|------|------|---------|
| 1 | data-source-auto-confirm | v3 | ~7323241 | L3数据层: auto_confirm=true |
| 2 | auto-confirm-commands | v4 | ~7507671 | L2知识分支: 黑名单自动确认 |
| 3 | service-layer-runcommand-confirm | v8 | ~7508254 | L2 else分支: 黑名单+守卫 |
| 4 | bypass-runcommandcard-redlist | v2 | ~8075009 | L1 UI: 弹窗消除 |
| 5 | **guard-clause-bypass** | **v1** | **~8706067** | **Guard Clause: !q&&!J 放行** |
| 6 | efh-resume-list | **v3** | **~8699513** | **可恢复列表: +循环检测+DEFAULT** |
| 7 | bypass-loop-detection | **v4** | **~8701180** | **J数组: +循环检测+DEFAULT** |
| 8 | auto-continue-thinking | **v5** | **~8706660** | **500ms+嵌套retry+直调resumeChat** |
