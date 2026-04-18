# Trae Unlock 补丁系统 (Patch System) 计划

## 目标

将当前"手动改源码"升级为**结构化补丁系统**：一键应用/回滚/验证，Trae 更新后快速重新打补丁。

---

## 文件结构（最终产出）

```
trae-unlock/
├── patches/
│   └── definitions.json          # 补丁定义（结构化数据）
├── scripts/
│   ├── apply-patches.ps1         # 一键应用所有补丁
│   ├── rollback.ps1              # 一键回滚到备份
│   └── verify.ps1                # 验证补丁状态
├── backups/                      # 自动备份目录（按日期）
│   └── ai-modules-chat-index.js.YYYYMMDD-HHMMSS.backup
├── docs/
│   └── source-architecture.md    # 已有，补充 patch system 说明
├── progress.txt                  # 已有
└── agents.md                     # 已有
```

---

## 实施步骤

### Step 1: 创建 `patches/definitions.json`

定义所有补丁的结构化描述：

```json
{
  "meta": {
    "name": "trae-unlock-patches",
    "version": "1.0.0",
    "target_version": "3.3.x",
    "target_file": "D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js"
  },
  "patches": [
    {
      "id": "auto-confirm-commands",
      "name": "命令自动确认",
      "description": "自动确认高风险命令，无需手动点击确认弹窗",
      "find": "e?.confirm_info?.confirm_status === \"unconfirmed\") {\n    if (s) {",
      "replace": "...完整的替换文本...",
      "offset_hint": "~7502574",
      "enabled": true,
      "added_at": "2026-04-18"
    },
    {
      "id": "auto-continue-thinking",
      "name": "自动续接思考上限",
      "description": "收到思考次数上限错误时无感自动发送'继续'",
      "find": "if(V&&J){let e=M.localize(\"continue\",{},\"Continue\");return sX().createElement(Cr.Alert,{onDoubleClick:e_,type:\"warning\",message:ef,actionText:e,onActionClick:ed})}",
      "replace": "if(V&&J){let e=M.localize(\"continue\",{},\"Continue\");setTimeout(function(){ed()},50);return null}",
      "offset_hint": "~8702342",
      "enabled": true,
      "added_at": "2026-04-18"
    },
    {
      "id": "efh-resume-list",
      "name": "可恢复错误列表扩展",
      "description": "将 TASK_TURN_EXCEEDED_ERROR 加入 efh 可恢复列表（备用方案）",
      "find": "efh=[kg.SERVER_CRASH,kg.CONNECTION_ERROR,...,kg.MODEL_AUTO_SELECTION_FAILED,kg.MODEL_FAIL]",
      "replace": "efh=[...,kg.TASK_TURN_EXCEEDED_ERROR]",
      "offset_hint": "~8695303",
      "enabled": true,
      "added_at": "2026-04-18"
    }
  ]
}
```

关键设计：
- `find`: 唯一标识原始代码的字符串片段（用于定位 + 验证）
- `replace`: 替换后的完整代码
- `offset_hint`: 人类可读的位置提示（用于调试，不用于定位）
- `enabled`: 可以单独启用/禁用某个补丁

### Step 2: 创建 `scripts/apply-patches.ps1`

核心逻辑：

```powershell
# 伪代码流程
1. 读取 definitions.json
2. 检查目标文件是否存在
3. **自动备份**: 复制目标文件 → backups/index.js.{timestamp}.backup
4. 读取目标文件内容到内存
5. 对每个 enabled 的 patch:
   a. 在文件内容中搜索 find 字符串
   b. 如果找到:
      - 检查是否已经被 replace 替换了（避免重复打）
      - 执行替换
      - 记录 ✅
   c. 如果找不到:
      - 用 offset_hint 附近的上下文做模糊搜索
      - 如果还是找不到 → 记录 ⚠️ 警告（可能是版本更新导致偏移变化）
6. 将修改后的内容写回文件
7. 输出报告：哪些成功、哪些失败
8. 返回退出码：0=全部成功, 1=部分失败, 2=全部失败
```

智能特性：
- **重复检测**：如果 find 已经被 replace 了，跳过不报错
- **模糊搜索回退**：精确匹配失败时，取 find 的前 50 字符再搜
- **安全检查**：替换前显示 diff 确认（可用 `-y` 参数跳过）
- **dry-run 模式**：`-WhatIf` 只检查不实际修改

### Step 3: 创建 `scripts/rollback.ps1`

```powershell
# 伪代码流程
1. 列出 backups/ 目录下所有备份文件
2. 如果只有一个 → 直接恢复
3. 如果有多个 → 选择最新的（或指定日期的）
4. 复制备份文件覆盖目标文件
5. 验证恢复后的文件不含任何 patch 的 replace 内容
6. 输出报告
```

支持参数：
- `--list` - 列出所有可用备份
- `--date 20260418` - 恢复指定日期的备份
- `--latest` - 恢复最新备份（默认）

### Step 4: 创建 `scripts/verify.ps1`

```powershell
# 伪代码流程
1. 读取 definitions.json
2. 读取目标文件当前内容
3. 对每个 patch:
   a. 检查 find 是否存在 → ❌ 未打补丁（或已被替换）
   b. 检查 replace 是否存在 → ✅ 补丁已生效
   c. 都不存在 → ⚠️ 代码可能已变更（版本更新？）
4. 输出彩色状态表格：
   [✅] auto-confirm-commands     已生效 (~7502574)
   [✅] auto-continue-thinking    已生效 (~8702342)
   [✅] efh-resume-list           已生效 (~8695303)
5. 返回统计摘要
```

### Step 5: 更新文档

在 `docs/source-architecture.md` 中添加 "Patch System 使用说明" 章节。

---

## 使用场景示例

### 场景 1：首次使用 / Trae 更新后
```powershell
cd d:\Test\trae-unlock
.\scripts\apply-patches.ps1
# 输出:
# [✅] auto-confirm-commands    applied at offset ~7502574
# [✅] auto-continue-thinking   applied at offset ~8702342
# [✅] efh-resume-list          applied at offset ~8695303
# All 3 patches applied successfully. Restart Trae to take effect.
```

### 场景 2：检查状态
```powershell
.\scripts\verify.ps1
# 输出:
# [✅] auto-confirm-commands    ACTIVE
# [✅] auto-continue-thinking   ACTIVE
# [⚠️] efh-resume-list         NOT FOUND (code may have changed)
```

### 场景 3：出问题了要回滚
```powershell
.\scripts\rollback.ps1 --latest
# 输出:
# Restored from backup: ai-modules-chat-index.js.20260418-143022.backup
# All patches removed. Restart Trae.
```

### 场景 4：添加新补丁
只需编辑 `patches/definitions.json`，追加一个新 patch 对象，然后重新运行 `apply-patches.ps1`。

---

## 注意事项

1. **沙箱兼容**：所有脚本使用 `[System.IO.File]::ReadAllText()` 等 .NET API，不用 PowerShell cmdlet
2. **编码处理**：源码是 UTF-8，确保读写一致
3. **大文件性能**：87MB 文件一次读入内存，Replace 操作在内存中完成
4. **原子性**：先在内存中完成所有替换，最后一次性写入磁盘（避免半成品状态）
