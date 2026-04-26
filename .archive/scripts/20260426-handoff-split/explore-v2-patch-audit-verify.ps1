param(
    [string]$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
)

$ErrorActionPreference = "Continue"
$content = [System.IO.File]::ReadAllText($TargetFile)

Write-Host "=== Verify: MATCH patches replace_with identifiers ===" -ForegroundColor Cyan
Write-Host ""

$checks = @(
    @{ Name = "auto-continue-l2-parse: Di token"; Pattern = "resolve(Di)" },
    @{ Name = "auto-continue-l2-parse: uj.getInstance"; Pattern = "uj.getInstance()" },
    @{ Name = "auto-continue-l2-parse: bQ.Warning"; Pattern = "bQ.Warning" },
    @{ Name = "auto-continue-l2-parse: bQ.Error"; Pattern = "bQ.Error" },
    @{ Name = "efh-resume-list: kg.TASK_TURN_EXCEEDED_ERROR"; Pattern = "kg.TASK_TURN_EXCEEDED_ERROR" },
    @{ Name = "efh-resume-list: kg.LLM_STOP_DUP_TOOL_CALL"; Pattern = "kg.LLM_STOP_DUP_TOOL_CALL" },
    @{ Name = "efh-resume-list: kg.LLM_STOP_CONTENT_LOOP"; Pattern = "kg.LLM_STOP_CONTENT_LOOP" },
    @{ Name = "efh-resume-list: kg.DEFAULT"; Pattern = "kg.DEFAULT" },
    @{ Name = "data-source-auto-confirm: CS.AskUserQuestion"; Pattern = "CS.AskUserQuestion" },
    @{ Name = "data-source-auto-confirm: CS.ExitPlanMode"; Pattern = "CS.ExitPlanMode" },
    @{ Name = "data-source-auto-confirm: CS.ViewFiles"; Pattern = "CS.ViewFiles" },
    @{ Name = "service-layer-runcommand-confirm: provideUserResponse"; Pattern = "provideUserResponse" },
    @{ Name = "ec-debug-log: Ir.Z"; Pattern = "Ir.Z" },
    @{ Name = "ec-debug-log: efg.includes"; Pattern = "efg.includes" },
    @{ Name = "ec-debug-log: resumeChat"; Pattern = "resumeChat" },
    @{ Name = "ec-debug-log: retryChatByUserMessageId"; Pattern = "retryChatByUserMessageId" },
    @{ Name = "guard-clause-bypass (applied): J variable"; Pattern = "!q&&!J)||et)return null" },
    @{ Name = "bypass-loop-detection (applied): J expanded"; Pattern = "J=!![kg.MODEL_OUTPUT_TOO_LONG,kg.TASK_TURN_EXCEEDED_ERROR,kg.LLM_STOP_DUP_TOOL_CALL,kg.LLM_STOP_CONTENT_LOOP,kg.DEFAULT].includes(_)" },
    @{ Name = "NEW: ee variable (premium limit)"; Pattern = "ee=!![kg.PREMIUM_MODE_USAGE_LIMIT" },
    @{ Name = "NEW: K=efg.includes"; Pattern = "K=efg.includes(_)" }
)

foreach ($check in $checks) {
    $idx = $content.IndexOf($check.Pattern)
    $status = if ($idx -ge 0) { "OK @$idx" } else { "MISSING" }
    $color = if ($idx -ge 0) { "Green" } else { "Red" }
    Write-Host "  $($check.Name): $status" -ForegroundColor $color
}

Write-Host ""
Write-Host "=== Verify: Already-applied patches offset drift ===" -ForegroundColor Cyan
Write-Host ""

$appliedPatches = @(
    @{ Id = "auto-confirm-commands"; OldHint = "~7507671"; Fingerprint = 'e?.toolName!=="AskUserQuestion"&&e?.toolName!=="ExitPlanMode"){this._taskService.provideUserResponse' },
    @{ Id = "guard-clause-bypass"; OldHint = "~8706067"; Fingerprint = '!q&&!J)||et)return null' },
    @{ Id = "auto-continue-thinking"; OldHint = "~8706660"; Fingerprint = 'console.log("[v7] triggering auto-continue' },
    @{ Id = "auto-continue-v11-store-subscribe"; OldHint = "~7588590"; Fingerprint = '[v11-bg] store.subscribe installed' },
    @{ Id = "bypass-runcommandcard-redlist"; OldHint = "~8076936"; Fingerprint = 'case Cr.AutoRunMode.WHITELIST:return P7.Default;case Cr.AutoRunMode.ALWAYS_RUN:return P7.Default;default:return P7.Default' },
    @{ Id = "bypass-loop-detection"; OldHint = "~8701180"; Fingerprint = 'kg.LLM_STOP_CONTENT_LOOP,kg.DEFAULT].includes(_)' }
)

foreach ($p in $appliedPatches) {
    $idx = $content.IndexOf($p.Fingerprint)
    $oldOff = [int]($p.OldHint -replace '~', '')
    $drift = if ($idx -ge 0) { $idx - $oldOff } else { "N/A" }
    Write-Host "  $($p.Id): fingerprint @$idx, old hint $($p.OldHint), drift: $drift" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Verify Complete ===" -ForegroundColor Cyan
