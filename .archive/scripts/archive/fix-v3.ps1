$content = Get-Content 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Raw

# Fix: 从黑名单移除 NotifyUser (v2 -> v3)
$find = 'o?.confirm_status==="unconfirmed"&&i.name!==CS.AskUserQuestion&&i.name!==CS.NotifyUser&&i.name!==CS.ExitPlanMode&&(o.auto_confirm=!0,o.confirm_status="confirmed")'
$replace = 'o?.confirm_status==="unconfirmed"&&i.name!==CS.AskUserQuestion&&i.name!==CS.ExitPlanMode&&(o.auto_confirm=!0,o.confirm_status="confirmed")'

if ($content.Contains($find)) {
    Write-Host "Found v2, applying v3 fix..."
    $content = $content.Replace($find, $replace)
    Set-Content -Path 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Value $content -NoNewline
    
    # Verify
    $verify = Get-Content 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Raw
    if ($verify.Contains($replace)) {
        Write-Host "SUCCESS: data-source-auto-confirm v3 applied!"
        Write-Host "New blacklist: AskUserQuestion, ExitPlanMode (NotifyUser removed)"
    } else {
        Write-Host "FAIL: verification failed!"
    }
} elseif ($content.Contains('o?.confirm_status==="unconfirmed"&&i.name!==CS.AskUserQuestion&&i.name!==CS.ExitPlanMode&&(o.auto_confirm=!0,o.confirm_status="confirmed")')) {
    Write-Host "ALREADY: v3 is already applied!"
} else {
    Write-Host "NOT FOUND: pattern not found. Checking current state..."
    $check = [regex]::Matches($content, 'o\?\.confirm_status===.{0,200}')
    foreach ($m in $check) { Write-Host $m.Value }
}