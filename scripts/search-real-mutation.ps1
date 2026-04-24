$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")

Write-Output "========== Spread/merge patterns that could write exception =========="
$patterns = @(
    "...e.error",           # spread error object
    'exception:e',          # shorthand property with error var
    'exception:t',          # shorthand with t var
    'exception:',           # colon after exception in object literal
    '"exception":',         # quoted key
    'errorInfo:',           # might set via errorInfo
    '.errorInfo='           # assignment
)
foreach ($p in $patterns) {
    $idx = 0
    $count = 0
    while ($true) {
        $idx = $c.IndexOf($p, $idx)
        if ($idx -lt 0) { break }
        $count++
        if ($count -le 8) {
            $start = [Math]::Max(0, $idx - 80)
            $len = [Math]::Min(200, $c.Length - $start)
            Write-Output "[${p}] #${count} Offset ${idx}:"
            Write-Output $c.Substring($start, $len)
            Write-Output ""
        }
        $idx++
    }
    Write-Output "[${p}] Total: ${count}`n"
}

Write-Output "========== updateMessage / updateLastMessage calls =========="
$patterns2 = @("updateMessage(", "updateLastMessage(")
foreach ($p in $patterns2) {
    $idx = 0
    $count2 = 0
    while ($true) {
        $idx = $c.IndexOf($p, $idx)
        if ($idx -lt 0) { break }
        $count2++
        if ($count2 -le 15) {
            $start2 = [Math]::Max(0, $idx - 30)
            $len2 = [Math]::Min(250, $c.Length - $start2)
            Write-Output "[${p}] #${count2} Offset ${idx2}:"
            Write-Output $c.Substring($start2, $len2)
            Write-Output ""
        }
        $idx++
    }
    Write-Output "[${p}] Total: ${count2}`n"
}

Write-Output "========== setState patterns near message/error handling =========="
$patterns3 = @("setState({", "setState((state")
foreach ($p in $patterns3) {
    $idx3 = 0
    $count3 = 0
    while ($true) {
        $idx3 = $c.IndexOf($p, $idx3)
        if ($idx3 -lt 0) { break }
        $count3++
        if ($count3 -le 10) {
            $start3 = [Math]::Max(0, $idx3 - 50)
            $len3 = [Math]::Min(250, $c.Length - $start3)
            Write-Output "[${p}] #${count3} Offset ${idx3}:"
            Write-Output $c.Substring($start3, $len3)
            Write-Output ""
        }
        $idx3++
    }
}
