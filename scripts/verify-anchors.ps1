<#
.SYNOPSIS
    Verify patch anchors for uniqueness and existence in target file
.DESCRIPTION
    Validates that all patch anchors in definitions.json are:
    1. Unique (appear only once in target file)
    2. Exist (can be found in target file)
    3. Properly formatted (20-50 chars, stable identifiers)
.EXAMPLE
    .\verify-anchors.ps1
.EXAMPLE
    .\verify-anchors.ps1 -Detailed
#>
param(
    [switch]$Detailed,
    [switch]$CheckUniqueness
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$DefPath = Join-Path $RootDir "patches\definitions.json"

function Write-ColorOutput {
    param([string]$Msg, [string]$Color = "White")
    Write-Host $Msg -ForegroundColor $Color
}

# Read definitions
Write-ColorOutput "[trae-unlock] Loading patch definitions..." "Cyan"
$defJson = [System.IO.File]::ReadAllText($DefPath)
$def = $defJson | ConvertFrom-Json
$TargetFile = $def.meta.target_file
$Patches = $def.patches | Where-Object { $_.enabled -eq $true }

Write-ColorOutput "  Target: $($def.meta.target_file_display)" "Gray"
Write-ColorOutput "  Active patches: $($Patches.Count)" "Gray"

# Check target exists
if (-not [System.IO.File]::Exists($TargetFile)) {
    Write-ColorOutput "[ERROR] Target file not found: $TargetFile" "Red"
    exit 2
}

# Read target file
$content = [System.IO.File]::ReadAllText($TargetFile)
Write-ColorOutput "  Target file size: $([math]::Round($content.Length / 1MB, 2)) MB" "Gray"
Write-ColorOutput "" "White"

# Statistics
$stats = @{
    Total = $Patches.Count
    WithAnchor = 0
    AnchorFound = 0
    AnchorUnique = 0
    AnchorTooShort = 0
    AnchorTooLong = 0
    AnchorMissing = 0
}

$issues = @()
$anchorLocations = @{}  # Track anchor -> [locations] for uniqueness check

foreach ($patch in $Patches) {
    $hasAnchor = $patch.PSObject.Properties.Name -contains "anchor"
    
    if (-not $hasAnchor) {
        Write-ColorOutput "[$($patch.id)]" "Yellow"
        Write-ColorOutput "  Status: NO ANCHOR (legacy format)" "Yellow"
        if ($Detailed) {
            Write-ColorOutput "  Recommendation: Add anchor field for better stability" "DarkYellow"
        }
        Write-ColorOutput "" "White"
        continue
    }
    
    $stats.WithAnchor++
    $anchor = $patch.anchor
    $anchorLen = $anchor.Length
    
    # Check anchor length
    $lengthOk = $anchorLen -ge 20 -and $anchorLen -le 50
    if ($anchorLen -lt 20) { $stats.AnchorTooShort++ }
    if ($anchorLen -gt 50) { $stats.AnchorTooLong++ }
    
    # Find all occurrences
    $locations = @()
    $idx = 0
    while (($idx = $content.IndexOf($anchor, $idx)) -ge 0) {
        $locations += $idx
        $idx++
    }
    
    $found = $locations.Count -gt 0
    $unique = $locations.Count -eq 1
    
    if ($found) { $stats.AnchorFound++ }
    if ($unique) { $stats.AnchorUnique++ }
    if (-not $found) { $stats.AnchorMissing++ }
    
    # Store for cross-reference
    $anchorLocations[$patch.id] = $locations
    
    # Determine status color
    $statusColor = "Green"
    $status = "OK"
    if (-not $found) {
        $statusColor = "Red"
        $status = "NOT FOUND"
    } elseif (-not $unique) {
        $statusColor = "Yellow"
        $status = "DUPLICATE ($($locations.Count) occurrences)"
    } elseif (-not $lengthOk) {
        $statusColor = "Yellow"
        $status = "LENGTH ISSUE"
    }
    
    Write-ColorOutput "[$($patch.id)]" $(if($statusColor -eq "Green"){"Green"}else{"Yellow"})
    Write-ColorOutput "  Anchor: $($anchor.Substring(0, [Math]::Min(60, $anchorLen)))$(if($anchorLen -gt 60){'...'})" "Gray"
    Write-ColorOutput "  Length: $anchorLen chars $(if(-not $lengthOk){'(recommended: 20-50)'})" $(if($lengthOk){"Gray"}else{"Yellow"})
    Write-ColorOutput "  Status: $status" $statusColor
    
    if ($Detailed -or $statusColor -ne "Green") {
        if ($found) {
            $firstLoc = $locations[0]
            Write-ColorOutput "  Location: offset ~$firstLoc" "Gray"
            
            if ($locations.Count -gt 1) {
                Write-ColorOutput "  All locations: $($locations -join ', ')" "Yellow"
                
                # Check if offset_hint helps disambiguate
                if ($patch.offset_hint -match "~(\d+)") {
                    $hintOffset = [int]$Matches[1]
                    $closestLoc = $locations | Sort-Object { [Math]::Abs($_ - $hintOffset) } | Select-Object -First 1
                    $closestDist = [Math]::Abs($closestLoc - $hintOffset)
                    Write-ColorOutput "  Offset hint: ~$hintOffset, closest match: $closestLoc (distance: $closestDist)" $(if($closestDist -lt 1000){"Green"}else{"Yellow"})
                }
            }
            
            # Show context
            $ctxStart = [Math]::Max(0, $firstLoc - 30)
            $ctxLen = [Math]::Min(100, $content.Length - $ctxStart)
            $context = $content.Substring($ctxStart, $ctxLen)
            $context = $context -replace "`r?`n", " "
            Write-ColorOutput "  Context: ...$context..." "DarkGray"
        } else {
            # Anchor not found - try to help
            Write-ColorOutput "  [ERROR] Anchor not found in target file!" "Red"
            
            # Try to find similar strings
            $keywords = @()
            $keywords += [regex]::Matches($anchor, '"([^"]{5,})"') | ForEach-Object { $_.Groups[1].Value }
            $keywords += [regex]::Matches($anchor, '[a-zA-Z_][a-zA-Z0-9_]{5,}') | ForEach-Object { $_.Value }
            
            if ($keywords.Count -gt 0) {
                Write-ColorOutput "  Searching for similar keywords: $($keywords -join ', ')" "Yellow"
                foreach ($kw in $keywords | Select-Object -First 3) {
                    $kwIdx = $content.IndexOf($kw)
                    if ($kwIdx -ge 0) {
                        Write-ColorOutput "    Found '$kw' at offset $kwIdx" "Green"
                    } else {
                        Write-ColorOutput "    Keyword '$kw' not found" "Red"
                    }
                }
            }
        }
        
        if ($patch.PSObject.Properties.Name -contains "anchor_reason") {
            Write-ColorOutput "  Reason: $($patch.anchor_reason)" "DarkGray"
        }
    }
    
    Write-ColorOutput "" "White"
}

# Cross-reference check for duplicate anchors
if ($CheckUniqueness) {
    Write-ColorOutput "[Cross-Reference Check]" "Cyan"
    $duplicateAnchors = $anchorLocations.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
    if ($duplicateAnchors) {
        Write-ColorOutput "  WARNING: Found anchors with multiple occurrences:" "Yellow"
        foreach ($dup in $duplicateAnchors) {
            Write-ColorOutput "    - $($dup.Key): $($dup.Value.Count) occurrences" "Yellow"
        }
    } else {
        Write-ColorOutput "  All anchors are unique" "Green"
    }
    Write-ColorOutput "" "White"
}

# Summary
Write-ColorOutput "=========================================" "White"
Write-ColorOutput "  ANCHOR VERIFICATION SUMMARY" "White"
Write-ColorOutput "=========================================" "White"
Write-ColorOutput "  Total active patches:     $($stats.Total)" "Gray"
Write-ColorOutput "  Patches with anchors:     $($stats.WithAnchor)" $(if($stats.WithAnchor -eq $stats.Total){"Green"}else{"Yellow"})
Write-ColorOutput "  Anchors found:            $($stats.AnchorFound)" $(if($stats.AnchorFound -eq $stats.WithAnchor){"Green"}else{"Yellow"})
Write-ColorOutput "  Anchors unique:           $($stats.AnchorUnique)" $(if($stats.AnchorUnique -eq $stats.WithAnchor){"Green"}else{"Yellow"})
if ($stats.AnchorTooShort -gt 0) {
    Write-ColorOutput "  Anchors too short (<20):  $($stats.AnchorTooShort)" "Yellow"
}
if ($stats.AnchorTooLong -gt 0) {
    Write-ColorOutput "  Anchors too long (>50):   $($stats.AnchorTooLong)" "Yellow"
}
if ($stats.AnchorMissing -gt 0) {
    Write-ColorOutput "  Anchors not found:        $($stats.AnchorMissing)" "Red"
}
Write-ColorOutput "=========================================" "White"

# Recommendations
if ($stats.AnchorMissing -gt 0 -or $stats.WithAnchor -lt $stats.Total) {
    Write-ColorOutput "`nRECOMMENDATIONS:" "Cyan"
    if ($stats.WithAnchor -lt $stats.Total) {
        Write-ColorOutput "  - Add 'anchor' field to legacy patches for better stability" "Yellow"
    }
    if ($stats.AnchorMissing -gt 0) {
        Write-ColorOutput "  - Update missing anchors to match current Trae version" "Yellow"
        Write-ColorOutput "  - Run: .\scripts\apply-patches.ps1 -DryRun to test" "Gray"
    }
    if ($stats.AnchorUnique -lt $stats.WithAnchor) {
        Write-ColorOutput "  - Use -Detailed flag to see duplicate anchor locations" "Gray"
        Write-ColorOutput "  - Consider using offset_hint to disambiguate" "Gray"
    }
}

# Exit code
$exitCode = 0
if ($stats.AnchorMissing -gt 0) { $exitCode = 2 }
elseif ($stats.AnchorUnique -lt $stats.WithAnchor) { $exitCode = 1 }

exit $exitCode
