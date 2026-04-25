$c = [IO.File]::ReadAllText('D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js')
Write-Host "File size: $($c.Length)"
Write-Host "[v19-bg] pos: $($c.IndexOf('[v19-bg]'))"
Write-Host "MC-validate-ignore pos: $($c.IndexOf('MC-validate-ignore'))"
Write-Host "resumeCount>=1 pos: $($c.IndexOf('resumeCount>=1'))"
Write-Host "resolve(Di) pos: $($c.IndexOf('resolve(Di)'))"
Write-Host "session_id pos: $($c.IndexOf('session_id'))"
Write-Host "Validate pos: $($c.IndexOf('Validate'))"
