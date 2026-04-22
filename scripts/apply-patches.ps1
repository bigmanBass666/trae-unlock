<#
.SYNOPSIS
    Apply Trae Unlock patches to ai-modules-chat/dist/index.js
.DESCRIPTION
    Reads patch definitions from patches/definitions.json and applies them
    to the target file. Auto-backups before modifying.
.EXAMPLE
    .\apply-patches.ps1
.EXAMPLE
    .\apply-patches.ps1 -DryRun
.EXAMPLE
    .\apply-patches.ps1 -PatchIds "auto-confirm-commands"
#>
param(
    [switch]$DryRun,
    [string]$PatchIds = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$DefPath = Join-Path $RootDir "patches\definitions.json"
$BackupDir = Join-Path $RootDir "backups"

function Write-ColorOutput {
    param([string]$Msg, [string]$Color = "White")
    Write-Host $Msg -ForegroundColor $Color
}

# Read definitions
Write-ColorOutput "[trae-unlock] Loading patch definitions..." "Cyan"
$defJson = [System.IO.File]::ReadAllText($DefPath)
$def = $defJson | ConvertFrom-Json
$TargetFile = $def.meta.target_file
$Patches = $def.patches

Write-ColorOutput "  Target: $($def.meta.target_file_display)" "Gray"
Write-ColorOutput "  Patches defined: $($Patches.Count)" "Gray"

# Check target exists
if (-not [System.IO.File]::Exists($TargetFile)) {
    Write-ColorOutput "[ERROR] Target file not found: $TargetFile" "Red"
    exit 2
}

# Filter patches by ID if specified
if ($PatchIds) {
    $FilterList = $PatchIds.Split(",").Trim()
    $Patches = @($Patches | Where-Object { $FilterList -contains $_.id })
    Write-ColorOutput "  Filtered to: $($Patches.Count) patch(es)" "Yellow"
}

# Create backup dir
if (-not [System.IO.Directory]::Exists($BackupDir)) {
    [System.IO.Directory]::CreateDirectory($BackupDir) | Out-Null
}

# Auto-backup
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BaseName = [System.IO.Path]::GetFileName($TargetFile)
$BackupFile = Join-Path $BackupDir "$BaseName.$Timestamp.backup"

if (-not $DryRun) {
    [System.IO.File]::Copy($TargetFile, $BackupFile, $true)
    Write-ColorOutput "  Backup created: $([System.IO.Path]::GetFileName($BackupFile))" "Green"
} else {
    Write-ColorOutput "  [DRY RUN] Would backup to: $([System.IO.Path]::GetFileName($BackupFile))" "DarkGray"
}

# Read target file
$content = [System.IO.File]::ReadAllText($TargetFile)
$originalContent = $content
$appliedCount = 0
$skippedCount = 0
$failedCount = 0

foreach ($patch in $Patches) {
    if (-not $patch.enabled) {
        Write-ColorOutput "  [-] $($patch.id): DISABLED, skipping" "DarkGray"
        continue
    }

    $find = $patch.find_original
    $replace = $patch.replace_with

    # Use fingerprint for detection if available (avoids long-string encoding issues)
    $fingerprint = ""
    if ($patch.PSObject.Properties.Name -contains "check_fingerprint") {
        $fingerprint = $patch.check_fingerprint
    }
    $detectStr = if ($fingerprint) { $fingerprint } else { $replace }

    # Check if already applied
    if ($content.Contains($detectStr)) {
        Write-ColorOutput "  [OK] $($patch.id) ($($patch.name)): Already applied" "Green"
        $skippedCount++
        continue
    }

    # Try exact match
    if ($content.Contains($find)) {
        if (-not $DryRun) {
            $content = $content.Replace($find, $replace)
            Write-ColorOutput "  [OK] $($patch.id) ($($patch.name)): Applied ($($patch.offset_hint))" "Green"
        } else {
            Write-ColorOutput "  [OK] $($patch.id) ($($patch.name)): Would apply ($($patch.offset_hint))" "DarkGreen"
        }
        $appliedCount++
        continue
    }

    # Fuzzy search: try first 50 chars
    $fuzzyFind = $find.Substring(0, [Math]::Min(50, $find.Length))
    $fuzzyIdx = $content.IndexOf($fuzzyFind)
    if ($fuzzyIdx -ge 0) {
        $ctx = $content.Substring([Math]::Max(0,$fuzzyIdx-20), 100)
        Write-ColorOutput "  [??] $($patch.id) ($($patch.name)): Exact match not found!" "Yellow"
        Write-ColorOutput "       Fuzzy match near offset $fuzzyIdx. Context:" "Yellow"
        Write-ColorOutput "       ...$ctx..." "DarkGray"
        Write-ColorOutput "       Code may have changed (version update?). Manual check needed." "Red"
        $failedCount++
        continue
    }

    # Not found at all
    Write-ColorOutput "  [!!] $($patch.id) ($($patch.name)): NOT FOUND! ($($patch.offset_hint))" "Red"
    Write-ColorOutput "       Original code may have changed. Check target version." "DarkRed"
    $failedCount++
}

# Write result
if ($appliedCount -gt 0 -and -not $DryRun) {
    # === Syntax Safety Check: Verify JS syntax before writing ===
    $tmpFile = Join-Path ([System.IO.Path]::GetTempPath()) "trae-unlock-syntax-check-$([guid]::NewGuid().ToString('N')).js"
    [System.IO.File]::WriteAllText($tmpFile, $content)
    $syntaxCheck = node --check $tmpFile 2>&1
    $syntaxOk = ($LASTEXITCODE -eq 0)
    Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue

    if (-not $syntaxOk) {
        Write-ColorOutput "`n  [SYNTAX ERROR] JavaScript syntax check FAILED! Aborting write to prevent crash." "Red"
        Write-ColorOutput "  Error: $syntaxCheck" "Red"
        Write-ColorOutput "  Target file NOT modified. Original content preserved." "Yellow"
        exit 1
    }
    Write-ColorOutput "  [SYNTAX OK] JavaScript syntax verified." "Green"

    [System.IO.File]::WriteAllText($TargetFile, $content)
    Write-ColorOutput "`n  File written successfully." "Cyan"
}

# Summary
Write-ColorOutput "`n=========================================" "White"
Write-ColorOutput "  Applied:  $appliedCount" $(if($appliedCount -gt 0){"Green"}else{"Gray"})
Write-ColorOutput "  Skipped:  $skippedCount (already applied)" "Gray"
Write-ColorOutput "  Failed:   $failedCount" $(if($failedCount -gt 0){"Red"}else{"Gray"})
Write-ColorOutput "=========================================" "White"

if ($DryRun) { Write-ColorOutput "  [DRY RUN] No files were modified." "Yellow" }
else { Write-ColorOutput "  Restart Trae window to take effect." "Cyan" }

if ($failedCount -eq 0 -and -not $DryRun) {
    # === Auto-Backup: Create timestamped clean backup ===
    $backupDir = "d:\Test\trae-unlock\backups"
    if (!(Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFile = Join-Path $backupDir "clean-$timestamp.ext"
    Copy-Item $TargetFile $backupFile -Force
    $maxBackups = 5
    $existing = Get-ChildItem $backupDir -Filter "clean-*.ext" | Sort-Object LastWriteTime -Descending | Select-Object -Skip $maxBackups
    foreach ($old in $existing) { Remove-Item $old.FullName -Force }
    Write-Host "[BACKUP] Created: $(Split-Path $backupFile -Leaf) ($([math]::Round((Get-Item $TargetFile).Length/1MB), 1) MB)" -ForegroundColor Cyan

    # === Auto-Commit: Snapshot all changes ===
    Push-Location $RootDir
    $status = git status --porcelain 2>$null
    if ($status) {
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm"
        $total = $appliedCount + $skippedCount
        git add -A 2>$null
        git commit -m "chore: auto-snapshot [$ts] — $total patches OK" 2>$null
        $commitHash = git rev-parse --short HEAD 2>$null
        Write-Host "[COMMIT] $commitHash — $total patches, $(($status -split "`n").Count) files changed" -ForegroundColor Green
    } else {
        Write-Host "[COMMIT] No changes to commit." -ForegroundColor DarkGray
    }
    Pop-Location
}

exit $(if($failedCount -gt 0){1}else{0})
