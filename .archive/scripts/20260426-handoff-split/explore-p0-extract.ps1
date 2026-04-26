$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$c = [System.IO.File]::ReadAllText($TargetFile)

Write-Host "=== Extracting API Config JSON ===" -ForegroundColor Cyan
$jsonStart = $c.IndexOf("JSON.parse('{", 5870400)
if ($jsonStart -gt 0) {
    $searchFrom = $jsonStart + 12
    $quoteEnd = $c.IndexOf("'})", $searchFrom)
    if ($quoteEnd -gt 0) {
        $json = $c.Substring($searchFrom, $quoteEnd - $searchFrom)
        Write-Host "JSON length: $($json.Length) chars"
        Write-Host $json
    } else {
        Write-Host "Could not find end of JSON"
    }
} else {
    Write-Host "Could not find JSON.parse start"
}

Write-Host "`n=== Extracting GET_STATE hits with context ===" -ForegroundColor Cyan
$positions = @()
$startIdx = 54415
while (($idx = $c.IndexOf(".getState()", $startIdx, [System.StringComparison]::Ordinal)) -ge 0 -and $idx -le 6268469) {
    $ctxStart = [Math]::Max(0, $idx - 200)
    $ctxLen = [Math]::Min(400, $c.Length - $ctxStart)
    $ctx = $c.Substring($ctxStart, $ctxLen) -replace "`n", " " -replace "`r", ""
    Write-Host "`n--- .getState() @$idx ---"
    Write-Host $ctx
    $positions += $idx
    $startIdx = $idx + 1
    if ($positions.Count -ge 20) { break }
}

Write-Host "`n=== Extracting SUBSCRIBE hits with context ===" -ForegroundColor Cyan
$startIdx = 54415
$count = 0
while (($idx = $c.IndexOf(".subscribe(", $startIdx, [System.StringComparison]::Ordinal)) -ge 0 -and $idx -le 6268469) {
    $ctxStart = [Math]::Max(0, $idx - 200)
    $ctxLen = [Math]::Min(400, $c.Length - $ctxStart)
    $ctx = $c.Substring($ctxStart, $ctxLen) -replace "`n", " " -replace "`r", ""
    Write-Host "`n--- .subscribe() @$idx ---"
    Write-Host $ctx
    $startIdx = $idx + 1
    $count++
    if ($count -ge 10) { break }
}

Write-Host "`n=== Extracting SET_STATE hits with context ===" -ForegroundColor Cyan
$startIdx = 54415
$count = 0
while (($idx = $c.IndexOf(".setState(", $startIdx, [System.StringComparison]::Ordinal)) -ge 0 -and $idx -le 6268469) {
    $ctxStart = [Math]::Max(0, $idx - 200)
    $ctxLen = [Math]::Min(400, $c.Length - $ctxStart)
    $ctx = $c.Substring($ctxStart, $ctxLen) -replace "`n", " " -replace "`r", ""
    Write-Host "`n--- .setState() @$idx ---"
    Write-Host $ctx
    $startIdx = $idx + 1
    $count++
    if ($count -ge 10) { break }
}

Write-Host "`n=== Extracting ChatError class and error codes ===" -ForegroundColor Cyan
$chatErrIdx = $c.IndexOf("class l extends Error{constructor(e,t,i=n.ERROR,r)", 54000)
if ($chatErrIdx -gt 0) {
    $ctx = $c.Substring([Math]::Max(0, $chatErrIdx - 1000), 2000) -replace "`n", " " -replace "`r", ""
    Write-Host "ChatError class context (@$chatErrIdx):"
    Write-Host $ctx
}

Write-Host "`n=== Extracting ContactType enum ===" -ForegroundColor Cyan
$contactIdx = $c.IndexOf("ContactType=void 0", 54000)
if ($contactIdx -gt 0) {
    $ctx = $c.Substring($contactIdx, [Math]::Min(2000, $c.Length - $contactIdx)) -replace "`n", " " -replace "`r", ""
    Write-Host "ContactType enum (@$contactIdx):"
    Write-Host $ctx
}

Write-Host "`n=== Extracting DocumentSetStatus/ExternalDocumentType ===" -ForegroundColor Cyan
$docSetIdx = $c.IndexOf("DocumentSetStatus", 54000)
if ($docSetIdx -gt 0) {
    $ctx = $c.Substring($docSetIdx, [Math]::Min(1500, $c.Length - $docSetIdx)) -replace "`n", " " -replace "`r", ""
    Write-Host "DocumentSetStatus (@$docSetIdx):"
    Write-Host $ctx
}

Write-Host "`n=== Extracting CueTrace class ===" -ForegroundColor Cyan
$cueIdx = $c.IndexOf("CueTrace=void 0", 110000)
if ($cueIdx -gt 0) {
    $ctx = $c.Substring($cueIdx, [Math]::Min(2000, $c.Length - $cueIdx)) -replace "`n", " " -replace "`r", ""
    Write-Host "CueTrace (@$cueIdx):"
    Write-Host $ctx
}

Write-Host "`n=== Extracting BootConfig area ===" -ForegroundColor Cyan
$bootIdx = $c.IndexOf("getBootConfig", 2535000)
if ($bootIdx -gt 0) {
    $ctx = $c.Substring([Math]::Max(0, $bootIdx - 500), 2000) -replace "`n", " " -replace "`r", ""
    Write-Host "BootConfig (@$bootIdx):"
    Write-Host $ctx
}

Write-Host "`n=== Extracting multimodal upload area ===" -ForegroundColor Cyan
$multiIdx = $c.IndexOf("multimodal", 2680000)
if ($multiIdx -gt 0) {
    $ctx = $c.Substring([Math]::Max(0, $multiIdx - 300), 1500) -replace "`n", " " -replace "`r", ""
    Write-Host "Multimodal (@$multiIdx):"
    Write-Host $ctx
}

Write-Host "`n=== Extracting CancelReason enum ===" -ForegroundColor Cyan
$cancelIdx = $c.IndexOf("CancelReason=a={})", 100000)
if ($cancelIdx -gt 0) {
    $ctx = $c.Substring([Math]::Max(0, $cancelIdx - 500), 1500) -replace "`n", " " -replace "`r", ""
    Write-Host "CancelReason (@$cancelIdx):"
    Write-Host $ctx
}
