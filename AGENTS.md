# Agent Rules for Trae Mod Project

## ⚠️⚠️⚠️ 强制执行：必须先加载项目规则

**这是本文件唯一且最重要的指令。**

在阅读本文件的任何其他内容之前，你**必须**立即执行以下命令来加载当前有效的项目规则集：

```powershell
powershell scripts/rules-engine.ps1
```

**禁止跳过此步骤！** 禁止基于旧记忆或假设行事！

---

## 📍 规则加载方式

根据当前任务需求，选择合适的运行模式：

### 默认模式（推荐）
加载并显示所有启用的规则详情：
```powershell
powershell scripts/rules-engine.ps1
```

### 验证模式
检查 rules/*.yaml 文件语法是否正确：
```powershell
powershell scripts/rules-engine.ps1 --check
```

### 列表模式
快速查看规则状态摘要表：
```powershell
powershell scripts/rules-engine.ps1 --list
```

---

## 🔄 规则刷新机制

- **动态生成**：所有具体规则由引擎从 `rules/` 目录实时读取和组装
- **修改后刷新**：如果编辑了 `rules/*.yaml` 文件，需重新运行上述命令获取最新规则
- **无需手动维护**：本文件是"路由器"，不是"规则存储"，禁止在此硬编码规则细节

---

## 📌 本文件定位

| 角色 | 说明 |
|------|------|
| **AGENTS.md** | 规则路由器 / 入口点（本文档） |
| **rules/\*.yaml** | 规则定义源文件（可编辑） |
| **scripts/rules-engine.ps1** | 规则解析与输出引擎 |

---

## 🎯 快速参考

- ✅ **正确做法**：每次新会话 → 运行 `rules-engine.ps1` → 遵循输出的规则
- ❌ **错误做法**：基于记忆操作、跳过规则加载、手动编辑本文件添加规则
- 🔧 **规则管理**：编辑 `rules/*.yaml` → 运行 `rules-engine.ps1 --check` 验证 → 正常使用
