$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")
$idx = 0
while ($true) {
    $idx = $c.IndexOf("teaEventChatFail", $idx)
    if ($idx -lt 0) { break }
    $start = [Math]::Max(0, $idx - 200)
    $len = [Math]::Min(400, $c.Length - $start)
    Write-Output "=== Offset $idx ==="
    Write-Output $c.Substring($start, $len)
    Write-Output ""
    $idx++
}
