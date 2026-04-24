$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")

Write-Output "========== Caller context: who calls taskAgentMessageParser.parse(e,t)? =========="
$idx = 7618200
$len = 800
Write-Output $c.Substring($idx, $len)
Write-Output ""

Write-Output "========== What is 't' (2nd param)? Trace back to function signature =========="
$idx2 = 7618000
$len2 = 1000
Write-Output $c.Substring($idx2, $len2)
Write-Output ""

Write-Output "========== Check: does h have agentMessageId? Region before h assignment =========="
$idx4 = 7615000
$len4 = 700
Write-Output $c.Substring($idx4, $len4)
Write-Output ""
