$content = Get-Content 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Raw

# Search for NotifyUser or notification card patterns
$patterns = @(
    'NotifyUser',
    'notification.*card',
    'spec.*confirm',
    'document.*generated',
    '文档已经生成'
)

foreach ($pattern in $patterns) {
    $matches = [regex]::Matches($content, ".{0,100}$pattern.{0,100}")
    if ($matches.Count -gt 0) {
        Write-Host "=== Pattern: $pattern (Found: $($matches.Count)) ==="
        foreach ($m in $matches | Select-Object -First 2) {
            Write-Host $m.Value
            Write-Host ""
        }
    }
}