<#
.SYNOPSIS
    Rollback Trae Unlock patches by restoring from backup
.DESCRIPTION
    Restores the target file from a backup in the backups/ directory.
    Without parameters, shows an interactive backup selection menu.
.EXAMPLE
    .\rollback.ps1
    Interactive mode - list backups and choose one
.EXAMPLE
    .\rollback.ps1 -Latest
    Restore the most recent backup directly
.EXAMPLE
    .\rollback.ps1 -List
    List all available backups
.EXAMPLE
    .\rollback.ps1 -Date 19
    Restore backup matching "19" (fuzzy match, no need for full timestamp)
.EXAMPLE
    .\rollback.ps1 -Date 20260419-214638
    Restore a specific backup by full timestamp
#>
param(
    [switch]$List,
    [switch]$Latest,
    [string]$Date = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
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

function Get-Backups {
    if (-not [System.IO.Directory]::Exists($BackupDir)) {
        return @()
    }
    return @(Get-ChildItem $BackupDir -Filter "*.backup" | Sort-Object LastWriteTime -Descending)
}

function Show-BackupList {
    param([array]$Backups)
    Write-ColorOutput "`n[trae-unlock] Available backups:" "Cyan"
    for ($i = 0; $i -lt $Backups.Count; $i++) {
        $b = $Backups[$i]
        $sizeKB = [Math]::Round($b.Length / 1KB, 0)
        $time = $b.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
        $name = $b.Name -replace '^index\.js\.', '' -replace '\.backup$', ''
        Write-ColorOutput "  [$($i+1)] $time  ($name)  ${sizeKB}KB" "White"
    }
}

$backups = Get-Backups

if ($backups.Count -eq 0) {
    Write-ColorOutput "[ERROR] No backups found in: $BackupDir" "Red"
    exit 2
}

# -List mode: just show and exit
if ($List) {
    Show-BackupList $backups
    exit 0
}

# Find backup to restore
$selectedBackup = $null

if ($Latest) {
    $selectedBackup = $backups[0]
    Write-ColorOutput "[trae-unlock] Using latest backup." "Cyan"
}
elseif ($Date) {
    $matched = @($backups | Where-Object { $_.Name -match [regex]::Escape($Date) })
    if ($matched.Count -eq 0) {
        Write-ColorOutput "[ERROR] No backup matching '$Date'" "Red"
        Write-ColorOutput "Tip: Use -List to see available backups, or try a shorter match like -Date 19" "Yellow"
        exit 2
    }
    elseif ($matched.Count -eq 1) {
        $selectedBackup = $matched[0]
    }
    else {
        Write-ColorOutput "[trae-unlock] Multiple backups match '$Date':" "Yellow"
        Show-BackupList $matched
        $choice = Read-Host "Enter number (1-$($matched.Count)), or Enter to cancel"
        if ([int]::TryParse($choice, [ref]$null) -and [int]$choice -ge 1 -and [int]$choice -le $matched.Count) {
            $selectedBackup = $matched[[int]$choice - 1]
        }
        else {
            Write-ColorOutput "Cancelled." "Yellow"
            exit 0
        }
    }
}
else {
    Show-BackupList $backups
    Write-ColorOutput "`n  Enter number to restore (1-$($backups.Count)), L for latest, or Enter to cancel:" "Cyan"
    $choice = Read-Host "Choice"
    
    if ($choice -eq "" -or $choice -eq "q") {
        Write-ColorOutput "Cancelled." "Yellow"
        exit 0
    }
    elseif ($choice -eq "L" -or $choice -eq "l") {
        $selectedBackup = $backups[0]
    }
    elseif ([int]::TryParse($choice, [ref]$null) -and [int]$choice -ge 1 -and [int]$choice -le $backups.Count) {
        $selectedBackup = $backups[[int]$choice - 1]
    }
    else {
        Write-ColorOutput "[ERROR] Invalid choice: $choice" "Red"
        exit 2
    }
}

if (-not $selectedBackup) {
    Write-ColorOutput "[ERROR] No backup selected." "Red"
    exit 2
}

Write-ColorOutput "`n[trae-unlock] Rolling back patches..." "Cyan"
$backupName = $selectedBackup.Name -replace '^index\.js\.', '' -replace '\.backup$', ''
Write-ColorOutput "  From: $backupName" "Yellow"
Write-ColorOutput "  To:   $TargetFile" "Gray"

[System.IO.File]::Copy($selectedBackup.FullName, $TargetFile, $true)

$content = [System.IO.File]::ReadAllText($TargetFile)
$patchFound = $false
foreach ($patch in $def.patches) {
    if ($patch.enabled -and $content.Contains($patch.replace_with)) {
        $patchFound = $true
        break
    }
}

if ($patchFound) {
    Write-ColorOutput "[WARNING] File still contains patch content. Partial rollback?" "Yellow"
}
else {
    Write-ColorOutput "[OK] Rollback verified - no patch content detected." "Green"
}

Write-ColorOutput "Done. Restart Trae window." "Cyan"
