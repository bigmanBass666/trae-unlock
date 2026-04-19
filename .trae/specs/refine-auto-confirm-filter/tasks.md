# Tasks

- [x] Task 1: 确认 AskUserQuestion 和 RunCommandCard 的 toolName 具体值
  - [x] SubTask 1.1: 在 PlanItemStreamParser 日志中添加 toolName 输出，观察 AskUserQuestion 场景的 toolName
  - [x] SubTask 1.2: 在 PlanItemStreamParser 日志中添加 toolName 输出，观察 RunCommandCard 场景的 toolName
  - [x] SubTask 1.3: 记录所有发现的 toolName 值，建立白名单/黑名单

- [x] Task 2: 设计 isAutoConfirmTool 过滤函数
  - [x] SubTask 2.1: 定义允许自动确认的 toolName 白名单（命令执行类）
  - [x] SubTask 2.2: 定义禁止自动确认的 toolName 黑名单（用户交互类）
  - [x] SubTask 2.3: 确定默认策略（保守：不确定时不确认）

- [ ] Task 3: 修改 service-layer-runcommand-confirm 补丁
  - [ ] SubTask 3.1: 在 provideUserResponse 调用前增加 toolName 检查
  - [ ] SubTask 3.2: 更新 definitions.json 中的 find_original 和 replace_with

- [ ] Task 4: 修改 auto-confirm-commands 补丁（如有必要）
  - [ ] SubTask 4.1: 检查 knowledges 补丁是否也需要相同过滤
  - [ ] SubTask 4.2: 如需要，同步修改

- [ ] Task 5: 应用补丁并验证
  - [ ] SubTask 5.1: 运行 apply-patches.ps1 应用修改后的补丁
  - [ ] SubTask 5.2: 验证 RunCommandCard 仍然自动确认
  - [ ] SubTask 5.3: 验证 AskUserQuestionCard 不再被自动确认，UI 正常显示

# Task Dependencies
- [Task 2] depends on [Task 1] — 需要先知道 toolName 值才能设计过滤函数
- [Task 3] depends on [Task 2] — 需要先设计好过滤函数才能修改补丁
- [Task 4] depends on [Task 2] — 同上
- [Task 5] depends on [Task 3, Task 4] — 需要补丁修改完成后才能验证

# Task 1 发现总结

## ToolCallName 完整枚举 (位置 ~41400)

### 命令执行类（需要自动确认 ✅）
| 枚举值 | 字符串值 | 说明 |
|--------|---------|------|
| `RunCommand` | `"run_command"` | RunCommandCard — **核心目标** |

### 用户交互类（不应自动确认 ❌）
| 枚举值 | 字符串值 | 说明 |
|--------|---------|------|
| `ResponseToUser` | `"response_to_user"` | AskUserQuestionCard — **必须排除** |

### 文件操作类（可选自动确认 ⚠️）
| 枚举值 | 字符串值 | 说明 |
|--------|---------|------|
| `CreateFile` | `"create_file"` | 创建文件 |
| `WriteToFile` | `"write_to_file"` | 写入文件 |
| `EditFileSearchReplace` | `"edit_file_search_replace"` | 编辑文件 |
| `DeleteFile` | `"delete_file"` | 删除文件 |
| `OpenFolder` | `"open_folder"` | 打开文件夹 |

### 其他工具类
| 枚举值 | 字符串值 | 说明 |
|--------|---------|------|
| `ViewFile` | `"view_file"` | 查看文件 |
| `WebSearch` | `"web_search"` | 网络搜索 |
| `MCPCall` | `"run_mcp"` | MCP 调用 |
| `Finish` | `"finish"` | 完成 |
| `TodoWrite` | `"todo_write"` | Todo 写入 |

# Task 2 过滤函数设计

```javascript
// isAutoConfirmTool(toolName): boolean
// 返回 true = 自动确认, false = 不自动确认（保留 UI）

function isAutoConfirmTool(toolName) {
  // 白名单：只允许命令执行类自动确认
  const AUTO_CONFIRM_WHITELIST = [
    "run_command",        // RunCommandCard — 核心目标
    // 可选：如果未来需要其他工具也自动确认，可在此添加
    // "create_file",
    // "write_to_file",
  ];

  // 黑名单：明确排除的用户交互类
  const AUTO_CONFIRM_BLACKLIST = [
    "response_to_user",   // AskUserQuestionCard — 必须排除！
  ];

  // 检查黑名单优先
  if (AUTO_CONFIRM_BLACKLIST.includes(toolName)) return false;

  // 检查白名单
  if (AUTO_CONFIRM_WHITELIST.includes(toolName)) return true;

  // 默认策略：保守 — 不确定的工具类型不自动确认
  return false;
}
```

**策略选择**: 白名单模式（只允许明确的命令执行类），比黑名单更安全。
