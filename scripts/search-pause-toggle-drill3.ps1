param(
    [string]$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
)

$ErrorActionPreference = "SilentlyContinue"
$content = Get-Content $TargetFile -Raw -Encoding UTF8
$fs = $content.Length

function ShowCtx($label, $offset, $len) {
    Write-Host ""
    Write-Host "=== $label @~$offset ===" -ForegroundColor Cyan
    $s = [Math]::Max(0, $offset); $e = [Math]::Min($fs, $s + $len)
    if ($s -lt $e) {
        $txt = ($content.Substring($s, [Math]::Min($len, $e-$s)) -replace "`r","")
        foreach ($line in ($txt -split "`n")[0..35]) { Write-Host "  $line" }
    }
}

Write-Host "=== DRILL F: Find the VISUAL send/pause button component ===" -ForegroundColor Green
Write-Host "Searching for component that renders icon based on iw/i_/iy..."
Write-Host ""

$inputRegion = $content.Substring(2950000, [Math]::Min(50000, $fs - 2950000))

$fPatterns = @(
    @{Label="F1: iw (sendingState) usage"; Pattern="iw"},
    @{Label="F2: iL (stopClick handler) usage near button"; Pattern="iL[^a-zA-Z]"},
    @{Label="F3: iM (sendClick handler) usage near button"; Pattern="iM[^a-zA-Z].{0,40}(button|click|onClick)"},
    @{Label="F4: iF (disabled) prop passed to element"; Pattern="iF[^a-zA-Z]"},
    @{Label="F5: ChatSendingStateEnum usage"; Pattern="ChatSendingStateEnum"},
    @{Label="F6: send_button or stop_button text"; Pattern="send.button|stop.button|pause"}
)

foreach ($fp in $fPatterns) {
    $fm = [regex]::Matches($inputRegion, $fp.Pattern)
    Write-Host "$($fp.Label): $($fm.Count) matches in 2950000-3000000 range"
    for ($k = 0; $k -lt [Math]::Min($fm.Count, 6); $k++) {
        $mk = $fm[$k]
        $absOff = 2950000 + $mk.Index
        $cs = [Math]::Max(0, $mk.Index - 60); $ce = [Math]::Min($inputRegion.Length, $mk.Index + $mk.Length + 60)
        Write-Host "  [$k] @$absOff : $($inputRegion.Substring($cs,$ce-$cs).Replace("`n"," ").Replace("  "," "))"
    }
    Write-Host ""
}

Write-Host ""
Write-Host "=== DRILL G: Search for actual button component after io/iT render ===" -ForegroundColor Green
ShowCtx "After iT render, looking for button" 2953200 4000

Write-Host ""
Write-Host "=== DRILL H: Search broader area for Codicon/SVG with send/pause ===" -ForegroundColor Green
$iconRx = [regex]::Matches($content, '(?i)(codicon|svg|icon).{0,60}(send|pause|stop|arrow)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$inInputArea = $iconRx | Where-Object { $_.Index -gt 2870000 -and $_.Index -lt 2970000 }
Write-Host "Total matches: $($iconRx.Count), in input area(2.87-2.97M): $($inInputArea.Count)"
foreach ($im in $inInputArea[0..10]) {
    $cs = [Math]::Max(0, $im.Index - 80); $ce = [Math]::Min($fs, $im.Index + $im.Length + 80)
    Write-Host "  @ $($im.Index): $($content.Substring($cs,$ce-$cs).Replace("`n"," ").Replace("  "," "))"
}

Write-Host ""
Write-Host "=== DRILL I: N() function definition (status setter) ===" -ForegroundColor Green
$nDefRx = [regex]::Matches($content, '(?:function\s+N\s*\(|const\s+N=\s*function|let\s+N=\s*function|var\s+N=\s*function)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
foreach ($nm in $nDefRx) {
    ShowCtx "N() definition candidate" $nm.Index 600
}

Write-Host ""
Write-Host "=== DRILL J: setRunningStatusMap definition ===" -ForegroundColor Green
$srmRx = [regex]::Matches($content, 'setRunningStatusMap[\s(]', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
foreach ($sm in $srmRx) {
    $cs = [Math]::Max(0, $sm.Index - 200); $ce = [Math]::Min($fs, $sm.Index + 300)
    Write-Host "  @ $($sm.Index): $($content.Substring($cs,$ce-$cs).Substring(0,[Math]::Min(300,$ce-$cs)))"
}
