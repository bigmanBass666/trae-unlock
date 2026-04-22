$content = Get-Content 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Raw

# Find the full context around NotifyUserCard to understand variable definitions
$pattern = "TaskExecutionStatusEnum\.REJECTED:b\|\|""unconfirmed"""
$matches = [regex]::Matches($content, ".{0,1000}$pattern.{0,1000}", [System.Text.RegularExpressions.RegexOptions]::Singleline)
Write-Host "Found $($matches.Count) matches"
foreach ($m in $matches) {
    Write-Host "=== Full Context ==="
    Write-Host $m.Value
    Write-Host ""
}