param(
    [string]$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
)

$ErrorActionPreference = "SilentlyContinue"
$content = Get-Content $TargetFile -Raw -Encoding UTF8
$fs = $content.Length

function ShowContext($label, $offset, $len) {
    Write-Host ""
    Write-Host "=== $label @~$offset ===" -ForegroundColor Cyan
    $s = [Math]::Max(0, $offset)
    $e = [Math]::Min($fs, $s + $len)
    if ($s -lt $e) {
        $txt = $content.Substring($s, $e - $s) -replace "`r", ""
        foreach ($line in ($txt -split "`n")[0..30]) {
            Write-Host "  $line"
        }
    }
}

ShowContext "DRILL1: io (SendButton) component" 2877000 1000
ShowContext "DRILL2: io+iT render site" 2952800 800
ShowContext "DRILL3: isRunning/i_ source" 2951800 1500

Write-Host ""
Write-Host "=== DRILL4: iT (StopButton) definition ===" -ForegroundColor Cyan
$rx = [regex]::Matches($content, '(?:function|var|let|const)\s+iT\s*[\(=]', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
if ($rx.Count -gt 0) {
    foreach ($m in $rx) {
        $cs = [Math]::Max(0, $m.Index - 30)
        $ce = [Math]::Min($fs, $m.Index + 500)
        Write-Host ""
        Write-Host "  @ $($m.Index):"
        Write-Host "  $($content.Substring($cs, $ce - $cs).Substring(0, [Math]::Min(530, $ce - $cs)))"
    }
} else {
    Write-Host "  No 'iT' function/var found, searching for StopButton pattern..."
    $rx2 = [regex]::Matches($content, 'iT[,.\s}]|function\s+\w*\([^)]*onStop', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    Write-Host "  Found $($rx2.Count) loose references"
}

Write-Host ""
Write-Host "=== DRILL5: Io enum values ===" -ForegroundColor Cyan
$enumRx = [regex]::Matches($content, 'Io\.\w+\s*[=,)]', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$seen = @{}
foreach ($m in $enumRx) {
    $val = $m.Value.TrimEnd('=', ',', ')')
    if (-not $seen.ContainsKey($val)) {
        $seen[$val] = $true
        $cs = [Math]::Max(0, $m.Index - 20)
        $ce = [Math]::Min($fs, $m.Index + $m.Length + 10)
        Write-Host "  @ $($m.Index): $($content.Substring($cs, $ce - $cs))"
    }
}

Write-Host ""
Write-Host "=== DRILL6: setRunningStatusMap ALL calls ===" -ForegroundColor Cyan
$statusRx = [regex]::Matches($content, 'setRunningStatusMap\([^)]{10,80}\)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
foreach ($m in $statusRx) {
    Write-Host "  @ $($m.Index): $($m.Value)"
}

Write-Host ""
Write-Host "=== DRILL7: N(a,Io.Sending) status setter ===" -ForegroundColor Cyan
$sendRx = [regex]::Matches($content, 'N\(a,\s*Io\.\w+\)|setRunningStatus\([^)]{5,60}\)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
foreach ($m in $sendRx[0..15]) {
    $cs = [Math]::Max(0, $m.Index - 40)
    $ce = [Math]::Min($fs, $m.Index + $m.Length + 20)
    Write-Host "  @ $($m.Index): $($content.Substring($cs, $ce - $cs))"
}
