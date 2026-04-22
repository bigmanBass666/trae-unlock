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

---

### [2026-04-21 19:00] 为什么 auto-continue-thinking 从 ed()→ec()→直调 D.resumeChat() (v3→v4→v5 演进)

**选择**: auto-continue-thinking v5: 直调 D.resumeChat() + sendChatMessage fallback + 500ms 延迟
**否决 A**: v2 的 ed()/sendChatMessage — 发送"继续"作为新消息，服务端不识别为续接 → 空响应 → Cancel → "手动终止输出"
**否决 B**: v3 的 ec()/resumeChat — ec() 内部有 `"v3"===p` 条件，agentProcessSupport 不是 "v3" 时走 retryChatByUserMessageId 而非 resumeChat
**否决 C**: v4 的直调 resumeChat + 2000ms 延迟 — 二次错误(2000000/DEFAULT)在 2000ms 内到达并覆盖 errorCode，J 变 false，setTimeout 回调执行但状态已变
**原因**: 
- v2: sendChatMessage 创建新消息轮次，语义错误
- v3: 中间层 ec() 有隐藏条件判断（rule-012: 中间层陷阱）
- v4: 延迟太长 + 无 retry + DEFAULT 不在 J 数组中
- v5: 三管齐下 — 直调绕过 ec() 条件、500ms 抢在二次错误前、嵌套 retry 防 failure、DEFAULT 入 J 数组防覆盖

---

### [2026-04-21 21:00] 为什么新增 guard-clause-bypass 补丁而非修改现有补丁

**选择**: 新增独立补丁 guard-clause-bypass v1: `if(!n||!q||et)` → `if(!n||(!q&&!J)||et)`
**否决 A**: 在 auto-continue-thinking 中修改 guard clause — guard clause 在 if(V&&J) **之前**，属于不同的代码区域，混入一个补丁违反单一职责
**否决 B**: 删除 guard clause 整体 — guard clause 的原始目的是过滤无效渲染（n 为空/q 不是 Error/et 为 true），删除会导致组件在无错误时也渲染
**原因**: 
- guard clause 是 efp 组件的前置守卫，与 auto-continue-thinking 是正交关系
- 独立补丁更易维护和理解——每个补丁只做一件事
- `!q&&!J` 的逻辑是："如果不是 Error/Warning 状态 **且** 也不是可续接错误，则拦截"——精确控制

---

### [2026-04-21 23:00] 为什么 v5 选择三重加固 (DEFAULT入J + 500ms + 嵌套retry)

**选择**: 同时修改 3 个补丁（bypass-loop-detection v4 + auto-continue-thinking v5 + efh-resume-list v3）
**否决 A**: 只改 auto-continue-thinking — J 不含 DEFAULT，二次错误覆盖后 J=false 跳出 if(V&J)
**否决 B**: 只加 DEFAULT 到 J 数组 — setTimeout 2000ms 太慢，二次错误在回调前已到达
**否决 C**: 只缩短延迟到 500ms — 如果 resumeChat 失败（状态已变），没有 fallback 就完全失败
**原因**: 三重加固是"纵深防御"——每一层解决一个独立的风险点：
1. DEFAULT 入 J 数组 → 即使被覆盖也保持 J=true（防止跳出 if(V&J)）
2. 500ms 延迟 → 抢在二次错误到达前触发（时间竞争）
3. 嵌套 retry → 即使 resumeChat 失败也有 sendChatMessage fallback（最终安全网）

**类比**: 像三层防空系统——拦截导弹(DEFAULT入J)、近防炮(500ms)、装甲(retry)

---

### [2026-04-21 23:00] 为什么 bypass-loop-detection 要加入 kg.DEFAULT

**选择**: 将 kg.DEFAULT(2000000) 加入 J 数组和 efh 列表
**否决 A**: 忽略 DEFAULT 错误 — 用户实测显示 DEFAULT 错误确实会出现在循环检测之后
**否决 B**: 只在 efh 列表加入 DEFAULT 不加入 J 数组 — J=false 导致 if(V&J) 不满足，efp 组件不渲染，auto-continue-thinking 的 setTimeout 根本不会设置
**原因**: 
- 2000000 是循环检测(4000009)之后的**二次错误**，不是独立的首次错误
- 它出现在同一消息的错误处理流程中，应该被视为可续接场景
- J 数组控制"是否显示可续接 Alert"，efh 控制"ec() 是否调用 resumeChat"
- 两者都需要包含 DEFAULT 才能形成完整的恢复链路

---

### [2026-04-22 09:30] 为什么选择"脚本内嵌自动commit"而非仅依赖检查清单

**选择**: 在 apply-patches.ps1 和 auto-heal.ps1 成功路径中直接嵌入 `git add -A` + `git commit` 逻辑
**否决 A**: 仅在 _registry.md 检查清单中写"应该 commit" — 已证明在单 AI 场景下就不可靠（2 天未 commit），多 AI 场景下更不可靠（旁观者效应）
**否决 B**: 创建 git pre-commit hook — hook 只在手动 commit 时触发，不能解决"没人手动 commit"的问题
**否决 C**: 创建定时任务定期 commit — 过于复杂，且可能在不恰当的时机 commit 半成品
**原因**:
- **根本问题不是"不知道要 commit"而是"没有强制执行的机制"**
- apply-patches/auto-heal 是项目中唯二修改目标文件的入口，在这两个点嵌入 commit = 覆盖 100% 的补丁变更场景
- shared/* 文件和 rules/* 文件的变更是次要的（可通过 snapshot.ps1 手动补充）
- commit message 格式约定为 `chore: auto-snapshot [时间戳] — 状态摘要`，便于追溯

**配套措施**:
- 新建 `scripts/snapshot.ps1` 作为手动兜底（用于非补丁类变更的快照）
- status.md 安全状态仪表盘可视化最后备份/提交时间
- rule-002 检查清单保留安全检查项（作为 L4 补充防线）

---

### [2026-04-22 11:00] 为什么选择"语法验证+诊断脚本"组合而非仅修复补丁

**选择**: 在修复崩溃问题时，不仅重新应用了补丁，还建立了 `node --check` 语法验证 + diagnose-patch-health.ps1 诊断系统
**否决 A**: 仅修复 definitions.json 并重新 apply — 治标不治本，下次 Trae 更新还会遇到同样问题
**否决 B**: 用 AST 解析替代字符串匹配做补丁 — 过度工程化，当前字符串匹配在 8/10 次情况下工作良好
**否决 C**: 禁用自动更新 Trae — 不现实，用户需要 Trae 的新功能和安全修复
**原因**:
- **崩溃是系统性问题**：三个独立根因（版本不一致+无语法验证+变量重命名）协同作用，只修一个不够
- **语法验证是成本最低收益最高的防御**：一行 node --check 命令就能防止 10MB 文件变废料
- **诊断脚本让未来调试从"盲目猜测"变成"数据驱动"**：100 分制评分 + 三级状态一目了然
- **minifier 变量重命名是不可避的**：每次 Trae 更新都可能变化，必须建立快速定位和修复的能力

**配套决策**:
- auto-continue-thinking 回到干净 v6（去掉 console.log debug），等真正需要时再加
- diagnose-patch-health.ps1 作为标准工具加入工具链
- 未来每次 Trae 更新后第一步应该是运行 diagnose-patch-health.ps1 而不是直接 apply-patches

---

### [2026-04-22 14:30] 为什么 v7 选择"防重复+监控 fallback"而非其他方案

**选择**: v7 = 防重复守卫(window.__traeAC + 5秒冷却) + resumeChat 先尝试 + setTimeout(2000) 监控 + sendChatMessage fallback
**否决 A: 纯 sendChatMessage（放弃 resumeChat）** — 太激进。日志证明 resumeChat 至少不抛异常，可能在某些 session 状态下有效。完全放弃可能丢失"真正续接"的能力（resumeChat 保持上下文，sendChatMessage 是发新消息）
**否决 B: 只加防重复不改续接逻辑** — 不够。日志证明 resumeChat 是 no-op，只防重复 = 精确地调用了一个无效 API 一次，仍然不会续接
**否决 C: 延迟重试 resumeChat（多次 retry）** — 如果第一次是 no-op，后续大概率也是 no-op（同一 session 状态）。不如用监控来检测有效性
**否决 D: 更早阶段拦截（在 D7.Error 处理阶段）** — 过于复杂且高风险，当前方案已能解决问题

**原因**:
1. **v7-debug 日志是决定性证据**: 第一次有了数据驱动的修复方向（之前 v3-v6 都是猜测）
2. **三层纵深防御**: 防重复(避免风暴) → resumeChat(尝试最佳API) → 监控(检测是否生效) → fallback(保证可用)
3. **5秒冷却窗口**: 足够长防止 React 重渲染风暴，又足够短不影响下一次真实错误
4. **2秒监控窗口**: 平衡用户体验（不想等太久）和可靠性（给 resumeChat 足够时间）

**v7 的执行流程**:
```
if(V&&J) 进入
  ↓ 检查 __traeAC 时间戳 (5秒冷却)
  ↓ 通过 → 记录当前消息数 _ml
  ↓ queueMicrotask → D.resumeChat({messageId, sessionId})
  ↓ setTimeout(2000) 开始监控:
     ├─ 消息数增长 → ✅ resumeChat 生效! (不做任何事)
     └─ 消息数没变 → 🔁 fallback 到 D.sendChatMessage({message:"继续"})
```

---

### [2026-04-22 15:00] 为什么选择"硬性规则"而非仅靠自觉来防止知识孤岛

**选择**: 创建 rule-014（诊断前强制检索已有发现），作为 critical 级强制规则写入 workflow.yaml
**否决 A**: 仅在 AGENTS.md 中添加提醒文字 — 会话 #23 证明：AGENTS.md 虽然每次都读，但 AI 遇到具体问题时仍然不主动关联已有发现。文字提醒不够
**否决 B**: 在 spec 模板的 Task 1 中固定写"先搜索 discoveries.md" — 只有通过 /spec 创建的任务才会经过这个流程，用户直接问问题时不会触发
**否决 C**: 依赖 AI 的"常识"——前序会话已花大量精力做的调查应该自然被利用 — **会话 #23 本身就是反例，证明这条"常识"不成立**
**原因**:
1. **违规已被量化**: ~25 分钟的重复调查 = 该会话总时间的 ~30%。这不是小问题
2. **已有规则不够用**: rule-005 和 rule-011 都提到了"先搜索"，但它们是通用方法论。需要一条**针对诊断场景的具体操作规则**，明确说"第一步做什么"
3. ** enforcement: mandatory**: 这是 critical 级别，不是建议。未来的 AI 会话必须执行
4. **可自动化验证**: 可以在 checklist 或工作流中加入检查点："诊断开始前是否搜索了 discoveries.md？"

**rule-014 的设计要点**:
- 触发条件明确："遇到任何补丁/崩溃/异常问题时"
- 第一步明确："不是创建 spec 或派子代理调查"
- 操作明确："Grep 搜索 shared/discoveries.md 中的关键词"
- 关键词列表明确：函数名、组件名、现象描述词、错误信息关键字
- 违规示例明确：直接引用会话 #23 的实际案例


