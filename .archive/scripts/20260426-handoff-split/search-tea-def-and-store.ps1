$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")

Write-Output "========== teaEventChatFail definition =========="
$idx = $c.IndexOf("teaEventChatFail(")
if ($idx -ge 0) {
    $start = [Math]::Max(0, $idx - 30)
    $len = [Math]::Min(400, $c.Length - $start)
    Write-Output "Offset ${idx}:"
    Write-Output $c.Substring($start, $len)
}
Write-Output ""

Write-Output "========== setCurrentSession (Store writer) - first 10 =========="
$target = "setCurrentSession("
$searchIdx = 0
$count = 0
while ($count -lt 10) {
    $searchIdx = $c.IndexOf($target, $searchIdx)
    if ($searchIdx -lt 0) { break }
    $ctxStart = [Math]::Max(0, $searchIdx - 60)
    $ctxLen = [Math]::Min(200, $c.Length - $ctxStart)
    Write-Output "[#${count+1}] Offset ${searchIdx}:"
    Write-Output $c.Substring($ctxStart, $ctxLen)
    Write-Output ""
    $count++
    $searchIdx++
}

Write-Output "========== GZt / createError patterns (from main process stack trace) =========="
$patternsGZt = @("GZt", "createError", "iCubeAgentService")
foreach ($p in $patternsGZt) {
    $gi = $c.IndexOf($p)
    if ($gi -ge 0) {
        $gs = [Math]::Max(0, $gi - 60)
        $gl = [Math]::Min(200, $c.Length - $gs)
        Write-Output "[${p}] Offset ${gi}:"
        Write-Output $c.Substring($gs, $gl)
        Write-Output ""
    }
}

Write-Output "========== Check: who calls teaEventChatFail with error info? Search backwards from definition =========="
Write-Output "(teaEventChatFail likely receives error code as param)"
