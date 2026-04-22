$file = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$content = Get-Content $file -Raw

Write-Host "=== Applying remaining patches ===`n"

# ============================================================
# Patch 1: auto-continue-thinking (new pattern)
# Old: setTimeout(function(){ed()},50) -> setTimeout(()=>{ed()},50)
# New: The pattern changed - need to find the Alert component and add auto-click
# ============================================================
Write-Host "[1/2] auto-continue-thinking..."

# The new pattern is: if(V&&J){...return sX().createElement(Cr.Alert,{...actionText:e,onActionClick:ed})}
# We need to add setTimeout to auto-click
$original1 = 'if(V&&J){let e=M.localize("continue",{},"Continue");return sX().createElement(Cr.Alert,{onDoubleClick:e_,type:"warning",message:ef,actionText:e,onActionClick:ed})}'
$patched1 = 'if(V&&J){let e=M.localize("continue",{},"Continue");setTimeout(()=>{ed()},50);return sX().createElement(Cr.Alert,{onDoubleClick:e_,type:"warning",message:ef,actionText:e,onActionClick:ed})}'

if ($content.Contains($original1) -and -not $content.Contains($patched1)) {
    $content = $content.Replace($original1, $patched1)
    Write-Host "  APPLIED (new pattern)"
} elseif ($content.Contains($patched1)) {
    Write-Host "  ALREADY APPLIED"
} else {
    Write-Host "  NOT FOUND - checking alternative patterns..."
    # Try to find the pattern with different formatting
    $altPattern = 'if\(V&&J\)\{let e=M\.localize\("continue",\{\},"Continue"\);return sX\(\)\.createElement\(Cr\.Alert,\{onDoubleClick:e_,type:"warning",message:ef,actionText:e,onActionClick:ed\}\)\}'
    $matches = [regex]::Matches($content, $altPattern)
    Write-Host "  Alternative matches: $($matches.Count)"
}

# ============================================================
# Patch 2: bypass-loop-detection (already PASS per earlier check)
# Let's verify
# ============================================================
Write-Host "[2/2] bypass-loop-detection..."
$pattern = 'kg\.LLM_STOP_DUP_TOOL_CALL'
$matches = [regex]::Matches($content, $pattern)
if ($matches.Count -gt 0) {
    Write-Host "  ALREADY EXISTS (no patch needed)"
} else {
    Write-Host "  NOT FOUND"
}

# Save changes
Write-Host "`n=== Saving ==="
Set-Content -Path $file -Value $content -NoNewline
Write-Host "Done"

# Final verification
Write-Host "`n=== Final Verification ==="
$verify = Get-Content $file -Raw

$checks = @(
    @{name="data-source-auto-confirm v3"; pattern='o\?\.confirm_status==="unconfirmed"&&i\.name!==CS\.AskUserQuestion&&i\.name!==CS\.ExitPlanMode'},
    @{name="auto-confirm-commands v4"; pattern='e\?\.toolName!=="AskUserQuestion"&&e\?\.toolName!=="ExitPlanMode"\)'},
    @{name="service-layer-runcommand-confirm v8"; pattern='e\?\.toolName!=="ExitPlanMode"\)&&\(e\?\.confirm_info\?\.confirm_status!=="confirmed"\)'},
    @{name="bypass-runcommandcard-redlist v2"; pattern='case Cr\.AutoRunMode\.WHITELIST:return P8\.Default;case Cr\.AutoRunMode\.ALWAYS_RUN:return P8\.Default'},
    @{name="auto-continue-thinking"; pattern='setTimeout\(\(\)=>\{ed\(\)\},50\)'},
    @{name="bypass-loop-detection"; pattern='kg\.LLM_STOP_DUP_TOOL_CALL'},
    @{name="efh-resume-list"; pattern='kg\.TASK_TURN_EXCEEDED_ERROR'}
)

foreach ($check in $checks) {
    $m = [regex]::Matches($verify, $check.pattern)
    $status = if ($m.Count -gt 0) { "PASS" } else { "FAIL" }
    Write-Host "$status - $($check.name)"
}