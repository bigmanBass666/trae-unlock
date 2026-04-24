$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")

Write-Output "========== handleCommonError =========="
$idx = 0
while ($true) {
    $idx = $c.IndexOf("handleCommonError", $idx)
    if ($idx -lt 0) { break }
    $start = [Math]::Max(0, $idx - 100)
    $len = [Math]::Min(300, $c.Length - $start)
    Write-Output "--- Offset ${idx} ---"
    Write-Output $c.Substring($start, $len)
    Write-Output ""
    $idx++
}

Write-Output "========== .exception= patterns =========="
$idx = 0
$count = 0
$search = ".exception={"
while ($true) {
    $idx = $c.IndexOf($search, $idx)
    if ($idx -lt 0) { break }
    $count++
    if ($count -le 15) {
        $start = [Math]::Max(0, $idx - 100)
        $len = [Math]::Min(250, $c.Length - $start)
        Write-Output "[${search}] #${count} Offset ${idx}:"
        Write-Output $c.Substring($start, $len)
        Write-Output ""
    }
    $idx++
}
Write-Output "[${search}] Total: ${count}"
Write-Output ""

Write-Output "========== setErrorInfo / updateMessageError =========="
$searches = @("setErrorInfo", "updateMessageError", "setException")
foreach ($p in $searches) {
    $idx = $c.IndexOf($p)
    if ($idx -ge 0) {
        $start = [Math]::Max(0, $idx - 80)
        $len = [Math]::Min(250, $c.Length - $start)
        Write-Output "[${p}] Offset ${idx}:"
        Write-Output $c.Substring($start, $len)
        Write-Output ""
    } else {
        Write-Output "[${p}] NOT FOUND"
        Write-Output ""
    }
}
