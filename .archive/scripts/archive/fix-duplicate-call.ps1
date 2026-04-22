$file = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$content = [System.IO.File]::ReadAllText($file)

$oldStr = 'e.confirm_info&&(e.confirm_info.confirm_status="confirmed"))),(e?.toolName||e?.id||e?.toolCallId)&&(this._taskService.provideUserResponse({task_id:i||"",type:"tool_confirm",toolcall_id:e?.planItemId||e?.id||e?.toolCallId||"",tool_name:e?.toolName||"",decision:"confirm"}).catch(function(e){this._logService.warn("[PlanItemStreamParser] auto-confirm runcommand failed:",e)}))'

$newStr = 'e.confirm_info&&(e.confirm_info.confirm_status="confirmed")))'

$idx = $content.IndexOf($oldStr)
Write-Host "Found at: $idx"

if ($idx -ge 0) {
    $content = $content.Replace($oldStr, $newStr)
    [System.IO.File]::WriteAllText($file, $content)
    Write-Host "Fixed! Removed duplicate provideUserResponse call"
} else {
    Write-Host "Exact pattern not found. Trying position-based replacement..."
    $pos = 7503862
    $context = $content.Substring($pos - 50, 500)
    Write-Host "Context around pos $pos :"
    Write-Host $context
    
    $dupStart = $content.IndexOf('),(e?.toolName||e?.id||e?.toolCallId)&&(this._taskService.provideUserResponse', 7503700)
    Write-Host "`nDuplicate call starts at: $dupStart"
    if ($dupStart -ge 0) {
        $dupEnd = $content.IndexOf('))}', $dupStart) + 3
        Write-Host "Duplicate call ends at: $dupEnd"
        Write-Host "Will remove: $($dupEnd - $dupStart) chars"
        $content = $content.Substring(0, $dupStart) + $content.Substring($dupEnd)
        [System.IO.File]::WriteAllText($file, $content)
        Write-Host "Fixed by position!"
    }
}