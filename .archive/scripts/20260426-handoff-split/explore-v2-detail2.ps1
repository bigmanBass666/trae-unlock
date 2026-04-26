param([string]$IndexFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js")
$c = [System.IO.File]::ReadAllText($IndexFile)

Write-Host "=== kP function (isInternal) ===" -ForegroundColor Cyan
$kpPos = $c.IndexOf("let kP=")
if ($kpPos -ge 0) {
    Write-Host ("kP at {0}" -f $kpPos)
    $ctx = $c.Substring($kpPos, [Math]::Min(200, $c.Length - $kpPos))
    Write-Output $ctx
}

Write-Host "`n=== CLAUDE_MODEL_FORBIDDEN UI rendering @8717132 ===" -ForegroundColor Cyan
$ctx = $c.Substring([Math]::Max(0, 8717132 - 300), [Math]::Min(800, $c.Length - [Math]::Max(0, 8717132 - 300)))
Write-Output $ctx

Write-Host "`n=== De class (AIChatRequestErrorService) ===" -ForegroundColor Cyan
$dePos = $c.IndexOf("class De extends")
if ($dePos -ge 0) {
    Write-Host ("De at {0}" -f $dePos)
    $ctx = $c.Substring($dePos, [Math]::Min(2000, $c.Length - $dePos))
    Write-Output $ctx
}

Write-Host "`n=== eYZ class (IAiCompletionService) ===" -ForegroundColor Cyan
$eyzPos = $c.IndexOf("class eYZ extends")
if ($eyzPos -ge 0) {
    Write-Host ("eYZ at {0}" -f $eyzPos)
    $ctx = $c.Substring($eyzPos, [Math]::Min(2000, $c.Length - $eyzPos))
    Write-Output $ctx
}

Write-Host "`n=== NR class (ModelService) ===" -ForegroundColor Cyan
$nrPos = $c.IndexOf("class NR extends")
if ($nrPos -ge 0) {
    Write-Host ("NR at {0}" -f $nrPos)
    $ctx = $c.Substring($nrPos, [Math]::Min(500, $c.Length - $nrPos))
    Write-Output $ctx
}

Write-Host "`n=== usageLimitConfig context ===" -ForegroundColor Cyan
$ulcPos = $c.IndexOf("usageLimitConfig")
if ($ulcPos -ge 0) {
    $positions = @()
    $pos = 0
    while (($pos = $c.IndexOf("usageLimitConfig", $pos)) -ge 0) {
        $positions += $pos
        $pos += "usageLimitConfig".Length
    }
    Write-Host ("{0} hits" -f $positions.Count)
    foreach ($p in $positions[0..2]) {
        Write-Host ("  @{0}" -f $p)
        $ctx = $c.Substring([Math]::Max(0, $p - 100), [Math]::Min(400, $c.Length - [Math]::Max(0, $p - 100)))
        Write-Output $ctx
        Write-Output ""
    }
}

Write-Host "`n=== ICommercialActivityService ===" -ForegroundColor Cyan
$casPos = $c.IndexOf("ICommercialActivityService")
if ($casPos -ge 0) {
    Write-Host ("ICommercialActivityService at {0}" -f $casPos)
    $ctx = $c.Substring([Math]::Max(0, $casPos - 100), [Math]::Min(600, $c.Length - [Math]::Max(0, $casPos - 100)))
    Write-Output $ctx
}

Write-Host "`n=== efc() function (freeCommercialActivity) ===" -ForegroundColor Cyan
$efcPos = $c.IndexOf("efc=()")
if ($efcPos -ge 0) {
    Write-Host ("efc at {0}" -f $efcPos)
    $ctx = $c.Substring($efcPos, [Math]::Min(500, $c.Length - $efcPos))
    Write-Output $ctx
}

Write-Host "`n=== Oo enum (strategy) ===" -ForegroundColor Cyan
$ooPos = $c.IndexOf("Oo=")
if ($ooPos -ge 0) {
    Write-Host ("Oo at {0}" -f $ooPos)
    $ctx = $c.Substring($ooPos, [Math]::Min(300, $c.Length - $ooPos))
    Write-Output $ctx
}
