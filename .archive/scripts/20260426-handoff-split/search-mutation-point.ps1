$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")

Write-Output "========== getErrorInfoWithError (the .exception= mutation) =========="
$idx = $c.IndexOf("getErrorInfoWithError")
$start = [Math]::Max(0, $idx - 200)
$len = [Math]::Min(600, $c.Length - $start)
Write-Output "Definition Offset: ${idx}"
Write-Output $c.Substring($start, $len)
Write-Output ""

Write-Output "========== All callers of getErrorInfoWithError =========="
$idx2 = 0
while ($true) {
    $idx2 = $c.IndexOf("getErrorInfoWithError", $idx2)
    if ($idx2 -lt 0) { break }
    $start2 = [Math]::Max(0, $idx2 - 150)
    $len2 = [Math]::Min(300, $c.Length - $start2)
    Write-Output "--- Caller Offset ${idx2} ---"
    Write-Output $c.Substring($start2, $len2)
    Write-Output ""
    $idx2++
}

Write-Output "========== getErrorInfo (similar, might be related) =========="
$idx3 = 0
$count3 = 0
while ($true) {
    $idx3 = $c.IndexOf("getErrorInfo(", $idx3)
    if ($idx3 -lt 0) { break }
    $count3++
    if ($count3 -le 8) {
        $start3 = [Math]::Max(0, $idx3 - 80)
        $len3 = [Math]::Min(200, $c.Length - $start3)
        Write-Output "[${count3}] Offset ${idx3}:"
        Write-Output $c.Substring($start3, $len3)
        Write-Output ""
    }
    $idx3++
}

Write-Output "========== updateMessage / setMessage (Store operations) =========="
$searches = @("updateMessage(", "setMessage(")
foreach ($p in $searches) {
    $idx4 = 0
    $count4 = 0
    while ($true) {
        $idx4 = $c.IndexOf($p, $idx4)
        if ($idx4 -lt 0) { break }
        $count4++
        if ($count4 -le 5) {
            $start4 = [Math]::Max(0, $idx4 - 80)
            $len4 = [Math]::Min(250, $c.Length - $start4)
            Write-Output "[${p}] #${count4} Offset ${idx4}:"
            Write-Output $c.Substring($start4, $len4)
            Write-Output ""
        }
        $idx4++
    }
    Write-Output "[${p}] Total: ${count4}"
    Write-Output ""
}
