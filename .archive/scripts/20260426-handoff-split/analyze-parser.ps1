$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")

Write-Output "========== Class name and full function signature around mutation =========="
$idx = 7614800
$len = 1500
Write-Output $c.Substring($idx, $len)
Write-Output ""

Write-Output "========== Search for TaskAgentMessageParser =========="
$search = "TaskAgentMessageParser"
$idx2 = 0
while ($true) {
    $idx2 = $c.IndexOf($search, $idx2)
    if ($idx2 -lt 0) { break }
    $start2 = [Math]::Max(0, $idx2 - 50)
    $len2 = [Math]::Min(200, $c.Length - $start2)
    Write-Output "[${search}] Offset ${idx2}:"
    Write-Output $c.Substring($start2, $len2)
    Write-Output ""
    $idx2++
}

Write-Output "========== Search for who CALLS .parse() near 7615000 region =========="
Write-Output "Looking for patterns like .parse( in the broader area that might call this parser..."
$search2 = "taskAgentMessageParser"
$idx3 = $c.IndexOf($search2)
if ($idx3 -ge 0) {
    $start3 = [Math]::Max(0, $idx3 - 100)
    $len3 = [Math]::Min(400, $c.Length - $start3)
    Write-Output "[${search2}] Offset ${idx3}:"
    Write-Output $c.Substring($start3, $len3)
} else {
    Write-Output "[${search2}] NOT FOUND - trying case variants..."
}

Write-Output ""
Write-Output "========== Search for handleSideChat (from ErrorStreamParser discovery) =========="
$search3 = "handleSideChat"
$idx4 = 0
$count4 = 0
while ($true) {
    $idx4 = $c.IndexOf($search3, $idx4)
    if ($idx4 -lt 0) { break }
    $count4++
    if ($count4 -le 8) {
        $start4 = [Math]::Max(0, $idx4 - 100)
        $len4 = [Math]::Min(300, $c.Length - $start4)
        Write-Output "[#${count4}] Offset ${idx4}:"
        Write-Output $c.Substring($start4, $len4)
        Write-Output ""
    }
    $idx4++
}
