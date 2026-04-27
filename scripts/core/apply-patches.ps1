<#
.SYNOPSIS
    Apply Trae Unlock patches to ai-modules-chat/dist/index.js
.DESCRIPTION
    Reads patch definitions from patches/definitions.json and applies them
    to the target file. Supports short anchor-based matching for improved stability.
    Auto-backups before modifying.
.EXAMPLE
    .\apply-patches.ps1
.EXAMPLE
    .\apply-patches.ps1 -DryRun
.EXAMPLE
    .\apply-patches.ps1 -PatchIds "auto-confirm-commands"
.EXAMPLE
    .\apply-patches.ps1 -UseLegacyMode  # Use old find_original matching
#>
param(
    [switch]$DryRun,
    [string]$PatchIds = "",
    [switch]$UseLegacyMode  # Fallback to old find_original matching
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

# Read definitions
Write-ColorOutput "[trae-unlock] Loading patch definitions..." "Cyan"
$defJson = [System.IO.File]::ReadAllText($DefPath)
$def = $defJson | ConvertFrom-Json
$TargetFile = $def.meta.target_file
$Patches = $def.patches
$FormatVersion = if ($def.meta.PSObject.Properties.Name -contains "format_version") { $def.meta.format_version } else { "1.0" }

Write-ColorOutput "  Target: $($def.meta.target_file_display)" "Gray"
Write-ColorOutput "  Patches defined: $($Patches.Count)" "Gray"
Write-ColorOutput "  Format version: $FormatVersion" "Gray"
if (-not $UseLegacyMode -and $FormatVersion -ge "2.0") {
    Write-ColorOutput "  Mode: Short anchor matching (v2.0+)" "Green"
} else {
    Write-ColorOutput "  Mode: Legacy find_original matching" "Yellow"
}

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

function Find-AnchorLocation {
    param(
        [string]$Content,
        [PSCustomObject]$Patch,
        [string]$Mode
    )
    
    $result = @{
        Found = $false
        Index = -1
        Method = ""
        Context = ""
    }
    
    # Try anchor-based matching first (v2.0+ mode)
    if ($Mode -ne "legacy" -and $Patch.PSObject.Properties.Name -contains "anchor") {
        $anchor = $Patch.anchor
        $anchorType = if ($Patch.PSObject.Properties.Name -contains "anchor_type") { $Patch.anchor_type } else { "exact" }
        
        # Method 1: Exact anchor match
        $idx = $Content.IndexOf($anchor)
        if ($idx -ge 0) {
            # Check if anchor appears multiple times
            $nextIdx = $Content.IndexOf($anchor, $idx + 1)
            if ($nextIdx -lt 0) {
                # Unique anchor found
                $result.Found = $true
                $result.Index = $idx
                $result.Method = "anchor-exact"
                return $result
            } else {
                # Multiple occurrences - use offset_hint to disambiguate
                $offsetHint = 0
                if ($Patch.offset_hint -match "~(\d+)") {
                    $offsetHint = [int]$Matches[1]
                }
                
                # Find the occurrence closest to offset_hint
                $closestIdx = $idx
                $minDiff = [Math]::Abs($idx - $offsetHint)
                $currentIdx = $nextIdx
                while ($currentIdx -ge 0) {
                    $diff = [Math]::Abs($currentIdx - $offsetHint)
                    if ($diff -lt $minDiff) {
                        $minDiff = $diff
                        $closestIdx = $currentIdx
                    }
                    $currentIdx = $Content.IndexOf($anchor, $currentIdx + 1)
                }
                
                $result.Found = $true
                $result.Index = $closestIdx
                $result.Method = "anchor-exact-offset"
                return $result
            }
        }
        
        # Method 2: Fuzzy anchor match (if exact fails)
        if ($anchorType -eq "fuzzy" -or $anchorType -eq "exact") {
            # Extract keywords from anchor (identifiers, strings)
            $keywords = @()
            # Match quoted strings
            $keywords += [regex]::Matches($anchor, '"([^"]{5,})"') | ForEach-Object { $_.Groups[1].Value }
            # Match identifiers (camelCase, snake_case)
            $keywords += [regex]::Matches($anchor, '[a-zA-Z_][a-zA-Z0-9_]{3,}') | ForEach-Object { $_.Value }
            
            if ($keywords.Count -gt 0) {
                # Use offset_hint to narrow search range
                $offsetHint = 0
                if ($Patch.offset_hint -match "~(\d+)") {
                    $offsetHint = [int]$Matches[1]
                }
                $searchStart = [Math]::Max(0, $offsetHint - 5000)
                $searchEnd = [Math]::Min($Content.Length, $offsetHint + 5000)
                $searchRegion = $Content.Substring($searchStart, $searchEnd - $searchStart)
                
                # Find location with most keyword matches
                $bestIdx = -1
                $bestScore = 0
                foreach ($kw in $keywords | Select-Object -Unique) {
                    $kwIdx = 0
                    while (($kwIdx = $searchRegion.IndexOf($kw, $kwIdx)) -ge 0) {
                        $score = $kw.Length  # Longer matches = higher score
                        if ($score -gt $bestScore) {
                            $bestScore = $score
                            $bestIdx = $searchStart + $kwIdx
                        }
                        $kwIdx++
                    }
                }
                
                if ($bestIdx -ge 0) {
                    $result.Found = $true
                    $result.Index = $bestIdx
                    $result.Method = "anchor-fuzzy"
                    return $result
                }
            }
        }
    }
    
    # Fallback: Legacy find_original matching
    if ($Patch.PSObject.Properties.Name -contains "find_original") {
        $find = $Patch.find_original
        
        # Try exact match
        $idx = $Content.IndexOf($find)
        if ($idx -ge 0) {
            $result.Found = $true
            $result.Index = $idx
            $result.Method = "legacy-exact"
            return $result
        }
        
        # Fuzzy search: try first 50 chars
        $fuzzyFind = $find.Substring(0, [Math]::Min(50, $find.Length))
        $fuzzyIdx = $Content.IndexOf($fuzzyFind)
        if ($fuzzyIdx -ge 0) {
            $result.Found = $true
            $result.Index = $fuzzyIdx
            $result.Method = "legacy-fuzzy"
            $result.Context = $Content.Substring([Math]::Max(0, $fuzzyIdx - 20), [Math]::Min(100, $Content.Length - $fuzzyIdx + 20))
            return $result
        }
    }
    
    return $result
}

foreach ($patch in $Patches) {
    if (-not $patch.enabled) {
        Write-ColorOutput "  [-] $($patch.id): DISABLED, skipping" "DarkGray"
        continue
    }

    # Use fingerprint for detection if available (avoids long-string encoding issues)
    $fingerprint = ""
    if ($patch.PSObject.Properties.Name -contains "check_fingerprint") {
        $fingerprint = $patch.check_fingerprint
    }
    $detectStr = if ($fingerprint) { $fingerprint } else { $patch.replace_with }

    # Check if already applied
    if ($content.Contains($detectStr)) {
        Write-ColorOutput "  [OK] $($patch.id) ($($patch.name)): Already applied" "Green"
        $skippedCount++
        continue
    }

    # Find patch location
    $mode = if ($UseLegacyMode) { "legacy" } else { "anchor" }
    $location = Find-AnchorLocation -Content $content -Patch $patch -Mode $mode
    
    if (-not $location.Found) {
        Write-ColorOutput "  [!!] $($patch.id) ($($patch.name)): NOT FOUND! ($($patch.offset_hint))" "Red"
        Write-ColorOutput "       Neither anchor nor find_original matched. Code may have changed." "DarkRed"
        $failedCount++
        continue
    }
    
    # Get the find/replace strings
    $find = ""
    $replace = $patch.replace_with
    
    if ($location.Method -eq "anchor-exact" -or $location.Method -eq "anchor-exact-offset") {
        # Use anchor-based replacement
        $anchor = $patch.anchor
        # Find the full find_original context around the anchor
        $contextStart = [Math]::Max(0, $location.Index - 100)
        $contextEnd = [Math]::Min($content.Length, $location.Index + $patch.find_original.Length + 100)
        $context = $content.Substring($contextStart, $contextEnd - $contextStart)
        
        # Verify the context contains the anchor
        if ($context.Contains($anchor)) {
            # Try to find exact find_original in context
            if ($context.Contains($patch.find_original)) {
                $find = $patch.find_original
            } else {
                # Use fuzzy matching within context
                $anchorIdx = $context.IndexOf($anchor)
                # Extract surrounding code to construct find string
                $findStart = $contextStart + $anchorIdx
                $find = $patch.find_original  # Fallback to original
            }
        } else {
            $find = $patch.find_original
        }
    } elseif ($location.Method -eq "anchor-fuzzy") {
        Write-ColorOutput "  [WARN] $($patch.id): Using fuzzy anchor match at offset $($location.Index)" "Yellow"
        $find = $patch.find_original
    } else {
        # Legacy mode
        $find = $patch.find_original
        if ($location.Method -eq "legacy-fuzzy") {
            Write-ColorOutput "  [WARN] $($patch.id): Using fuzzy legacy match" "Yellow"
            Write-ColorOutput "       Context: ...$($location.Context.Substring(20, 60))..." "DarkGray"
        }
    }
    
    # Apply the patch
    if ($content.Contains($find)) {
        if (-not $DryRun) {
            $content = $content.Replace($find, $replace)
            $methodStr = if ($location.Method.StartsWith("anchor")) { "anchor" } else { "legacy" }
            Write-ColorOutput "  [OK] $($patch.id) ($($patch.name)): Applied via $methodStr ($($patch.offset_hint))" "Green"
        } else {
            Write-ColorOutput "  [OK] $($patch.id) ($($patch.name)): Would apply via $($location.Method) ($($patch.offset_hint))" "DarkGreen"
        }
        $appliedCount++
    } else {
        Write-ColorOutput "  [!!] $($patch.id) ($($patch.name)): Location found but replacement failed" "Red"
        $failedCount++
    }
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
