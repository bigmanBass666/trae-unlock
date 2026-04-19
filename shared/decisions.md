---
module: decisions
description: 技术决策记录
read_priority: P2
read_when: 需要理解决策时
write_when: 做出重要决策时
format: registry
---

# 技术决策记录

> 记录"为什么选择 X 而不是 Y"

> 📝 写入格式遵循 `shared/_registry.md` 中的约定

### [2026-04-18 10:00] 为什么修改源码而不是写插件

**选择**: 直接修改 Trae 源码
**否决**: 插件/设置方案
**原因**: Trae 的很多限制是在前端代码中硬编码的，无法通过设置或插件修改。前端硬编码限制只能通过源码定制突破。

---

### [2026-04-18 18:00] 为什么服务层补丁才有效

**选择**: PlanItemStreamParser 服务层补丁
**否决**: React 组件内补丁（7次迭代全部失败）
**原因**: 切换 AI 会话窗口后 React 组件冻结，useEffect/useMemo/useCallback 全部暂停。PlanItemStreamParser 是 SSE 流解析器，不属于任何 React 组件，数据到达时立即执行，不受窗口状态影响。

---

### [2026-04-19 12:00] 为什么自动确认用黑名单而非白名单

**选择**: `e?.toolName!=="response_to_user"` 黑名单
**否决**: `e?.toolName==="run_command"` 白名单
**原因**: 白名单太保守，只允许 run_command 自动确认，其他工具类型也需手动确认。黑名单只排除 response_to_user（用户问答），其余所有工具类型默认自动确认，更灵活实用。

---

### [2026-04-18 20:00] 为什么强制每次 commit 后 push

**选择**: 每次 commit 后立即 push
**否决**: 本地攒多次 commit 再 push
**原因**: .git 目录可能损坏，已有血的教训。本地存储不可靠，push 到 GitHub 才是真正的安全保障。

---

### [2026-04-20 10:00] 为什么补丁中必须用箭头函数

**选择**: `.catch(e=>{...})` 箭头函数
**否决**: `.catch(function(e){...})` 普通函数
**原因**: service-layer-runcommand-confirm v5 使用普通函数，严格模式下 this 为 undefined，Promise reject 时抛出 TypeError，未捕获异常导致整个 React 组件树崩溃，AI 聊天窗口消失。

---

### [2026-04-20 14:00] 为什么系统名集中定义而非散布

**选择**: 系统名只在 AGENTS.md + _registry.md 中硬编码，其他文件去品牌化
**否决**: 全项目统一替换系统名（19 个文件 48 处）
**原因**: 全项目替换是"牵一发动全身"的做法，与 Anchor 系统的设计理念矛盾。系统名散布在所有文件中，每次改名都要全项目搜索替换。集中化后，未来改名只需修改 AGENTS.md（2处）+ _registry.md（2处），共 4 处。shared/*.md 只描述功能不提品牌名，历史文件保持原名不改。

**改名规则**:
- **活文件** (AGENTS.md, _registry.md): 集中定义系统名，改名必改
- **shared/*.md**: 去品牌化，只描述功能，改名不需要动
- **历史文件** (progress.txt, .trae/specs/): 保持原名，改名等于篡改历史

---

### [2026-04-20 11:00] 为什么 check_fingerprint 必须精确匹配

**选择**: check_fingerprint 字符串必须与 replace_with 生成的实际代码完全一致，包括括号
**否决**: 使用近似匹配或省略细节
**原因**: service-layer-runcommand-confirm v6 的 check_fingerprint 缺少一个 `)` — 写的是 `confirm_status!=="confirmed"&&(this._taskService` 但实际代码是 `confirm_status!=="confirmed")&&(this._taskService`。这导致指纹检测失败，apply-patches.ps1 认为补丁未应用，每次运行都重复应用同一个补丁，造成代码重复和潜在崩溃。

---

### [2026-04-20 11:10] 为什么补丁不能改变原始控制流

**选择**: 用 if/else 结构避免 return/break/continue
**否决**: 在补丁中添加 return 语句提前退出
**原因**: auto-confirm-commands v2 在 `if(!r)` 块中添加了 `return` 语句，当 toolcall id 为空时提前退出整个 `_handlePlanItem()` 方法。这跳过了后续的 `if(s)` 块和其他处理逻辑，导致某些 toolcall 的处理被意外中断。改为 `if(r){provideUserResponse}else{warn}` 结构，不改变原始控制流。

---

### [2026-04-20 11:20] 为什么需要 confirm_status 守卫防双重调用

**选择**: `(e?.confirm_info?.confirm_status!=="confirmed")&&(this._taskService.provideUserResponse(...))`
**否决**: 两个补丁独立调用 provideUserResponse 不加守卫
**原因**: auto-confirm-commands (knowledge 分支, ~7502574) 和 service-layer-runcommand-confirm (else 分支, ~7503319) 可能对同一个 toolcall 都调用 provideUserResponse。knowledge 分支先处理，将 confirm_status 设为 "confirmed"；else 分支检查 confirm_status!=="confirmed" 后跳过，避免重复调用。没有这个守卫，同一 toolcall 会被确认两次，导致服务端状态混乱。
