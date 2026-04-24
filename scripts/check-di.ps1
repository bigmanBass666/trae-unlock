$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")
$idx = $c.IndexOf("Di=")
if ($idx -ge 0) {
    $ctx = [Math]::Max(0, $idx - 30)
    Write-Output "Di= definition at ${idx}:"
    Write-Output $c.Substring($ctx, 100)
} else {
    Write-Output "Di= NOT FOUND as variable assignment"
    # Search for Di in other contexts
    $diIdx = $c.IndexOf(",Di")
    if ($diIdx -ge 0) { Write-Output "Found ,Di at ${diIdx}:" + $c.Substring([Math]::Max(0,$diIdx-20), 60) }
}
