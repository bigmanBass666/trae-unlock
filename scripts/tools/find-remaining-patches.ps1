$file = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$content = Get-Content $file -Raw

# Find auto-continue-thinking pattern - the setTimeout(ed()) pattern
$patterns = @(
    'setTimeout.*ed\(\)',
    'M\.localize.*continue.*Continue',
    'kg\.LLM_STOP',
    'J=.*includes\(_\)',
    'kg\.MODEL_OUTPUT_TOO_LONG'
)

foreach ($pattern in $patterns) {
    $matches = [regex]::Matches($content, ".{0,100}$pattern.{0,100}")
    if ($matches.Count -gt 0) {
        Write-Host "=== Pattern: $pattern ($($matches.Count) matches) ==="
        foreach ($m in $matches | Select-Object -First 3) {
            Write-Host $m.Value
            Write-Host ""
        }
    }
}