# 交接单

> **用途**: 每个会话结束前覆盖此文件。新 AI 启动时第一步读取此文件，3 秒内获得完整上下文。
> **规则**: 不得追加，始终覆盖。格式字段不可省略（未知填 N/A）。

---

## 元数据

- **时间**: 2026-04-22 23:21
- **会话编号**: #25
- **Spec Mode**: ✅ 是（migrate-auto-continue-l1-to-l2）

## 当前焦点

**v8 实现已完成，等待用户测试验证！** 核心变更：auto-continue 从纯 L1（React render）迁移到 L1+L2 双层架构，解决切走窗口后补丁失效问题。

## 活跃 Spec

| 路径 | 状态 | 下一步 |
|------|------|--------|
| `.trae/specs/migrate-auto-continue-l1-to-l2/` | ⏳ **Task 1-4 完成, Task 5 待测试** | 用户重启 Trae 后测试 3 个场景 |

## 本轮做了什么

### Phase 1: L1 冻结原则提炼（承接 #24）
1. 分析 v7 成功日志三阶段时间线 → 确认切走=静默、切回=延迟触发
2. 搜索历史发现 4/18 已记录 + 后台测试文件已展示症状
3. 提炼 **L1 UI 层冻结原则**（Chromium rAF→React Scheduler→memo 不渲染）
4. 全量知识库更新 (commit `2c1d34f`)

### Phase 2: 交接单系统设计+实现
5. 设计 `shared/handoff.md` 结构化交接单（8 字段固定格式）
6. 实现: handoff.md 创建 + AGENTS.md Step 0 + _registry P0 注册 + rule-015 (commit `febad97`)

### Phase 3: v8 L1→L2 迁移（核心工作）
7. **Task 1 研究**: 用 ast-grep 发现 D/b 在 React 组件闭包内 → 改用 "L1 捕获服务引用到 window + L2 轮询读取" 方案
8. **Task 2 新补丁**: `auto-continue-l2-event` — 文件末尾注入 setInterval(3000) 轮询器
9. **Task 3 简化 v8**: `auto-continue-thinking` — 移除所有执行逻辑，只保留 Alert 显示 + `window.__traeSvc` 服务捕获
10. **Task 4 应用**: apply-patches.ps1 → 两个补丁 Applied + Syntax OK + fingerprint 9/10 PASS (commit `a5d91b6`)

## 关键决策

| 决策 | 选择 | 否决 |
|------|------|------|
| L2 注入方式 | **文件末尾 setInterval 轮询** | SessionServiceImpl.onStreamingStop hook（find_original 太长太脆弱） |
| 服务引用传递 | **L1 首次检测时捕获 D/b/M 到 window.__traeSvc** | 直接在模块顶层访问（D/b 在组件闭包内不可达） |
| 轮询间隔 | 3000ms | 2000ms（太频繁）/ 5000ms（响应太慢） |
| 错误检测方式 | **检查最后消息 status/code** | 监听 SSE 事件（需要找到事件系统入口） |

## v8 架构设计

```
┌─────────────────────────────────────────────┐
│  L1 (if(V&&J) in React render):             │
│  1. 首次检测错误 → window.__traeSvc = {D,b,M} │
│  2. 设置 __taeAC 冷却标记                    │
│  3. 显示 Alert 按钮（纯展示）                 │
├─────────────────────────────────────────────┤
│  L2 (文件末尾 IIFE, setInterval 3000):       │
│  1. 读 window.__traeSvc                      │
│  2. b.getCurrentSession() → 最后消息          │
│  3. 检查可续接错误码                          │
│  4. __taeAC 冷却检查                          │
│  5. D.sendChatMessage("继续")                │
│  ✅ 不受窗口焦点影响                           │
└─────────────────────────────────────────────┘
```

## 用户最后意图

> "你先解决当前这个切换窗口就失效的现象, 先把这个解决好先, 解决好了再把经验落实下来"

## 遗留 / 待办

- [ ] **🔥 用户测试 Task 5（核心！）**:
  - 重启 Trae
  - 场景 A: 聚焦 → 循环检测 → 自动续接
  - **场景 B: 切走 → 循环检测 → 后台自动续接 ← 这是目标!**
  - 场景 C: 切回 → 无重复
  - 收集控制台日志（应有 [v8-L1] 和 [v8-L2] 输出）
- [ ] Task 6: 测试通过后更新知识库 + 复盘 + handoff

## 相关文件速查

| 文件 | 变更内容 | commit |
|------|---------|--------|
| `patches/definitions.json` | 🔄 auto-continue-thinking v7→v8 + 🆕 auto-continue-l2-event | `a5d91b6` |
| target `index.js` | v8 L1 + v8 L2 已应用 (9/10 PASS) | `a5d91b6` |
| `shared/handoff.md` | 🆕 交接单系统 | `febad97` / `2baea7a` |
| `AGENTS.md` | 启动协议 3→4 步 | `febad97` |
| `shared/_registry.md` | handoff.md P0 注册 | `febad97` |
| `rules/workflow.yaml` | +rule-015 | `febad97` |
| `shared/discoveries.md` | +L1 冻结原则 | `2c1d34f` |

## 知识库索引（新 AI 快速定位）

如果下个会话需要继续以下方向，直接搜：

| 方向 | 搜索关键词 | 位置 |
|------|-----------|------|
| **🔥 接手本会话** | 读 `shared/handoff.md`（本文件！） | **Step 0 最优先** |
| **🔥 v8 测试结果分析** | `[v8-L1]` 或 `[v8-L2]` 控制台日志 | 用户提供的 log 文件 |
| v8 架构说明 | "v8"/"L1 L2 双层"/"__traeSvc" | 本 handoff + spec |
| 补丁失效诊断 | diagnosis-playbook 场景 A+F | shared/diagnosis-playbook.md |
| L1 冻结原则 | "冻结"/"L1"/"rAF" | discoveries.md [2026-04-22 16:00] |
