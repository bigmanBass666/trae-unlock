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

Write-Host "=== Deep Investigation: PARTIAL + BROKEN + FINGERPRINT Patches ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "--- 1. auto-confirm-commands (PARTIAL @ 7512527) ---" -ForegroundColor Yellow
Write-Host "Checking if find_original exists vs if replace_with exists..." -ForegroundColor Gray
$fo = 'e?.confirm_info?.confirm_status==="unconfirmed"){if(s){let r=e.planItemId||e.id||e.toolCallId||"";if(this._logService.info("[PlanItemStreamParser] auto-confirming knowledges background toolcall"'
$rw = 'e?.toolName!=="AskUserQuestion"&&e?.toolName!=="ExitPlanMode"){this._taskService.provideUserResponse'
$foIdx = $content.IndexOf($fo)
$rwIdx = $content.IndexOf($rw)
Write-Host "  find_original prefix found at: $foIdx" -ForegroundColor $(if($foIdx -ge 0){"Green"}else{"Red"})
Write-Host "  replace_with fingerprint found at: $rwIdx" -ForegroundColor $(if($rwIdx -ge 0){"Green"}else{"Red"})
if ($foIdx -ge 0) {
    Write-Host "  Context around find_original:" -ForegroundColor Gray
    $ctx = Get-Context -Offset $foIdx -Before 0 -After 700
    Write-Host "  $($ctx.Substring(0, [Math]::Min(700, $ctx.Length)))" -ForegroundColor DarkGray
}
Write-Host ""

Write-Host "--- 2. guard-clause-bypass (FINGERPRINT @ 8712898) ---" -ForegroundColor Yellow
$fo2 = 'if(!n||!q||et)return null;'
$rw2 = '!q&&!J)||et)return null'
$fo2Idx = $content.IndexOf($fo2)
$rw2Idx = $content.IndexOf($rw2)
Write-Host "  find_original found at: $fo2Idx" -ForegroundColor $(if($fo2Idx -ge 0){"Green"}else{"Red"})
Write-Host "  replace_with fingerprint found at: $rw2Idx" -ForegroundColor $(if($rw2Idx -ge 0){"Green"}else{"Red"})
if ($rw2Idx -ge 0) {
    Write-Host "  Context around fingerprint:" -ForegroundColor Gray
    $ctx = Get-Context -Offset $rw2Idx -Before 20 -After 80
    Write-Host "  $ctx" -ForegroundColor DarkGray
}
Write-Host ""

Write-Host "--- 3. auto-continue-thinking (FINGERPRINT @ 8713624) ---" -ForegroundColor Yellow
$fo3prefix = 'if(V&&J){let e=M.localize("continue"'
$rw3 = 'console.log("[v7] triggering auto-continue'
$fo3Idx = $content.IndexOf($fo3prefix)
$rw3Idx = $content.IndexOf($rw3)
Write-Host "  find_original prefix found at: $fo3Idx" -ForegroundColor $(if($fo3Idx -ge 0){"Green"}else{"Red"})
Write-Host "  replace_with fingerprint found at: $rw3Idx" -ForegroundColor $(if($rw3Idx -ge 0){"Green"}else{"Red"})
if ($fo3Idx -ge 0) {
    Write-Host "  Context around find_original:" -ForegroundColor Gray
    $ctx = Get-Context -Offset $fo3Idx -Before 0 -After 300
    Write-Host "  $($ctx.Substring(0, [Math]::Min(300, $ctx.Length)))" -ForegroundColor DarkGray
}
if ($rw3Idx -ge 0) {
    Write-Host "  Context around fingerprint:" -ForegroundColor Gray
    $ctx = Get-Context -Offset $rw3Idx -Before 60 -After 60
    Write-Host "  $ctx" -ForegroundColor DarkGray
}
Write-Host ""

Write-Host "--- 4. auto-continue-v11-store-subscribe (FINGERPRINT @ 7592779) ---" -ForegroundColor Yellow
$fo4 = 'd!==t.currentSessionId)&&a()})}async function FP(e){let t=uj.getInstance(),i=t.resolve(k1),{currentAgent:r}=t.resolve(xC).getState()'
$rw4 = '[v11-bg] store.subscribe installed'
$fo4Idx = $content.IndexOf($fo4)
$rw4Idx = $content.IndexOf($rw4)
Write-Host "  find_original found at: $fo4Idx" -ForegroundColor $(if($fo4Idx -ge 0){"Green"}else{"Red"})
Write-Host "  replace_with fingerprint found at: $rw4Idx" -ForegroundColor $(if($rw4Idx -ge 0){"Green"}else{"Red"})
if ($fo4Idx -ge 0) {
    Write-Host "  Context around find_original:" -ForegroundColor Gray
    $ctx = Get-Context -Offset $fo4Idx -Before 0 -After 200
    Write-Host "  $($ctx.Substring(0, [Math]::Min(200, $ctx.Length)))" -ForegroundColor DarkGray
}
if ($rw4Idx -ge 0) {
    Write-Host "  Context around fingerprint:" -ForegroundColor Gray
    $ctx = Get-Context -Offset $rw4Idx -Before 60 -After 60
    Write-Host "  $ctx" -ForegroundColor DarkGray
}
Write-Host ""

Write-Host "--- 5. bypass-runcommandcard-redlist (FINGERPRINT @ 8081540) ---" -ForegroundColor Yellow
$fo5prefix = 'case Cr.AutoRunMode.WHITELIST:switch(i){case Cr.BlockLevel.RedList:return P7'
$rw5 = 'case Cr.AutoRunMode.WHITELIST:return P7.Default;case Cr.AutoRunMode.ALWAYS_RUN:return P7.Default;default:return P7.Default'
$fo5Idx = $content.IndexOf($fo5prefix)
$rw5Idx = $content.IndexOf($rw5)
Write-Host "  find_original prefix found at: $fo5Idx" -ForegroundColor $(if($fo5Idx -ge 0){"Green"}else{"Red"})
Write-Host "  replace_with fingerprint found at: $rw5Idx" -ForegroundColor $(if($rw5Idx -ge 0){"Green"}else{"Red"})
if ($fo5Idx -ge 0) {
    Write-Host "  Context around find_original:" -ForegroundColor Gray
    $ctx = Get-Context -Offset $fo5Idx -Before 0 -After 400
    Write-Host "  $($ctx.Substring(0, [Math]::Min(400, $ctx.Length)))" -ForegroundColor DarkGray
}
if ($rw5Idx -ge 0) {
    Write-Host "  Context around fingerprint:" -ForegroundColor Gray
    $ctx = Get-Context -Offset $rw5Idx -Before 40 -After 80
    Write-Host "  $ctx" -ForegroundColor DarkGray
}
Write-Host ""

Write-Host "--- 6. bypass-loop-detection (FINGERPRINT @ 8707800) ---" -ForegroundColor Yellow
$fo6 = 'J=!![kg.MODEL_OUTPUT_TOO_LONG,kg.TASK_TURN_EXCEEDED_ERROR].includes(_)'
$rw6 = 'kg.LLM_STOP_CONTENT_LOOP,kg.DEFAULT].includes(_)'
$fo6Idx = $content.IndexOf($fo6)
$rw6Idx = $content.IndexOf($rw6)
$fo6v = 'K=!![kg.MODEL_OUTPUT_TOO_LONG,kg.TASK_TURN_EXCEEDED_ERROR].includes(_)'
$fo6vIdx = $content.IndexOf($fo6v)
Write-Host "  find_original (J) found at: $fo6Idx" -ForegroundColor $(if($fo6Idx -ge 0){"Green"}else{"Red"})
Write-Host "  find_original (J->K variant) found at: $fo6vIdx" -ForegroundColor $(if($fo6vIdx -ge 0){"Green"}else{"Red"})
Write-Host "  replace_with fingerprint found at: $rw6Idx" -ForegroundColor $(if($rw6Idx -ge 0){"Green"}else{"Red"})
if ($rw6Idx -ge 0) {
    Write-Host "  Context around fingerprint:" -ForegroundColor Gray
    $ctx = Get-Context -Offset $rw6Idx -Before 80 -After 80
    Write-Host "  $ctx" -ForegroundColor DarkGray
}
Write-Host ""

Write-Host "--- 7. force-auto-confirm (BROKEN) ---" -ForegroundColor Red
$fo7 = '!e&&er===Ck.Unconfirmed&&ew.confirm(!0)'
$fo7Idx = $content.IndexOf($fo7)
Write-Host "  find_original found at: $fo7Idx" -ForegroundColor $(if($fo7Idx -ge 0){"Green"}else{"Red"})
$fo7a = 'Ck.Unconfirmed'
$fo7aIdx = $content.IndexOf($fo7a)
Write-Host "  Ck.Unconfirmed found at: $fo7aIdx" -ForegroundColor $(if($fo7aIdx -ge 0){"Green"}else{"Red"})
$fo7b = 'Unconfirmed'
$fo7bMatches = @()
$searchFrom = 0
while (($idx = $content.IndexOf($fo7b, $searchFrom)) -ge 0) {
    $fo7bMatches += $idx
    $searchFrom = $idx + 1
    if ($fo7bMatches.Count -ge 10) { break }
}
Write-Host "  'Unconfirmed' occurrences (first 10): $($fo7bMatches -join ', ')" -ForegroundColor Gray
$fo7c = 'ew.confirm'
$fo7cIdx = $content.IndexOf($fo7c)
Write-Host "  'ew.confirm' found at: $fo7cIdx" -ForegroundColor $(if($fo7cIdx -ge 0){"Green"}else{"Red"})
Write-Host ""

Write-Host "--- 8. sync-force-confirm (BROKEN) ---" -ForegroundColor Red
$fo8 = 'ey=(0,sK.useMemo)(()=>er===Ck.Unconfirmed?Ck.Confirmed:en?Ck.Confirmed:e&&er===Ck.Unconfirmed?Ck.Canceled:er,[en,er,e])'
$fo8Idx = $content.IndexOf($fo8)
Write-Host "  find_original found at: $fo8Idx" -ForegroundColor $(if($fo8Idx -ge 0){"Green"}else{"Red"})
$fo8a = 'ey=(0,sK.useMemo)'
$fo8aIdx = $content.IndexOf($fo8a)
Write-Host "  'ey=(0,sK.useMemo)' found at: $fo8aIdx" -ForegroundColor $(if($fo8aIdx -ge 0){"Green"}else{"Red"})
$fo8b = 'Ck.Confirmed'
$fo8bMatches = @()
$searchFrom = 0
while (($idx = $content.IndexOf($fo8b, $searchFrom)) -ge 0) {
    $fo8bMatches += $idx
    $searchFrom = $idx + 1
    if ($fo8bMatches.Count -ge 10) { break }
}
Write-Host "  'Ck.Confirmed' occurrences (first 10): $($fo8bMatches -join ', ')" -ForegroundColor Gray
Write-Host ""

Write-Host "--- 9. bypass-whitelist-sandbox-blocks (BROKEN) ---" -ForegroundColor Red
$fo9 = 'case Cr.AutoRunMode.WHITELIST:switch(i){case Cr.BlockLevel.RedList:return P8'
$fo9Idx = $content.IndexOf($fo9)
Write-Host "  find_original prefix found at: $fo9Idx" -ForegroundColor $(if($fo9Idx -ge 0){"Green"}else{"Red"})
$fo9a = 'P8.V2_Sandbox_RedList'
$fo9aIdx = $content.IndexOf($fo9a)
Write-Host "  'P8.V2_Sandbox_RedList' found at: $fo9aIdx" -ForegroundColor $(if($fo9aIdx -ge 0){"Green"}else{"Red"})
$fo9b = 'P8.Default'
$fo9bMatches = @()
$searchFrom = 0
while (($idx = $content.IndexOf($fo9b, $searchFrom)) -ge 0) {
    $fo9bMatches += $idx
    $searchFrom = $idx + 1
    if ($fo9bMatches.Count -ge 10) { break }
}
Write-Host "  'P8.Default' occurrences (first 10): $($fo9bMatches -join ', ')" -ForegroundColor Gray
$fo9c = 'P8.V2_Manual'
$fo9cIdx = $content.IndexOf($fo9c)
Write-Host "  'P8.V2_Manual' found at: $fo9cIdx" -ForegroundColor $(if($fo9cIdx -ge 0){"Green"}else{"Red"})
$fo9d = 'AutoRunMode.WHITELIST'
$fo9dMatches = @()
$searchFrom = 0
while (($idx = $content.IndexOf($fo9d, $searchFrom)) -ge 0) {
    $fo9dMatches += $idx
    $searchFrom = $idx + 1
    if ($fo9dMatches.Count -ge 10) { break }
}
Write-Host "  'AutoRunMode.WHITELIST' occurrences: $($fo9dMatches -join ', ')" -ForegroundColor Gray
if ($fo9dMatches.Count -gt 0) {
    foreach ($m in $fo9dMatches) {
        Write-Host "    Context @ $m :" -ForegroundColor Gray
        $ctx = Get-Context -Offset $m -Before 20 -After 200
        Write-Host "    $($ctx.Substring(0, [Math]::Min(220, $ctx.Length)))" -ForegroundColor DarkGray
    }
}
Write-Host ""

Write-Host "=== Deep Investigation Complete ===" -ForegroundColor Cyan
