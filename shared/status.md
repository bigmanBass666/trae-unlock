---
module: status
description: 当前状态和待办
read_priority: P1
read_when: 每个新会话
write_when: 每次会话结束时
format: registry
---

# 当前状态和待办

> 每次会话结束时更新，下一个会话读取

> 📝 写入格式遵循 `shared/_registry.md` 中的约定

## 已完成功能

| 功能 | 补丁 | 状态 |
|------|------|------|
| 命令自动确认 | auto-confirm-commands v3 | ✅ 已验证 |
| 服务层 RunCommand 确认 | service-layer-runcommand-confirm v6 | ✅ 已验证 |
| 思考上限自动续接 | auto-continue-thinking | ⚠️ 已应用，未实测 |
| 可恢复错误列表扩展 | efh-resume-list | ✅ 已应用 |
| 循环检测绕过 | bypass-loop-detection | ✅ 已应用 |
| WHITELIST 沙箱绕过 | bypass-whitelist-sandbox-blocks | ✅ 已应用 |
| 规则子系统 | rules-engine.ps1 + rules/*.yaml | ✅ 已上线 |
| 共享知识库 | shared/ (Anchor) | ✅ 已上线 |
| 源码架构深度解读 | docs/architecture/ 4份文档 | ✅ 已完成 |

## 已应用补丁列表

| ID | 位置 | 版本 | 说明 |
|----|------|------|------|
| auto-confirm-commands | ~7502574 | v3 | knowledge 命令自动确认（黑名单+无return+状态同步） |
| service-layer-runcommand-confirm | ~7503319 | v6 | else 分支确认（箭头函数+confirm_status守卫+状态同步） |
| auto-continue-thinking | ~8702342 | v1 | 思考上限自动点"继续" |
| efh-resume-list | ~8695303 | v1 | TASK_TURN_EXCEEDED_ERROR 加入可恢复列表 |
| bypass-loop-detection | ~8696378 | v1 | 4000009/4000012 加入 J 变量列表 |
| bypass-whitelist-sandbox-blocks | ~8069700 | v1 | WHITELIST 模式沙箱 block 直接执行 |

**已禁用补丁**: bypass-runcommandcard-redlist, force-auto-confirm, sync-force-confirm, data-source-auto-confirm, service-layer-confirm-status-update

## 待处理/待验证

### 高优先级
- [ ] ALWAYS_RUN + RedList 弹窗绕过（修改 getRunCommandCardBranch ~8069620）
- [ ] default(Ask) 模式弹窗绕过（所有模式都返回 Default）
- [ ] 思考上限续接的实际效果测试（需触发长任务）

### 中优先级
- [ ] MODEL_PREMIUM_EXHAUSTED 加入 J 变量（~8701000）
- [ ] CLAUDE_MODEL_FORBIDDEN 加入 J 变量（~8705020）
- [ ] INVALID_TOOL_CALL 加入 J 变量（~8708463）
- [ ] TOOL_CALL_RETRY_LIMIT 加入 J 变量（~8709130）
- [ ] LLM_TASK_PROMPT_TOKEN_EXCEED_LIMIT 加入 J 变量（~54415）
- [ ] 循环检测绕过后是否会形成续接死循环

### 低优先级
- [ ] 自定义主题/光标样式
- [ ] 解除其他 UI 限制
- [ ] 企业/付费相关限制（可能无法绕过）

## 已知问题

- **补丁崩溃风险**: 箭头函数/控制流/fingerprint 任一出错可能导致 React 组件树崩溃（聊天窗口消失）
- **双重调用风险**: 多个补丁可能对同一 toolcall 调用 provideUserResponse（已有 confirm_status 守卫）
- **Trae 更新后偏移量可能变化**: 需重新定位 find_original
- **check_fingerprint 精确性**: 必须与 replace_with 生成的实际代码完全一致，包括括号
- **find_original 子串问题**: 如果 find_original 是 replace_with 的子串，补丁会被重复应用
