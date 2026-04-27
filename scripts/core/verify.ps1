<#
.SYNOPSIS
    Verify current patch status on target file
.DESCRIPTION
    Checks each patch definition against the actual file content.
    Uses check_fingerprint (short string) for reliable detection, falls back to replace_with.
.EXAMPLE
    .\verify.ps1
#>

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$DefPath = Join-Path $RootDir "patches\definitions.json"

$defJson = [System.IO.File]::ReadAllText($DefPath)
$def = $defJson | ConvertFrom-Json
$TargetFile = $def.meta.target_file

function Write-ColorOutput {
    param([string]$Msg, [string]$Color = "White")
    Write-Host $Msg -ForegroundColor $Color
}

Write-ColorOutput "[trae-unlock] Verifying patch status..." "Cyan"
Write-ColorOutput "  Target: $($def.meta.target_file_display)" "Gray"

if (-not [System.IO.File]::Exists($TargetFile)) {
    Write-ColorOutput "[ERROR] Target file not found!" "Red"
    exit 2
}

$content = [System.IO.File]::ReadAllText($TargetFile)
$activeCount = 0
$inactiveCount = 0
$unknownCount = 0
$failedIds = @()

foreach ($patch in $def.patches) {
    if (-not $patch.enabled) {
        Write-ColorOutput "  [--]       $($patch.id.PadRight(28)) $($patch.name) DISABLED" "DarkGray"
        continue
    }

    $fingerprint = ""
    if ($patch.PSObject.Properties.Name -contains "check_fingerprint") {
        $fingerprint = $patch.check_fingerprint
    }
    $checkStr = if ($fingerprint) { $fingerprint } else { $patch.replace_with }

    $hasOriginal = $content.Contains($patch.find_original)
    $hasPatched = $content.Contains($checkStr)

    if ($hasPatched) {
        Write-ColorOutput "  [ACTIVE]   $($patch.id.PadRight(28)) $($patch.name) ($($patch.offset_hint))" "Green"
        $activeCount++
    } elseif ($hasOriginal) {
        Write-ColorOutput "  [INACTIVE] $($patch.id.PadRight(28)) $($patch.name) ($($patch.offset_hint))" "DarkGray"
        $inactiveCount++
        $failedIds += $patch.id
    } else {
        Write-ColorOutput "  [UNKNOWN]  $($patch.id.PadRight(28)) $($patch.name) ($($patch.offset_hint)) - code may have changed!" "Yellow"
        $unknownCount++
        $failedIds += $patch.id
    }
}

Write-ColorOutput "`n-----------------------------------------" "White"
Write-ColorOutput "  Active: $activeCount | Inactive: $inactiveCount | Unknown: $unknownCount" "White"
Write-ColorOutput "-----------------------------------------" "White"

$failedJson = ($failedIds | ForEach-Object { "`"$_`"" }) -join ","
Write-Host "`n{`"active`":$activeCount,`"inactive`":$inactiveCount,`"unknown`":$unknownCount,`"failed_ids`":[$failedJson]}"
