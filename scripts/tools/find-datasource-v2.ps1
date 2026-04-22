$content = Get-Content 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Raw

# Find the exact data-source-auto-confirm pattern
$patterns = @(
    'i\.name!==CS\.AskUserQuestion',
    'o\.auto_confirm=!0',
    'o\.confirm_status="confirmed"'
)

foreach ($pattern in $patterns) {
    $matches = [regex]::Matches($content, ".{0,100}$pattern.{0,100}")
    Write-Host "=== Pattern: $pattern (Found: $($matches.Count)) ==="
    foreach ($m in $matches | Select-Object -First 3) {
        Write-Host $m.Value
        Write-Host ""
    }
}