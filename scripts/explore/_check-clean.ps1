$targetFile = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
if (Test-Path $targetFile) {
    $f = Get-Item $targetFile
    Write-Host ("Target file size: " + [math]::Round($f.Length / 1MB, 2) + " MB")
    $c = [System.IO.File]::ReadAllText($targetFile)
    $checks = @('[AC]', '[v22-bg]', '[v11-bg]', '[v7]', '__traeAC', '_v11s.subscribe', 'queueMicrotask')
    foreach ($check in $checks) {
        $count = ([regex]::Matches($c, [regex]::Escape($check))).Count
        if ($count -gt 0) {
            Write-Host ("FOUND: " + $check + " x" + $count + " (NOT CLEAN!)")
        }
    }
    $clean = ($c.IndexOf('[AC]') -lt 0) -and ($c.IndexOf('__traeAC') -lt 0) -and ($c.IndexOf('_v11s') -lt 0)
    if ($clean) {
        Write-Host "SOURCE IS CLEAN - no patches detected"
    } else {
        Write-Host "SOURCE HAS PATCHES - need clean install"
    }
} else {
    Write-Host "FILE NOT FOUND - Trae may be at different path"
    Write-Host "Searching for index.js..."
    $found = Get-ChildItem -Path 'D:\apps' -Filter 'index.js' -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like '*ai-modules-chat*' } | Select-Object -First 3
    foreach ($f in $found) {
        Write-Host ("  Found: " + $f.FullName + " (" + [math]::Round($f.Length / 1MB, 2) + " MB)")
    }
}
