param(
    [string]$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
)

$ErrorActionPreference = "SilentlyContinue"
$content = Get-Content $TargetFile -Raw -Encoding UTF8
$fs = $content.Length

function At($off, $len) {
    $s = [Math]::Max(0,$off); $e = [Math]::Min($fs,$s+$len)
    if ($s -lt $e) { return ($content.Substring($s,$e-$s) -replace "`r","") } else { return "(out of bounds)" }
}

Write-Host "=== THE BUTTON COMPONENT (sendingState prop) @2796000 ===" -ForegroundColor Cyan
Write-Host (At 2796000 2500)
Write-Host ""

Write-Host "=== Where is this component used? (search for its reference) ===" -ForegroundColor Green
$btnComp = $content.Substring(2796000, 2500)
$funcNameRx = [regex]::Matches($btnComp, '(?:function|const|let|var|=)\s*([a-zA-Z_$][a-zA-Z0-9_$]*)\s*[\(]')
if ($funcNameRx.Count -gt 0) {
    $compName = $funcNameRx[0].Groups[1].Value
    Write-Host "Component name appears to be: $compName"
    
    $refRx = [regex]::Matches($content, "$compName[\s,(]")
    Write-Host "Found $($refRx.Count) references to $compName"
    foreach ($r in $refRx[0..8]) {
        $cs = [Math]::Max(0,$r.Index-80); $ce = [Math]::Min($fs,$r.Index+$r.Length+100)
        Write-Host "  @ $($r.Index): $($content.Substring($cs,$ce-$cs).Replace("`n"," ").Replace("  "," "))"
    }
}

Write-Host ""
Write-Host "=== Search for the icon switch ternary INSIDE this component ===" -ForegroundColor Green
$compArea = $content.Substring(2796000, 3000)
$ternaryRx = [regex]::Matches($compArea, '\?.{0,100}:.{0,100}')
Write-Host "Found $($ternaryRx.Count) ternary expressions in component"
foreach ($t in $ternaryRx[0..12]) {
    $absOff = 2796000 + $t.Index
    $ctx = $t.Value
    if ($ctx.Length -gt 200) { $ctx = $ctx.Substring(0,200) + "..." }
    Write-Host "  @$absOff : $ctx"
}
