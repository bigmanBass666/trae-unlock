$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")

Write-Output "========== Search for subscribe patterns with currentSession.messages.length =========="
$patterns = @(
    'currentSession.*messages.*length.*currentSessionId',
    'messages.*length.*currentSessionId',
    '.subscribe((e,t)'
)
foreach ($p in $patterns) {
    $idx = 0
    while ($true) {
        $idx = $c.IndexOf($p, $idx)
        if ($idx -lt 0) { break }
        $start = [Math]::Max(0, $idx - 30)
        $len = [Math]::Min(200, $c.Length - $start)
        Write-Output "[${p}] Offset ${idx}:"
        Write-Output $c.Substring($start, $len)
        Write-Output ""
        $idx++
    }
}

Write-Output "========== Search for n.subscribe =========="
$idx2 = 0
$count = 0
while ($true) {
    $idx2 = $c.IndexOf("n.subscribe(", $idx2)
    if ($idx2 -lt 0) { break }
    $count++
    if ($count -le 15) {
        $s2 = [Math]::Max(0, $idx2 - 20)
        $l2 = [Math]::Min(250, $c.Length - $s2)
        Write-Output "[n.subscribe #${count}] Offset ${idx2}:"
        Write-Output $c.Substring($s2, $l2)
        Write-Output ""
    }
    $idx2++
}
Write-Output "Total n.subscribe: ${count}"
