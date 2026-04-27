$targetFile = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$c = [System.IO.File]::ReadAllText($targetFile)

# Find the anchor for auto-continue-thinking
$anchor = 'if(V&&J){let e=M.localize("continue",{},"Continue")'
$idx = $c.IndexOf($anchor)
Write-Host ("Anchor found at offset: " + $idx)

# Extract 500 chars from anchor
$chunk = $c.Substring($idx, [Math]::Min(500, $c.Length - $idx))
Write-Host ""
Write-Host "=== Clean source code at anchor ==="
Write-Host $chunk
