param([string]$IndexFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js")
$c = [System.IO.File]::ReadAllText($IndexFile)

Write-Host "=== bJ Enum Definition ===" -ForegroundColor Cyan
$patterns = @("bJ={", "bJ=(", "var bJ", "let bJ", "bJ[bJ", "bJ.Lite")
foreach ($pat in $patterns) {
    $pos = $c.IndexOf($pat)
    if ($pos -ge 0) {
        Write-Host ("Found [{0}] at {1}" -f $pat, $pos)
        $ctx = $c.Substring([Math]::Max(0, $pos - 50), [Math]::Min(500, $c.Length - [Math]::Max(0, $pos - 50)))
        Write-Output $ctx
        Write-Output ""
    }
}

Write-Host "=== kG Enum Definition ===" -ForegroundColor Cyan
$patterns = @("kG={", "kG=(", "var kG", "let kG", "kG[kG", "kG.Max", "kG.Auto", "kG.Manual")
foreach ($pat in $patterns) {
    $pos = $c.IndexOf($pat)
    if ($pos -ge 0) {
        Write-Host ("Found [{0}] at {1}" -f $pat, $pos)
        $ctx = $c.Substring([Math]::Max(0, $pos - 50), [Math]::Min(500, $c.Length - [Math]::Max(0, $pos - 50)))
        Write-Output $ctx
        Write-Output ""
    }
}

Write-Host "=== bK Enum (AppProviderCompany) ===" -ForegroundColor Cyan
$patterns = @("bK={", "bK=(", "bK.SAAS", "bK.BYTEDANCE")
foreach ($pat in $patterns) {
    $pos = $c.IndexOf($pat)
    if ($pos -ge 0) {
        Write-Host ("Found [{0}] at {1}" -f $pat, $pos)
        $ctx = $c.Substring([Math]::Max(0, $pos - 50), [Math]::Min(500, $c.Length - [Math]::Max(0, $pos - 50)))
        Write-Output $ctx
        Write-Output ""
    }
}

Write-Host "=== kP function (isInternal check) ===" -ForegroundColor Cyan
$kPPos = $c.IndexOf("function kP(")
if ($kPPos -ge 0) {
    Write-Host ("kP at {0}" -f $kPPos)
    $ctx = $c.Substring($kPPos, [Math]::Min(500, $c.Length - $kPPos))
    Write-Output $ctx
}

Write-Host "`n=== CLAUDE_MODEL_FORBIDDEN context ===" -ForegroundColor Cyan
$cmfPos = $c.IndexOf("CLAUDE_MODEL_FORBIDDEN")
if ($cmfPos -ge 0) {
    $positions = @()
    $pos = 0
    while (($pos = $c.IndexOf("CLAUDE_MODEL_FORBIDDEN", $pos)) -ge 0) {
        $positions += $pos
        $pos += "CLAUDE_MODEL_FORBIDDEN".Length
    }
    Write-Host ("{0} hits" -f $positions.Count)
    foreach ($p in $positions) {
        Write-Host ("  @{0}" -f $p)
        if ($p -ne $positions[0]) { continue }
        $ctx = $c.Substring([Math]::Max(0, $p - 300), [Math]::Min(800, $c.Length - [Math]::Max(0, $p - 300)))
        Write-Output $ctx
        Write-Output ""
    }
}

Write-Host "`n=== isCNOuterUser ===" -ForegroundColor Cyan
$cnouPos = $c.IndexOf("isCNOuterUser")
if ($cnouPos -ge 0) {
    Write-Host ("isCNOuterUser at {0}" -f $cnouPos)
    $ctx = $c.Substring($cnouPos, [Math]::Min(800, $c.Length - $cnouPos))
    Write-Output $ctx
}

Write-Host "`n=== eYH (usage limit service) ===" -ForegroundColor Cyan
$eyhPos = $c.IndexOf("eYH")
if ($eyhPos -ge 0) {
    $positions = @()
    $pos = 0
    while (($pos = $c.IndexOf("eYH", $pos)) -ge 0) {
        $positions += $pos
        $pos += 3
    }
    Write-Host ("eYH: {0} hits" -f $positions.Count)
    foreach ($p in $positions[0..4]) {
        Write-Host ("  @{0}" -f $p)
    }
}

Write-Host "`n=== kA (IProductService) ===" -ForegroundColor Cyan
$kaPos = $c.IndexOf("IProductService")
if ($kaPos -ge 0) {
    Write-Host ("IProductService at {0}" -f $kaPos)
    $ctx = $c.Substring([Math]::Max(0, $kaPos - 100), [Math]::Min(500, $c.Length - [Math]::Max(0, $kaPos - 100)))
    Write-Output $ctx
}

Write-Host "`n=== A2 function (agent check) ===" -ForegroundColor Cyan
$a2Pos = $c.IndexOf("function A2(")
if ($a2Pos -ge 0) {
    Write-Host ("A2 at {0}" -f $a2Pos)
    $ctx = $c.Substring($a2Pos, [Math]::Min(300, $c.Length - $a2Pos))
    Write-Output $ctx
}
