$c = [IO.File]::ReadAllText('D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js')
Write-Host "File size: $($c.Length)"
Write-Host "_ts=function pos: $($c.IndexOf('_ts=function'))"
Write-Host "[v19-bg] pos: $($c.IndexOf('[v19-bg]'))"
$focusCheck = 'addEventListener("focus"'
Write-Host "addEventListener(focus) pos: $($c.IndexOf($focusCheck))"
Write-Host "FOCUS pos: $($c.IndexOf('FOCUS'))"
Write-Host "scrollTo pos: $($c.IndexOf('scrollTo'))"
Write-Host "MC-validate-ignore pos: $($c.IndexOf('MC-validate-ignore'))"
Write-Host "resolve(Di) pos: $($c.IndexOf('resolve(Di)'))"
$vCheck = 'visibilitychange'
$vInArea = $c.Substring(7458679, 3000)
Write-Host "visibilitychange in v19 area: $($vInArea.IndexOf($vCheck))"
