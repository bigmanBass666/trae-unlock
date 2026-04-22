$def = Get-Content 'd:\Test\trae-unlock\patches\definitions.json' | ConvertFrom-Json
$targetFile = $def.meta.target_file
Write-Host "Target file: $targetFile"
$content = [System.IO.File]::ReadAllText($targetFile)

Write-Host "`n=== Searching efh=[ ==="
$idx = $content.IndexOf('efh=[')
if ($idx -ge 0) {
    Write-Host "Found efh=[ at offset $idx"
    Write-Host $content.Substring([Math]::Max(0,$idx-20), 400)
} else { 
    Write-Host 'efh=[ NOT FOUND' 
}

Write-Host "`n=== Searching SERVER_CRASH ==="
$idx2 = $content.IndexOf('SERVER_CRASH')
if ($idx2 -ge 0) { 
    Write-Host "Found SERVER_CRASH at offset $idx2" 
    Write-Host "--- Context ---"
    Write-Host $content.Substring([Math]::Max(0,$idx2-80), 300)
} else { Write-Host 'SERVER_CRASH NOT FOUND' }

Write-Host "`n=== Searching efh= (bare) ==="
$idx3 = $content.IndexOf('efh=')
if ($idx3 -ge 0) { 
    Write-Host "Found efh= at offset $idx3"
    if ($idx3 -ne $idx) {
        Write-Host $content.Substring([Math]::Max(0,$idx3-20), 200)
    }
}

Write-Host "`n=== Searching AutoRunMode.WHITELIST ==="
$idx4 = $content.IndexOf('AutoRunMode.WHITELIST')
if ($idx4 -ge 0) {
    Write-Host "Found at offset $idx4"
    Write-Host "--- Context (500 chars) ---"
    Write-Host $content.Substring([Math]::Max(0,$idx4-150), 500)
} else { Write-Host 'NOT FOUND' }

Write-Host "`n=== Searching P8.V2_Sandbox ==="
$idx5 = $content.IndexOf('P8.V2_Sandbox_RedList')
if ($idx5 -ge 0) {
    Write-Host "Found P8.V2_Sandbox_RedList at offset $idx5"
    Write-Host "--- Context ---"
    Write-Host $content.Substring([Math]::Max(0,$idx5-50), 400)
} else { 
    Write-Host "P8.V2_Sandbox_RedList NOT FOUND, trying P7..."
    $idx5b = $content.IndexOf('P7.V2_Sandbox_RedList')
    if ($idx5b -ge 0) {
        Write-Host "Found P7.V2_Sandbox_RedList at offset $idx5b"
        Write-Host "--- Context ---"
        Write-Host $content.Substring([Math]::Max(0,$idx5b-50), 600)
    } else { Write-Host 'P7.V2_Sandbox_RedList also NOT FOUND' }
}
