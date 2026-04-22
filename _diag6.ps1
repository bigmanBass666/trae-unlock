$def = Get-Content 'patches\definitions.json' -Raw | ConvertFrom-Json
$targetFile = $def.meta.target_file

# Read as bytes to check for BOM or hidden chars
$bytes = [System.IO.File]::ReadAllBytes($targetFile)
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

$patch = $def.patches | Where-Object { $_.id -eq 'ec-debug-log' }
$findOrig = $patch.find_original

# Convert find_orig to UTF8 bytes too
$origBytes = [System.Text.Encoding]::UTF8.GetBytes($findOrig)

Write-Host "find_orig byte length: $($origBytes.Length)"
Write-Host "find_orig char length: $($findOrig.Length)"

# Search for the bytes in the file
$found = $false
for ($i = 0; $i -le $bytes.Length - $origBytes.Length; $i++) {
    $match = $true
    for ($j = 0; $j -lt $origBytes.Length; $j++) {
        if ($bytes[$i + $j] -ne $origBytes[$j]) {
            $match = $false
            break
        }
    }
    if ($match) {
        Write-Host "[OK] Byte-level match FOUND at offset ${i}!"
        
        # Verify by decoding
        $fileSnippet = $content.Substring($i, $findOrig.Length)
        $strMatch = $fileSnippet -eq $findOrig
        Write-Host "String equality: ${strMatch}"
        
        # If string doesn't match despite bytes matching, show details
        if (-not $strMatch) {
            Write-Host "`nBytes match but STRINGS differ! Checking char by char..."
            $minLen = [Math]::Min($fileSnippet.Length, $findOrig.Length)
            for ($c = 0; $c -lt $minLen; $c++) {
                if ($fileSnippet[$c] -ne $findOrig[$c]) {
                    $fb = [System.Text.Encoding]::UTF8.GetBytes($fileSnippet[$c])
                    $ob = [System.Text.Encoding]::UTF8.GetBytes($findOrig[$c])
                    Write-Host "Char ${c}: file=$($fileSnippet[$c]) bytes=($($fb -join ',')) orig=$($findOrig[$c]) bytes=($($ob -join ','))"
                }
            }
        }
        $found = $true
        break
    }
}

if (-not $found) {
    Write-Host "[FAIL] Byte-level match NOT found either"
    
    # Show what's around offset 8703863
    $regionStart = 8703863
    $regionBytes = $bytes[$regionStart..($regionStart + 100)]
    Write-Host "`nBytes at offset 8703863:"
    Write-Host ($regionBytes -join ',')
    
    # Also show orig bytes start
    Write-Host "`nOrig bytes start:"
    Write-Host ($origBytes[0..50] -join ',')
}
