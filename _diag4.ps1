$def = Get-Content 'patches\definitions.json' -Raw | ConvertFrom-Json
$targetFile = $def.meta.target_file
$content = [System.IO.File]::ReadAllText($targetFile)

Write-Host "File size: $($content.Length) bytes"

# Search for ALL occurrences of key strings
$searches = @('[v7-auto]', '[v7-manual]', '[v7]', 'ec=(0,Ir.Z)', 'if(V&&J)')
foreach ($s in $searches) {
    $idx = 0
    $count = 0
    while (($idx = $content.IndexOf($s, $idx)) -ge 0) {
        $count++
        Write-Host "'${s}' found at offset ${idx}"
        $ctxStart = [Math]::Max(0, $idx - 30)
        Write-Host "  -> $($content.Substring($ctxStart, [Math]::Min(80, $content.Length - $ctxStart)))"
        $idx++
    }
    if ($count -eq 0) { Write-Host "'${s}' NOT FOUND" }
    Write-Host ""
}
