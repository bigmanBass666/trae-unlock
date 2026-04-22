# 快速检查所有补丁是否还存在
$file = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$content = Get-Content $file -Raw

$checks = @(
    @{name="data-source-auto-confirm"; pattern='o\?\.confirm_status===.{0,100}auto_confirm'},
    @{name="service-layer-runcommand-confirm"; pattern='provideUserResponse.*tool_confirm'},
    @{name="auto-confirm-commands"; pattern='e\?\.toolName!==\"ExitPlanMode\"\)'},
    @{name="bypass-runcommandcard-redlist"; pattern='case Cr\.AutoRunMode\.WHITELIST:return P8\.Default'},
    @{name="auto-continue-thinking"; pattern='setTimeout\(\(\)=>\{ed\(\)\},50\)'},
    @{name="bypass-loop-detection"; pattern='kg\.LLM_STOP_DUP_TOOL_CALL'},
    @{name="efh-resume-list"; pattern='kg\.TASK_TURN_EXCEEDED_ERROR'}
)

Write-Host "=== Patch Status Check ===`n"
foreach ($check in $checks) {
    $matches = [regex]::Matches($content, $check.pattern)
    $status = if ($matches.Count -gt 0) { "✅ PASS" } else { "❌ FAIL" }
    Write-Host "$status - $($check.name) ($($matches.Count) matches)"
}
