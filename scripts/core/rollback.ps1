<#
.SYNOPSIS
    Rollback Trae Unlock patches by restoring from backup (v2)
.DESCRIPTION
    Restores index.mjs from a backup recorded in backups/manifest.json.
    Supports version selection by index, timestamp, or 'latest'.
    Falls back to scanning backups/ directory if manifest is missing.
.PARAMETER List
    List all available backups and exit
.PARAMETER Version
    Select backup: 'latest', timestamp string, or index number
.PARAMETER Force
    Skip confirmation prompt before rollback
.PARAMETER TargetPath
    Override target file path (default: from definitions.json)
.EXAMPLE
    .\rollback.ps1 -List
.EXAMPLE
    .\rollback.ps1 -Version latest
.EXAMPLE
    .\rollback.ps1 -Version 0 -Force
.EXAMPLE
    .\rollback.ps1 -Version 20260510-013000
#>

param(
    [switch]$List,
    [string]$Version = "",
    [switch]$Force,
    [string]$TargetPath = ""
)

$ErrorActionPreference = "Stop"

# ============================================================
# Key Path Constants
# ============================================================
# $PSScriptRoot = scripts/core, need two levels up to project root
$script:ProjectRoot     = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:DefinitionsPath = Join-Path $script:ProjectRoot "patches\definitions.json"
$script:BackupDir       = Join-Path $script:ProjectRoot "backups"
$script:ManifestPath    = Join-Path $script:BackupDir "manifest.json"

# ============================================================
# Function 1: Write-Log - Colored console output
# ============================================================
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")

    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [$Level] $Message"

    $colorMap = @{
        "INFO"    = "White"
        "SUCCESS" = "Green"
        "WARN"    = "Yellow"
        "ERROR"   = "Red"
        "DEBUG"   = "DarkGray"
    }
    $fg = if ($colorMap[$Level]) { $colorMap[$Level] } else { "White" }
    Write-Host $line -ForegroundColor $fg
}

# ============================================================
# Function 2: Resolve-TargetPath - Get target from defs or param
# ============================================================
function Resolve-TargetPath {
    if ($TargetPath) {
        return $TargetPath
    }

    if (-not (Test-Path $script:DefinitionsPath)) {
        throw "definitions.json not found and -TargetPath not specified"
    }

    try {
        $raw = [System.IO.File]::ReadAllText($script:DefinitionsPath)
        $def = $raw | ConvertFrom-Json
        return $def.meta.target_file
    }
    catch {
        throw "Failed to read target path from definitions.json: $($_.Exception.Message)"
    }
}

# ============================================================
# Function 3: Read-Manifest - Load manifest.json with fallback
# ============================================================
function Read-Manifest {
    $result = @{
        Entries = @()
        Source  = ""
    }

    # Try manifest.json first
    if (Test-Path $script:ManifestPath) {
        try {
            $raw = [System.IO.File]::ReadAllText($script:ManifestPath)
            $data = $raw | ConvertFrom-Json
            if ($data.entries) {
                $result.Entries = @($data.entries)
                $result.Source  = "manifest.json"
                return $result
            }
        }
        catch {
            Write-Log "Manifest corrupt: $($_.Exception.Message)" "WARN"
        }
    }

    # Fallback: scan backups/ directory for .backup and .mjs files
    if (Test-Path $script:BackupDir) {
        $files = @(Get-ChildItem $script:BackupDir -File |
                   Where-Object { $_.Extension -match '\.(backup|mjs|ext)$' } |
                   Sort-Object LastWriteTime -Descending)

        foreach ($f in $files) {
            $sizeMB = [Math]::Round($f.Length / 1MB, 2)
            $md5 = ""
            try { $md5 = (Get-FileHash -Path $f.FullName -Algorithm MD5).Hash.Substring(0, 8) } catch {}

            $result.Entries += @{
                timestamp      = $f.LastWriteTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                operation      = "scan-fallback"
                patches_applied = @("(unknown)")
                source_md5     = ""
                backup_md5     = $md5
                backup_path    = $f.FullName
                _sizeMB        = $sizeMB
                _fileName      = $f.Name
            }
        }

        if ($result.Entries.Count -gt 0) {
            $result.Source = "directory-scan"
            Write-Log "Manifest not found, scanned $($result.Entries.Count) backup files from backups/" "WARN"
        }
    }

    return $result
}

# ============================================================
# Function 4: Show-BackupList - Format and display backups
# ============================================================
function Show-BackupList {
    param([array]$Entries)

    $count = $Entries.Count

    Write-Host ""
    Write-Host ("=" * 63) -ForegroundColor Cyan
    Write-Host " Available Backups ($count total)" -ForegroundColor Cyan
    Write-Host ("=" * 63) -ForegroundColor Cyan

    # Header
    Write-Host " # | Timestamp                  | Size     | Patches           | MD5" -ForegroundColor White
    Write-Host ("-" * 63) -ForegroundColor DarkGray

    for ($i = 0; $i -lt $count; $i++) {
        $e = $Entries[$i]

        # Determine display fields based on source
        $ts = $e.timestamp
        if (-not $ts) {
            $ts = "(no timestamp)"
        }

        $sizeStr = if ($e._sizeMB) { "{0:N2} MB" -f $e._sizeMB } else { "N/A" }

        # Patches column
        $patchesArr = $e.patches_applied
        if ($patchesArr -and $patchesArr.Count -gt 0) {
            if ($patchesArr[0] -eq "(original)") {
                $patchStr = "(original)"
            }
            elseif ($patchesArr[0] -eq "(unknown)" -or $patchesArr[0] -eq "(all)") {
                $patchStr = $patchesArr[0]
            }
            elseif ($patchesArr.Count -le 2) {
                $patchStr = ($patchesArr -join ", ")
            }
            else {
                $patchStr = "all ($($patchesArr.Count) patches)"
            }
        }
        else {
            $patchStr = "-"
        }

        # MD5 short
        $md5Short = if ($e.backup_md5) { $e.backup_md5.Substring(0, [Math]::Min(8, $e.backup_md5.Length)) } else { "-" }

        $idxCol = "{0,-2}" -f $i
        $tsCol  = "{0,-26}" -f $ts
        $szCol  = "{0,-8}" -f $sizeStr
        $ptCol  = "{0,-17}" -f $patchStr

        Write-Host " $idxCol | $tsCol | $szCol | $ptCol | $md5Short" -ForegroundColor White
    }

    Write-Host ("-" * 63) -ForegroundColor DarkGray
    Write-Host ""
    Write-Log "Use: .\rollback.ps1 -Version <#|timestamp|latest>" "INFO"
    Write-Host ""
}

# ============================================================
# Function 5: Resolve-Version - Parse user input to entry
# ============================================================
function Resolve-Version {
    param(
        [string]$VersionInput,
        [array]$Entries
    )

    if ($Entries.Count -eq 0) {
        return $null
    }

    # 'latest' -> first entry (newest)
    if ($VersionInput -eq "latest") {
        return $Entries[0]
    }

    # Numeric index
    if ($VersionInput -match '^\d+$') {
        $idx = [int]$VersionInput
        if ($idx -ge 0 -and $idx -lt $Entries.Count) {
            return $Entries[$idx]
        }
        Write-Log "Index out of range: $idx (valid: 0-$($Entries.Count - 1))" "ERROR"
        return $null
    }

    # Timestamp fuzzy match
    $matched = @($Entries | Where-Object {
        $_.timestamp -and $_.timestamp.Contains($VersionInput)
    })

    if ($matched.Count -eq 1) {
        return $matched[0]
    }
    elseif ($matched.Count -gt 1) {
        Write-Log "Multiple matches for '$VersionInput', using first match" "WARN"
        return $matched[0]
    }

    # Also try matching against filename (for scan-fallback entries)
    $matched = @($Entries | Where-Object {
        $_._fileName -and $_._fileName.Contains($VersionInput)
    })

    if ($matched.Count -ge 1) {
        return $matched[0]
    }

    Write-Log "No backup matching: $VersionInput" "ERROR"
    return $null
}

# ============================================================
# Function 6: Test-FileIntegrity-Simple - Basic validation
# ============================================================
function Test-FileIntegrity-Simple {
    param([string]$FilePath)

    $result = @{ Pass = false; Issues = @(); Md5 = ""; SizeMB = 0 }

    if (-not (Test-Path $FilePath)) {
        $result.Issues += "File does not exist: $FilePath"
        return $result
    }

    $fi = Get-Item $FilePath
    $result.SizeMB = [Math]::Round($fi.Length / 1MB, 2)

    if ($fi.Length -eq 0) {
        $result.Issues += "File is empty (0 bytes)"
    }

    try {
        $result.Md5 = (Get-FileHash -Path $FilePath -Algorithm MD5).Hash
    }
    catch {
        $result.Issues += "MD5 computation failed: $($_.Exception.Message)"
    }

    $result.Pass = ($result.Issues.Count -eq 0)
    return $result
}

# ============================================================
# Function 7: Invoke-Rollback - Execute the rollback operation
# ============================================================
function Invoke-Rollback {
    param(
        [PSCustomObject]$Entry,
        [string]$TargetFilePath
    )

    $backupPath = $Entry.backup_path

    # Step 1: Verify backup exists
    if (-not (Test-Path $backupPath)) {
        Write-Log "Backup file not found: $backupPath" "ERROR"
        return $false
    }

    $backupFi = Get-Item $backupPath
    $backupSize = [Math]::Round($backupFi.Length / 1MB, 2)

    # Step 2: Show operation details
    Write-Host ""
    Write-Host ("-" * 50) -ForegroundColor Yellow
    Write-Log "ROLLBACK PREVIEW:" "WARN"
    Write-Log "  Source (backup): $backupPath" "INFO"
    Write-Log "  Backup size    : ${backupSize} MB" "INFO"
    Write-Log "  Target         : $TargetFilePath" "INFO"

    $tsDisplay = if ($Entry.timestamp) { $Entry.timestamp } else { "unknown" }
    Write-Log "  Backup time    : $tsDisplay" "INFO"

    $patchesInfo = $Entry.patches_applied
    if ($patchesInfo -and $patchesInfo.Count -gt 0) {
        $pStr = if ($patchesInfo.Count -le 3) { $patchesInfo -join ", " } else { "$($patchesInfo.Count) items" }
        Write-Log "  Patches at backup: $pStr" "INFO"
    }
    Write-Host ("-" * 50) -ForegroundColor Yellow

    # Step 3: Confirm unless -Force
    if (-not $Force) {
        Write-Host ""
        $confirm = Read-Host "Proceed with rollback? (Y/N)"
        if ($confirm -ne "Y" -and $confirm -ne "y") {
            Write-Log "Rollback cancelled by user." "WARN"
            return $false
        }
    }

    # Step 4: Check if target is locked (Trae running)
    $targetLocked = $false
    try {
        # Try to open file exclusively to check lock
        $stream = [System.IO.File]::Open($TargetFilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Close()
    }
    catch {
        $targetLocked = $true
    }

    if ($targetLocked) {
        Write-Log "" "ERROR"
        Write-Log "TARGET FILE IS LOCKED! Trae is likely still running." "ERROR"
        Write-Log "Please close Trae completely and retry." "ERROR"
        Write-Log "Tip: Check Task Manager for Trae processes." "WARN"
        return $false
    }

    # Step 5: Copy backup over target
    try {
        Copy-Item -Path $backupPath -Destination $TargetFilePath -Force
        Write-Log "File restored successfully." "SUCCESS"
    }
    catch {
        Write-Log "Copy failed: $($_.Exception.Message)" "ERROR"
        return $false
    }

    # Step 6: Integrity check on restored file
    Write-Log "Running integrity check on restored file..." "INFO"
    $integrity = Test-FileIntegrity-Simple -FilePath $TargetFilePath

    if ($integrity.Pass) {
        Write-Log "Integrity OK (MD5: $($integrity.Md5), Size: $($integrity.SizeMB)MB)" "SUCCESS"
    }
    else {
        Write-Log "Integrity warnings:" "WARN"
        foreach ($issue in $integrity.Issues) {
            Write-Log "  - $issue" "WARN"
        }
    }

    # Optional: compare MD5 with backup's recorded md5
    if ($Entry.backup_md5 -and $integrity.Md5) {
        $backupMd5Short = $Entry.backup_md5.Substring(0, [Math]::Min(32, $Entry.backup_md5.Length))
        if ($integrity.Md5.StartsWith($backupMd5Short)) {
            Write-Log "MD5 matches backup record." "SUCCESS"
        }
        else {
            Write-Log "MD5 differs from backup record (expected prefix: $backupMd5Short)" "WARN"
        }
    }

    return $true
}


# ============================================================
# MAIN WORKFLOW
# ============================================================

# --- Banner ---
Write-Host ""
Write-Host ("=" * 56) -ForegroundColor Cyan
Write-Host "  rollback v2  |  restore index.mjs from backup" -ForegroundColor Cyan
Write-Host ("=" * 56) -ForegroundColor Cyan
Write-Host ""

# --- Resolve target path ---
try {
    $resolvedTarget = Resolve-TargetPath
    Write-Log "Target : $resolvedTarget" "INFO"
}
catch {
    Write-Log $_.Exception.Message "ERROR"
    exit 2
}

# --- Load backup entries ---
$manifestData = Read-Manifest
$entries = $manifestData.Entries

if ($entries.Count -eq 0) {
    Write-Log "No backups found in: $($script:BackupDir)" "ERROR"
    Write-Log "Run apply-patches-v2.ps1 first to create backups." "WARN"
    exit 2
}

Write-Log "Source : $($manifestData.Source) ($($entries.Count) entries)" "INFO"

# --- Mode: -List ---
if ($List) {
    Show-BackupList -Entries $entries
    exit 0
}

# --- Mode: No version specified -> show help ---
if (-not $Version) {
    Show-BackupList -Entries $entries
    Write-Log "No -Version specified. Use one of:" "WARN"
    Write-Log "  -Version latest       Restore most recent backup" "INFO"
    Write-Log "  -Version <0-N>        Restore by index number" "INFO"
    Write-Log "  -Version <timestamp>  Restore by partial timestamp" "INFO"
    Write-Log "  -List                 Show this list again" "INFO"
    exit 0
}

# --- Mode: -Version specified ---
Write-Log "Resolving version: '$Version' ..." "INFO"
$selectedEntry = Resolve-Version -VersionInput $Version -Entries $entries

if (-not $selectedEntry) {
    Write-Log "Cannot resolve version '$Version'. Use -List to see available options." "ERROR"
    exit 2
}

# Execute rollback
$success = Invoke-Rollback -Entry $selectedEntry -TargetFilePath $resolvedTarget

if ($success) {
    Write-Host ""
    Write-Host ("=" * 56) -ForegroundColor Green
    Write-Log "ROLLBACK COMPLETE" "SUCCESS"
    Write-Log "Restart Trae window to take effect." "SUCCESS"
    Write-Log "To re-apply patches, run: .\apply-patches-v2.ps1 -All" "INFO"
    Write-Host ("=" * 56) -ForegroundColor Green
    exit 0
}
else {
    Write-Host ""
    Write-Log "ROLLBACK FAILED or CANCELLED." "ERROR"
    exit 1
}
