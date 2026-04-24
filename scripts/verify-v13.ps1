$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")
$idx = $c.IndexOf("[v13-bg]")
if ($idx -ge 0) {
    $start = [Math]::Max(0, $idx - 100)
    $len = [Math]::Min(300, $c.Length - $start)
    Write-Output "Found [v13-bg] at offset ${idx}:"
    Write-Output $c.Substring($start, $len)
} else {
    Write-Output "[v13-bg] NOT FOUND!"
}
