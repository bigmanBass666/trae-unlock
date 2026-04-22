$content = Get-Content 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Raw

# Search for the NotifyUserCard rendering condition
$pattern = "NotifyUserCard\{.*Documents have been generated"
$matches = [regex]::Matches($content, ".{0,500}$pattern.{0,500}", [System.Text.RegularExpressions.RegexOptions]::Singleline)
Write-Host "Found $($matches.Count) matches"
foreach ($m in $matches) {
    Write-Host "=== Full Context ==="
    Write-Host $m.Value
    Write-Host ""
}

# Also search for the condition (e||b)&&!w
$pattern2 = "\(e\|\|b\)&&!w"
$matches2 = [regex]::Matches($content, ".{0,200}$pattern2.{0,200}")
Write-Host "`nFound $($matches2.Count) matches for condition"
foreach ($m in $matches2) {
    Write-Host "=== Condition Context ==="
    Write-Host $m.Value
    Write-Host ""
}