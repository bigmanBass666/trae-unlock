$content = Get-Content 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Raw

# Search for the specific spec confirmation dialog pattern
$pattern = "Documents have been generated"
$matches = [regex]::Matches($content, ".{0,300}$pattern.{0,300}")
Write-Host "Found $($matches.Count) matches for spec dialog"
foreach ($m in $matches) {
    Write-Host "=== Match ==="
    Write-Host $m.Value
    Write-Host ""
}

# Also search for NotifyUserCard or similar component
$pattern2 = "NotifyUser"
$matches2 = [regex]::Matches($content, ".{0,200}$pattern2.{0,200}")
Write-Host "`nFound $($matches2.Count) matches for NotifyUser"
foreach ($m in $matches2 | Select-Object -First 3) {
    Write-Host "=== Match ==="
    Write-Host $m.Value
    Write-Host ""
}