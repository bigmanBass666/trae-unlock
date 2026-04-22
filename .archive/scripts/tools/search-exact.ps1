$content = Get-Content 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Raw

# Find the exact pattern with escaped quotes
$pattern = 'REJECTED:b\|\|"unconfirmed"'
$matches = [regex]::Matches($content, ".{0,1500}$pattern.{0,500}", [System.Text.RegularExpressions.RegexOptions]::Singleline)
Write-Host "Found $($matches.Count) matches"
foreach ($m in $matches) {
    Write-Host "=== Full Context ==="
    Write-Host $m.Value
    Write-Host ""
}