<#
.SYNOPSIS
    One-click snapshot: backup target file + git commit all changes
.DESCRIPTION
    Creates a timestamped clean backup of the patched target file,
    then commits all working directory changes to git.
    Use this after any important work or before risky operations.
.EXAMPLE
    .\snapshot.ps1
.EXAMPLE
    .\snapshot.ps1 -Message "feat: new patch applied"
#>
param(
    [string]$Message = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$DefPath = Join-Path $RootDir "patches\definitions.json"
$BackupDir = Join-Path $RootDir "backups"

function Write-ColorOutput {
    param([string]$Msg, [string]$Color = "White")
    Write-Host $Msg -ForegroundColor $Color
}

Write-ColorOutput "[snapshot] 📸 Starting safety snapshot..." "Cyan"

# Step 1: Read target file path from definitions
if (-not [System.IO.File]::Exists($DefPath)) {
    Write-ColorOutput "[ERROR] definitions.json not found: $DefPath" "Red"
    exit 2
}
$defJson = [System.IO.File]::ReadAllText($DefPath)
$def = $defJson | ConvertFrom-Json
$TargetFile = $def.meta.target_file
Write-ColorOutput "  Target: $($def.meta.target_file_display)" "Gray"

# Step 2: Backup target file
if (-not [System.IO.File]::Exists($TargetFile)) {
    Write-ColorOutput "[WARNING] Target file not found: $TargetFile — skipping backup" "Yellow"
} else {
    if (-not [System.IO.Directory]::Exists($BackupDir)) {
        [System.IO.Directory]::CreateDirectory($BackupDir) | Out-Null
    }
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFile = Join-Path $BackupDir "clean-$timestamp.ext"
    [System.IO.File]::Copy($TargetFile, $backupFile, $true)
    $sizeMB = [math]::Round((Get-Item $TargetFile).Length / 1MB, 1)
    Write-ColorOutput "  ✅ Backup: $(Split-Path $backupFile -Leaf) ($sizeMB MB)" "Green"

    # Rotate: keep only latest 5 clean backups
    $maxBackups = 5
    $existing = Get-ChildItem $BackupDir -Filter "clean-*.ext" | Sort-Object LastWriteTime -Descending | Select-Object -Skip $maxBackups
    foreach ($old in $existing) { Remove-Item $old.FullName -Force }
}

# Step 3: Git commit
Push-Location $RootDir
$status = git status --porcelain 2>$null
if (-not $status) {
    Write-ColorOutput "  ℹ️  No changes to commit." "DarkGray"
    Pop-Location
    exit 0
}

$changedFiles = ($status -split "`n").Count
Write-ColorOutput "  📝 Staging $changedFiles file(s)..." "Gray"
git add -A 2>$null

# Determine commit message
$ts = Get-Date -Format "yyyy-MM-dd HH:mm"
if ($Message) {
    $commitMsg = $Message
} else {
    $commitMsg = "chore: manual-snapshot [$ts] — $changedFiles files changed"
}

git commit -m $commitMsg 2>$null
$commitHash = git rev-parse --short HEAD 2>$null
$commitTime = git log -1 --format=%ai 2>$null

Write-ColorOutput ""
Write-ColorOutput "=========================================" "White"
Write-ColorOutput "  ✅ Snapshot complete!" "Green"
Write-ColorOutput "  Backup:  clean-$timestamp.ext" "Cyan"
Write-ColorOutput "  Commit:  $commitHash ($commitTime)" "Cyan"
Write-ColorOutput "  Files:   $changedFiles changed" "Gray"
Write-ColorOutput "=========================================" "White"
Pop-Location
