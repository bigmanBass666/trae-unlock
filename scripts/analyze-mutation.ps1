$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")

Write-Output "========== THE MUTATION POINT: offset 7615678 (800 chars context) =========="
$idx = 7615500
$len = 800
Write-Output $c.Substring($idx, $len)
Write-Output ""

Write-Output "========== WIDER: 1200 chars before mutation point =========="
$idx2 = 7615000
$len2 = 1200
Write-Output $c.Substring($idx2, $len2)
Write-Output ""

Write-Output "========== Find enclosing function: scan backwards for 'function' or '=>' or '{' balance =========="
$target = 7615778
$openBrace = 0
$foundFunc = $false
$pos = $target
while ($pos -gt 0) {
    $ch = $c.Substring($pos, 1)
    if ($ch -eq "}") { $openBrace++ }
    elseif ($ch -eq "{") {
        if ($openBrace -gt 0) { $openBrace-- }
        else {
            Write-Output "Found opening brace at offset ${pos} (delta from target: $($target - $pos))"
            $ctxStart = [Math]::Max(0, $pos - 200)
            $ctxLen = [Math]::Min(400, $c.Length - $ctxStart)
            Write-Output $c.Substring($ctxStart, $ctxLen)
            Write-Output ""
            break
        }
    }
    $pos--
}

Write-Output "========== Search for class/function name near 7615000-7616000 =========="
$region = $c.Substring(7614800, 2000)
Write-Output "(searching for async function / function / class / => patterns in region)"
