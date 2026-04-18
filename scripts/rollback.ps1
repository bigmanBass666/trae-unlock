<#
.SYNOPSIS
    Rollback Trae Unlock patches by restoring from backup
.DESCRIPTION
    Restores the target file from a backup in the backups/ directory.
.EXAMPLE
    .\rollback.ps1
.EXAMPLE
    .\rollback.ps1 --list
.EXAMPLE
    .\rollback.ps1 --date 20260418
#>
param(
    [switch]$List,
    [string]$Date = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$DefPath = Join-Path $RootDir "patches\definitions.json"
$BackupDir = Join-Path $RootDir "backups"

$defJson = [System.IO.File]::ReadAllText($DefPath)
$def = $defJson | ConvertFrom-Json
$TargetFile = $def.meta.target_file
$BaseName = [System.IO.Path]::GetFileName($TargetFile)

function Write-ColorOutput {
    param([string]$Msg, [string]$Color = "White")
    Write-Host $Msg -ForegroundColor $Color
}

# List mode
if ($List) {
    Write-ColorOutput "[trae-unlock] Available backups:" "Cyan"
    if (-not [System.IO.Directory]::Exists($BackupDir)) {
        Write-ColorOutput "  No backups directory found." "Yellow"
        exit 0
    }
    $backups = Get-ChildItem $BackupDir -Filter "*.backup" | Sort-Object LastWriteTime -Descending
    if ($backups.Count -eq 0) {
        Write-ColorOutput "  No backup files found." "Yellow"
        exit 0
    }
    foreach ($b in $backups) {
        $sizeKB = [Math]::Round($b.Length / 1KB, 0)
        Write-ColorOutput "  [$($b.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))] $($b.Name) ($sizeKB KB)" "White"
    }
    exit 0
}

# Find backup to restore
$backupFiles = Get-ChildItem $BackupDir -Filter "*.backup" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending

if ($backupFiles.Count -eq 0) {
    Write-ColorOutput "[ERROR] No backups found in: $BackupDir" "Red"
    exit 2
}

$selectedBackup = $null
if ($Date) {
    $selectedBackup = $backupFiles | Where-Object { $_.Name -match $Date } | Select-Object -First 1
    if (-not $selectedBackup) {
        Write-ColorOutput "[ERROR] No backup matching date '$Date'" "Red"
        exit 2
    }
} else {
    $selectedBackup = $backupFiles[0]
}

Write-ColorOutput "[trae-unlock] Rolling back patches..." "Cyan"
Write-ColorOutput "  Restoring from: $($selectedBackup.Name)" "Yellow"
Write-ColorOutput "  To: $TargetFile" "Gray"

# Restore
[System.IO.File]::Copy($selectedBackup.FullName, $TargetFile, $true)

# Verify
$content = [System.IO.File]::ReadAllText($TargetFile)
$patchFound = $false
foreach ($patch in $def.patches) {
    if ($content.Contains($patch.replace_with)) {
        $patchFound = $true
        break
    }
}

if ($patchFound) {
    Write-ColorOutput "[WARNING] File still contains patch content. Partial rollback?" "Yellow"
} else {
    Write-ColorOutput "[OK] Rollback verified - no patch content detected." "Green"
}

Write-ColorOutput "Done. Restart Trae window." "Cyan"
