---
module: rules
description: 协作规则和行为约束（L0-L3 四层体系）
read_priority: P1
read_when: 需要了解写入规范和行为准则时
write_when: 规则变更时
format: registry
last_reviewed: 2026-04-28
---

# 协作规则清单（L0-L3 四层体系）

> 基于 AI Agent 自我进化系统指令.md §5 Rules 执行协议
> 规则源文件：rules/L0-always.yaml, rules/L1-techstack.yaml, rules/L2-domain.yaml, rules/L3-sop.yaml

---

## 规则层级说明

| 层级 | 激活方式 | 说明 | 文件 |
|------|----------|------|------|
| **L0** | Always Apply | 始终应用，每次对话都遵守 | rules/L0-always.yaml |
| **L1** | File-Specific | 操作对应文件类型时遵守 | rules/L1-techstack.yaml |
| **L2** | Intelligent | 识别到相关业务场景时遵守 | rules/L2-domain.yaml |
| **L3** | Manual/Smart | 用户明确要求或高风险操作时遵守 | rules/L3-sop.yaml |

---

## L0 — 始终应用（5 条）

| ID | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| L0-001 | 会话启动必读共享知识库 | 🔴 critical | 先读 _registry.md + skills/_index.md，禁止无背景修改代码 |
| L0-002 | 操作后写入共享模块 | 🔴 critical | 发现→discoveries.md，决策→decisions.md，完成→status.md |
| L0-003 | 追加而非重写共享模块 | 🟡 high | 追加新条目，不得删除或覆盖已有条目 |
| L0-004 | 任务完成后自动复盘 | 🔴 critical | 回顾→反思→提炼→更新→记录 evolution-log.md |
| L0-005 | 诊断前强制检索已有发现 | 🔴 critical | 先搜 discoveries.md + skills/_index.md，再开始调查 |

---

## L1 — 文件类型触发（6 条）

| ID | 名称 | 文件类型 | 优先级 | 说明 |
|----|------|----------|--------|------|
| L1-001 | JS 代码使用箭头函数 | *.js, *.jsx, *.ts, *.tsx | 🔴 critical | .catch(e=>{}) 非 .catch(function(e){}) |
| L1-002 | 补丁定义格式规范 | definitions.json | 🟡 high | anchor + anchor_type + replace_with + fingerprint |
| L1-003 | 服务层优先于 UI 层 | *.js | 🔴 critical | L2 服务层不受 React 冻结影响 |
| L1-004 | 搜索优先三原则 | *.js, *.ps1 | 🟡 high | 搜工具→搜方案→搜生态，最后才自己写 |
| L1-005 | 理解代码之前先用工具映射 | *.js | 🟡 high | 不靠猜，先用搜索工具映射架构 |
| L1-006 | PowerShell 脚本规范 | *.ps1 | ⚪ medium | 时间戳用 Get-Date，遵循 T1-T4 生命周期 |

---

## L2 — 业务场景智能应用（8 条）

| ID | 名称 | 域 | 优先级 | 说明 |
|----|------|-----|--------|------|
| L2-001 | DI Token 迁移模式 | DI, Store, SSE | 🟡 high | Store/Parser 用 Symbol()，Facade/Service 用 Symbol.for() |
| L2-002 | SSE 错误传播链路 | SSE, Error | 🟡 high | 最佳拦截点 ErrorStreamParser.parse()，错误码白名单 |
| L2-003 | 商业权限判断链 | Commercial, Model | 🟡 high | NS→Nu→MX 链，isFreeUser 在 efi() Hook |
| L2-004 | 错误码体系 | Error | 🟡 high | kg(56)+efg(14)+J(5)+ee(2)，付费码 4008/4009/700 |
| L2-005 | Zustand Store 架构 | Store | ⚪ medium | 8 Store + uB Hook + 3 个关键 subscribe |
| L2-006 | 命令确认双层系统 | SSE, Sandbox, MCP | 🟡 high | 服务层+UI层独立，两层都需补丁 |
| L2-007 | 假设优先搜索法 | DI, SSE, Error, Commercial | 🟡 high | 先列假设再搜索，禁止广撒网 |
| L2-008 | 中间层陷阱警告 | SSE, React, Sandbox | 🟡 high | 不假设回调行为，先看内部实现 |

---

## L3 — 手动/高风险触发（4 条）

| ID | 名称 | 触发条件 | 优先级 | 说明 |
|----|------|----------|--------|------|
| L3-001 | 补丁应用流程 | apply-patches, 补丁应用 | 🟡 high | 修改→apply→verify→auto-heal→更新 status |
| L3-002 | 版本适配流程 | 版本更新, 偏移量漂移 | 🟡 high | unpack→remeasure→检查漂移→更新→apply+verify |
| L3-003 | Git 提交流程 | git commit | 🟡 high | add→commit→push 立即执行，禁止 merge |
| L3-004 | 代码修改安全原则 | 代码修改 | 🟡 high | 先理解上下文，不泄露密钥，修改后备份 |

---

📊 **规则统计**: 共 **23** 条 | L0: **5** 条 | L1: **6** 条 | L2: **8** 条 | L3: **4** 条
