$file = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$content = Get-Content $file -Raw

# Find the efh array (error handling array) - this is what we patched before
$pattern = 'let efh=\[kg\.SERVER_CRASH.*?\]'
$matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
Write-Host "Found efh array: $($matches.Count) matches"
if ($matches.Count -gt 0) {
    Write-Host $matches[0].Value
    Write-Host ""
}

# Also search for where kg.TASK_TURN_EXCEEDED_ERROR is used with includes
$pattern2 = 'efh\.includes\(_\)'
$matches2 = [regex]::Matches($content, $pattern2)
Write-Host "efh.includes(_) usage: $($matches2.Count) matches"
foreach ($m in $matches2) {
    $start = [Math]::Max(0, $m.Index - 200)
    $len = [Math]::Min(500, $content.Length - $start)
    Write-Host $content.Substring($start, $len)
    Write-Host ""
}