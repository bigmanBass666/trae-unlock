$path = "D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js"
$c = [IO.File]::ReadAllText($path)

Write-Host "=== Fingerprint check ==="
$fp = '[v19-bg]'
$count = ([regex]::Matches($c, $fp)).Count
Write-Host "[v19-bg] occurrences: $count"

Write-Host ""
Write-Host "=== PART1: teaEventChatFail injection (300 chars) ==="
$idx = $c.IndexOf('[v19-bg] FLAG')
if ($idx -ge 0) {
    Write-Host $c.Substring([Math]::Max(0,$idx-50), 250)
}

Write-Host ""
Write-Host "=== PART2: MC-resume check ==="
$idx2 = $c.IndexOf('[v19-bg] MC-resume')
if ($idx2 -ge 0) {
    Write-Host "FOUND at $idx2"
}

Write-Host ""
Write-Host "=== PART3: VISIBLE/check ==="
$idx3 = $c.IndexOf('[v19-bg] VISIBLE')
if ($idx3 -ge 0) {
    Write-Host "FOUND at $idx3"
}

Write-Host ""
Write-Host "=== File tail (150 chars) ==="
Write-Host $c.Substring($c.Length - 150)

Write-Host ""
Write-Host "=== File size: $($c.Length) ==="
