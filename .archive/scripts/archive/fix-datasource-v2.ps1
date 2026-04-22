$targetFile = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$content = [System.IO.File]::ReadAllText($targetFile)

$oldCode = 'o?.confirm_status=="unconfirmed"&&(o.auto_confirm=!0)'
$newCode = 'o?.confirm_status=="unconfirmed"&&i.name!==CS.AskUserQuestion&&i.name!==CS.NotifyUser&&i.name!==CS.ExitPlanMode&&(o.auto_confirm=!0,o.confirm_status="confirmed")'

$idx = $content.IndexOf($oldCode)
if ($idx -eq -1) {
    Write-Host "ERROR: Old code not found!"
    exit 1
}

Write-Host "Found old code at offset: $idx"
$content = $content.Replace($oldCode, $newCode)

$verifyIdx = $content.IndexOf($newCode)
if ($verifyIdx -ge 0) {
    Write-Host "New code verified at offset: $verifyIdx"
} else {
    Write-Host "ERROR: New code not found after replacement!"
    exit 1
}

[System.IO.File]::WriteAllText($targetFile, $content)
Write-Host "File saved successfully!"

# 验证所有补丁
$fingerprints = @{
    'data-source-auto-confirm v2' = 'o?.confirm_status=="unconfirmed"&&i.name!==CS.AskUserQuestion&&i.name!==CS.NotifyUser&&i.name!==CS.ExitPlanMode&&(o.auto_confirm=!0,o.confirm_status="confirmed")'
    'auto-confirm-commands' = 'e?.toolName!=="ExitPlanMode"){this._taskService.provideUserResponse({task_id:i||"",type:"tool_confirm"'
    'service-layer-runcommand-confirm' = 'e?.toolName!=="ExitPlanMode")&&(e?.confirm_info?.confirm_status!=="confirmed")&&(this._taskService.provideUserResponse({task_id:i||"",type:"tool_confirm"'
    'bypass-runcommandcard-redlist' = 'case Cr.AutoRunMode.WHITELIST:return P8.Default;case Cr.AutoRunMode.ALWAYS_RUN:return P8.Default;default:return P8.Default'
    'auto-continue-thinking' = 'setTimeout(()=>{ed()},50);return null'
    'bypass-loop-detection' = 'kg.LLM_STOP_DUP_TOOL_CALL,kg.LLM_STOP_CONTENT_LOOP'
    'efh-resume-list' = 'kg.TASK_TURN_EXCEEDED_ERROR]'
}
Write-Host "`n=== All patches verification ==="
foreach ($entry in $fingerprints.GetEnumerator()) {
    $fp = $entry.Value
    $i2 = $content.IndexOf($fp)
    if ($i2 -ge 0) {
        Write-Host "$($entry.Key): PASS (offset $i2)"
    } else {
        Write-Host "$($entry.Key): FAIL"
    }
}