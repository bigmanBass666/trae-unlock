param(
    [string]$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
)

$ErrorActionPreference = "SilentlyContinue"
$content = Get-Content $TargetFile -Raw -Encoding UTF8
$fs = $content.Length

function ShowCtx($label, $offset, $len) {
    Write-Host ""
    Write-Host "=== $label @~$offset ===" -ForegroundColor Cyan
    $s = [Math]::Max(0, $offset)
    $e = [Math]::Min($fs, $s + $len)
    if ($s -lt $e) {
        $txt = ($content.Substring($s, [Math]::Min($len, $e - $s)) -replace "`r", "")
        foreach ($line in ($txt -split "`n")[0..40]) { Write-Host "  $line" }
    }
}

Write-Host "=== DRILL A: FULL io component (SendButton) ===" -ForegroundColor Green
ShowCtx "io function body" 2877146 3000

Write-Host ""
Write-Host "=== DRILL B: isRunning/i_ derivation (where does i_ come from?) ===" -ForegroundColor Green
ShowCtx "i_ source area" 2949000 4000

Write-Host ""
Write-Host "=== DRILL C: Search for icon/pause/stop INSIDE input button area (~2.87M-2.96M) ===" -ForegroundColor Green
$inputArea = $content.Substring(2870000, [Math]::Min(100000, $fs - 2870000))
$cPatterns = @(
    @{Label="C1: pause/stop icon in input"; Pattern="(?i)(pause|stop).{0,60}(icon|svg|codicon|img|button)"},
    @{Label="C2: send arrow icon in input"; Pattern="(?i)(send|arrow|paper-plane).{0,40}(icon|svg|codicon)"},
    @{Label="C3: Codicon name with send/pause"; Pattern="(?i)Codicon.*name.{0,20}(send|pause|stop|arrow)"},
    @{Label="C4: isRunning conditional render in io"; Pattern="(?i)(isRunning|t\?).{0,80}(return|createElement|Fragment|\?)"}
)

foreach ($cp in $cPatterns) {
    $cm = [regex]::Matches($inputArea, $cp.Pattern)
    Write-Host ""
    Write-Host "  $($cp.Label): $($cm.Count) matches"
    for ($k = 0; $k -lt [Math]::Min($cm.Count, 5); $k++) {
        $mk = $cm[$k]
        $absOff = 2870000 + $mk.Index
        $cs2 = [Math]::Max(0, $mk.Index - 80)
        $ce2 = [Math]::Min($inputArea.Length, $mk.Index + $mk.Length + 80)
        Write-Host "    [$k] @$absOff : $($inputArea.Substring($cs2, $ce2 - $cs2).Replace("`n"," ").Replace("  "," "))"
    }
}

Write-Host ""
Write-Host "=== DRILL D: Io enum definition ===" -ForegroundColor Green
$ioEnumRx = [regex]::Matches($content, 'Io\s*=\s*\{[^}]{200,2000}\}', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
if ($ioEnumRx.Count -gt 0) {
    $m0 = $ioEnumRx[0]
    ShowCtx "Io enum definition" $m0.Index ([Math]::Min(1500, $m0.Value.Length))
} else {
    Write-Host "  Trying broader pattern..."
    $ioEnumRx2 = [regex]::Matches($content, '(?:WaitingInput|Running|Sending)\s*=\s*"[^"]*"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($m in $ioEnumRx2[0..10]) {
        $cs3 = [Math]::Max(0, $m.Index - 100)
        $ce3 = [Math]::Min($fs, $m.Index + 200)
        Write-Host "  @ $($m.Index): $($content.Substring($cs3, $ce3 - $cs3))"
    }
}

Write-Host ""
Write-Host "=== DRILL E: N() status setter function definition ===" -ForegroundColor Green
$nRx = [regex]::Matches($content, '(?:function|const|let|var)\s+N\s*[\(=]', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
foreach ($nm in $nRx[0..5]) {
    $cs4 = [Math]::Max(0, $nm.Index - 10)
    $ce4 = [Math]::Min($fs, $nm.Index + 500)
    Write-Host "  @ $($nm.Index): $($content.Substring($cs4, $ce4 - $cs4).Substring(0,[Math]::Min(510,$ce4-$cs4)))"
}
