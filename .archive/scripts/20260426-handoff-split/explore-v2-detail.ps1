param([string]$IndexFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js")
$c = [System.IO.File]::ReadAllText($IndexFile)

Write-Host "=== NS Class (ICommercialPermissionService) ===" -ForegroundColor Cyan
$nsPos = $c.IndexOf("class NS")
Write-Host ("NS class at: {0}" -f $nsPos)
if ($nsPos -ge 0) {
    $ctx = $c.Substring($nsPos, [Math]::Min(5000, $c.Length - $nsPos))
    Write-Output $ctx
}

Write-Host "`n=== efi() Hook (isFreeUser React Hook) ===" -ForegroundColor Cyan
$efiPos = $c.IndexOf("function efi()")
Write-Host ("efi() at: {0}" -f $efiPos)
if ($efiPos -ge 0) {
    $ctx = $c.Substring($efiPos, [Math]::Min(2000, $c.Length - $efiPos))
    Write-Output $ctx
}

Write-Host "`n=== efr Enum (FreeNewSubscriptionUser*) ===" -ForegroundColor Cyan
$efrPos = $c.IndexOf("FreeNewSubscriptionUserCompletionRemaining")
Write-Host ("efr at: {0}" -f $efrPos)
if ($efrPos -ge 0) {
    $ctx = $c.Substring([Math]::Max(0, $efrPos - 100), [Math]::Min(2000, $c.Length - [Math]::Max(0, $efrPos - 100)))
    Write-Output $ctx
}

Write-Host "`n=== bJ Enum (Identity Types) ===" -ForegroundColor Cyan
$bjPos = $c.IndexOf("bJ={")
if ($bjPos -ge 0) {
    Write-Host ("bJ at: {0}" -f $bjPos)
    $ctx = $c.Substring($bjPos, [Math]::Min(500, $c.Length - $bjPos))
    Write-Output $ctx
} else {
    Write-Host "bJ={} not found, searching bJ.Lite context..."
    $bjLitePos = $c.IndexOf("bJ.Lite")
    if ($bjLitePos -ge 0) {
        $start = [Math]::Max(0, $bjLitePos - 2000)
        $ctx = $c.Substring($start, [Math]::Min(2500, $c.Length - $start))
        Write-Output $ctx
    }
}

Write-Host "`n=== kG Enum (Mode Types) ===" -ForegroundColor Cyan
$kgPos = $c.IndexOf("kG={")
if ($kgPos -ge 0) {
    Write-Host ("kG at: {0}" -f $kgPos)
    $ctx = $c.Substring($kgPos, [Math]::Min(500, $c.Length - $kgPos))
    Write-Output $ctx
} else {
    Write-Host "kG={} not found, searching kG.Max context..."
    $kgMaxPos = $c.IndexOf("kG.Max")
    if ($kgMaxPos -ge 0) {
        $start = [Math]::Max(0, $kgMaxPos - 2000)
        $ctx = $c.Substring($start, [Math]::Min(2500, $c.Length - $start))
        Write-Output $ctx
    }
}

Write-Host "`n=== FREE_ACTIVITY_QUOTA_EXHAUSTED ===" -ForegroundColor Cyan
$faqPos = $c.IndexOf("FREE_ACTIVITY_QUOTA_EXHAUSTED")
Write-Host ("FREE_ACTIVITY_QUOTA_EXHAUSTED at: {0}" -f $faqPos)
if ($faqPos -ge 0) {
    $ctx = $c.Substring([Math]::Max(0, $faqPos - 300), [Math]::Min(800, $c.Length - [Math]::Max(0, $faqPos - 300)))
    Write-Output $ctx
}

Write-Host "`n=== IModelStore (k2 class) ===" -ForegroundColor Cyan
$k2Pos = $c.IndexOf("class k2 extends Aq")
Write-Host ("k2 class at: {0}" -f $k2Pos)
if ($k2Pos -ge 0) {
    $ctx = $c.Substring($k2Pos, [Math]::Min(3000, $c.Length - $k2Pos))
    Write-Output $ctx
}

Write-Host "`n=== switchSelectedModel / switchToAutoModeIfAvailable ===" -ForegroundColor Cyan
$ssmPos = $c.IndexOf("switchSelectedModel")
Write-Host ("switchSelectedModel at: {0}" -f $ssmPos)
if ($ssmPos -ge 0) {
    $ctx = $c.Substring([Math]::Max(0, $ssmPos - 200), [Math]::Min(1000, $c.Length - [Math]::Max(0, $ssmPos - 200)))
    Write-Output $ctx
}

Write-Host "`n=== getSelectedModel ===" -ForegroundColor Cyan
$gsmPositions = @()
$pos = 0
while (($pos = $c.IndexOf("getSelectedModel", $pos)) -ge 0) {
    $gsmPositions += $pos
    $pos += "getSelectedModel".Length
}
Write-Host ("getSelectedModel: {0} hits" -f $gsmPositions.Count)
foreach ($p in $gsmPositions) {
    Write-Host ("  @{0}" -f $p)
}
