$file = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$content = Get-Content $file -Raw

# 搜索 auto-confirm-commands 的原始模式 - PlanItemStreamParser confirm_status 检查
$patterns = @(
    'confirm_status.*unconfirmed.*provideUserResponse',
    'e\?\.confirm_info.*confirm_status.*unconfirmed',
    'e\.confirm_info.*confirm_status.*unconfirmed',
    'confirm_status===.unconfirmed.',
    'confirm_status===..unconfirmed..',
    'confirm_status=="unconfirmed"'
)

foreach ($pattern in $patterns) {
    $matches = [regex]::Matches($content, $pattern)
    if ($matches.Count -gt 0) {
        Write-Host "FOUND with pattern: $pattern ($($matches.Count) matches)"
        $m = $matches[0]
        $start = [Math]::Max(0, $m.Index - 50)
        $end = [Math]::Min($content.Length, $m.Index + $m.Length + 200)
        Write-Host $content.Substring($start, $end - $start)
        Write-Host ""
    }
}