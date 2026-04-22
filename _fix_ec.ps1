$def = Get-Content 'patches\definitions.json' -Raw | ConvertFrom-Json
$targetFile = $def.meta.target_file
$content = [System.IO.File]::ReadAllText($targetFile)

# Get the ACTUAL ec= block from the target file
$idx = $content.IndexOf('ec=(0,Ir.Z)')
$patch = $def.patches | Where-Object { $_.id -eq 'ec-debug-log' }
$origFindOrig = $patch.find_original

# Extract same-length snippet from file
$fileSnippet = $content.Substring($idx, $origFindOrig.Length)

Write-Host "=== Current find_original (last 30 chars) ==="
Write-Host $origFindOrig.Substring($origFindOrig.Length - 30)
Write-Host "`n=== File snippet (last 30 chars) ==="
Write-Host $fileSnippet.Substring($fileSnippet.Length - 30)

# Show exact difference
for ($c = [Math]::Max(0, $origFindOrig.Length - 20); $c -lt $origFindOrig.Length; $c++) {
    $fc = if ($c -lt $fileSnippet.Length) { $fileSnippet[$c] } else { '?' }
    $oc = $origFindOrig[$c]
    $marker = if ($fc -ne $oc) { ' <<<' } else { '' }
    Write-Host "  ${c}: file=[$fc] orig=[${oc}]${marker}"
}

# Now produce the corrected find_original as JSON-escaped string
# We need to take the file content and JSON-encode it properly
$jsonEscaped = $fileSnippet.Replace('\', '\\').Replace('"', '\"')
Write-Host "`n=== Corrected find_original (JSON-safe, first 100 chars) ==="
Write-Host $jsonEscaped.Substring(0, [Math]::Min(100, $jsonEscaped.Length))
Write-Host "... (total length: $($jsonEscaped.Length))"
