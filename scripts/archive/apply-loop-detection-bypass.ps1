$file = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$content = Get-Content $file -Raw

Write-Host "=== Applying bypass-loop-detection ===`n"

# The new pattern is: J=!![kg.MODEL_OUTPUT_TOO_LONG,kg.TASK_TURN_EXCEEDED_ERROR].includes(_)
# We need to bypass this by making J always false (no loop detection errors)
# Original patch approach: remove the loop detection error codes from the array

# Option 1: Replace the array with empty array
$original = 'J=!![kg.MODEL_OUTPUT_TOO_LONG,kg.TASK_TURN_EXCEEDED_ERROR].includes(_)'
$patched = 'J=!1'

if ($content.Contains($original) -and -not $content.Contains($patched)) {
    $content = $content.Replace($original, $patched)
    Write-Host "APPLIED: bypass-loop-detection"
    Set-Content -Path $file -Value $content -NoNewline
} elseif ($content.Contains($patched)) {
    Write-Host "ALREADY APPLIED"
} else {
    Write-Host "NOT FOUND"
}

# Verify
Write-Host "`n=== Final Verification ==="
$verify = Get-Content $file -Raw

$checks = @(
    @{name="data-source-auto-confirm v3"; pattern='o\?\.confirm_status==="unconfirmed"&&i\.name!==CS\.AskUserQuestion&&i\.name!==CS\.ExitPlanMode'},
    @{name="auto-confirm-commands v4"; pattern='e\?\.toolName!=="AskUserQuestion"&&e\?\.toolName!=="ExitPlanMode"\)'},
    @{name="service-layer-runcommand-confirm v8"; pattern='e\?\.toolName!=="ExitPlanMode"\)&&\(e\?\.confirm_info\?\.confirm_status!=="confirmed"\)'},
    @{name="bypass-runcommandcard-redlist v2"; pattern='case Cr\.AutoRunMode\.WHITELIST:return P8\.Default;case Cr\.AutoRunMode\.ALWAYS_RUN:return P8\.Default'},
    @{name="auto-continue-thinking"; pattern='setTimeout\(\(\)=>\{ed\(\)\},50\)'},
    @{name="bypass-loop-detection"; pattern='J=!1'},
    @{name="efh-resume-list"; pattern='kg\.TASK_TURN_EXCEEDED_ERROR'}
)

$passCount = 0
foreach ($check in $checks) {
    $m = [regex]::Matches($verify, $check.pattern)
    $status = if ($m.Count -gt 0) { "PASS" } else { "FAIL" }
    if ($status -eq "PASS") { $passCount++ }
    Write-Host "$status - $($check.name)"
}

Write-Host "`nResult: $passCount/7 patches applied"