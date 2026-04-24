$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")

Write-Output "========== Check: is [v14-bg] code inside or outside IIFE? =========="
$vcIdx = $c.IndexOf("[v14-bg]")
if ($vcIdx -ge 0) {
    $ctxStart = [Math]::Max(0, $vcIdx - 200)
    $ctxLen = [Math]::Min(500, $c.Length - $ctxStart)
    Write-Output "Context around [v14-bg] (offset ${vcIdx}):"
    Write-Output $c.Substring($ctxStart, $ctxLen)
}

Write-Output ""
Write-Output "========== Check: last 500 chars of file =========="
$lastStart = [Math]::Max(0, $c.Length - 500)
Write-Output $c.Substring($lastStart)

Write-Output ""
Write-Output "========== Count braces from end to check if inside IIFE =========="
$pos = $c.Length - 1
$depth = 0
while ($pos -gt $c.Length - 1000) {
    $ch = $c.Substring($pos, 1)
    if ($ch -eq "}") { $depth++ }
    elseif ($ch -eq "{") { $depth-- }
    $pos--
}
Write-Output "Brace balance in last 1000 chars: depth=${depth} (positive=more closing than opening=outside IIFE)"
