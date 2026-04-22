# Comprehensive patch re-application after Trae update
# v3 fixes: NotifyUser removed from blacklist (should auto-confirm)

$file = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$content = Get-Content $file -Raw
$changes = 0

Write-Host "=== Starting Patch Re-application (v3 fixes) ===`n"

# ============================================================
# Patch 1: data-source-auto-confirm v3
# Key change: blacklist = AskUserQuestion + ExitPlanMode (NOT NotifyUser)
# ============================================================
Write-Host "[1/5] data-source-auto-confirm v3..."
$find1 = 'i.name!==CS.ViewFiles||"object"!=typeof _||Array.isArray(_)||(_.files=_.files&&Array.isArray(_.files)?_.files.map(e=>'
$replace1 = 'i.name!==CS.ViewFiles||"object"!=typeof _||Array.isArray(_)||(_.files=_.files&&Array.isArray(_.files)?_.files.map(e=>'

# The actual change is in the files.map callback
$original1 = '(e.start_line_one_indexed&&e.start_line_one_indexed>0&&(e.start_line=e.start_line_one_indexed-1)'
$patched1 = '(e.start_line_one_indexed&&e.start_line_one_indexed>0&&(e.start_line=e.start_line_one_indexed,o?.confirm_status==="unconfirmed"&&i.name!==CS.AskUserQuestion&&i.name!==CS.ExitPlanMode&&(o.auto_confirm=!0,o.confirm_status="confirmed")-1)'

if ($content.Contains($original1) -and -not $content.Contains($patched1)) {
    $content = $content.Replace($original1, $patched1)
    $changes++
    Write-Host "  APPLIED"
} elseif ($content.Contains($patched1)) {
    Write-Host "  ALREADY APPLIED"
} else {
    Write-Host "  NOT FOUND - pattern may have changed"
}

# ============================================================
# Patch 2: auto-confirm-commands v4 (NotifyUser removed from blacklist)
# ============================================================
Write-Host "[2/5] auto-confirm-commands v4..."
$original2 = 'e?.confirm_info?.confirm_status==="unconfirmed"){if(s){let r=e.planItemId||e.id||e.toolCallId||"";if(this._logService.info("[PlanItemStreamParser] auto-confirming knowledges background toolcall",{sessionId:t.sessionId,toolName:e.toolName,planItemId:e.planItemId||e.id,toolCallId:e.toolCallId,confirmToolcallId:r}),!r){this._logService.warn("[PlanItemStreamParser] auto-confirm skipped because toolcall id is missing",{sessionId:t.sessionId,toolName:e.toolName});return}this._taskService.provideUserResponse({task_id:i||"",type:"tool_confirm",toolcall_id:r,tool_name:e.toolName||"",decision:"confirm"}).catch(e=>{this._logService.warn("[PlanItemStreamParser] auto-confirm failed:",e)})}'
$patched2 = 'e?.confirm_info?.confirm_status==="unconfirmed"){if(s){let r=e.planItemId||e.id||e.toolCallId||"";if(this._logService.info("[PlanItemStreamParser] auto-confirming knowledges background toolcall",{sessionId:t.sessionId,toolName:e.toolName,planItemId:e.planItemId||e.id,toolCallId:e.toolCallId,confirmToolcallId:r}),!r){this._logService.warn("[PlanItemStreamParser] auto-confirm skipped because toolcall id is missing",{sessionId:t.sessionId,toolName:e.toolName})}else if(e?.toolName!=="response_to_user"&&e?.toolName!=="AskUserQuestion"&&e?.toolName!=="ExitPlanMode"){this._taskService.provideUserResponse({task_id:i||"",type:"tool_confirm",toolcall_id:r,tool_name:e.toolName||"",decision:"confirm"}).catch(e=>{this._logService.warn("[PlanItemStreamParser] auto-confirm failed:",e)}),e.confirm_info&&(e.confirm_info.confirm_status="confirmed")}}'

if ($content.Contains($original2) -and -not $content.Contains($patched2)) {
    $content = $content.Replace($original2, $patched2)
    $changes++
    Write-Host "  APPLIED"
} elseif ($content.Contains($patched2)) {
    Write-Host "  ALREADY APPLIED"
} else {
    Write-Host "  NOT FOUND - pattern may have changed"
}

# ============================================================
# Patch 3: service-layer-runcommand-confirm v8 (NotifyUser removed from blacklist)
# ============================================================
Write-Host "[3/5] service-layer-runcommand-confirm v8..."
$original3 = 't?.sessionId===o||e?.confirm_info?.auto_confirm||this.storeService.setBadgesBySessionId(t.sessionId,e?.confirm_info?.confirm_status)'
$patched3 = 't?.sessionId===o||e?.confirm_info?.auto_confirm||this.storeService.setBadgesBySessionId(t.sessionId,e?.confirm_info?.confirm_status),(e?.toolName||e?.id||e?.toolCallId)&&(e?.toolName!=="response_to_user"&&e?.toolName!=="AskUserQuestion"&&e?.toolName!=="ExitPlanMode")&&(e?.confirm_info?.confirm_status!=="confirmed")&&(this._taskService.provideUserResponse({task_id:i||"",type:"tool_confirm",toolcall_id:e?.planItemId||e?.id||e?.toolCallId||"",tool_name:e?.toolName||"",decision:"confirm"}).catch(e=>{this._logService.warn("[PlanItemStreamParser] auto-confirm runcommand failed:",e)}),e.confirm_info&&(e.confirm_info.confirm_status="confirmed"))'

if ($content.Contains($original3) -and -not $content.Contains($patched3)) {
    $content = $content.Replace($original3, $patched3)
    $changes++
    Write-Host "  APPLIED"
} elseif ($content.Contains($patched3)) {
    Write-Host "  ALREADY APPLIED"
} else {
    Write-Host "  NOT FOUND - pattern may have changed"
}

# ============================================================
# Patch 4: bypass-runcommandcard-redlist v2
# ============================================================
Write-Host "[4/5] bypass-runcommandcard-redlist v2..."
$original4 = 'case Cr.AutoRunMode.WHITELIST:switch(i){case Cr.BlockLevel.RedList:return P8.V2_Sandbox_RedList;case Cr.BlockLevel.SandboxNotBlockCommand:return n?P8.V2_Sandbox_NotBlocking_RedList:P8.V2_Sandbox_NotBlocking;case Cr.BlockLevel.SandboxExecuteFailure:return n?P8.V2_Sandbox_Execute_Failure_RedList:P8.V2_Sandbox_Execute_Failure;case Cr.BlockLevel.SandboxToRecovery:return n?P8.V2_Sandbox_To_Recovery_RedList:P8.V2_Sandbox_To_Recovery;case Cr.BlockLevel.SandboxUnavailable:return n?P8.V2_Sandbox_Unavailable_RedList:P8.V2_Sandbox_Unavailable;default:return P8.Default}case Cr.AutoRunMode.ALWAYS_RUN:if(i===Cr.BlockLevel.RedList||n)return P8.V2_Manual_RedList;return P8.Default;default:if(i===Cr.BlockLevel.RedList||n)return P8.V2_Manual_RedList;return P8.V2_Manual'
$patched4 = 'case Cr.AutoRunMode.WHITELIST:return P8.Default;case Cr.AutoRunMode.ALWAYS_RUN:return P8.Default;default:return P8.Default'

if ($content.Contains($original4) -and -not $content.Contains($patched4)) {
    $content = $content.Replace($original4, $patched4)
    $changes++
    Write-Host "  APPLIED"
} elseif ($content.Contains($patched4)) {
    Write-Host "  ALREADY APPLIED"
} else {
    Write-Host "  NOT FOUND - pattern may have changed"
}

# ============================================================
# Patch 5: auto-continue-thinking
# ============================================================
Write-Host "[5/5] auto-continue-thinking..."
$original5 = 'if(V&&J){let e=M.localize("continue",{},"Continue");setTimeout(function(){ed()},50);return null}'
$patched5 = 'if(V&&J){let e=M.localize("continue",{},"Continue");setTimeout(()=>{ed()},50);return null}'

if ($content.Contains($original5) -and -not $content.Contains($patched5)) {
    $content = $content.Replace($original5, $patched5)
    $changes++
    Write-Host "  APPLIED"
} elseif ($content.Contains($patched5)) {
    Write-Host "  ALREADY APPLIED"
} else {
    Write-Host "  NOT FOUND - pattern may have changed"
}

# ============================================================
# Save and verify
# ============================================================
Write-Host "`n=== Saving changes ==="
if ($changes -gt 0) {
    Set-Content -Path $file -Value $content -NoNewline
    Write-Host "Saved $changes patches to file"
} else {
    Write-Host "No changes to save"
}

# ============================================================
# Verification
# ============================================================
Write-Host "`n=== Verification ==="
$verifyContent = Get-Content $file -Raw

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
    $matches = [regex]::Matches($verifyContent, $check.pattern)
    $status = if ($matches.Count -gt 0) { "PASS" } else { "FAIL" }
    Write-Host "$status - $($check.name)"
}

Write-Host "`n=== Done ==="