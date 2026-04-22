<#
.SYNOPSIS
    4-step self-healing loop for Trae mod patches
.DESCRIPTION
    Step 1: Verify patch fingerprints against target file
    Step 2: Diagnose failures (offset drift vs code change)
    Step 3: Auto-fix offset-drift patches by re-applying find_original→replace_with
    Step 4: Re-verify all patches and report final status
.EXAMPLE
    .\auto-heal.ps1
    Full heal: verify → diagnose → fix → re-verify
.EXAMPLE
    .\auto-heal.ps1 -DiagnoseOnly
    Only Step 1+2, no file modifications
.EXAMPLE
    .\auto-heal.ps1 -SkipDefUpdate
    Fix target file but don't update definitions.json
#>
param(
    [switch]$DiagnoseOnly,
    [switch]$SkipDefUpdate
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

$defJson = [System.IO.File]::ReadAllText($DefPath)
$def = $defJson | ConvertFrom-Json
$TargetFile = $def.meta.target_file

Write-ColorOutput "[auto-heal] Step 1: Verify patch fingerprints..." "Cyan"
Write-ColorOutput "  Target: $($def.meta.target_file_display)" "Gray"

if (-not [System.IO.File]::Exists($TargetFile)) {
    Write-ColorOutput "[ERROR] Target file not found: $TargetFile" "Red"
    exit 2
}

$content = [System.IO.File]::ReadAllText($TargetFile)

$verifyResults = @()

foreach ($patch in $def.patches) {
    if (-not $patch.enabled) {
        continue
    }

    $fingerprint = ""
    if ($patch.PSObject.Properties.Name -contains "check_fingerprint") {
        $fingerprint = $patch.check_fingerprint
    }
    $checkStr = if ($fingerprint) { $fingerprint } else { $patch.replace_with }

    $found = $content.Contains($checkStr)
    $offsetHint = $patch.offset_hint
    $numericHint = $offsetHint -replace '^~', ''
    $approxOffset = if ([long]::TryParse($numericHint, [ref]$null)) { [long]$numericHint } else { 0 }

    $verifyResults += [PSCustomObject]@{
        Patch      = $patch
        Status     = if ($found) { "PASS" } else { "FAIL" }
        CheckStr   = $checkStr
        OffsetHint = $approxOffset
    }

    if ($found) {
        Write-ColorOutput "  [PASS] $($patch.id)" "Green"
    } else {
        Write-ColorOutput "  [FAIL] $($patch.id)" "Red"
    }
}

$failResults = @($verifyResults | Where-Object { $_.Status -eq "FAIL" })

if ($failResults.Count -eq 0) {
    Write-ColorOutput "`n[auto-heal] All patches PASS. Nothing to heal." "Green"
    exit 0
}

Write-ColorOutput "`n[auto-heal] Step 2: Diagnose $($failResults.Count) failing patch(es)..." "Cyan"

$diagnoses = @()

foreach ($fr in $failResults) {
    $patch = $fr.Patch
    $findOriginal = $patch.find_original
    $fuzzyLen = [Math]::Min(30, $findOriginal.Length)
    $fuzzySearch = $findOriginal.Substring(0, $fuzzyLen)

    $findIdx = $content.IndexOf($findOriginal)
    $fuzzyIdx = $content.IndexOf($fuzzySearch)

    $action = "MANUAL-NEEDED"
    if ($findIdx -ge 0) {
        $action = "AUTO-FIX"
    } elseif ($fuzzyIdx -ge 0) {
        $action = "AUTO-FIX"
    }

    $diag = [PSCustomObject]@{
        Patch       = $patch
        FindIdx     = $findIdx
        FuzzyIdx    = $fuzzyIdx
        FuzzySearch = $fuzzySearch
        Action      = $action
    }
    $diagnoses += $diag

    Write-ColorOutput "[DIAGNOSE] $($patch.id) ($($patch.name))" "Yellow"
    Write-ColorOutput "  Expected offset: ~$($fr.OffsetHint)" "Gray"
    Write-ColorOutput "  Fingerprint: NOT FOUND" "Red"
    Write-ColorOutput "  find_original: $(if($findIdx -ge 0){"FOUND at $findIdx"}else{"NOT FOUND"})" $(if($findIdx -ge 0){"Green"}else{"Red"})
    Write-ColorOutput "  Fuzzy search: $(if($fuzzyIdx -ge 0){"FOUND at $fuzzyIdx"}else{"NOT FOUND"})" $(if($fuzzyIdx -ge 0){"Yellow"}else{"Red"})

    if ($fuzzyIdx -ge 0) {
        $ctxStart = [Math]::Max(0, $fuzzyIdx - 25)
        $ctxLen = [Math]::Min(50, $content.Length - $ctxStart)
        $ctx = $content.Substring($ctxStart, $ctxLen) -replace '[\r\n]', ' '
        Write-ColorOutput "  Context: ...$ctx..." "DarkGray"
    }

    $actionColor = if ($action -eq "AUTO-FIX") { "Green" } else { "Red" }
    Write-ColorOutput "  Action: $action" $actionColor
}

if ($DiagnoseOnly) {
    Write-ColorOutput "`n[auto-heal] -DiagnoseOnly mode. No modifications made." "Yellow"
    $manualCount = @($diagnoses | Where-Object { $_.Action -eq "MANUAL-NEEDED" }).Count
    exit $(if ($manualCount -gt 0) { 1 } else { 0 })
}

Write-ColorOutput "`n[auto-heal] Step 3: Fix..." "Cyan"

if (-not [System.IO.Directory]::Exists($BackupDir)) {
    [System.IO.Directory]::CreateDirectory($BackupDir) | Out-Null
}

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BaseName = [System.IO.Path]::GetFileName($TargetFile)
$BackupFile = Join-Path $BackupDir "$BaseName.$Timestamp.backup"

$needsWrite = $false
$fixedCount = 0
$manualCount = 0
$defModified = $false

foreach ($diag in $diagnoses) {
    $patch = $diag.Patch

    if ($diag.Action -eq "MANUAL-NEEDED") {
        Write-ColorOutput "  [SKIP] $($patch.id): MANUAL-NEEDED — cannot auto-fix" "Red"
        $manualCount++
        continue
    }

    $findOriginal = $patch.find_original
    $replaceWith = $patch.replace_with
    $fingerprint = ""
    if ($patch.PSObject.Properties.Name -contains "check_fingerprint") {
        $fingerprint = $patch.check_fingerprint
    }

    if ($diag.FindIdx -ge 0) {
        if (-not $needsWrite) {
            [System.IO.File]::Copy($TargetFile, $BackupFile, $true)
            Write-ColorOutput "  Backup: $([System.IO.Path]::GetFileName($BackupFile))" "Green"
            $needsWrite = $true
        }
        $content = $content.Replace($findOriginal, $replaceWith)
        Write-ColorOutput "  [FIX] $($patch.id): Replaced find_original at offset $($diag.FindIdx)" "Green"
    } elseif ($diag.FuzzyIdx -ge 0) {
        $fuzzySearch = $diag.FuzzySearch
        $fuzzyMatchEnd = $diag.FuzzyIdx + $fuzzySearch.Length
        $remainingAfterFuzzy = $content.Substring($fuzzyMatchEnd)
        $fullFindInRemaining = $remainingAfterFuzzy.IndexOf($findOriginal.Substring($fuzzyLen))
        if ($fullFindInRemaining -ge 0) {
            $actualFindStart = $diag.FuzzyIdx
            $actualFindEnd = $fuzzyMatchEnd + $fullFindInRemaining + $findOriginal.Substring($fuzzyLen).Length
            $actualFindStr = $content.Substring($actualFindStart, $actualFindEnd - $actualFindStart)
            if (-not $needsWrite) {
                [System.IO.File]::Copy($TargetFile, $BackupFile, $true)
                Write-ColorOutput "  Backup: $([System.IO.Path]::GetFileName($BackupFile))" "Green"
                $needsWrite = $true
            }
            $content = $content.Replace($actualFindStr, $replaceWith)
            Write-ColorOutput "  [FIX] $($patch.id): Replaced via fuzzy-guided match at offset $actualFindStart" "Yellow"
        } else {
            Write-ColorOutput "  [SKIP] $($patch.id): Fuzzy match found but full pattern diverged — MANUAL-NEEDED" "Red"
            $manualCount++
            continue
        }
    }

    $fixedCount++

    if (-not $SkipDefUpdate) {
        $checkStr = if ($fingerprint) { $fingerprint } else { $replaceWith }
        $newOffset = $content.IndexOf($checkStr)
        if ($newOffset -ge 0) {
            $newHint = "~$newOffset"
            $oldHint = $patch.offset_hint
            if ($oldHint -ne $newHint) {
                $pattern = '"' + $patch.id + '"'
                $idPos = $defJson.IndexOf($pattern)
                if ($idPos -ge 0) {
                    $hintKey = '"offset_hint"'
                    $searchFrom = $idPos
                    $hintPos = $defJson.IndexOf($hintKey, $searchFrom)
                    if ($hintPos -ge 0 -and $hintPos -lt $idPos + 500) {
                        $oldValPattern = '"offset_hint":\s*"' + [regex]::Escape($oldHint) + '"'
                        $newValPattern = "`"offset_hint`": `"$newHint`""
                        $defJson = $defJson -replace $oldValPattern, $newValPattern
                        $defModified = $true
                        Write-ColorOutput "  [DEF] $($patch.id): offset_hint $oldHint → $newHint" "Cyan"
                    }
                }
            }
        }
    }
}

if ($needsWrite) {
    $tmpFile = Join-Path ([System.IO.Path]::GetTempPath()) "trae-unlock-syntax-check-$([guid]::NewGuid().ToString('N')).js"
    [System.IO.File]::WriteAllText($tmpFile, $content)
    $syntaxCheck = node --check $tmpFile 2>&1
    $syntaxOk = ($LASTEXITCODE -eq 0)
    Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue

    if (-not $syntaxOk) {
        Write-ColorOutput "`n  [SYNTAX ERROR] JavaScript syntax check FAILED! Aborting write to prevent crash." "Red"
        Write-ColorOutput "  Error: $syntaxCheck" "Red"
        Write-ColorOutput "  Target file NOT modified. Original content preserved." "Yellow"
        $latestBackup = Get-ChildItem $BackupDir -Filter "clean-*.ext" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestBackup) {
            Copy-Item $latestBackup.FullName $TargetFile -Force
            Write-ColorOutput "  Restored from backup: $($latestBackup.Name)" "Yellow"
        }
        exit 1
    }
    Write-ColorOutput "  [SYNTAX OK] JavaScript syntax verified." "Green"

    [System.IO.File]::WriteAllText($TargetFile, $content)
    Write-ColorOutput "  Target file written." "Cyan"
}

if ($defModified -and -not $SkipDefUpdate) {
    [System.IO.File]::WriteAllText($DefPath, $defJson)
    Write-ColorOutput "  definitions.json updated." "Cyan"
}

Write-ColorOutput "`n[auto-heal] Step 4: Re-verify..." "Cyan"

$content = [System.IO.File]::ReadAllText($TargetFile)
$allPass = $true
$passCount = 0
$stillFailCount = 0

foreach ($patch in $def.patches) {
    if (-not $patch.enabled) {
        continue
    }

    $fingerprint = ""
    if ($patch.PSObject.Properties.Name -contains "check_fingerprint") {
        $fingerprint = $patch.check_fingerprint
    }
    $checkStr = if ($fingerprint) { $fingerprint } else { $patch.replace_with }

    if ($content.Contains($checkStr)) {
        Write-ColorOutput "  [PASS] $($patch.id)" "Green"
        $passCount++
    } else {
        Write-ColorOutput "  [FAIL] $($patch.id)" "Red"
        $stillFailCount++
        $allPass = $false
    }
}

Write-ColorOutput "`n=========================================" "White"
Write-ColorOutput "  Fixed:       $fixedCount" $(if($fixedCount -gt 0){"Green"}else{"Gray"})
Write-ColorOutput "  Manual:      $manualCount" $(if($manualCount -gt 0){"Red"}else{"Gray"})
Write-ColorOutput "  Pass now:    $passCount" "Green"
Write-ColorOutput "  Still fail:  $stillFailCount" $(if($stillFailCount -gt 0){"Red"}else{"Gray"})
Write-ColorOutput "=========================================" "White"

if ($DiagnoseOnly) {
    Write-ColorOutput "  [DIAGNOSE ONLY] No files were modified." "Yellow"
} elseif ($needsWrite) {
    Write-ColorOutput "  Restart Trae window to take effect." "Cyan"
}

if ($allPass -and $needsWrite) {
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
        git add -A 2>$null
        git commit -m "chore: auto-snapshot [$ts] — healed $fixedCount patches, $passCount pass" 2>$null
        $commitHash = git rev-parse --short HEAD 2>$null
        Write-Host "[COMMIT] $commitHash — healed $fixedCount, $(($status -split "`n").Count) files changed" -ForegroundColor Green
    } else {
        Write-Host "[COMMIT] No changes to commit." -ForegroundColor DarkGray
    }
    Pop-Location
}

exit $(if ($allPass) { 0 } else { 1 })
