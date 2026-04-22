$targetFile = "D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js"
$content = [System.IO.File]::ReadAllText($targetFile)

Write-Host "=== Full context around efg= (new efh) at ~8701952 ==="
$idx = $content.IndexOf('efg=[kg.SERVER_CRASH')
if ($idx -ge 0) {
    Write-Host "Found at offset $idx"
    Write-Host $content.Substring([Math]::Max(0,$idx-10), 500)
} else {
    Write-Host "efg=[kg.SERVER_CRASH not found, searching efg=["
    $idx2 = $content.IndexOf('efg=[')
    if ($idx2 -ge 0) {
        Write-Host "Found efg=[ at offset $idx2"
        Write-Host $content.Substring([Math]::Max(0,$idx2-10), 500)
    }
}

Write-Host "`n=== Full P7 switch context at AutoRunMode.WHITELIST ==="
$idx3 = $content.IndexOf('AutoRunMode.WHITELIST:switch(i){case Cr.BlockLevel.RedList:return P7.V2_Sandbox_RedList')
if ($idx3 -ge 0) {
    Write-Host "Found exact match at offset $idx3"
    Write-Host $content.Substring([Math]::Max(0,$idx3-10), 800)
} else {
    Write-Host "Exact not found, trying broader search..."
    $idx4 = $content.IndexOf('AutoRunMode.WHITELIST:switch(i)')
    if ($idx4 -ge 0) {
        Write-Host "Found broader at offset $idx4"
        Write-Host $content.Substring([Math]::Max(0,$idx4-10), 900)
    }
}
