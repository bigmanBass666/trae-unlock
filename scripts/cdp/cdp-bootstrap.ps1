<#
.SYNOPSIS
    CDP Bootstrap Installer — 将 CDP 启用代码注入 Trae 的 main.js
    
.DESCRIPTION
    在 out/main.js 最前面插入 CDP 启用代码，使 Trae 每次启动都自动开启远程调试端口。
    这是"启动劫持"方案（方向 4），只需修改一次入口文件，不影响业务代码。
    
.PARAMETER Action
    "install" | "uninstall" | "status"
    
.EXAMPLE
    .\cdp-bootstrap.ps1 -Action install
    # 注入 CDP 启用代码到 main.js
    
.EXAMPLE
    .\cdp-bootstrap.ps1 -Action uninstall
    # 移除注入的代码，恢复原始 main.js
    
.EXAMPLE
    .\cdp-bootstrap.ps1 -Action status
    # 检查当前状态
#>

param(
    [ValidateSet("install", "uninstall", "status")]
    [string]$Action = "status"
)

$ErrorActionPreference = "Stop"

$traeAppDir = "D:\apps\Trae CN\resources\app"
$mainJsPath = Join-Path $traeAppDir "out\main.js"
$backupPath = Join-Path $traeAppDir "out\main.js.pre-cdp-backup"
$bootstrapPath = Join-Path $PSScriptRoot "_cdp-bootstrap.js"
$markerStart = "// CDP Enable Block — trae-unlock (do not remove)"
$markerEnd   = "// End CDP Enable Block"

function Get-Status {
    if (-not (Test-Path $mainJsPath)) {
        Write-Host "[ERROR] main.js not found: $mainJsPath" -ForegroundColor Red
        return "missing"
    }
    
    $content = [IO.File]::ReadAllText($mainJsPath)
    if ($content.StartsWith("/**")) {
        # 原始文件以 /*! 开头（VS Code 版权头）
        if ($content.Contains($markerStart)) {
            return "installed"
        } else {
            return "clean"
        }
    } elseif ($content.StartsWith("// CDP Enable Block")) {
        return "installed"
    } else {
        return "unknown"
    }
}

switch ($Action) {
    "status" {
        $status = Get-Status
        switch ($status) {
            "installed" { 
                Write-Host "[STATUS] ✅ CDP bootstrap is INSTALLED" -ForegroundColor Green
                Write-Host "  main.js has been modified to enable CDP on every launch" 
                Write-Host "  Backup: $backupPath"
            }
            "clean" {
                Write-Host "[STATUS] ⚪ CDP bootstrap is NOT installed (original)" -ForegroundColor Yellow
                Write-Host "  Run with -Action install to enable CDP"
            }
            "missing" {
                Write-Host "[STATUS] ❌ main.js not found!" -ForegroundColor Red
            }
            default {
                Write-Host "[STATUS] ❓ Unknown state: $status" -ForegroundColor DarkGray
            }
        }
    }
    
    "install" {
        $status = Get-Status
        if ($status -eq "installed") {
            Write-Host "[SKIP] Already installed. Nothing to do." -ForegroundColor Yellow
            exit 0
        }
        
        if (-not (Test-Path $bootstrapPath)) {
            Write-Host "[ERROR] Bootstrap file not found: $bootstrapPath" -ForegroundColor Red
            exit 1
        }
        
        # 备份原始文件
        if (-not (Test-Path $backupPath)) {
            Copy-Item $mainJsPath $backupPath
            Write-Host "[BACKUP] Created: $backupPath" -ForegroundColor Cyan
        } else {
            Write-Host "[INFO] Backup already exists: $backupPath" -ForegroundColor Gray
        }
        
        # 读取 bootstrap 和原始内容
        $bootstrapContent = [IO.File]::ReadAllText($bootstrapPath)
        $originalContent = [IO.File]::ReadAllText($mainJsPath)
        
        # 写入合并后的文件
        $newContent = $bootstrapContent + "`n" + $originalContent
        [IO.File]::WriteAllText($mainJsPath, $newContent, [System.Text.Encoding]::UTF8)
        
        $newSize = [math]::Round((Get-Item $mainJsPath).Length / 1KB, 1)
        Write-Host "[OK] ✅ CDP bootstrap installed!" -ForegroundColor Green
        Write-Host "  main.js size: ${newSize}KB (+ bootstrap)"
        Write-Host ""
        Write-Host "Next step:" -ForegroundColor Cyan
        Write-Host "  1. Start Trae normally (double-click icon or shortcut)"
        Write-Host "  2. CDP will be available at http://localhost:9222/json"
        Write-Host "  3. Run: node scripts/cdp-inject.js --port 9222"
    }
    
    "uninstall" {
        $status = Get-Status
        if ($status -ne "installed") {
            if ($status -eq "clean") {
                Write-Host "[SKIP] Not installed, nothing to uninstall." -ForegroundColor Yellow
            } else {
                Write-Host "[WARN] Unexpected status: $status, cannot safely uninstall" -ForegroundColor Red
            }
            exit 0
        }
        
        if (Test-Path $backupPath) {
            # 从备份恢复
            Copy-Item $backupPath $mainJsPath -Force
            Write-Host "[OK] ✅ Restored from backup" -ForegroundColor Green
            
            # 可选：删除备份
            # Remove-Item $backupPath
            # Write-Host "[CLEANUP] Removed backup file"
        } else {
            Write-Host "[ERROR] No backup found! Cannot safely uninstall." -ForegroundColor Red
            Write-Host "  Manual intervention required."
            exit 1
        }
    }
}
