$file = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$content = Get-Content $file -Raw

# Search for loop detection patterns
$patterns = @(
    'LLM_STOP_DUP',
    'LLM_STOP',
    'STOP_DUP',
    'dup.*tool.*call',
    'duplicate.*tool',
    'loop.*detect',
    'efj\s*=\s*\[',
    'LLM.*ERROR'
)

Write-Host "Searching for bypass-loop-detection patterns...`n"
foreach ($pattern in $patterns) {
    $matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($matches.Count -gt 0) {
        Write-Host "Pattern '$pattern': $($matches.Count) matches"
        # Show first match context
        $m = $matches[0]
        $start = [Math]::Max(0, $m.Index - 100)
        $len = [Math]::Min(300, $content.Length - $start)
        Write-Host "  Context: $($content.Substring($start, $len))"
        Write-Host ""
    }
}

# Also search for the efj array definition
$pattern2 = 'var efj\s*=\s*\['
$matches2 = [regex]::Matches($content, $pattern2)
Write-Host "efj array definition: $($matches2.Count) matches"
foreach ($m in $matches2) {
    $start = $m.Index
    $len = [Math]::Min(500, $content.Length - $start)
    Write-Host "  $($content.Substring($start, $len))"
    Write-Host ""
}