$file = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$content = [System.IO.File]::ReadAllText($file)

$count = 0
$idx = 7490000
while ($idx -ge 0 -and $idx -lt 7520000) {
    $idx = $content.IndexOf("provideUserResponse", $idx + 1)
    if ($idx -ge 0 -and $idx -lt 7520000) {
        $count++
        Write-Host "`n=== Call #$count at pos: $idx ==="
        Write-Host $content.Substring([Math]::Max(0,$idx-150), 350)
    }
}
Write-Host "`nTotal: $count"
