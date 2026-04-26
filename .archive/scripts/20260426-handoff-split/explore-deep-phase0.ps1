$path = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$f = Get-Item $path -ErrorAction SilentlyContinue
if ($f) {
    Write-Host "File exists: $($f.FullName)"
    Write-Host "Size: $([math]::Round($f.Length / 1MB, 2)) MB"
    Write-Host "Last modified: $($f.LastWriteTime)"
    $c = [IO.File]::ReadAllText($path)
    Write-Host "Total length: $($c.Length) chars"

    $anchors = @(
        @{Name="IPlanItemStreamParser"; Pattern='Symbol("IPlanItemStreamParser")'},
        @{Name="ISessionStore"; Pattern='Symbol("ISessionStore")'},
        @{Name="TASK_TURN_EXCEEDED"; Pattern="4000002"},
        @{Name="ICommercialPermissionService"; Pattern='Symbol("ICommercialPermissionService")'},
        @{Name="IEntitlementStore"; Pattern='Symbol("IEntitlementStore")'},
        @{Name="kg.TASK_TURN_EXCEEDED_ERROR"; Pattern="kg.TASK_TURN_EXCEEDED_ERROR"},
        @{Name="resumeChat"; Pattern="resumeChat"},
        @{Name="provideUserResponse"; Pattern="provideUserResponse"},
        @{Name="uJ({identifier:"; Pattern="uJ({identifier:"},
        @{Name="uX("; Pattern="uX("},
        @{Name="eventHandlerFactory"; Pattern="eventHandlerFactory"},
        @{Name="registerCommand"; Pattern="registerCommand"}
    )

    Write-Host "`n--- Anchor Verification ---"
    foreach ($a in $anchors) {
        $idx = $c.IndexOf($a.Pattern)
        if ($idx -ge 0) {
            Write-Host "  $($a.Name): @$idx (FOUND)"
        } else {
            Write-Host "  $($a.Name): NOT FOUND!"
        }
    }

    $beautifiedPath = "d:\Test\trae-unlock\unpacked\beautified.js"
    if (Test-Path $beautifiedPath) {
        $bf = Get-Item $beautifiedPath
        Write-Host "`n--- Beautified.js ---"
        Write-Host "  Size: $([math]::Round($bf.Length / 1MB, 2)) MB"
        Write-Host "  Last modified: $($bf.LastWriteTime)"
        $blines = (Get-Content $beautifiedPath | Measure-Object -Line).Lines
        Write-Host "  Lines: $blines"
    } else {
        Write-Host "`n--- Beautified.js: NOT FOUND ---"
    }
} else {
    Write-Host "ERROR: File not found at $path"
}
