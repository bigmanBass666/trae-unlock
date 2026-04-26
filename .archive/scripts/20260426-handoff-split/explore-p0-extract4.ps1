$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$c = [System.IO.File]::ReadAllText($TargetFile)

$byteGateMarker = "byteGate"
$idx = $c.IndexOf($byteGateMarker, 5870000)
if ($idx -gt 0) {
    $jsonSearchStart = $idx
    while ($jsonSearchStart -gt 0 -and $c[$jsonSearchStart] -ne '{') {
        $jsonSearchStart--
    }
    $depth = 1
    $pos = $jsonSearchStart + 1
    while ($pos -lt $c.Length -and $depth -gt 0) {
        $ch = $c[$pos]
        if ($ch -eq '{') { $depth++ }
        elseif ($ch -eq '}') { $depth--; if ($depth -eq 0) { break } }
        $pos++
    }
    $json = $c.Substring($jsonSearchStart, $pos - $jsonSearchStart + 1)
    $outFile = "d:\Test\trae-unlock\scripts\p0-api-endpoints.json"
    $json | Out-File -FilePath $outFile -Encoding UTF8 -Force
    Write-Host "API endpoints JSON saved to: $outFile ($($json.Length) chars)"
    Write-Host "Offset: $($jsonSearchStart) - $($pos)"
} else {
    Write-Host "Could not find byteGate marker"
}

$idx2 = $c.IndexOf("externalCopilotDomains", 5874000)
if ($idx2 -gt 0) {
    $ctx = $c.Substring([Math]::Max(0, $idx2 - 200), 800) -replace "`n", " " -replace "`r", ""
    Write-Host "`nexternalCopilotDomains context:"
    Write-Host $ctx
}

$idx3 = $c.IndexOf("SaasServer", 5874000)
if ($idx3 -gt 0) {
    $ctx = $c.Substring($idx3, 500) -replace "`n", " " -replace "`r", ""
    Write-Host "`nSaasServer context:"
    Write-Host $ctx
}

Write-Host "`n=== Searching for all API-related JSON configs in P0 ===" -ForegroundColor Cyan
$jsonParsePositions = @()
$searchFrom = 54415
while (($idx = $c.IndexOf("JSON.parse('", $searchFrom, [System.StringComparison]::Ordinal)) -ge 0 -and $idx -le 6268469) {
    $peek = $c.Substring($idx, [Math]::Min(100, $c.Length - $idx))
    $jsonParsePositions += $idx
    Write-Host "  JSON.parse @$idx : $($peek.Substring(0, [Math]::Min(80, $peek.Length)))"
    $searchFrom = $idx + 1
    if ($jsonParsePositions.Count -ge 30) { break }
}

Write-Host "`nDone."
