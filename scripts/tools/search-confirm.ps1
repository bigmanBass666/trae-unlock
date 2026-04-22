$content = Get-Content 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Raw
$matches = [regex]::Matches($content, '.{0,200}confirm_status.{0,200}')
Write-Host "Found $($matches.Count) matches for confirm_status"
foreach ($m in $matches | Select-Object -First 3) {
    Write-Host "=== Match ==="
    Write-Host $m.Value
    Write-Host ""
}