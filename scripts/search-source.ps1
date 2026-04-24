param(
    [string]$Keyword,
    [int]$Context = 150,
    [int]$MaxResults = 200
)
$path = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$c = [IO.File]::ReadAllText($path)
$idx = 0
$count = 0
while (($idx = $c.IndexOf($Keyword, $idx)) -ge 0) {
    $count++
    if ($count -gt $MaxResults) { break }
    $start = [Math]::Max(0, $idx - 80)
    $len = [Math]::Min($Context, $c.Length - $start)
    Write-Output "=== #$count @ $idx ==="
    Write-Output $c.Substring($start, $len)
    Write-Output ""
    $idx += $Keyword.Length
}
Write-Output "TOTAL: $count"
