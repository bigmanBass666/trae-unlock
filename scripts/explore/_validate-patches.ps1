$targetFile = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$defFile = 'D:\Test\trae-unlock\patches\definitions.json'

if (-not (Test-Path $targetFile)) {
    Write-Host "TARGET FILE NOT FOUND: $targetFile"
    exit 1
}

$c = [System.IO.File]::ReadAllText($targetFile)
$defs = Get-Content $defFile -Raw | ConvertFrom-Json

Write-Host "=== Patch Anchor & find_original Validation ==="
Write-Host ("Target file size: " + [math]::Round($c.Length / 1MB, 2) + " MB")
Write-Host ""

foreach ($patch in $defs.patches) {
    if ($patch.enabled -ne $true) {
        Write-Host ("[SKIP] " + $patch.id + " (disabled)")
        continue
    }

    Write-Host ("--- " + $patch.id + " ---")

    # Check anchor
    $anchorIdx = $c.IndexOf($patch.anchor)
    if ($anchorIdx -ge 0) {
        $anchorCount = ([regex]::Matches($c, [regex]::Escape($patch.anchor))).Count
        Write-Host ("  ANCHOR: FOUND at offset " + $anchorIdx + " (count: " + $anchorCount + ")")
        if ($anchorCount -gt 1) {
            Write-Host "  WARNING: Anchor is NOT unique! Multiple matches!"
        }
    } else {
        Write-Host "  ANCHOR: NOT FOUND!"
    }

    # Check find_original
    $findIdx = $c.IndexOf($patch.find_original)
    if ($findIdx -ge 0) {
        Write-Host ("  FIND_ORIGINAL: FOUND at offset " + $findIdx)
    } else {
        Write-Host "  FIND_ORIGINAL: NOT FOUND!"
        # Try first 50 chars
        $prefix = $patch.find_original
        if ($prefix.Length -gt 50) { $prefix = $prefix.Substring(0, 50) }
        $prefixIdx = $c.IndexOf($prefix)
        if ($prefixIdx -ge 0) {
            Write-Host ("  FIND_ORIGINAL prefix (50 chars): FOUND at offset " + $prefixIdx)
            Write-Host "  -> find_original has drift or format mismatch"
        } else {
            Write-Host "  FIND_ORIGINAL prefix (50 chars): NOT FOUND either!"
            Write-Host "  -> Anchor area may have changed completely"
        }
    }

    # Check if replace_with is already in file (already applied)
    $replaceIdx = $c.IndexOf($patch.replace_with)
    if ($replaceIdx -ge 0) {
        Write-Host ("  REPLACE_WITH: ALREADY IN FILE at offset " + $replaceIdx + " (already applied!)")
    }

    Write-Host ""
}

Write-Host "=== Summary ==="
$enabled = $defs.patches | Where-Object { $_.enabled -eq $true }
$anchorOk = 0; $anchorFail = 0; $findOk = 0; $findFail = 0; $alreadyApplied = 0
foreach ($patch in $enabled) {
    if ($c.IndexOf($patch.anchor) -ge 0) { $anchorOk++ } else { $anchorFail++ }
    if ($c.IndexOf($patch.find_original) -ge 0) { $findOk++ } else { $findFail++ }
    if ($c.IndexOf($patch.replace_with) -ge 0) { $alreadyApplied++ }
}
Write-Host ("Enabled patches: " + $enabled.Count)
Write-Host ("Anchor found: " + $anchorOk + " / not found: " + $anchorFail)
Write-Host ("find_original found: " + $findOk + " / not found: " + $findFail)
Write-Host ("Already applied (replace_with in file): " + $alreadyApplied)
