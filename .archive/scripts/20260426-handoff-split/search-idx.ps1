param([string]$Search,[int]$Context=120,[int]$MaxResults=30)
$path='D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$c=[IO.File]::ReadAllText($path)
$idx=0
$count=0
while(($idx=$c.IndexOf($Search,$idx)) -gt 0 -and $count -lt $MaxResults){
    $start=[Math]::Max(0,$idx-$Context)
    $len=[Math]::Min($Context*2+$Search.Length,$c.Length-$start)
    $ctx=$c.Substring($start,$len)
    Write-Output "=== @ $idx ==="
    Write-Output $ctx
    Write-Output ""
    $idx+=$Search.Length
    $count++
}
Write-Output "Total: $count matches"
