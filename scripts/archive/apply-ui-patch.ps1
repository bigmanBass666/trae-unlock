$content = Get-Content 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Raw

# The exact pattern to find and replace
$find = '(e||b)&&!w)?sX().createElement(Cr.NotifyUserCard,{title:r("Confirm Execution")'
$replace = 'false)?sX().createElement(Cr.NotifyUserCard,{title:r("Confirm Execution")'

if ($content.Contains($find)) {
    Write-Host "✅ Found target pattern at position: $($content.IndexOf($find))"
    
    # Apply the patch
    $newContent = $content.Replace($find, $replace)
    Set-Content -Path 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Value $newContent -NoNewline
    
    Write-Host "✅ Patch applied successfully!"
    
    # Verify
    $verify = Get-Content 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js' -Raw
    if ($verify.Contains($replace)) {
        Write-Host "✅ Verification passed!"
    } else {
        Write-Host "❌ Verification failed!"
    }
} else {
    Write-Host "❌ Target pattern not found!"
}