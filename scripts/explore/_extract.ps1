$c = [System.IO.File]::ReadAllText('D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js')
$anchor = "}async function FP(e){let t=uj.getInstance(),i=t.resolve(k1)"
$idx = $c.IndexOf($anchor)
if ($idx -ge 0) {
    $start = [Math]::Max(0, $idx - 800)
    $len = [Math]::Min(900, $c.Length - $start)
    $chunk = $c.Substring($start, $len)
    Write-Host $chunk
} else {
    Write-Host "ANCHOR NOT FOUND"
}
