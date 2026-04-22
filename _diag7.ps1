$def = Get-Content 'patches\definitions.json' -Raw | ConvertFrom-Json
$targetFile = $def.meta.target_file
$content = [System.IO.File]::ReadAllText($targetFile)

# Search for ec=(0,Ir.Z) in CURRENT file
$idx = $content.IndexOf('ec=(0,Ir.Z)')
Write-Host "ec=(0,Ir.Z) current offset: ${idx}"

if ($idx -ge 0) {
    # Show context
    $ctxStart = [Math]::Max(0, $idx - 50)
    Write-Host "`nContext (50 before):"
    Write-Host $content.Substring($ctxStart, [Math]::Min(200, $content.Length - $ctxStart))
    
    # Now get find_orig and try match
    $patch = $def.patches | Where-Object { $_.id -eq 'ec-debug-log' }
    $findOrig = $patch.find_original
    
    $testIdx = $content.IndexOf($findOrig)
    Write-Host "`nIndexOf find_orig in current file: ${testIdx}"
    
    if ($testIdx -ge 0) {
        Write-Host "[OK] EXACT MATCH FOUND at offset ${testIdx}!"
    } else {
        Write-Host "[FAIL] Still not found. Comparing..."
        
        $filePart = $content.Substring($idx, [Math]::Min($findOrig.Length, $content.Length - $idx))
        $matchCount = 0
        $minLen = [Math]::Min($filePart.Length, $findOrig.Length)
        for ($c = 0; $c -lt $minLen; $c++) {
            if ($filePart[$c] -eq $findOrig[$c]) { $matchCount++ }
            else { 
                Write-Host "First mismatch at char ${c}:"
                Write-Host "  file: [$($filePart[$c])] orig: [$($findOrig[$c])]"
                break 
            }
        }
        Write-Host "Matched ${matchCount} of ${minLen} chars"
    }
}

# Also check what's at old offset 8703863 now
Write-Host "`n--- Old offset 8703863 ---"
Write-Host $content.Substring(8703863, [Math]::Min(80, $content.Length - 8703863))
