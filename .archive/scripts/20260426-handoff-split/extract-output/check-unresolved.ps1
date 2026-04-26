$sourceFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$c = [System.IO.File]::ReadAllText($sourceFile)

$offsets = @(7045862, 7155062, 7227161, 7303131, 7475995, 7573743, 7668855, 7749472, 7769113, 7841713, 7859447)

foreach ($off in $offsets) {
    $ctx = $c.Substring($off, [Math]::Min(300, $c.Length - $off))
    Write-Host "=== @${off} ==="
    Write-Host $ctx
    Write-Host ""
}
