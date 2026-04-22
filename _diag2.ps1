$def = Get-Content 'patches\definitions.json' -Raw | ConvertFrom-Json
$targetFile = $def.meta.target_file
$content = [System.IO.File]::ReadAllText($targetFile)

# Get full if(V&&J) block - need to capture until the Alert closing
$idx = $content.IndexOf('if(V&&J)')
# Find the end: look for the next major structural element after the return statement
# The block ends after the Cr.Alert component
$snippet = $content.Substring($idx, [Math]::Min(900, $content.Length - $idx))
Write-Host "=== FULL if(V&&J) block ==="
Write-Host $snippet
Write-Host "`n--- LENGTH: $($snippet.Length) ---"

Write-Host "`n`n========================================`n"

# Get full ec= block
$idx3 = $content.IndexOf('ec=(0,Ir.Z)')
$snippet2 = $content.Substring($idx3, [Math]::Min(800, $content.Length - $idx3))
Write-Host "=== FULL ec=(0,Ir.Z) block ==="
Write-Host $snippet2
Write-Host "`n--- LENGTH: $($snippet2.Length) ---"
