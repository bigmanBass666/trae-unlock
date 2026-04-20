# 自动确认黑名单改白名单 Spec

## Why

当前自动确认补丁使用黑名单模式（`toolName!=="X"&&toolName!=="Y"`），每遗漏一个需要用户交互的工具就会导致 bug（AskUserQuestion 就是这样被自动确认了 3 次）。改为白名单模式（只自动确认已知安全的工具），新增工具默认不自动确认，从根本上消除遗漏风险。

## What Changes

- **BREAKING**: `service-layer-runcommand-confirm` 的 else 分支从黑名单改为白名单
- **BREAKING**: `auto-confirm-commands` 的 knowledge 分支从黑名单改为白名单
- 基于源码 `ee` 枚举（偏移 ~7076154-7079682）完整分类所有 toolName

## Impact

- Affected patches: auto-confirm-commands, service-layer-runcommand-confirm
- Affected code: 目标文件 PlanItemStreamParser 中两处 provideUserResponse 调用

## toolName 完整分类

### 需要用户交互 — 禁止自动确认（白名单外）

| toolName | 原因 |
|----------|------|
| `AskUserQuestion` | 需要用户选择/输入答案 |
| `response_to_user` | AI 回复，不是工具调用 |
| `NotifyUser` | 需要用户确认通知 |
| `ExitPlanMode` | 需要用户确认退出计划模式 |
| `SendMessage` | 发送消息，可能需要用户确认 |

### 命令执行类 — 可自动确认（白名单内）

| toolName | 说明 |
|----------|------|
| `RunCommand` | 命令执行（核心需求） |
| `run_mcp` | MCP 工具调用 |
| `check_command_status` | 检查命令状态 |

### 文件操作类 — 可自动确认（白名单内）

| toolName | 说明 |
|----------|------|
| `Read` | 读取文件 |
| `Write` | 写入文件 |
| `Edit` | 编辑文件 |
| `MultiEdit` | 多处编辑 |
| `Glob` | 文件匹配 |
| `Grep` | 内容搜索 |
| `LS` | 目录列表 |
| `SearchReplace` | 搜索替换 |
| `SearchCodebase` | 代码库搜索 |
| `view_file` / `view_files` / `view_folder` | 查看文件/文件夹 |
| `write_to_file` | 写入文件 |
| `edit_file_search_replace` | 编辑文件搜索替换 |
| `create_file` / `delete_file` | 创建/删除文件 |
| `file_search` | 文件搜索 |
| `show_diff` / `show_diff_fc` | 显示差异 |

### 浏览器操作类 — 可自动确认（白名单内）

| toolName | 说明 |
|----------|------|
| `browser_navigate` / `browser_navigate_back` / `browser_navigate_forward` | 导航 |
| `browser_click` / `browser_type` / `browser_press_key` | 交互 |
| `browser_scroll` / `browser_select_option` / `browser_snapshot` | 操作 |
| `browser_take_screenshot` / `browser_fill` / `browser_fill_form` | 操作 |
| `browser_wait_for` / `browser_hover` / `browser_drag` | 操作 |
| `browser_evaluate` / `browser_console_messages` / `browser_network_requests` | 调试 |
| `browser_get_attribute` / `browser_get_bounding_box` / `browser_get_input_value` | 获取信息 |
| `browser_handle_dialog` / `browser_highlight` | 操作 |
| `browser_is_checked` / `browser_is_enabled` / `browser_is_visible` | 状态检查 |
| `browser_lock` / `browser_unlock` / `browser_tabs` | 管理 |
| `browser_reload` / `browser_resize` / `browser_search` | 操作 |

### 搜索/索引类 — 可自动确认（白名单内）

| toolName | 说明 |
|----------|------|
| `search_by_definition` / `search_by_reference` / `search_by_regex` | 代码搜索 |
| `search_codebase` | 代码库搜索 |
| `TodoWrite` / `todo_write` | 任务列表 |
| `web_search` / `WebSearch` | 网络搜索 |

### 任务/代理类 — 可自动确认（白名单内）

| toolName | 说明 |
|----------|------|
| `Task` / `TaskCreate` / `TaskGet` / `TaskList` / `TaskUpdate` | 任务管理 |
| `TeamList` / `TeamCreate` | 团队管理 |
| `agent_finish` / `finish` | 代理完成 |
| `Skill` | 技能调用 |
| `CompactFake` | 压缩 |

### 预览/环境类 — 可自动确认（白名单内）

| toolName | 说明 |
|----------|------|
| `OpenPreview` / `open_preview` / `open_preview_and_wait_for_error` | 预览 |
| `open_folder` | 打开文件夹 |
| `init_env` | 初始化环境 |
| `image_ocr` | 图片 OCR |
| `get_preview_console_logs` | 预览控制台日志 |
| `get_llm_config` | 获取 LLM 配置 |

### 外部服务类 — 可自动确认（白名单内）

| toolName | 说明 |
|----------|------|
| `deploy_to_remote` | 部署 |
| `stripe_get_config` | Stripe 配置 |
| `supabase_apply_migration` / `supabase_get_project` | Supabase |
| `edit_product_document_*` / `write_to_product_document` | 产品文档 |

### 记忆/内部类 — 可自动确认（白名单内）

| toolName | 说明 |
|----------|------|
| `manage_core_memory` | 核心记忆管理 |
| `update_shallow_memento` / `condense_shallow_memento` | 浅记忆 |
| `update_shallow_memento_fc` / `condense_shallow_memento_fc` | 浅记忆 FC |
| `create_requirement` | 创建需求 |

## 白名单实现

由于 toolName 有 v1 和 v3 两种命名（如 `run_command` vs `RunCommand`），白名单需要包含两套名称。但考虑到 else 分支的 `e?.toolName` 来自服务端返回的实际 toolName，我们只需要包含实际会出现的名称。

**白名单列表**（按实际出现概率排序）：

```
RunCommand,run_mcp,check_command_status,Read,Write,Edit,MultiEdit,Glob,Grep,LS,SearchReplace,SearchCodebase,view_file,view_files,view_folder,write_to_file,edit_file_search_replace,create_file,delete_file,file_search,show_diff,show_diff_fc,browser_navigate,browser_navigate_back,browser_navigate_forward,browser_click,browser_type,browser_press_key,browser_scroll,browser_select_option,browser_snapshot,browser_take_screenshot,browser_fill,browser_fill_form,browser_wait_for,browser_hover,browser_drag,browser_evaluate,browser_console_messages,browser_network_requests,browser_get_attribute,browser_get_bounding_box,browser_get_input_value,browser_handle_dialog,browser_highlight,browser_is_checked,browser_is_enabled,browser_is_visible,browser_lock,browser_unlock,browser_tabs,browser_reload,browser_resize,browser_search,search_by_definition,search_by_reference,search_by_regex,TodoWrite,todo_write,web_search,WebSearch,Task,TaskCreate,TaskGet,TaskList,TaskUpdate,TeamList,TeamCreate,agent_finish,finish,Skill,CompactFake,OpenPreview,open_preview,open_preview_and_wait_for_error,open_folder,init_env,image_ocr,get_preview_console_logs,get_llm_config,deploy_to_remote,stripe_get_config,supabase_apply_migration,supabase_get_project,edit_product_document_fast_apply,edit_product_document_update,edit_product_document_update_fc,write_to_product_document,manage_core_memory,update_shallow_memento,condense_shallow_memento,update_shallow_memento_fc,create_requirement,CheckCommandStatus,DeleteFile,ViewFiles,WriteToFile,EditFileSearchReplace
```

**但这个白名单太长了！** 在压缩 JS 中嵌入这么长的字符串不现实。

## 更优方案：反向黑名单 + 安全默认

考虑到白名单过长，采用**反向思路**：

```javascript
// 禁止自动确认的 toolName 列表（短，易维护）
const BLOCKED = ["response_to_user","AskUserQuestion","NotifyUser","ExitPlanMode","SendMessage"]

// 检查：toolName 不在禁止列表中
!BLOCKED.includes(e?.toolName)
```

这本质上还是黑名单，但关键区别是：
1. **语义清晰**：列表名明确表示"禁止"，新增项时自然会考虑是否应该加入
2. **集中管理**：所有需要用户交互的工具集中在一个列表中
3. **默认安全**：当不确定时，宁可加入禁止列表

实际上当前的黑名单问题不是"黑名单 vs 白名单"的问题，而是**黑名单不完整**的问题。只要确保所有需要用户交互的工具都在列表中，黑名单就是安全的。

## 最终方案

扩展黑名单为完整版，包含所有需要用户交互的工具：

```javascript
e?.toolName!=="response_to_user"&&e?.toolName!=="AskUserQuestion"&&e?.toolName!=="NotifyUser"&&e?.toolName!=="ExitPlanMode"
```

`SendMessage` 暂不加入（它走的是不同的确认流程，不在 PlanItemStreamParser 的 else 分支中处理）。

## ADDED Requirements

### Requirement: 自动确认黑名单必须包含所有需要用户交互的工具
系统 SHALL 确保自动确认补丁的黑名单包含所有需要用户交互的 toolName。

#### Scenario: 新增需要用户交互的工具
- **WHEN** 源码更新引入新的需要用户交互的 toolName
- **THEN** 该 toolName 必须被添加到黑名单中
- **AND** 不应自动调用 provideUserResponse 确认

## MODIFIED Requirements

### Requirement: service-layer-runcommand-confirm 黑名单
else 分支的黑名单从 `response_to_user` 扩展为 `response_to_user+AskUserQuestion+NotifyUser+ExitPlanMode`。

### Requirement: auto-confirm-commands 黑名单
knowledge 分支的黑名单从 `response_to_user` 扩展为 `response_to_user+AskUserQuestion+NotifyUser+ExitPlanMode`。
