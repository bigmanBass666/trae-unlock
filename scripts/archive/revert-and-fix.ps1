$content = Get-Content 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Raw

# Step 1: 撤销 UI 层错误补丁 (恢复原始渲染逻辑)
$find = 'false)?sX().createElement(Cr.NotifyUserCard,{title:r("Confirm Execution")'
$replace = '(e||b)&&!w)?sX().createElement(Cr.NotifyUserCard,{title:r("Confirm Execution")'

if ($content.Contains($find)) {
    Write-Host "✅ Found wrong UI patch, reverting..."
    $content = $content.Replace($find, $replace)
    Write-Host "✅ UI patch reverted!"
} else {
    Write-Host "⚠️ Wrong UI patch not found (maybe already clean?)"
}

# Step 2: 修复 data-source-auto-confirm v3 - 从黑名单移除 NotifyUser
$find2 = 'o?.confirm_status==="unconfirmed"&&i.name!==CS.AskUserQuestion&&i.name!==CS.NotifyUser&&i.name!==CS.ExitPlanMode&&(o.auto_confirm=!0,o.confirm_status="confirmed")'
$replace2 = 'o?.confirm_status==="unconfirmed"&&i.name!==CS.AskUserQuestion&&i.name!==CS.ExitPlanMode&&(o.auto_confirm=!0,o.confirm_status="confirmed")'

if ($content.Contains($find2)) {
    Write-Host "✅ Found data-source-auto-confirm v2, fixing to v3..."
    $content = $content.Replace($find2, $replace2)
    Write-Host "✅ data-source-auto-confirm v3 applied (NotifyUser removed from blacklist)!"
} else {
    Write-Host "❌ data-source-auto-confirm v2 not found!"
}

Set-Content -Path 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Value $content -NoNewline
Write-Host "✅ All patches applied! Please restart Trae to test."