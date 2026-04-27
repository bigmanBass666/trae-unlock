param([string]$Search)
$c = [System.IO.File]::ReadAllText('D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js')
$idx = $c.IndexOf($Search)
if ($idx -ge 0) {
    Write-Host "Found at offset $idx"
    $start = [Math]::Max(0, $idx - 100)
    $len = [Math]::Min(500, $c.Length - $start)
    Write-Host $c.Substring($start, $len)
} else {
    Write-Host "NOT FOUND: $Search"
}
