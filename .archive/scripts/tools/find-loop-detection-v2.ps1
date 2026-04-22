$file = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$content = Get-Content $file -Raw

# The old pattern was: J=![...].includes(_)
# New version uses: J=!![...].includes(_) (double negation)
# Let's find it

$patterns = @(
    'J=!!\[.*LLM_STOP_DUP.*\]\.includes\(_\)',
    'J=!.*LLM_STOP_DUP.*\.includes',
    'J=.*LLM_STOP_DUP_TOOL_CALL.*includes',
    'LLM_STOP_DUP_TOOL_CALL.*TASK_TURN_EXCEEDED_ERROR'
)

foreach ($pattern in $patterns) {
    $matches = [regex]::Matches($content, $pattern)
    if ($matches.Count -gt 0) {
        Write-Host "Pattern: $pattern -> $($matches.Count) matches"
        $m = $matches[0]
        $start = [Math]::Max(0, $m.Index - 50)
        $len = [Math]::Min(300, $content.Length - $start)
        Write-Host "  $($content.Substring($start, $len))"
        Write-Host ""
    }
}