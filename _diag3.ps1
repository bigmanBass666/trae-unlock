$def = Get-Content 'patches\definitions.json' -Raw | ConvertFrom-Json
$targetFile = $def.meta.target_file
$content = [System.IO.File]::ReadAllText($targetFile)

$patch = $def.patches | Where-Object { $_.id -eq 'ec-debug-log' }
$findOrig = $patch.find_original

Write-Host "find_original length: $($findOrig.Length)"

$startStr = 'ec=(0,Ir.Z)(()=>{console.log("[v7-manual]"'
$startIdx = $content.IndexOf($startStr)
if ($startIdx -ge 0) {
    Write-Host "Found [v7-manual] start at offset $startIdx"
    
    $fileSnippet = $content.Substring($startIdx, [Math]::Min($findOrig.Length, $content.Length - $startIdx))
    Write-Host "File snippet length: $($fileSnippet.Length)"
    Write-Host "find_orig length: $($findOrig.Length)"
    
    $minLen = [Math]::Min($fileSnippet.Length, $findOrig.Length)
    $diffFound = $false
    for ($i = 0; $i -lt $minLen; $i++) {
        if ($fileSnippet[$i] -ne $findOrig[$i]) {
            Write-Host "First difference at position ${i}:"
            $fc = [int][char]$fileSnippet[$i]
            $oc = [int][char]$findOrig[$i]
            Write-Host "  File char:      [$($fileSnippet[$i])] (U+${fc:X4})"
            Write-Host "  find_orig char: [$($findOrig[$i])] (U+${oc:X4})"
            $ctxStart = [Math]::Max(0, $i - 30)
            Write-Host "  Context file:   ...$($fileSnippet.Substring($ctxStart, 60))..."
            Write-Host "  Context orig:   ...$($findOrig.Substring($ctxStart, 60))..."
            $diffFound = $true
            break
        }
    }
    if (-not $diffFound) {
        if ($fileSnippet.Length -ne $findOrig.Length) {
            Write-Host "No diff in first ${minLen} chars. Lengths differ:"
            Write-Host "  File snippet: $($fileSnippet.Length)"
            Write-Host "  find_orig:    $($findOrig.Length)"
        } else {
            Write-Host "[OK] Strings are IDENTICAL! Length=$($findOrig.Length)"
        }
    }
} else {
    Write-Host "[v7-manual] NOT FOUND"
}
