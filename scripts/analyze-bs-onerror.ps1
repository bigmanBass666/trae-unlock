$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")

Write-Output "========== Bs.onError (calls teaEventChatFail) - full context =========="
$bsIdx = $c.IndexOf("Bs.onError")
if ($bsIdx -ge 0) {
    # Find ALL Bs.onError occurrences
    $searchFrom = 0
    $count = 0
    while ($true) {
        $idx = $c.IndexOf("Bs.onError", $searchFrom)
        if ($idx -lt 0) { break }
        $count++
        $ctxStart = [Math]::Max(0, $idx - 20)
        $ctxLen = [Math]::Min(500, $c.Length - $ctxStart)
        Write-Output "[Bs.onerror #$count] Offset ${idx}:"
        Write-Output $c.Substring($ctxStart, $ctxLen)
        Write-Output ""
        $searchFrom = $idx + 1
    }
}

Write-Output "========== Search for: where does Bs get session info? this._session / this.currentSession / sessionId near Bs =========="
$bsRegionStart = 7542000
$bsRegionEnd = 7544000
$bsRegion = $c.Substring($bsRegionStart, $bsRegionEnd - $bsRegionStart)

# Search for session-related patterns in Bs class
$patterns = @("sessionId", "currentSession", "_session", "getSession", ".session")
foreach ($p in $patterns) {
    $pIdx = 0
    while ($true) {
        $pIdx = $bsRegion.IndexOf($p, $pIdx)
        if ($pIdx -lt 0) { break }
        $absIdx = $bsRegionStart + $pIdx
        $ctxS = [Math]::Max(0, $absIdx - 60)
        $ctxL = [Math]::Min(150, $c.Length - $ctxS)
        Write-Output "[${p}] at absolute ${absIdx}:"
        Write-Output $c.Substring($ctxS, $ctxL)
        Write-Output ""
        $pIdx++
    }
}
