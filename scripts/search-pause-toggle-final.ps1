param(
    [string]$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
)

$ErrorActionPreference = "SilentlyContinue"
$content = Get-Content $TargetFile -Raw -Encoding UTF8
$fs = $content.Length

function At($off, $len) {
    $s = [Math]::Max(0,$off); $e = [Math]::Min($fs,$s+$len)
    if ($s -lt $e) { return ($content.Substring($s,$e-$s) -replace "`r","") } else { return "(out of bounds)" }
}

Write-Host "=== FINAL: N() status setter near sendMessage ===" -ForegroundColor Cyan
Write-Host (At 9335400 500)
Write-Host ""

Write-Host "=== FINAL: onSendChatMessageStart (sets Running) ===" -ForegroundColor Cyan
Write-Host (At 7536280 300)
Write-Host ""

Write-Host "=== FINAL: stopStreaming (sets WaitingInput) ===" -ForegroundColor Cyan
Write-Host (At 7538070 400)
Write-Host ""

Write-Host "=== FINAL: V.RunningStatus enum + ChatSendingStateEnum ===" -ForegroundColor Cyan
Write-Host (At 2790600 200)
Write-Host ""

Write-Host "=== FINAL: i_ derivation (isRunning = NOT WaitingInput) ===" -ForegroundColor Cyan
Write-Host (At 2949800 600)
Write-Host ""

Write-Host "=== FINAL: Search for actual visual button with icon toggle ===" -ForegroundColor Green
$btnRx = [regex]::Matches($content, '(?i)(sendingState|chatSendingState|iw\b).{0,150}')
Write-Host "Found $($btn.Count) references to sendingState/iw"
foreach ($b in $btnRx[0..10]) {
    Write-Host ""
    Write-Host "  @ $($b.Index): $($b.Value.Substring(0,[Math]::Min(160,$b.Value.Length)))"
}

Write-Host ""
Write-Host "=== FINAL: Button component that takes sendingState ===" -ForegroundColor Green
$btn2Rx = [regex]::Matches($content, '(?i)(?:function|const|let|var)\s+\w[\w]*[\s(].{0,200}(?:sendingState|ChatSendingState|isRunning|onStop|onClick).{0,100}(?:return|createElement)')
Write-Host "Found $($btn2Rx.Count) candidate button components"

Write-Host ""
Write-Host "=== FINAL: Search for 'send' icon name near input area (~2.87M-3.0M) ===" -ForegroundColor Green
$area = $content.Substring(2870000, [Math]::Min(130000, $fs-2870000))
$nameRx = [regex]::Matches($area, '(?i)(name\s*:\s*["''][^"'']*(send|pause|stop|arrow)[^"'']*["'']|icube-Send|icube-Pause|icube-Stop|icube-Arrow)')
Write-Host "Found $($nameRx.Count) icon names in input area"
foreach ($n in $nameRx) {
    $absOff = 2870000 + $n.Index
    $cs = [Math]::Max(0,$n.Index-60); $ce = [Math]::Min($area.Length,$n.Index+$n.Length+80)
    Write-Host "  @$absOff : $($area.Substring($cs,$ce-$cs))"
}
