$content = Get-Content 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Raw

# Find the exact position of (e||b)&&!w condition
$pattern = '\(e\|\|b\)&&!w\)'
$matches = [regex]::Matches($content, $pattern)
Write-Host "Found $($matches.Count) matches at positions:"
foreach ($m in $matches) {
    Write-Host "Position: $($m.Index)"
    Write-Host "Length: $($m.Length)"
    
    # Get surrounding context
    $start = [Math]::Max(0, $m.Index - 100)
    $length = [Math]::Min(200, $content.Length - $start)
    $context = $content.Substring($start, $length)
    Write-Host "Context: ...$context..."
    Write-Host ""
}