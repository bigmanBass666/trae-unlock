$file = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$content = Get-Content $file -Raw

# Find the exact J=!![...].includes(_) pattern for loop detection
$pattern = 'J=!!\[kg\.MODEL_OUTPUT_TOO_LONG,kg\.TASK_TURN_EXCEEDED_ERROR\]\.includes\(_\)'
$matches = [regex]::Matches($content, $pattern)
Write-Host "Found J=!! pattern: $($matches.Count) matches"
if ($matches.Count -gt 0) {
    $m = $matches[0]
    $start = [Math]::Max(0, $m.Index - 200)
    $len = [Math]::Min(500, $content.Length - $start)
    Write-Host "Context:"
    Write-Host $content.Substring($start, $len)
    Write-Host ""
}

# Also search for kg.LLM_STOP_DUP_TOOL_CALL with includes
$pattern2 = 'kg\.LLM_STOP_DUP_TOOL_CALL.*includes\(_\)'
$matches2 = [regex]::Matches($content, $pattern2)
Write-Host "`nFound LLM_STOP_DUP with includes: $($matches2.Count) matches"
foreach ($m in $matches2) {
    $start = [Math]::Max(0, $m.Index - 300)
    $len = [Math]::Min(500, $content.Length - $start)
    Write-Host $content.Substring($start, $len)
    Write-Host ""
}

# Search for the variable assignment that sets J based on loop detection
$pattern3 = 'J=.*kg\..*\.includes\(_\)'
$matches3 = [regex]::Matches($content, $pattern3)
Write-Host "`nFound J=.*includes pattern: $($matches3.Count) matches"
foreach ($m in $matches3) {
    Write-Host "Match at index: $($m.Index)"
    Write-Host "Value: $($m.Value)"
    Write-Host ""
}