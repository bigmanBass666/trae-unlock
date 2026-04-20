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

---

### [2026-04-20 19:30] 回滚应使用干净备份而非脏备份

**选择**: 使用 20260420-072436 干净备份进行回滚
**否决**: 使用 20260419-003102 等包含旧版补丁的脏备份
**原因**: 脏备份中包含旧版 service-layer-confirm-status-update 的残留代码。apply-patches 只做追加不做清理，回滚到脏备份后重新应用补丁会导致旧代码残留，产生未过滤的 provideUserResponse 调用，使 AskUserQuestion 被自动确认

---

### [2026-04-20 19:50] 黑名单应扩展为过滤所有需要用户交互的工具

**选择**: 将黑名单从 `response_to_user` 扩展为 `response_to_user+AskUserQuestion`
**否决**: 仅过滤 response_to_user（v6 的做法）
**原因**: AskUserQuestion 是需要用户交互的工具，其 toolName 不是 "response_to_user"，v6 的黑名单无法拦截。自动确认 AskUserQuestion 会导致工具返回 null，用户无法看到选项弹窗
**扩展性**: 未来如果发现其他需要用户交互的工具，应继续扩展黑名单，而非改用白名单

---

### [2026-04-20 20:10] 选择完整黑名单而非白名单

**选择**: 扩展黑名单为 `response_to_user+AskUserQuestion+NotifyUser+ExitPlanMode`（4 项完整列表）
**否决**: 改为白名单模式（80+ 项 toolName 列表）
**原因**: 白名单包含 80+ 个 toolName，在压缩 JS 中嵌入过长字符串不现实。黑名单只需 4 项，维护成本低。关键区别不是"黑名单 vs 白名单"，而是"黑名单是否完整"——基于源码 `ee` 枚举完整分类后，黑名单已覆盖所有需要用户交互的工具
**方法论**: 从"凭经验添加"升级为"基于源码枚举完整分类"，确保不遗漏

---

### [2026-04-20 20:30] 选择 data-source-auto-confirm 修复弹窗回归

**选择**: 启用 data-source-auto-confirm（数据解析层 ~7318521 设置 auto_confirm=true）
**否决 A**: sync-force-confirm（修改 ey useMemo）— find_original 可能不匹配新版代码，Trae 再更新可能又失效
**否决 C**: 新写适配新版 ey 的补丁 — 同样受 Trae 更新影响
**原因**: 数据源层是最底层拦截，所有组件都能看到 auto_confirm=true。不受 React 组件渲染时序影响，不受 ey 逻辑变化影响。配合已有黑名单（4 项），不会影响需要用户交互的工具
**风险**: auto_confirm=true 在全局生效，必须确保黑名单完整——已在会话 #11 中验证

---

### [2026-04-20 20:40] 三层架构分层法则 — 补丁修改必须遵循的分层原则

**选择**: 补丁修改优先级 L3数据层 > L2服务层 > L1 UI层
**否决**: 在L1 UI层尝试根本性修复（如改变弹窗行为、自动确认逻辑）
**原因**: 经过4个UI层补丁的实际验证（bypass-runcommandcard-redlist/force-auto-confirm/sync-force-confirm全部失效或效果有限），确认：
1. P8枚举只控制按钮样式，不控制是否弹窗
2. ey/useEffect依赖auto_confirm标志，改逻辑不如直接设置标志
3. React组件逻辑随Trae更新频繁变化，find_original容易失效
4. L2的provideUserResponse直接和服务端通信，是真正的"确认"动作
5. L3的auto_confirm标志是最稳定的数据源，所有下游组件都依赖它
**方法论**: 遇到新限制时，先定位属于哪一层，从最底层开始设计补丁方案
