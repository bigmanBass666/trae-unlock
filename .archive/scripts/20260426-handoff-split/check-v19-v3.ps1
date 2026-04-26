$c = [IO.File]::ReadAllText('D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js')
Write-Host "File size: $($c.Length)"
Write-Host "[v19-bg] pos: $($c.IndexOf('[v19-bg]'))"
Write-Host "resolve(Di) pos: $($c.IndexOf('resolve(Di)'))"
Write-Host "_cs.resumeChat pos: $($c.IndexOf('_cs.resumeChat'))"
Write-Host "MC-resume pos: $($c.IndexOf('MC-resume'))"
Write-Host "MC-no-svc pos: $($c.IndexOf('MC-no-svc'))"
Write-Host "resolve(BR) in v19 area: $(($c.Substring(7458700,2000)).IndexOf('resolve(BR)'))"
