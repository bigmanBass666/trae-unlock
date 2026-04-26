$ErrorActionPreference = "Stop"
$path = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'

Write-Host "========================================" -ForegroundColor White
Write-Host "  v19 v5 VERIFICATION" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor White

Write-Host ""
Write-Host "[CHECK 1] node --check syntax validation..." -ForegroundColor Cyan
$nodeCheck = node --check $path 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  PASS: Syntax OK" -ForegroundColor Green
} else {
    Write-Host "  FAIL: $nodeCheck" -ForegroundColor Red
}

Write-Host ""
Write-Host "[CHECK 2] Fingerprint verification (8 items)..." -ForegroundColor Cyan
$c = [IO.File]::ReadAllText($path)

$checks = @(
    @{ name="[v19-bg] fingerprint"; pattern="[v19-bg]" },
    @{ name="_ts=function"; pattern="_ts=function(){return new Date().toISOString().substr(11,12)}" },
    @{ name="typeof document!=='undefined'"; pattern="typeof document!=='undefined'&&typeof document.addEventListener==='function'" },
    @{ name="VC-skip (degrade log)"; pattern="VC-skip: no document.addEventListener" },
    @{ name="dispatchEvent(focus) UI refresh"; pattern="dispatchEvent(new Event('focus'))" },
    @{ name="MC-validate-ignore"; pattern="MC-validate-ignore" },
    @{ name="resolve(Di)"; pattern="resolve(Di)" }
)

$passCount = 0
foreach ($chk in $checks) {
    $idx = $c.IndexOf($chk.pattern)
    if ($idx -ge 0) {
        Write-Host "  PASS: $($chk.name) found at offset $idx" -ForegroundColor Green
        $passCount++
    } else {
        Write-Host "  FAIL: $($chk.name) NOT FOUND!" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor White
Write-Host "  RESULTS: $passCount / $($checks.Count) fingerprints + syntax check" -ForegroundColor $(if ($passCount -eq $checks.Count -and $LASTEXITCODE -eq 0) { "Green" } else { "Yellow" })
Write-Host "========================================" -ForegroundColor White
