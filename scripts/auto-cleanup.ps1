<#
.SYNOPSIS
    Auto-Cleanup Lifecycle System — 项目自动清理脚本

.DESCRIPTION
    三层自动化清理机制，保持项目永远整洁：
    - Layer 1: Archive 目录配额 enforcement (< 20 文件)
    - Layer 2: Backups 滚动窗口 (5 clean + 10 normal)
    - Layer 3: 健康度监控 + 报告

.PARAMETER WhatIf
    预览模式：只显示将要删除的文件，不实际删除

.PARAMETER Force
    强制模式：跳过确认提示

.PARAMETER Verbose
    详细输出：显示每个文件的清理原因

.EXAMPLE
    .\auto-cleanup.ps1
    正常运行清理

.EXAMPLE
    .\auto-cleanup.ps1 -WhatIf
    预览将要执行的清理操作

.NOTES
    版本: 1.0.0
    作者: Auto-Cleanup System
    集成点: auto-heal.ps1 末尾自动调用
#>

param(
    [switch]$WhatIf,
    [switch]$Force,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$script:cleanupLog = @()
$script:deletedCount = 0
$script:skippedCount = 0

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
    $result = Invoke-AutoCleanup

    exit 0
}
