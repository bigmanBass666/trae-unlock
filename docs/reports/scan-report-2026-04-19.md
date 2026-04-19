# 主动性全面扫描报告 (2026-04-19)

> 完整扫描报告。progress.txt 只保留摘要。

## 扫描范围

目标文件: `ai-modules-chat/dist/index.js` (~87MB)
扫描日期: 2026-04-19
扫描方法: 关键词搜索 + 枚举提取 + Alert 渲染点定位

---

## 发现1: 30 个 Alert 弹窗渲染点

位置范围: ~8700000 - ~8930000 (ErrorMessageWithActions 组件内)

| # | 位置 | 错误码/条件 | 类型 | 已有补丁? | 备注 |
|---|------|------------|------|----------|------|
| 1 | ~8700219 | ENTERPRISE_QUOTA_CONFIG_INVALID | warning | ❌ | 企业配额配置无效 |
| 2 | ~8701000 | MODEL_PREMIUM_EXHAUSTED | warning | ❌ | 高级模型额度用完 |
| 3 | ~8701454 | PAYMENT_METHOD_INVALID | warning | ❌ | 支付方式无效 |
| 4 | ~8701681 | INTERNAL_USAGE_LIMIT | warning | ❌ | 内部用量限制 |
| 5 | ~8701968 | usage_limit (internal) | warning | ❌ | 内部用户限制 |
| 6 | ~8702410 | RISK_REQUEST_V2 | error/warning | ❌ | 风控请求 |
| 7 | ~8703141 | CONTENT_SECURITY_BLOCKED | warning | ❌ | 内容安全拦截 |
| 8 | ~8703913 | FREE_ACTIVITY_QUOTA_EXHAUSTED | warning | ❌ | 免费活动额度用完 |
| 9 | ~8704548 | CAN_NOT_USE_SOLO_AGENT | warning | ❌ | 无法使用独立 Agent |
| 10 | ~8705020 | CLAUDE_MODEL_FORBIDDEN | **error** | ❌ | Claude 模型被禁 |
| 11 | ~8705534 | REPO_LEVEL_MODEL_UNAVAILABLE | warning | ❌ | 仓库级别模型不可用 |
| 12 | ~8705889 | FIREWALL_BLOCKED | **error** | ❌ | 防火墙拦截 |
| 13 | ~8706125 | bQ.Warning (general) | warning | ❌ | 通用警告 |
| 14 | ~8706147 | bQ.Error (general) | **error** | ❌ | 通用错误 |
| 15 | ~8706304 | PPE config error | **error** | ❌ | PPE 配置错误 |
| 16 | ~8706759 | EXTERNAL_LLM_REQUEST_FAILED | **error** | ⚠️ | 有 Retry 按钮 |
| 17 | ~8706979 | Diagnose error | **error** | ⚠️ | 有 Diagnose 按钮 |
| 18 | ~8707238 | Continue+Diagnose | **error** | ⚠️ | 有 Continue 按钮 |
| 19 | ~8707685 | PREMIUM_USAGE_LIMIT | **error** | ❌ | 高级版用量限制 |
| 20 | ~8708073 | STANDARD_MODE_USAGE_LIMIT | **error** | ❌ | 标准版用量限制 |
| 21 | ~8708463 | INVALID_TOOL_CALL | **error** | ❌ | 工具调用参数错误 |
| 22 | ~8708817 | INVALID_TOOL_CALL (schema) | **error** | ❌ | 工具 schema 不兼容 |
| 23 | ~8709130 | TOOL_CALL_RETRY_LIMIT | **error** | ⚠️ | 有 New Task 按钮 |
| 24 | ~8709536 | Feedback mail | **error** | ❌ | 反馈邮件 |
| 25 | ~8925891 | Usage quota info | info | ❌ | 用量信息提示 |
| 26 | ~8926810 | Commercial exhaust | warning | ❌ | 商业版额度耗尽 |
| 27 | ~8929022 | Info message | info | ❌ | 信息消息 |

### Alert 分类统计

| 类型 | 数量 | 有操作按钮? |
|------|------|-----------|
| error | 16 | 4 个有按钮 (Retry/Diagnose/Continue/NewTask) |
| warning | 9 | 0 |
| info | 2 | 0 |

---

## 发现2: 错误码枚举 (kg/eA)

位置: ~54000, ~7161400

| 错误码 | 名称 | 触发场景 | 已处理? | 补丁 |
|--------|------|---------|---------|------|
| 4000002 | TASK_TURN_EXCEEDED_ERROR | 思考轮次超限 | ✅ | auto-continue-thinking |
| 4000003 | LLM_INVALID_JSON | JSON 解析失败 | ❌ | — |
| 4000004 | LLM_INVALID_JSON_START | JSON 起始无效 | ❌ | — |
| 4000005 | LLM_QUEUING | 排队中 | ❌ | — |
| 4000009 | LLM_STOP_DUP_TOOL_CALL | 重复工具调用循环 | ✅ | bypass-loop-detection |
| 4000010 | LLM_TASK_PROMPT_TOKEN_EXCEED_LIMIT | Token 超限 | ❌ | — |
| 4000012 | LLM_STOP_CONTENT_LOOP | 内容循环 | ✅ | bypass-loop-detection |

---

## 发现3: BlockLevel 枚举 (Cr)

| 值 | 含义 | 触发条件 | 已处理? | 补丁 |
|----|------|---------|---------|------|
| RedList | 红名单命令 | 危险命令 | ✅ | bypass-whitelist + bypass-runcommandcard-redlist |
| SandboxNotBlockCommand | 沙箱非阻塞 | 沙箱内允许的命令 | ✅ | bypass-whitelist-sandbox-blocks |
| SandboxExecuteFailure | 沙箱执行失败 | 命令在沙箱中失败 | ✅ | bypass-whitelist-sandbox-blocks |
| SandboxToRecovery | 沙箱恢复中 | 需要恢复沙箱状态 | ✅ | bypass-whitelist-sandbox-blocks |
| SandboxUnavailable | 沙箱不可用 | 沙箱服务不可用 | ✅ | bypass-whitelist-sandbox-blocks |

---

## 发现4: ToolCallName 枚举 (r)

位置: ~41400

### 命令执行类
| 枚举值 | 字符串值 | 组件 |
|--------|---------|------|
| RunCommand | `"run_command"` | RunCommandCard |

### 用户交互类（已排除）
| 枚举值 | 字符串值 | 组件 |
|--------|---------|------|
| ResponseToUser | `"response_to_user"` | AskUserQuestionCard |

### 文件操作类
| 枚举值 | 字符串值 | 说明 |
|--------|---------|------|
| CreateFile | `"create_file"` | 创建文件 |
| WriteToFile | `"write_to_file"` | 写入文件 |
| EditFileSearchReplace | `"edit_file_search_replace"` | 编辑文件 |
| DeleteFile | `"delete_file"` | 删除文件 |
| OpenFolder | `"open_folder"` | 打开文件夹 |

### 其他工具类
| 枚举值 | 字符串值 | 说明 |
|--------|---------|------|
| ViewFile | `"view_file"` | 查看文件 |
| WebSearch | `"web_search"` | 网络搜索 |
| MCPCall | `"run_mcp"` | MCP 调用 |
| Finish | `"finish"` | 完成 |
| TodoWrite | `"todo_write"` | Todo 写入 |

---

## 待处理的潜在问题点 (优先级排序)

| 优先级 | 问题 | 位置 | 影响 | 建议 |
|--------|------|------|------|------|
| 🔴 高 | MODEL_PREMIUM_EXHAUSTED | ~8701000 | 高级模型额度用完时弹 warning | 可考虑自动切换模型或隐藏 |
| 🔴 高 | CLAUDE_MODEL_FORBIDDEN | ~8705020 | Claude 被禁用时 error 中断对话 | 可考虑自动回退到其他模型 |
| 🟡 中 | INVALID_TOOL_CALL | ~8708463 | 工具参数错误时 error | 可考虑自动重试/修正参数 |
| 🟡 中 | TOOL_CALL_RETRY_LIMIT | ~8709130 | 重试超限时 error + New Task 按钮 | 可考虑自动创建新任务 |
| 🟢 低 | FIREWALL_BLOCKED | ~8705889 | 网络防火墙拦截 | 用户侧问题，无需处理 |

---

*报告生成时间: 2026-04-19*
*下次扫描建议: Trae 版本更新后重新执行*
