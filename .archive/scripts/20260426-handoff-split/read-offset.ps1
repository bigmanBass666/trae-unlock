param(
    [string]$Keyword,
    [int]$Offset,
    [int]$Length = 500
)

$path = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$c = [IO.File]::ReadAllText($path)
$start = [Math]::Max(0, $Offset)
$len = [Math]::Min($Length, $c.Length - $start)
$ctx = $c.Substring($start, $len).Replace([char]10, ' ').Replace([char]13, ' ')
Write-Host "=== Offset $start, Length $len ==="
Write-Host $ctx
