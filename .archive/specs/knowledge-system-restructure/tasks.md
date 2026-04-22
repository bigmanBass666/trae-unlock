# Tasks

- [x] Task 1: 构建 discoveries.md 三维度索引
  - [x] 1.1 扫描全文提取函数/API/错误码/补丁名 ✅
  - [x] 1.2 按三维度组织索引表（24+22+9条目）✅
  - [x] 1.3 每条含摘要+发现编号+决策引用 ✅
  - [x] 1.4 追加到末尾（纯追加，+76行，覆盖率93%）✅

- [x] Task 2: 精简 AGENTS.md 为路由表
  - [x] 2.1 分析200行内容分类 ✅
  - [x] 2.2 保留：Anchor声明+3步启动+写入责任+路由表+规则列表 ✅
  - [x] 2.3 移除/缩短：方法论详情→discoveries索引/复盘→rule-013/搜索→rule-005/011 ✅
  - [x] 2.4 结果：**188行→59行**（-68%，目标≤60）✅

- [x] Task 3: 创建 diagnosis-playbook.md 诊断操作手册
  - [x] 3.1 定义5个场景(A-E) ✅
  - [x] 3.2 每个场景Step-by-step流程 ✅
  - [x] 3.3 每个场景Step 1嵌入"查discoveries索引"(rule-014) ✅

- [x] Task 4: 更新 _registry.md 注册新模块
  - [x] 4.1 添加 diagnosis-playbook.md P0 必读条目 ✅

- [x] Task 5: 验证 — 模拟"新AI会话"走一遍新系统
  - [x] 5.1 模拟 "auto-continue 不工作" 问题 ✅
  - [x] 5.2 diagnosis-playbook 场景B直接命中 ✅
  - [x] 5.3 discoveries索引54行匹配（vs 会话#23的25分钟重复调查） ✅
  - [x] 5.4 AGENTS.md 59行 ≤ 60 行目标 ✅

- [x] Task 6: 提交 + 复盘 → commit `0179dbb`

# Task Dependencies
- [Task 1-3] ✅ 并行完成
- [Task 4] ✅ 依赖 Task 3
- [Task 5] ✅ 依赖 Task 1-4
- [Task 6] ✅ 依赖 Task 5
- **全部完成 ✅**
