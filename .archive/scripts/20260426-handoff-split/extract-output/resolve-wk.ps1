$sourceFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$c = [System.IO.File]::ReadAllText($sourceFile)

Write-Host "=== Searching for WK definition ==="
$wkIdx = $c.IndexOf('WK=')
while ($wkIdx -ge 0 -and $wkIdx -lt 7800000) {
    $ctx = $c.Substring($wkIdx, [Math]::Min(200, $c.Length - $wkIdx))
    if ($ctx -match 'WK=\{') {
        Write-Host "  WK object @offset $wkIdx"
        Write-Host "  $ctx"
        Write-Host ""
        break
    }
    $wkIdx = $c.IndexOf('WK=', $wkIdx + 3)
}

Write-Host "=== Searching for WK. properties ==="
$wkProps = [regex]::Matches($c, 'WK\.(\w+)')
$uniqueProps = $wkProps | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
Write-Host "WK properties: $($uniqueProps -join ', ')"

Write-Host "`n=== Searching for ai.IDocsetService ==="
$idx = $c.IndexOf('ai.IDocsetService')
if ($idx -ge 0) {
    $ctx = $c.Substring([Math]::Max(0, $idx - 100), [Math]::Min(300, $c.Length - [Math]::Max(0, $idx - 100)))
    Write-Host $ctx
}
