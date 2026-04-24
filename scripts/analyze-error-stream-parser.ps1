$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")

Write-Output "========== CRITICAL: offset 7513700-7514000 (ErrorStreamParser exception literal) =========="
$idx = 7513650
$len = 500
Write-Output $c.Substring($idx, $len)
Write-Output ""

Write-Output "========== WIDER: find enclosing function name =========="
$idx2 = 7513500
$len2 = 600
Write-Output $c.Substring($idx2, $len2)
Write-Output ""

Write-Output "========== Who calls this function? Search for the method name =========="
Write-Output "(looking for method signature around this area)"
$region = $c.Substring(7513000, 1200)
Write-Output $region
