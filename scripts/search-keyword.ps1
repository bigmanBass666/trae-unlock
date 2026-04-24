param(
    [Parameter(Mandatory=$true)]
    [string]$Keyword,
    [int]$ContextBefore = 80,
    [int]$ContextAfter = 120,
    [int]$MaxResults = 50
)
$path = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$c = [IO.File]::ReadAllText($path)
$idx = 0
$count = 0
while (($idx = $c.IndexOf($Keyword, $idx)) -ge 0) {
    $count++
    if ($count -gt $MaxResults) {
        Write-Output "... truncated at $MaxResults results (more exist)"
        break
    }
    $start = [Math]::Max(0, $idx - $ContextBefore)
    $totalLen = $ContextBefore + $Keyword.Length + $ContextAfter
    $len = [Math]::Min($totalLen, $c.Length - $start)
    $ctx = $c.Substring($start, $len)
    Write-Output "=== #${count} @ offset ${idx} ==="
    Write-Output $ctx
    Write-Output ""
    $idx += $Keyword.Length
}
Write-Output "TOTAL '${Keyword}' occurrences: ${count}"
