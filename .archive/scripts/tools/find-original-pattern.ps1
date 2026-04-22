$content = Get-Content 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Raw

# Search for the original DG.parse location where data-source-auto-confirm should be
$pattern = 'i\.name!==CS\.ViewFiles'
$matches = [regex]::Matches($content, ".{0,200}$pattern.{0,200}")
Write-Host "Found $($matches.Count) matches for ViewFiles pattern"
foreach ($m in $matches | Select-Object -First 3) {
    Write-Host "=== Match ==="
    Write-Host $m.Value
    Write-Host ""
}

# Also check for CS enumeration
$pattern2 = 'CS\.\('
$matches2 = [regex]::Matches($content, ".{0,100}$pattern2.{0,100}")
Write-Host "`nFound $($matches2.Count) matches for CS enumeration"
foreach ($m in $matches2 | Select-Object -First 2) {
    Write-Host "=== Match ==="
    Write-Host $m.Value
    Write-Host ""
}