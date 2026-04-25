param(
    [string]$Keyword,
    [int]$ContextBefore = 40,
    [int]$ContextAfter = 120,
    [int]$MaxResults = 80
)

$path = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$c = [IO.File]::ReadAllText($path)
Write-Host "File length: $($c.Length)"

$idx = 0
$count = 0
while (($idx = $c.IndexOf($Keyword, $idx)) -ge 0) {
    $count++
    $start = [Math]::Max(0, $idx - $ContextBefore)
    $len = [Math]::Min($ContextBefore + $ContextAfter, $c.Length - $start)
    $ctx = $c.Substring($start, $len).Replace([char]10, ' ').Replace([char]13, ' ')
    Write-Host "  #$count @${idx}: $ctx"
    $idx += $Keyword.Length
    if ($count -ge $MaxResults) {
        Write-Host "  ... (truncated at $MaxResults)"
        break
    }
}
Write-Host "Total '$Keyword': $count"
