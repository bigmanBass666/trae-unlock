$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$c = [System.IO.File]::ReadAllText($TargetFile)

$jsonMarker = "e.exports=JSON.parse('"
$jsonStart = $c.IndexOf($jsonMarker, 5870400)
if ($jsonStart -gt 0) {
    $searchFrom = $jsonStart + $jsonMarker.Length
    $depth = 1
    $pos = $searchFrom
    while ($pos -lt $c.Length -and $depth -gt 0) {
        $ch = $c[$pos]
        if ($ch -eq '{') { $depth++ }
        elseif ($ch -eq '}') { $depth--; if ($depth -eq 0) { break } }
        $pos++
    }
    $json = $c.Substring($searchFrom, $pos - $searchFrom + 1)
    $outFile = "d:\Test\trae-unlock\scripts\p0-api-config.json"
    $json | Out-File -FilePath $outFile -Encoding UTF8 -Force
    Write-Host "API config JSON saved to: $outFile ($($json.Length) chars)"
    Write-Host "Offset: $($jsonStart) - $($pos)"
} else {
    Write-Host "Could not find JSON.parse start"
}

$errMarker = "CONNECTION_ERROR"
$errStart = $c.IndexOf($errMarker, 54000)
if ($errStart -gt 0) {
    $ctxStart = [Math]::Max(0, $errStart - 100)
    $ctx = $c.Substring($ctxStart, 3000) -replace "`n", " " -replace "`r", ""
    $outFile2 = "d:\Test\trae-unlock\scripts\p0-error-codes.txt"
    $ctx | Out-File -FilePath $outFile2 -Encoding UTF8 -Force
    Write-Host "Error codes saved to: $outFile2"
}

$contactMarker = "ContactType=void 0"
$contactStart = $c.IndexOf($contactMarker, 55000)
if ($contactStart -gt 0) {
    $ctx = $c.Substring($contactStart, 3000) -replace "`n", " " -replace "`r", ""
    $outFile3 = "d:\Test\trae-unlock\scripts\p0-contact-type.txt"
    $ctx | Out-File -FilePath $outFile3 -Encoding UTF8 -Force
    Write-Host "ContactType saved to: $outFile3"
}

Write-Host "`nDone."
