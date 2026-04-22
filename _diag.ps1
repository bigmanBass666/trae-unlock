$def = Get-Content 'patches\definitions.json' -Raw | ConvertFrom-Json
$targetFile = $def.meta.target_file
$content = [System.IO.File]::ReadAllText($targetFile)

Write-Host "Target file: $targetFile"
Write-Host "File size (bytes): $($content.Length)"

# 搜索 if(V&&J) 区域
$idx = $content.IndexOf('if(V&&J)')
if ($idx -ge 0) {
    $snippet = $content.Substring($idx, [Math]::Min(800, $content.Length - $idx))
    Write-Host "`n=== if(V&&J) at offset $idx ==="
    Write-Host $snippet
} else {
    Write-Host "`n if(V&&J) NOT FOUND!"
    $idx2 = $content.IndexOf('[v7-auto]')
    if ($idx2 -ge 0) {
        $ctx = [Math]::Max(0, $idx2 - 200)
        Write-Host "`n=== [v7-auto] found at $idx2, context from $ctx ==="
        Write-Host $content.Substring($ctx, [Math]::Min(600, $content.Length - $ctx))
    }
}

# 搜索 ec= 区域
$idx3 = $content.IndexOf('ec=(0,Ir.Z)')
if ($idx3 -ge 0) {
    $snippet2 = $content.Substring($idx3, [Math]::Min(700, $content.Length - $idx3))
    Write-Host "`n=== ec=(0,Ir.Z) at offset $idx3 ==="
    Write-Host $snippet2
} else {
    $idx4 = $content.IndexOf('[v7-manual]')
    if ($idx4 -ge 0) {
        $ctxStart = [Math]::Max(0, $idx4 - 150)
        $snippet3 = $content.Substring($ctxStart, [Math]::Min(500, $content.Length - $ctxStart))
        Write-Host "`n=== [v7-manual] found at $idx4 ==="
        Write-Host $snippet3
    } else {
        $idx5 = $content.LastIndexOf('ec=(')
        if ($idx5 -ge 0) {
            $ctx5 = [Math]::Max(0, $idx5 - 50)
            Write-Host "`n=== last ec=( found at $idx5 ==="
            Write-Host $content.Substring($ctx5, [Math]::Min(400, $content.Length - $ctx5))
        } else {
            Write-Host "[v7-manual] NOT FOUND and ec=( NOT FOUND either!"
        }
    }
}
