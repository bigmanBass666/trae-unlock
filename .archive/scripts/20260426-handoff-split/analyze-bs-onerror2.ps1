$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")

Write-Output "========== Bs.onError method - find and show full implementation =========="
# Bs is ErrorStreamParser or ChatStreamService. Search for onError near the teaEventChatFail call
$targetRegionStart = 7542400
$targetRegionEnd = 7542800

# Find "onError" in this region
$region = $c.Substring($targetRegionStart, $targetRegionEnd - $targetRegionStart)
$onErrorIdx = $region.IndexOf("onError")
if ($onErrorIdx -ge 0) {
    $absOnError = $targetRegionStart + $onErrorIdx
    Write-Output "onError found at absolute offset: ${absOnError}"
    # Show from onError to end of this function (approx 500 chars)
    $ctxLen = [Math]::Min(600, $c.Length - $absOnError)
    Write-Output $c.Substring($absOnError, $ctxLen)
}

Write-Output ""
Write-Output "========== Also: search for ALL onError methods that call/have error_code/4000002 nearby =========="
$searchFrom = 0
while ($true) {
    $idx = $c.IndexOf("onError(", $searchFrom)
    if ($idx -lt 0) { break }
    # Check if this one has teaEventChatFail within 200 chars after
    $afterEnd = [Math]::Min($idx + 300, $c.Length)
    $afterText = $c.Substring($idx, $afterEnd - $idx)
    if ($afterText.Contains("teaEventChatFail") -or $afterText.Contains("4000002") -or $afterText.Contains("exceeded")) {
        $ctxS = [Math]::Max(0, $idx - 30)
        $ctxL = [Math]::Min(350, $c.Length - $ctxS)
        Write-Output "[onError with error handling] at ${idx}:"
        Write-Output $c.Substring($ctxS, $ctxL)
        Write-Output ""
    }
    $searchFrom = $idx + 1
}

Write-Output ""
Write-Output "========== KEY: what vars are available at the teaEventChatFail CALL site? (@7542473 area) =========="
$callSite = 7542400
$callCtx = $c.Substring($callSite, 500)
Write-Output $callCtx

Write-Output ""
Write-Output "========== Search for 'this.' patterns near Bs.onError that give session info =========="
# In Bs class definition area, look for session-related properties
$bsClassStart = 7541500
$bsClassEnd = 7545000
$bsClass = $c.Substring($bsClassStart, $bsClassEnd - $bsClassStart)

$thisPatterns = @("this._session", "this.session", "this.currentSession", "this.storeService", "this._store")
foreach ($p in $thisPatterns) {
    $pi = 0
    while ($true) {
        $pi = $bsClass.IndexOf($p, $pi)
        if ($pi -lt 0) { break }
        $absPi = $bsClassStart + $pi
        $cs = [Math]::Max(0, $absPi - 40)
        $cl = [Math]::Min(120, $c.Length - $cs)
        Write-Output "[${p}] at ${absPi}:"
        Write-Output $c.Substring($cs, $cl)
        Write-Output ""
        $pi++
    }
}
