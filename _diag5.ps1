$def = Get-Content 'patches\definitions.json' -Raw | ConvertFrom-Json
$targetFile = $def.meta.target_file
$content = [System.IO.File]::ReadAllText($targetFile)

$patch = $def.patches | Where-Object { $_.id -eq 'ec-debug-log' }
$findOrig = $patch.find_original

Write-Host "find_original (first 80 chars): $($findOrig.Substring(0, [Math]::Min(80, $findOrig.Length)))"
Write-Host "find_original length: $($findOrig.Length)"

$idx = $content.IndexOf('ec=(0,Ir.Z)')
if ($idx -ge 0) {
    $fileRegion = $content.Substring($idx, [Math]::Min($findOrig.Length + 50, $content.Length - $idx))
    Write-Host "`nFile at ec=(0,Ir.Z) (first 80): $($fileRegion.Substring(0, [Math]::Min(80, $fileRegion.Length)))"
    
    $testIdx = $content.IndexOf($findOrig)
    Write-Host "`nIndexOf result: ${testIdx} (-1 = not found)"
    
    $compareLen = [Math]::Min(100, $findOrig.Length, $content.Length - $idx)
    $filePart = $content.Substring($idx, $compareLen)
    $origPart = $findOrig.Substring(0, $compareLen)
    
    $mismatch = $null
    for ($c = 0; $c -lt $compareLen; $c++) {
        if ($filePart[$c] -ne $origPart[$c]) {
            $mismatch = $c
            break
        }
    }
    
    if ($mismatch -ne $null) {
        $fc = [int][char]$filePart[$mismatch]
        $oc = [int][char]$origPart[$mismatch]
        Write-Host "First mismatch at char ${mismatch}:"
        Write-Host "  File: U+$([Convert]::ToString($fc, 16)) = [$($filePart[$mismatch])]"
        Write-Host "  Orig: U+$([Convert]::ToString($oc, 16)) = [$($origPart[$mismatch])]"
        
        $hexStart = [Math]::Max(0, $mismatch - 5)
        $hexFile = ""
        $hexOrig = ""
        for ($x = $hexStart; $x -lt [Math]::Min($mismatch + 10, $compareLen); $x++) {
            $v1 = [int][char]$filePart[$x]
            $v2 = [int][char]$origPart[$x]
            $hexFile += "$([Convert]::ToString($v1, 2)) "
            $hexOrig += "$([Convert]::ToString($v2, 2)) "
        }
        Write-Host "  File dec: $hexFile"
        Write-Host "  Orig dec: $hexOrig"
    } else {
        Write-Host "First ${compareLen} chars MATCH exactly!"
        
        if ($findOrig.Length -gt $content.Length - $idx) {
            Write-Host "find_orig longer than remaining file content"
        } elseif ($findOrig.Length -lt $content.Length - $idx) {
            $nextChar = $content.Substring($idx + $findOrig.Length, 1)
            $nc = [int][char]$nextChar
            Write-Host "Strings match for $($findOrig.Length) chars. Next char in file: dec=$nc=[$nextChar]"
            
            # Show the full tail of find_orig and file
            $tailLen = [Math]::Min(50, $findOrig.Length)
            Write-Host "Tail of find_orig:"
            Write-Host $findOrig.Substring($findOrig.Length - $tailLen)
            Write-Host "Tail of file (same position):"
            Write-Host $content.Substring($idx + $findOrig.Length - $tailLen, [Math]::Min($tailLen + 20, $content.Length - $idx - $findOrig.Length + $tailLen))
        } else {
            Write-Host "[OK] Strings are IDENTICAL for full length!"
        }
    }
}
