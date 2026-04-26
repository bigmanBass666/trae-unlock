$sourceFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$c = [System.IO.File]::ReadAllText($sourceFile)

Write-Host "=== WK object definition ==="
$wkMatches = [regex]::Matches($c, 'WK=(\{[^}]{0,500}\})')
foreach ($m in $wkMatches) {
    Write-Host "  WK definition @offset $($m.Index)"
    Write-Host "  $($m.Value.Substring(0, [Math]::Min(300, $m.Value.Length)))"
}

Write-Host "`n=== WK.IDocsetService value ==="
$idx = $c.IndexOf('WK.IDocsetService')
if ($idx -ge 0) {
    $before = $c.Substring([Math]::Max(0, $idx - 500), [Math]::Min(500, $idx))
    $after = $c.Substring($idx, [Math]::Min(200, $c.Length - $idx))
    if ($before -match 'WK=([^;]{0,300})') {
        Write-Host "  WK = $($Matches[1].Substring(0, [Math]::Min(200, $Matches[1].Length)))"
    }
}

Write-Host "`n=== Do and jP context ==="
$doIdx = $c.IndexOf('uJ({identifier:Do})')
if ($doIdx -ge 0) {
    $before = $c.Substring([Math]::Max(0, $doIdx - 300), [Math]::Min(300, $doIdx))
    Write-Host "Before Do: ...$($before.Substring($before.Length - 200))"
}

$jpIdx = $c.IndexOf('uJ({identifier:jP})')
if ($jpIdx -ge 0) {
    $before = $c.Substring([Math]::Max(0, $jpIdx - 300), [Math]::Min(300, $jpIdx))
    Write-Host "Before jP: ...$($before.Substring($before.Length - 200))"
}

Write-Host "`n=== Hx and HH context ==="
$hxIdx = $c.IndexOf('uJ({identifier:Hx})')
if ($hxIdx -ge 0) {
    $before = $c.Substring([Math]::Max(0, $hxIdx - 300), [Math]::Min(300, $hxIdx))
    Write-Host "Before Hx: ...$($before.Substring($before.Length - 200))"
}

$hhIdx = $c.IndexOf('uJ({identifier:HH})')
if ($hhIdx -ge 0) {
    $before = $c.Substring([Math]::Max(0, $hhIdx - 300), [Math]::Min(300, $hhIdx))
    Write-Host "Before HH: ...$($before.Substring($before.Length - 200))"
}
