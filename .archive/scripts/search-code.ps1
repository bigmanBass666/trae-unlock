$c = [System.IO.File]::ReadAllText('D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js')

$oldCode = ',(e?.toolName||e?.id||e?.toolCallId)&&(this._taskService.provideUserResponse({task_id:i||"",type:"tool_confirm",toolcall_id:e?.planItemId||e?.id||e?.toolCallId||"",tool_name:e?.toolName||"",decision:"confirm"}).catch(function(e){this._logService.warn("[PlanItemStreamParser] auto-confirm runcommand failed:",e)}))'

$idx = $c.IndexOf($oldCode)
Write-Host "Old code found at offset: $idx"
Write-Host "Old code length: $($oldCode.Length)"

if($idx -ge 0){
    $start = [Math]::Max(0, $idx - 50)
    $len = [Math]::Min(100, $c.Length - $start)
    Write-Host "Before: $($c.Substring($start, $len - $oldCode.Length + 50))"
    Write-Host ""
    $afterIdx = $idx + $oldCode.Length
    $afterLen = [Math]::Min(50, $c.Length - $afterIdx)
    Write-Host "After: $($c.Substring($afterIdx, $afterLen))"
}
