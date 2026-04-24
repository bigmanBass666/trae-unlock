$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")

Write-Output "========== teaEventChatFail definition + context =========="
$idx = $c.IndexOf("teaEventChatFail(")
if ($idx -ge 0) {
    $start = [Math]::Max(0, $idx - 50)
    $len = [Math]::Min(500, $c.Length - $start)
    Write-Output "Definition Offset: ${idx}"
    Write-Output $c.Substring($start, $len)
}
Write-Output ""

Write-Output "========== IPC / bridge / onMessage patterns that could receive error from main process =========="
$patterns = @(
    "ipcRenderer",
    "ipc.on(",
    'ipcRenderer.on(',
    "receive(",
    "onMessage(",
    "$_onMessage",
    "__onMessage",
    "handleIPC",
    "bridge",
    "electronIpc"
)
foreach ($p in $patterns) {
    $idx2 = 0
    $count = 0
    while ($true) {
        $idx2 = $c.IndexOf($p, $idx2)
        if ($idx2 -lt 0) { break }
        $count++
        if ($count -le 5) {
            $start2 = [Math]::Max(0, $idx2 - 60)
            $len2 = [Math]::Min(200, $c.Length - $start2)
            Write-Output "[${p}] #${count} Offset ${idx2}:"
            Write-Output $c.Substring($start2, $len2)
            Write-Output ""
        }
        $idx2++
    }
    if ($count -gt 0) { Write-Output "[${p}] Total: ${count}`n" } else { Write-Output "[${p}] NOT FOUND`n" }
}

Write-Output "========== setCurrentSession (the ultimate Store writer) =========="
$idx3 = 0
$count3 = 0
while ($true) {
    $idx3 = $c.IndexOf("setCurrentSession", $idx3)
    if ($idx3 -lt 0) { break }
    $count3++
    if ($count3 -le 15) {
        $start3 = [Math]::Max(0, $idx3 - 40)
        $len3 = [Math]::Min(200, $c.Length - $start3)
        Write-Output "[#${count3}] Offset ${idx3}:"
        Write-Output $c.Substring($start3, $len3)
        Write-Output ""
    }
    $idx3++
}
