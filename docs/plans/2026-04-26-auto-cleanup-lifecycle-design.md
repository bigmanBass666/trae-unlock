# Auto-Cleanup Lifecycle System — 设计方案

> **目标**: 让项目自我净化，永远不需要手动大扫除
> **原则**: 边产生边清理，零维护成本
> **触发**: 每次 auto-heal.ps1 运行时自动执行（无感）

---

## 一、问题根因分析

| 问题 | 当前行为 | 后果 |
|------|---------|------|
| T3 脚本堆积 | 归档到 `.archive/scripts/YYYYMMDD-/` | 200+ 文件 |
| Specs 堆积 | 完成后保留在 `.archive/specs/` | 47 个历史 spec |
| Backups 无限增长 | auto-heal 每次备份，从不清理 | 95 个备份 |
| 共享文件膨胀 | "只追加不重写"规则 | 持续增长 |

---

## 二、解决方案：三层自动化机制

### Layer 1: 即时清理（T3/T4 脚本 + Specs）

**改革脚本生命周期规则**：

| 层级 | 旧规则 | ✅ 新规则 | 清理时机 |
|------|--------|----------|---------|
| **T1: 核心工具** | 永久保留 | 永久保留（不变） | — |
| **T2: 可复用工具** | 版本更新时评估 | 版本更新时评估（不变） | — |
| **T3: 一次性产出** | 归档到 `.archive/` | **会话结束时直接删除** | Explorer Agent 结束时 |
| **T4: 临时垃圾** | 立即删除 | 立即删除（不变） | 产生时 |

**Specs 生命周期**：

| 状态 | 旧行为 | ✅ 新行为 | 清理时机 |
|------|--------|----------|---------|
| 进行中 | 保留在 `.trae/specs/` | 保留在 `.trae/specs/` | — |
| 已完成 | 移动到 `.archive/specs/` | **直接删除** | Developer/Explorer 结束时 |

**理由**：
- Git history 已有完整记录，无需本地保留
- 删除后可随时 `git checkout` 恢复
- 避免"先归档再清理"的两步操作

---

### Layer 2: 配额制（Backups + Archive）

**Backups 滚动窗口**：

```powershell
# 配额配置
$backupQuota = @{
    CleanBackups = 5    # 保留最新 5 个 clean backup
    NormalBackups = 10   # 保留最新 10 个普通 backup（含特殊标记）
}

# 自动清理逻辑
function Cleanup-Backups {
    # 1. 获取所有 clean backups，按时间排序
    $cleanBackups = Get-ChildItem backups\*clean* | Sort-Object LastWriteTime -Descending

    # 2. 保留最新的 5 个，删除其余
    if ($cleanBackups.Count -gt $backupQuota.CleanBackups) {
        $cleanBackups | Select-Object -Skip $backupQuota.CleanBackups | Remove-Item -Force
    }

    # 3. 同理处理普通 backups
    $normalBackups = Get-ChildItem backups\*.backup | Sort-Object LastWriteTime -Descending
    if ($normalBackups.Count -gt $backupQuota.NormalBackups) {
        $normalBackups | Select-Object -Skip $backupQuota.NormalBackups | Remove-Item -Force
    }
}
```

**Archive 目录上限**：

```powershell
# 硬性配额
$maxArchiveFiles = 20  # .archive/ 最多允许 20 个文件

function Enforce-ArchiveQuota {
    $archiveFiles = Get-ChildItem .archive\ -Recurse -File | Sort-Object LastWriteTime -Descending

    if ($archiveFiles.Count -gt $maxArchiveFiles) {
        $filesToDelete = $archiveFiles | Select-Object -Skip $maxArchiveFiles
        Write-Host "[auto-cleanup] 删除 $($filesToDelete.Count) 个过期归档文件"
        $filesToDelete | Remove-Item -Force
    }
}
```

---

### Layer 3: 健康度监控（共享文件 + 整体状态）

**共享文件行数监控**：

```powershell
# 行数阈值
$fileSizeThresholds = @{
    'shared/status.md'           = 500   # 超过 500 行告警
    'shared/handoff-developer.md' = 300  # 超过 300 行告警
    'shared/handoff-explorer.md'  = 300  # 超过 300 行告警
    'shared/context.md'          = 150   # 超过 150 行告警
    'AGENTS.md'                  = 100   # 超过 100 行告警
}

function Check-FileHealth {
    foreach ($file in $fileSizeThresholds.Keys) {
        if (Test-Path $file) {
            $lineCount = (Get-Content $file).Count
            $threshold = $fileSizeThresholds[$file]

            if ($lineCount -gt $threshold) {
                Write-Host "[⚠️] $file 行数超标: $lineCount / $threshold" -ForegroundColor Yellow
                # 可选：自动压缩或通知用户
            }
        }
    }
}
```

**整体健康度报告**：

```powershell
function Show-HealthReport {
    Write-Host "`n=== 📊 项目健康度 ===" -ForegroundColor Cyan
    Write-Host ".archive/ 文件数: $( (Get-ChildItem .archive\ -Recurse -File).Count )"
    Write-Host "backups/ 文件数: $( (Get-ChildItem backups\).Count )"
    Write-Head "shared/ 文件数: $( (Get-ChildItem shared\).Count )"
    Write-Host "docs/architecture/ 主目录: $( (Get-ChildItem docs\architecture\*.md).Count )"
    Write-Host "AGENTS.md 行数: $((Get-Content AGENTS.md).Count)"
}
```

---

## 三、集成方案

### 方案 A：集成到 auto-heal.ps1（推荐 ✅）

**优点**：
- 复用现有的自动化流程
- 每次补丁操作时自动执行
- 用户完全无感

**实现方式**：

```powershell
# 在 auto-heal.ps1 末尾添加
function Invoke-AutoCleanup {
    param([switch]$Force)

    Write-Host "`n🧹 [auto-cleanup] 开始自动清理..." -ForegroundColor Green

    # Layer 1: 清理过期归档（如果有残留）
    Enforce-ArchiveQuota

    # Layer 2: Backups 滚动窗口
    Cleanup-Backups

    # Layer 3: 健康度检查
    Check-FileHealth
    Show-HealthReport

    Write-Host "✅ [auto-cleanup] 完成" -ForegroundColor Green
}

# 在主流程末尾调用
Invoke-AutoCleanup
```

**触发时机**：
- `apply-patches.ps1` 执行后
- `auto-heal.ps1` 执行后
- 手动运行 `scripts/auto-cleanup.ps1`

---

### 方案 B：独立脚本 + Git Hook（备选）

**适用场景**：如果不想修改 auto-heal.ps1

```bash
# .git/hooks/post-commit
#!/bin/bash
powershell -File scripts/auto-cleanup.ps1
```

**缺点**：需要额外配置 Git hook

---

## 四、实施计划

### Phase 1: 创建 auto-cleanup.ps1（30 分钟）

- [ ] 创建 `scripts/auto-cleanup.ps1`
- [ ] 实现 Layer 1: Archive 配额 enforcement
- [ ] 实现 Layer 2: Backups 滚动窗口
- [ ] 实现 Layer 3: 健康度检查 + 报告
- [ ] 添加详细日志输出

### Phase 2: 更新 _registry.md 规则（15 分钟）

- [ ] 修改 T3 生命周期：从"归档"改为"即删"
- [ ] 添加 Specs 生命周期：完成后即删
- [ ] 添加 Backups 配额说明
- [ ] 添加 auto-cleanup.ps1 到核心工具列表

### Phase 3: 集成测试（15 分钟）

- [ ] 手动运行 `scripts/auto-cleanup.ps1` 验证功能
- [ ] 验证不会误删重要文件
- [ ] 验证 health report 输出正确
- [ ] 测试边界条件（空目录、刚好达标等）

### Phase 4: 集成到 auto-heal.ps1（10 分钟）

- [ ] 在 auto-heal.ps1 末尾调用 Invoke-AutoCleanup
- [ ] 测试完整流程：apply → heal → cleanup
- [ ] 更新 AGENTS.md 说明新机制

---

## 五、预期效果对比

| 维度 | 当前（手动大扫除） | 未来（auto-cleanup） |
|------|------------------|---------------------|
| **清理频率** | 每 N 次会话一次（痛苦） | **每次操作后自动**（无感） |
| **单次耗时** | 1-2 小时 | **< 5 秒** |
| **文件数量** | 波动大（300+ → 120） | **恒定 < 130** |
| **用户参与** | 需要监督 + 决策 | **完全自动化** |
| **磁盘占用** | 峰值 ~1 GB（backups） | **恒定 < 200 MB** |
| **认知负担** | 高（要理解该删什么） | **零**（规则已内置） |

---

## 六、风险控制

### 安全措施

1. **Dry-run 模式**：首次运行只显示将要删除的文件，不实际删除
   ```powershell
   scripts/auto-cleanup.ps1 -WhatIf  # 预览模式
   ```

2. **白名单机制**：关键文件永远不会被删除
   ```powershell
   $protectedFiles = @(
       'patches/definitions.json',
       'shared/discoveries.md',
       '.archive/definitions-v7-6cfb3de.json',  # 特殊备份
       'indexjs-v14.backup',
       'indexjs-v15.backup',
       'indexjs-v16.backup'
   )
   ```

3. **Git 安全网**：所有删除都在 Git 追踪内，可恢复
   ```powershell
   # 误删恢复
   git checkout HEAD~1 -- backups/deleted-file.backup
   ```

4. **日志记录**：所有清理操作写入日志
   ```powershell
   Write-Log "[auto-cleanup] 删除 $fileName (原因: 超出配额)"
   ```

---

## 七、成功标准

✅ **项目永远保持整洁**：
- `.archive/` < 20 文件
- `backups/` < 15 文件
- 总文件数 < 130

✅ **用户零参与**：
- 不需要手动运行清理命令
- 不需要决定哪些文件该删
- 不需要定期"大扫除"

✅ **可追溯**：
- 所有清理操作有日志
- 误删可通过 Git 恢复
- Dry-run 模式可预览变更

---

## 八、下一步行动

**如果你同意这个方案**，我将立即开始实施：

1. 创建 `scripts/auto-cleanup.ps1`（核心脚本）
2. 更新 `_registry.md` 规则（T3 改为即删）
3. 集成到 `auto-heal.ps1`（自动触发）
4. 测试验证（确保安全）

**预计总耗时**：60-90 分钟
**长期收益**：**永远告别手动大扫除** 🎉
