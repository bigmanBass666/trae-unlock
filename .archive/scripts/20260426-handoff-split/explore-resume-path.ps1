$c = [IO.File]::ReadAllText('D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js')
$out = ""

# 1. GZt.create
$gz = $c.IndexOf('GZt.create')
if($gz -ge 0){
    $out += "=== GZt.create pos:$gz ===`n"
    $start = [Math]::Max(0,$gz-100)
    $len = [Math]::Min(400, $c.Length-$gz+100)
    $out += $c.Substring($start, $len) + "`n`n"
}

# 2. Validate data failed
$vdf = $c.IndexOf('Validate data failed')
if($vdf -ge 0){
    $out += "=== Validate data failed pos:$vdf ===`n"
    $start = [Math]::Max(0,$vdf-200)
    $len = [Math]::Min(500, $c.Length-$vdf+200)
    $out += $c.Substring($start, $len) + "`n`n"
}

# 3. missing field
$mfs = $c.IndexOf('missing field')
if($mfs -ge 0){
    $out += "=== missing field pos:$mfs ===`n"
    $start = [Math]::Max(0,$mfs-200)
    $len = [Math]::Min(400, $c.Length-$mfs+200)
    $out += $c.Substring($start, $len) + "`n`n"
}

# 4. resumeChat definition
$rsm = $c.IndexOf('.resumeChat=function')
if($rsm -lt 0){$rsm = $c.IndexOf('.resumeChat=(')}
if($rsm -ge 0){
    $out += "=== .resumeChat= pos:$rsm ===`n"
    $start = [Math]::Max(0,$rsm-30)
    $len = [Math]::Min(600, $c.Length-$rsm+30)
    $out += $c.Substring($start, $len) + "`n`n"
}

# 5. prototype.chat
$pChat = $c.IndexOf('prototype.chat')
if($pChat -ge 0){
    $out += "=== prototype.chat pos:$pChat ===`n"
    $start = [Math]::Max(0,$pChat-50)
    $len = [Math]::Min(600, $c.Length-$pChat+50)
    $out += $c.Substring($start, $len) + "`n`n"
}

# 6. sendChatMessage
$scm = $c.IndexOf('sendChatMessage=function')
if($scm -lt 0){$scm = $c.IndexOf('sendChatMessage=(')}
if($scm -ge 0){
    $out += "=== sendChatMessage= pos:$scm ===`n"
    $start = [Math]::Max(0,$scm-30)
    $len = [Math]::Min(600, $c.Length-$scm+30)
    $out += $c.Substring($start, $len) + "`n`n"
}

[System.IO.File]::WriteAllText('d:\Test\trae-unlock\scripts\explore-output.txt', $out)
Write-Host "Done! Output written to explore-output.txt"
