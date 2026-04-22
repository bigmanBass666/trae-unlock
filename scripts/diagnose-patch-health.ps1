<#
.SYNOPSIS
    Diagnose Trae target file health — syntax, fingerprints, residuals, size, backups
.DESCRIPTION
    Runs 5 health checks on the patched target file and produces a structured report.
    Use this when chat UI disappears or patches seem broken.
.EXAMPLE
    .\diagnose-patch-health.ps1
#>

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
$defJson = [System.IO.File]::ReadAllText($DefPath)
$def = $defJson | ConvertFrom-Json
$TargetFile = $def.meta.target_file

Write-ColorOutput "`n=========================================" "Cyan"
Write-ColorOutput "  🏥 Trae Unlock — Patch Health Diagnosis" "Cyan"
Write-ColorOutput "=========================================`n" "Cyan"

# Check 1: Target file exists?
Write-ColorOutput "📋 CHECK 1: Target File Existence" "White"
if (-not [System.IO.File]::Exists($TargetFile)) {
    Write-ColorOutput "   ❌ FILE NOT FOUND: $TargetFile" "Red"
    Write-ColorOutput "   → Trae may not be installed or path changed" "Yellow"
    exit 2
}
$fileSizeMB = [math]::Round((Get-Item $TargetFile).Length / 1MB, 2)
Write-ColorOutput "   ✅ Found: $($def.meta.target_file_display)" "Green"
Write-ColorOutput "   📦 Size: $fileSizeMB MB (expected ~10.73)" $(if($fileSizeMB -gt 8 -and $fileSizeMB -lt 15){"Green"}else{"Yellow"})

# Check 2: JavaScript Syntax
Write-ColorOutput "`n📋 CHECK 2: JavaScript Syntax" "White"
$syntaxOutput = node --check $TargetFile 2>&1
$syntaxOk = ($LASTEXITCODE -eq 0)
if ($syntaxOk) {
    Write-ColorOutput "   ✅ Syntax VALID" "Green"
} else {
    Write-ColorOutput "   ❌ SYNTAX ERROR!" "Red"
    Write-ColorOutput "   $syntaxOutput" "Red"
}

# Check 3: Patch Fingerprints
Write-ColorOutput "`n📋 CHECK 3: Patch Fingerprints ($(($def.patches | Where-Object { $_.enabled }).Count) enabled)" "White"
$content = [System.IO.File]::ReadAllText($TargetFile)
$passCount = 0
$failCount = 0
$residualCount = 0

foreach ($patch in $def.patches) {
    if (-not $patch.enabled) { continue }

    $fingerprint = ""
    if ($patch.PSObject.Properties.Name -contains "check_fingerprint") {
        $fingerprint = $patch.check_fingerprint
    }
    $checkStr = if ($fingerprint) { $fingerprint } else { $patch.replace_with }

    $fpFound = $content.Contains($checkStr)
    $findFound = $content.Contains($patch.find_original)

    if ($fpFound) {
        Write-ColorOutput "   ✅ [$($patch.id)] PASS" "Green"
        $passCount++
    } elseif ($findFound) {
        Write-ColorOutput "   ⚠️  [$($patch.id)] RESIDUAL (find_original exists but patch not applied)" "Yellow"
        $residualCount++
        $failCount++
    } else {
        Write-ColorOutput "   ❌ [$($patch.id)] FAIL (not found at all)" "Red"
        $failCount++
    }
}

# Check 4: Version Consistency
Write-ColorOutput "`n📋 CHECK 4: Definition Consistency" "White"
$consistencyIssues = 0
foreach ($patch in $def.patches) {
    if (-not $patch.enabled) { continue }
    $fingerprint = ""
    if ($patch.PSObject.Properties.Name -contains "check_fingerprint") {
        $fingerprint = $patch.check_fingerprint
    }
    if ($fingerprint -and -not $patch.replace_with.Contains($fingerprint)) {
        Write-ColorOutput "   ⚠️  [$($patch.id)] fingerprint not in replace_with!" "Yellow"
        $consistencyIssues++
    }
}
if ($consistencyIssues -eq 0) {
    Write-ColorOutput "   ✅ All fingerprints consistent with replace_with" "Green"
}

# Check 5: Backups
Write-ColorOutput "`n📋 CHECK 5: Available Backups" "White"
if (-not [System.IO.Directory]::Exists($BackupDir)) {
    Write-ColorOutput "   ⚠️  backups/ directory does not exist" "Yellow"
} else {
    $backups = Get-ChildItem $BackupDir -Filter "*.ext" | Sort-Object LastWriteTime -Descending
    if ($backups.Count -eq 0) {
        Write-ColorOutput "   ❌ No backups found! CRITICAL RISK" "Red"
    } else {
        foreach ($b in $backups) {
            $age = ((Get-Date) - $b.LastWriteTime)
            $ageStr = if ($age.Days -gt 0) { "$($age.Day)d ago" } elseif ($age.Hours -gt 0) { "$($age.Hours)h ago" } else { "$($age.Minutes)m ago" }
            $sizeMB = [math]::Round($b.Length / 1MB, 1)
            Write-ColorOutput "   📦 $($b.Name) ($sizeMB MB, $ageStr)" "Gray"
        }
        Write-ColorOutput "   ✅ $($backups.Count) backup(s) available" "Green"
    }
}

# Summary
Write-ColorOutput "`n=========================================" "White"
$totalScore = ($passCount * 10) - ($failCount * 20) - ($residualCount * 10) - (if(-not $syntaxOk){50}else{0}) - ($consistencyIssues * 15)
$healthStatus = if ($totalScore -ge 70) { "HEALTHY" } elseif ($totalScore -ge 30) { "DEGRADED" } else { "CRITICAL" }
$statusColor = if ($healthStatus -eq "HEALTHY") { "Green" } elseif ($healthStatus -eq "DEGRADED") { "Yellow" } else { "Red" }

Write-ColorOutput "  Score: $totalScore/100  Status: $healthStatus" $statusColor
Write-ColorOutput "  Patches: $passCount pass, $failCount fail, $residualCount residual" $(if($failCount -gt 0){"Red"}else{"Green"})
Write-ColorOutput "  Syntax: $(if($syntaxOk){'OK'}else{'FAILED'})" $(if($syntaxOk){'Green'}else{'Red'})
Write-ColorOutput "  Consistency: $(if($consistencyIssues -eq 0){'OK'}else{"$consistencyIssues issues"})" $(if($consistencyIssues -eq 0){'Green'}else{'Yellow'})
Write-ColorOutput "=========================================" "White"

if ($healthStatus -eq "CRITICAL") {
    Write-ColorOutput "`n⚠️  Recommendation: Restore from latest clean backup immediately!" "Red"
    Write-ColorOutput "   Run: .\scripts\auto-heal.ps1  (will attempt auto-fix)" "Yellow"
    Write-ColorOutput "   Or manually: copy backups\clean-latest.ext → target file" "Yellow"
} elseif ($healthStatus -eq "DEGRADED") {
    Write-ColorOutput "`n💡 Recommendation: Run .\scripts\apply-patches.ps1 to re-apply missing patches" "Yellow"
}
