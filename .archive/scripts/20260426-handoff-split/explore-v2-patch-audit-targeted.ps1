param(
    [string]$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
)

$ErrorActionPreference = "Continue"
$content = [System.IO.File]::ReadAllText($TargetFile)

function Get-Context {
    param([int]$Offset, [int]$Before = 80, [int]$After = 200)
    $start = [Math]::Max(0, $Offset - $Before)
    $len = [Math]::Min($After + $Before, $content.Length - $start)
    return $content.Substring($start, $len)
}

Write-Host "=== Targeted Investigation: BROKEN Patches Context ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "--- force-auto-confirm: Ck.Unconfirmed context ---" -ForegroundColor Yellow
$idx = 8623099
Write-Host "  Context @ $idx :" -ForegroundColor Gray
$ctx = Get-Context -Offset $idx -Before 100 -After 300
Write-Host "  $ctx" -ForegroundColor DarkGray
Write-Host ""

Write-Host "--- force-auto-confirm: ew.confirm context ---" -ForegroundColor Yellow
$idx = 8651333
Write-Host "  Context @ $idx :" -ForegroundColor Gray
$ctx = Get-Context -Offset $idx -Before 150 -After 200
Write-Host "  $ctx" -ForegroundColor DarkGray
Write-Host ""

Write-Host "--- sync-force-confirm: ey=(0,sK.useMemo) context ---" -ForegroundColor Yellow
$idx = 8648226
Write-Host "  Context @ $idx :" -ForegroundColor Gray
$ctx = Get-Context -Offset $idx -Before 30 -After 300
Write-Host "  $ctx" -ForegroundColor DarkGray
Write-Host ""

Write-Host "--- bypass-loop-detection: check what variable name is used ---" -ForegroundColor Yellow
$idx = 8707800
Write-Host "  Context @ $idx (wider) :" -ForegroundColor Gray
$ctx = Get-Context -Offset $idx -Before 200 -After 200
Write-Host "  $ctx" -ForegroundColor DarkGray
Write-Host ""

Write-Host "--- auto-confirm-commands: check if original unpatched code exists ---" -ForegroundColor Yellow
$origEnd = 'return}this._taskService.provideUserResponse'
$origEndIdx = $content.IndexOf($origEnd)
Write-Host "  Original ending pattern found at: $origEndIdx" -ForegroundColor $(if($origEndIdx -ge 0){"Green"}else{"Red"})
$patchedEnd = 'e.confirm_info&&(e.confirm_info.confirm_status="confirmed")}}'
$patchedEndIdx = $content.IndexOf($patchedEnd)
Write-Host "  Patched ending pattern found at: $patchedEndIdx" -ForegroundColor $(if($patchedEndIdx -ge 0){"Green"}else{"Red"})
if ($patchedEndIdx -ge 0) {
    $ctx = Get-Context -Offset $patchedEndIdx -Before 50 -After 50
    Write-Host "  Context: $ctx" -ForegroundColor DarkGray
}
Write-Host ""

Write-Host "--- guard-clause-bypass: check original vs patched ---" -ForegroundColor Yellow
$origGC = 'if(!n||!q||et)return null'
$origGCIdx = $content.IndexOf($origGC)
Write-Host "  Original guard clause found at: $origGCIdx" -ForegroundColor $(if($origGCIdx -ge 0){"Green"}else{"Red"})
$patchedGC = 'if(!n||(!q&&!J)||et)return null'
$patchedGCIdx = $content.IndexOf($patchedGC)
Write-Host "  Patched guard clause found at: $patchedGCIdx" -ForegroundColor $(if($patchedGCIdx -ge 0){"Green"}else{"Red"})
$altGC = 'if(!n||(!q&&!K)||et)return null'
$altGCIdx = $content.IndexOf($altGC)
Write-Host "  Alt guard clause (J->K) found at: $altGCIdx" -ForegroundColor $(if($altGCIdx -ge 0){"Green"}else{"Red"})
Write-Host ""

Write-Host "--- bypass-whitelist-sandbox-blocks: P7 vs P8 analysis ---" -ForegroundColor Yellow
$p7Default = @()
$searchFrom = 0
while (($idx = $content.IndexOf('P7.Default', $searchFrom)) -ge 0) {
    $p7Default += $idx
    $searchFrom = $idx + 1
    if ($p7Default.Count -ge 20) { break }
}
Write-Host "  P7.Default occurrences (first 20): $($p7Default.Count) total" -ForegroundColor Gray
Write-Host "  Offsets: $($p7Default -join ', ')" -ForegroundColor DarkGray
$p8search = @()
$searchFrom = 0
while (($idx = $content.IndexOf('P8.', $searchFrom)) -ge 0) {
    $p8search += $idx
    $searchFrom = $idx + 1
    if ($p8search.Count -ge 10) { break }
}
Write-Host "  P8.* occurrences (first 10): $($p8search.Count) total" -ForegroundColor Gray
if ($p8search.Count -gt 0) {
    Write-Host "  Offsets: $($p8search -join ', ')" -ForegroundColor DarkGray
} else {
    Write-Host "  P8 namespace has been REMOVED/RENAMED" -ForegroundColor Red
}
Write-Host ""

Write-Host "=== Targeted Investigation Complete ===" -ForegroundColor Cyan
