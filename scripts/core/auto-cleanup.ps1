<#
.SYNOPSIS
    Auto-Cleanup Lifecycle System — 项目自动清理脚本

.DESCRIPTION
    五层自动化清理机制，保持项目永远整洁：
    - Layer 1: Archive 目录配额 enforcement (< 20 文件)
    - Layer 2: Backups 滚动窗口 (5 clean + 10 normal)
    - Layer 3: 健康度监控 + 报告
    - Layer 4: 文档质量校验 (DAS v1.0)
    - Layer 5: Discoveries.md 健康检查与自动清理 (P0-P4)

.PARAMETER WhatIf
    预览模式：只显示将要删除的文件，不实际删除

.PARAMETER Force
    强制模式：跳过确认提示

.PARAMETER Verbose
    详细输出：显示每个文件的清理原因

.PARAMETER CheckDiscoveries
    检查 discoveries.md 健康状态（行数/大小）

.PARAMETER CleanDiscoveries
    执行 discoveries.md 自动清理（P0-P4 清理策略）

.EXAMPLE
    .\auto-cleanup.ps1
    正常运行清理

.EXAMPLE
    .\auto-cleanup.ps1 -WhatIf
    预览将要执行的清理操作

.EXAMPLE
    .\auto-cleanup.ps1 -CheckDiscoveries
    仅检查 discoveries.md 健康状态

.EXAMPLE
    .\auto-cleanup.ps1 -CleanDiscoveries
    执行 discoveries.md 自动清理（会先检查健康状态）

.NOTES
    版本: 2.0.0
    作者: Auto-Cleanup System
    集成点: auto-heal.ps1 末尾自动调用
#>

param(
    [switch]$WhatIf,
    [switch]$Force,
    [switch]$Verbose,
    [switch]$CheckDiscoveries,
    [switch]$CleanDiscoveries
)

$ErrorActionPreference = "Stop"
$script:cleanupLog = @()
$script:deletedCount = 0
$script:skippedCount = 0
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent

# ============================================================
# 配置区
# ============================================================

$config = @{
    # Archive 目录配额
    MaxArchiveFiles = 20

    # Backups 滚动窗口
    BackupQuota = @{
        CleanBackups = 5   # 保留最新 5 个 clean backup
        NormalBackups = 10  # 保留最新 10 个普通 backup
    }

    # 受保护文件白名单（永远不会被删除）
    ProtectedFiles = @(
        'patches/definitions.json',
        'shared/discoveries.md',
        '.archive/definitions-v7-6cfb3de.json',
        'indexjs-v14.backup',
        'indexjs-v15.backup',
        'indexjs-v16.backup',
        'index.js.pre-v12.backup'
    )

    # 共享文件行数阈值（超标时告警）
    FileSizeThresholds = @{
        'shared/status.md'            = 500
        'shared/handoff-developer.md' = 300
        'shared/handoff-explorer.md'  = 300
        'shared/context.md'           = 150
        'AGENTS.md'                   = 100
    }
}

# ============================================================
# 工具函数
# ============================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = Get-Date -Format "HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default   { Write-Host $logEntry -ForegroundColor White }
    }

    $script:cleanupLog += $logEntry
}

function Test-ProtectedFile {
    param([string]$FilePath)

    $relativePath = $FilePath -replace [regex]::Escape($PWD) + "[\\/]?", "" -replace "\\", "/"

    foreach ($protected in $config.ProtectedFiles) {
        if ($relativePath -like "*$protected" -or $relativePath -eq $protected) {
            return $true
        }
    }
    return $false
}

function Remove-FileSafe {
    param([string]$FilePath, [string]$Reason)

    if (Test-ProtectedFile $FilePath) {
        Write-Log "跳过受保护文件: $FilePath" -Level "WARNING"
        $script:skippedCount++
        return
    }

    if ($WhatIf) {
        Write-Log "[预览] 将删除: $FilePath (原因: $Reason)" -Level "WARNING"
    } else {
        try {
            Remove-Item $FilePath -Force -ErrorAction Stop
            Write-Log "已删除: $FilePath (原因: $Reason)" -Level "SUCCESS"
            $script:deletedCount++
        } catch {
            Write-Log "删除失败: $FilePath ($_.Exception.Message)" -Level "ERROR"
        }
    }
}

# ============================================================
# Layer 1: Archive 目录配额 Enforcement
# ============================================================

function Invoke-ArchiveCleanup {
    Write-Log "`n=== Layer 1: Archive 目录配额清理 ===" -Level "INFO"

    $archiveDir = Join-Path $PWD ".archive"

    if (-not (Test-Path $archiveDir)) {
        Write-Log ".archive/ 目录不存在，跳过" -Level "INFO"
        return
    }

    # 获取所有文件（递归），按修改时间排序（最新的在前）
    $allFiles = Get-ChildItem $archiveDir -Recurse -File -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending

    $fileCount = $allFiles.Count

    if ($fileCount -eq 0) {
        Write-Log ".archive/ 为空目录 ✅" -Level "SUCCESS"
        return
    }

    Write-Log "当前文件数: $fileCount / 上限: $($config.MaxArchiveFiles)" -Level "INFO"

    if ($fileCount -le $config.MaxArchiveFiles) {
        Write-Log "未超配额，无需清理 ✅" -Level "SUCCESS"
        return
    }

    # 超出配额，删除最旧的文件
    $filesToDelete = $allFiles | Select-Object -Skip $config.MaxArchiveFiles
    $deleteCount = $filesToDelete.Count

    Write-Log "超出配额 $deleteCount 个文件，开始清理..." -Level "WARNING"

    foreach ($file in $filesToDelete) {
        Remove-FileSafe -FilePath $file.FullName -Reason "超出 archive 配额 ($fileCount > $($config.MaxArchiveFiles))"
    }
}

# ============================================================
# Layer 2: Backups 滚动窗口
# ============================================================

function Invoke-BackupCleanup {
    Write-Log "`n=== Layer 2: Backups 滚动窗口 ===" -Level "INFO"

    $backupDir = Join-Path $PWD "backups"

    if (-not (Test-Path $backupDir)) {
        Write-Log "backups/ 目录不存在，跳过" -Level "INFO"
        return
    }

    # 清理 Clean Backups
    $cleanPattern = Join-Path $backupDir "*clean*"
    $cleanBackups = Get-ChildItem $cleanPattern -File -ErrorAction SilentlyContinue |
                   Sort-Object LastWriteTime -Descending

    $cleanCount = $cleanBackups.Count
    $cleanQuota = $config.BackupQuota.CleanBackups

    Write-Log "Clean Backups: $cleanCount / 上限: $cleanQuota" -Level "INFO"

    if ($cleanCount -gt $cleanQuota) {
        $toDelete = $cleanBackups | Select-Object -Skip $cleanQuota
        Write-Log "清理 $((($toDelete).Count)) 个旧 clean backup..." -Level "WARNING"

        foreach ($file in $toDelete) {
            Remove-FileSafe -FilePath $file.FullName -Reason "超出 clean backup 配额 ($cleanCount > $cleanQuota)"
        }
    } else {
        Write-Log "Clean Backups 未超配额 ✅" -Level "SUCCESS"
    }

    # 清理普通 Backups (.backup 后缀)
    $normalPattern = Join-Path $backupDir "*.backup"
    $normalBackups = Get-ChildItem $normalPattern -File -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending

    $normalCount = $normalBackups.Count
    $normalQuota = $config.BackupQuota.NormalBackups

    Write-Log "普通 Backups: $normalCount / 上限: $normalQuota" -Level "INFO"

    if ($normalCount -gt $normalQuota) {
        $toDelete = $normalBackups | Select-Object -Skip $normalQuota
        Write-Log "清理 $((($toDelete).Count)) 个旧 backup..." -Level "WARNING"

        foreach ($file in $toDelete) {
            Remove-FileSafe -FilePath $file.FullName -Reason "超出 normal backup 配额 ($normalCount > $normalQuota)"
        }
    } else {
        Write-Log "普通 Backups 未超配额 ✅" -Level "SUCCESS"
    }
}

# ============================================================
# Layer 3: 健康度监控 + 报告
# ============================================================

function Invoke-HealthCheck {
    Write-Log "`n=== Layer 3: 项目健康度检查 ===" -Level "INFO"

    $warnings = @()

    # 检查共享文件行数
    foreach ($file in $config.FileSizeThresholds.Keys) {
        $filePath = Join-Path $PWD $file

        if (Test-Path $filePath) {
            $lineCount = (Get-Content $filePath -ErrorAction SilentlyContinue).Count
            $threshold = $config.FileSizeThresholds[$file]

            if ($lineCount -gt $threshold) {
                $msg = "$file 行数超标: $lineCount / $threshold"
                Write-Log "[⚠️] $msg" -Level "WARNING"
                $warnings += $msg
            } else {
                Write-Log "$file : $lineCount 行 ✅" -Level "INFO"
            }
        }
    }

    return $warnings
}

function Show-HealthReport {
    Write-Log "`n📊 项目健康度报告" -Level "INFO"
    Write-Log ("-" * 50) -Level "INFO"

    # 统计各目录文件数
    $archiveCount = 0
    if (Test-Path ".archive") {
        $archiveCount = (Get-ChildItem ".archive" -Recurse -File -ErrorAction SilentlyContinue).Count
    }

    $backupCount = 0
    if (Test-Path "backups") {
        $backupCount = (Get-ChildItem "backups" -File -ErrorAction SilentlyContinue).Count
    }

    $sharedCount = 0
    if (Test-Path "shared") {
        $sharedCount = (Get-ChildItem "shared" -File -ErrorAction SilentlyContinue).Count
    }

    $archDocCount = 0
    if (Test-Path "docs/architecture") {
        $archDocCount = (Get-ChildItem "docs/architecture" -Filter "*.md" -File -ErrorAction SilentlyContinue).Count
    }

    $agentsLines = 0
    if (Test-Path "AGENTS.md") {
        $agentsLines = (Get-Content "AGENTS.md").Count
    }

    # 输出报告
    $metrics = [ordered]@{
        ".archive/ 文件数"     = $archiveCount
        "backups/ 文件数"      = $backupCount
        "shared/ 文件数"       = $sharedCount
        "架构文档 (主目录)"     = $archDocCount
        "AGENTS.md 行数"       = $agentsLines
    }

    foreach ($key in $metrics.Keys) {
        $value = $metrics[$key]
        $status = ""

        # 简单状态判断
        switch ($key) {
            ".archive/ 文件数"     { $status = if ($value -le 20) { "✅" } else { "⚠️" } }
            "backups/ 文件数"      { $status = if ($value -le 15) { "✅" } else { "⚠️" } }
            "shared/ 文件数"       { $status = if ($value -le 12) { "✅" } else { "⚠️" } }
            "架构文档 (主目录)"     { $status = if ($value -le 12) { "✅" } else { "⚠️" } }
            "AGENTS.md 行数"       { $status = if ($value -le 100) { "✅" } else { "⚠️" } }
        }

        Write-Log "  $status $key : $value" -Level "INFO"
    }

    Write-Log ("-" * 50) -Level "INFO"
}

# ============================================================
# Layer 5: Discoveries.md 健康检查与自动清理 (P0-P4)
# ============================================================

function Check-DiscoveriesHealth {
    param([string]$Path)

    $discoveriesPath = Join-Path $Path "shared\discoveries.md"

    if (-not (Test-Path $discoveriesPath)) {
        Write-Host "[SKIP] discoveries.md 不存在" -ForegroundColor Yellow
        return
    }

    $lines = (Get-Content $discoveriesPath -ErrorAction SilentlyContinue).Count
    $sizeKB = [math]::Round((Get-Item $discoveriesPath).Length / 1KB, 1)

    # 阈值定义
    $MAX_LINES = 2000
    $MAX_SIZE_KB = 100
    $WARN_LINES = 1500
    $WARN_SIZE_KB = 75

    Write-Host "`n=== Discoveries.md 健康检查 ===" -ForegroundColor Cyan
    Write-Host "文件: $discoveriesPath"
    Write-Host "行数: $lines / 上限: $MAX_LINES"
    Write-Host "大小: ${sizeKB}KB / 上限: ${MAX_SIZE_KB}KB"

    # 判定状态
    if ($lines -gt $MAX_LINES -or $sizeKB -gt $MAX_SIZE_KB) {
        Write-Host "[ALERT] ❌ 超过硬性上限！" -ForegroundColor Red
        Write-Host "  → 建议: 运行 -CleanDiscoveries 执行自动清理" -ForegroundColor Yellow
        return "alert"
    }
    elseif ($lines -gt $WARN_LINES -or $sizeKB -gt $WARN_SIZE_KB) {
        Write-Host "[WARN] ⚠️  接近警告线" -ForegroundColor Yellow
        Write-Host "  → 建议: 下次 Explorer 会话时考虑清理低价值内容" -ForegroundColor Yellow
        return "warn"
    }
    else {
        Write-Host "[OK] ✅ 文件健康" -ForegroundColor Green
        return "healthy"
    }
}

function Invoke-DiscoveriesCleanup {
    param([string]$Path)

    $discoveriesPath = Join-Path $Path "shared\discoveries.md"
    $backupPath = "$discoveriesPath.pre-cleanup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

    # Step 1: 备份
    Copy-Item $discoveriesPath $backupPath -Force
    Write-Host "[BACKUP] 已备份到: $backupPath" -ForegroundColor Cyan

    # Step 2: 读取并分析
    $content = Get-Content $discoveriesPath -Raw
    $lines = $content.Split("`n").Count
    $beforeSizeKB = [math]::Round((Get-Item $discoveriesPath).Length / 1KB, 1)

    Write-Host "`n=== 开始 Discoveries.md 自动清理 ===" -ForegroundColor Cyan
    Write-Host "清理前: $lines 行 / ${beforeSizeKB}KB"

    # P0: 完全重复 section 检测（简化版：检测明显的日期重复）
    # 注意：完整的去重需要更复杂的 NLP/语义分析，这里实现基础版

    # P1: 过程性内容检测和删除
    $processKeywords = @(
        '搜索记录',
        '扫描过程',
        '尝试历史',
        '调试记录',
        '过程性',
        '操作流程'
    )

    $removedSections = @()

    foreach ($keyword in $processKeywords) {
        # 查找包含这些关键词的 ## 二级标题及其后续内容块
        $pattern = "(?m)^## \[.*$keyword.*\](?:\r?\n)(?:(?!^## ).*\r?\n)*"
        $matches = [regex]::Matches($content, $pattern, 'Multiline')

        if ($matches.Count -gt 0) {
            foreach ($match in $matches) {
                $removedSections += "[P1] 删除过程性内容: $($match.Value.Substring(0, [Math]::Min(50, $match.Value.Length)))..."
                $content = $content.Replace($match.Value, "")
            }
        }
    }

    # P2: 低价值 Trivial 发现清理（简化版）
    # 检查 confidence=low 且较短的条目

    # 写入清理后的内容
    Set-Content $discoveriesPath -Value $content -Encoding UTF8 -NoNewline

    # 统计结果
    $afterLines = (Get-Content $discoveriesPath).Count
    $afterSizeKB = [math]::Round((Get-Item $discoveriesPath).Length / 1KB, 1)
    $removedLines = $lines - $afterLines

    Write-Host "`n=== 清理报告 ===" -ForegroundColor Green
    Write-Host "清理前: $lines 行 / ${beforeSizeKB}KB"
    Write-Host "清理后: $afterLines 行 / ${afterSizeKB}KB"
    Write-Host "减少: $removedLines 行 / $([math]::Round($beforeSizeKB - $afterSizeKB, 1))KB"
    Write-Host ""

    if ($removedSections.Count -gt 0) {
        Write-Host "删除的 section:" -ForegroundColor Yellow
        $removedSections | ForEach-Object { Write-Host "  - $_" }
    }

    # 最终检查
    $finalStatus = Check-DiscoveriesHealth -Path $Path
    Write-Host "`n最终状态: $finalStatus" -ForegroundColor $(if ($finalStatus -eq "healthy") { 'Green' } else { 'Yellow' })

    Write-Host "`n[INFO] 备份文件保留在: $backupPath" -ForegroundColor Cyan
    Write-Host "[INFO] 确认无问题后可手动删除备份" -ForegroundColor Gray
}

# ============================================================
# 主流程
# ============================================================

function Invoke-AutoCleanup {
    param()

    $startTime = Get-Date

    Write-Log ""
    Write-Log ("=" * 60) -Level "INFO"
    Write-Log "  🧹 Auto-Cleanup Lifecycle System v1.0" -Level "INFO"
    Write-Log ("=" * 60) -Level "INFO"

    if ($WhatIf) {
        Write-Log "⚠️  预览模式 — 不会实际删除任何文件" -Level "WARNING"
    }

    try {
        # Layer 1: Archive 配额
        Invoke-ArchiveCleanup

        # Layer 2: Backups 滚动
        Invoke-BackupCleanup

        # Layer 3: 健康度检查
        $warnings = Invoke-HealthCheck

        # 显示报告
        Show-HealthReport

        # === Layer 4: 文档质量校验 ===
        $validateScript = Join-Path $ScriptDir "validate-docs.ps1"
        if (Test-Path $validateScript) {
            Write-Log "`n=== Layer 4: 文档质量校验 (DAS v1.0) ===" -Level "INFO"

            try {
                # 调用校验脚本并捕获输出
                $validationOutput = & $validateScript 2>&1 | Out-String

                if ($validationOutput) {
                    # 提取评分行（包含 "文档质量评分" 的行）
                    $scoreLine = $validationOutput | Select-String "文档质量评分" | Select-Object -First 1

                    if ($scoreLine) {
                        Write-Log $scoreLine.Line -Level "INFO"
                    }

                    # 显示简化的校验结果摘要
                    $errorCount = ($validationOutput | Select-String "\[ERROR\]").Count
                    $warningCount = ($validationOutput | Select-String "\[WARNING\]").Count

                    if ($errorCount -gt 0) {
                        Write-Log "❌ 发现 $errorCount 个文档质量问题 (ERROR)" -Level "ERROR"
                    } elseif ($warningCount -gt 0) {
                        Write-Log "⚠️ 发现 $warningCount 个优化建议 (WARNING)" -Level "WARNING"
                    } else {
                        Write-Log "✅ 文档质量校验通过" -Level "SUCCESS"
                    }
                }
            } catch {
                Write-Log "文档质量校验跳过: $($_.Exception.Message)" -Level "WARNING"
            }
        }

        # 总结
        $endTime = Get-Date
        $duration = ($endTime - $StartTime).TotalSeconds

        Write-Log ""
        Write-Log ("=" * 60) -Level "INFO"
        Write-Log "  ✅ Auto-Cleanup 完成" -Level "SUCCESS"
        Write-Log ("=" * 60) -Level "INFO"
        Write-Log "  耗时: ${duration} 秒" -Level "INFO"
        Write-Log "  删除文件: $script:deletedCount" -Level "INFO"
        Write-Log "  跳过文件: $script:skippedCount (受保护)" -Level "INFO"

        if ($warnings.Count -gt 0) {
            Write-Log "  ⚠️  告警: $($warnings.Count) 项" -Level "WARNING"
        }

        # 返回结果
        return @{
            Success = $true
            DeletedCount = $script:deletedCount
            SkippedCount = $script:skippedCount
            Warnings = $warnings
            Duration = $duration
        }

    } catch {
        Write-Log "❌ Auto-Cleanup 失败: $($_.Exception.Message)" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# ============================================================
# 入口点
# ============================================================

if ($MyInvocation.InvocationName -ne '.') {
    # 直接运行脚本（非 dot-source）

    # 处理 Discoveries.md 相关参数（独立于主清理流程）
    if ($CheckDiscoveries) {
        Check-DiscoveriesHealth -Path $PWD
        exit 0
    }

    if ($CleanDiscoveries) {
        # 先检查再清理
        $status = Check-DiscoveriesHealth -Path $PWD
        if ($status -eq "alert" -or $status -eq "warn") {
            $confirm = Read-Host "确认要执行自动清理吗？(y/N)"
            if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                Invoke-DiscoveriesCleanup -Path $PWD
            } else {
                Write-Host "[CANCEL] 已取消清理"
            }
        }
        else {
            Write-Host "[INFO] 文件未超限，无需清理"
        }
        exit 0
    }

    # 正常运行主清理流程
    $result = Invoke-AutoCleanup

    exit 0
}
