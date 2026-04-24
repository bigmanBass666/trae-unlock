$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")

Write-Output "========== ALL .exception patterns (broader search) =========="
$patterns = @(".exception=", ".exception:", ".exception[", '["exception"]', '"exception":')
foreach ($p in $patterns) {
    $idx = 0
    $count = 0
    while ($true) {
        $idx = $c.IndexOf($p, $idx)
        if ($idx -lt 0) { break }
        $count++
        if ($count -le 10) {
            $start = [Math]::Max(0, $idx - 60)
            $len = [Math]::Min(150, $c.Length - $start)
            Write-Output "[${p}] #${count} Offset ${idx}:"
            Write-Output $c.Substring($start, $len)
            Write-Output ""
        }
        $idx++
    }
    Write-Output "[${p}] Total: ${count}"
    Write-Output ""
}

Write-Output "========== immer/produce patterns (indirect mutation) =========="
$patterns2 = @("produce(", "draft.exception", "state.exception", "currentSession.*exception", "messages.*exception", ".exception =", "exception :")
foreach ($p in $patterns2) {
    $idx = 0
    $count2 = 0
    while ($true) {
        $idx = $c.IndexOf($p, $idx)
        if ($idx -lt 0) { break }
        $count2++
        if ($count2 -le 5) {
            $start2 = [Math]::Max(0, $idx - 60)
            $len2 = [Math]::Min(150, $c.Length - $start2)
            Write-Output "[${p}] #${count2} Offset ${idx}:"
            Write-Output $c.Substring($start2, $len2)
            Write-Output ""
        }
        $idx++
    }
    if ($count2 -gt 0) { Write-Output "[${p}] Total: ${count2}`n" }
}

Write-Output "========== setError / setException / withError patterns =========="
$patterns3 = @("setErrorInfo", "setException", "withError", "markAsError", "setFailed", "failMessage", "errorOut")
foreach ($p in $patterns3) {
    $idx3 = $c.IndexOf($p)
    if ($idx3 -ge 0) {
        $start3 = [Math]::Max(0, $idx3 - 80)
        $len3 = [Math]::Min(200, $c.Length - $start3)
        Write-Output "[${p}] Offset ${idx3}:"
        Write-Output $c.Substring($start3, $len3)
        Write-Output ""
    }
}

Write-Output "========== TASK_TURN_EXCEEDED or turn_exceeded patterns =========="
$patterns4 = @("TASK_TURN_EXCEEDED", "turn_exceeded", "exceed.*turn", "max.*turn")
foreach ($p in $patterns4) {
    $idx4 = $c.IndexOf($p, [System.StringComparison]::OrdinalIgnoreCase)
    if ($idx4 -ge 0) {
        $start4 = [Math]::Max(0, $idx4 - 80)
        $len4 = [Math]::Min(200, $c.Length - $start4)
        Write-Output "[${p}] Offset ${idx4}:"
        Write-Output $c.Substring($start4, $len4)
        Write-Output ""
    }
}
