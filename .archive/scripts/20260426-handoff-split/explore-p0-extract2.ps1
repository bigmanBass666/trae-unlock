$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$c = [System.IO.File]::ReadAllText($TargetFile)

Write-Host "=== API Config JSON ===" -ForegroundColor Cyan
$jsonMarker = "e.exports=JSON.parse('"
$jsonStart = $c.IndexOf($jsonMarker, 5870400)
if ($jsonStart -gt 0) {
    $searchFrom = $jsonStart + $jsonMarker.Length
    $depth = 1
    $pos = $searchFrom
    $found = $false
    while ($pos -lt $c.Length -and $depth -gt 0) {
        $ch = $c[$pos]
        if ($ch -eq '{') { $depth++ }
        elseif ($ch -eq '}') { 
            $depth--
            if ($depth -eq 0) { $found = $true; break }
        }
        $pos++
    }
    if ($found) {
        $json = $c.Substring($searchFrom, $pos - $searchFrom + 1)
        Write-Host "JSON length: $($json.Length) chars"
        Write-Host $json
    } else {
        Write-Host "Could not find end of JSON (depth=$depth)"
    }
} else {
    Write-Host "Could not find JSON.parse start"
}

Write-Host "`n=== Error codes in P0 range ===" -ForegroundColor Cyan
$errStart = $c.IndexOf("CONNECTION_ERROR=1]", 54000)
if ($errStart -gt 0) {
    $ctx = $c.Substring([Math]::Max(0, $errStart - 200), 3000) -replace "`n", " " -replace "`r", ""
    Write-Host "Error codes context:"
    Write-Host $ctx
}

Write-Host "`n=== icube_devtool_vscode area ===" -ForegroundColor Cyan
$devIdx = $c.IndexOf("__icube_devtool_vscode__", 5890000)
if ($devIdx -gt 0) {
    $ctx = $c.Substring([Math]::Max(0, $devIdx - 500), 2000) -replace "`n", " " -replace "`r", ""
    Write-Host "icube_devtool_vscode (@$devIdx):"
    Write-Host $ctx
}

Write-Host "`n=== vscodeService area ===" -ForegroundColor Cyan
$vsIdx = $c.IndexOf("window.vscodeService", 5890000)
if ($vsIdx -gt 0) {
    $ctx = $c.Substring([Math]::Max(0, $vsIdx - 300), 1500) -replace "`n", " " -replace "`r", ""
    Write-Host "vscodeService (@$vsIdx):"
    Write-Host $ctx
}

Write-Host "`n=== RegisterContextResolverRequest ===" -ForegroundColor Cyan
$regCtxIdx = $c.IndexOf("RegisterContextResolverRequest", 95000)
if ($regCtxIdx -gt 0) {
    $ctx = $c.Substring($regCtxIdx, [Math]::Min(500, $c.Length - $regCtxIdx)) -replace "`n", " " -replace "`r", ""
    Write-Host "RegisterContextResolverRequest (@$regCtxIdx):"
    Write-Host $ctx
}

Write-Host "`n=== WorktreeInvalidDialog area ===" -ForegroundColor Cyan
$wtIdx = $c.IndexOf("WorktreeInvalidDialog", 2535000)
if ($wtIdx -gt 0) {
    $ctx = $c.Substring([Math]::Max(0, $wtIdx - 200), 1000) -replace "`n", " " -replace "`r", ""
    Write-Host "WorktreeInvalidDialog (@$wtIdx):"
    Write-Host $ctx
}

Write-Host "`n=== Chat input Lexical commands ===" -ForegroundColor Cyan
$lexCmdIdx = $c.IndexOf("ADD_WORKSPACE_MENTION_SYMBOL", 2834000)
if ($lexCmdIdx -gt 0) {
    $ctx = $c.Substring([Math]::Max(0, $lexCmdIdx - 200), 2000) -replace "`n", " " -replace "`r", ""
    Write-Host "Lexical commands (@$lexCmdIdx):"
    Write-Host $ctx
}

Write-Host "`n=== SaasServer / externalCopilotDomains ===" -ForegroundColor Cyan
$saasIdx = $c.IndexOf("SaasServer", 5874000)
if ($saasIdx -gt 0) {
    $ctx = $c.Substring($saasIdx, [Math]::Min(1500, $c.Length - $saasIdx)) -replace "`n", " " -replace "`r", ""
    Write-Host "SaasServer (@$saasIdx):"
    Write-Host $ctx
}

Write-Host "`n=== AbstractBootService ===" -ForegroundColor Cyan
$bootIdx = $c.IndexOf("AbstractBootService", 2534000)
if ($bootIdx -gt 0) {
    $ctx = $c.Substring([Math]::Max(0, $bootIdx - 200), 2000) -replace "`n", " " -replace "`r", ""
    Write-Host "AbstractBootService (@$bootIdx):"
    Write-Host $ctx
}
