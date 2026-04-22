$jsonRaw = Get-Content 'patches\definitions.json' -Raw
$def = $jsonRaw | ConvertFrom-Json
$targetFile = $def.meta.target_file
$content = [System.IO.File]::ReadAllText($targetFile)

# Extract the ACTUAL ec= block from target file
$idx = $content.IndexOf('ec=(0,Ir.Z)')
$patch = $def.patches | Where-Object { $_.id -eq 'ec-debug-log' }
$oldFindOrig = $patch.find_original

# Get the real content from file (same length as old find_orig)
$fileActual = $content.Substring($idx, $oldFindOrig.Length)

# Verify the difference
Write-Host "Old find_orig tail: $($oldFindOrig.Substring($oldFindOrig.Length - 20))"
Write-Host "File actual tail:   $($fileActual.Substring($fileActual.Length - 20))"

# Build the replacement: old find_orig -> new (actual) find_orig in the JSON
# We need to do a string replace on the RAW JSON
# The old find_original is embedded in JSON with \u0026 etc already decoded by ConvertFrom-Json
# So we need to find it in the raw JSON text

# Since ConvertFrom-Json decoded \u0026 to &, we need to re-encode for JSON matching
# Or: search in raw JSON using the original encoded form

# Let's just find the ec-debug-log's find_original line in raw JSON and replace it
$lines = $jsonRaw -split "`n"
$newLines = @()
foreach ($line in $lines) {
    if ($line -match '"find_original".*"\[v7-manual\]') {
        # This is the ec-debug-log find_original line - rebuild it with correct content
        # Need to JSON-encode the fileActual string
        $escaped = $fileActual.Replace('\', '\\').Replace('"', '\"')
        $newLine = '                        "find_original":  "' + $escaped + '",'
        Write-Host "[REPLACING] ec-debug-log find_original"
        Write-Host "  Old length: $($oldFindOrig.Length)"
        Write-Host "  New length: $($fileActual.Length)"
        $newLines += $newLine
    } else {
        $newLines += $line
    }
}

$result = $newLines -join "`n"
Set-Content 'patches\definitions.json' $result -NoNewline

# Verify
$def2 = Get-Content 'patches\definitions.json' -Raw | ConvertFrom-Json
$patch2 = $def2.patches | Where-Object { $_.id -eq 'ec-debug-log' }
$newFindOrig = $patch2.find_original

$verifyIdx = $content.IndexOf($newFindOrig)
if ($verifyIdx -ge 0) {
    Write-Host "[OK] VERIFIED: New find_original matches file at offset ${verifyIdx}!"
} else {
    Write-Host "[WARN] New find_original still doesn't match file exactly"
}
