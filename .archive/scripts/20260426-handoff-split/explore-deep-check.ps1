$path = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$c = [IO.File]::ReadAllText($path)

$patterns = @(
    'Symbol("ICommercialPermissionService")',
    'Symbol.for("ICommercialPermissionService")',
    'ICommercialPermissionService',
    'aiAgent.ICommercialPermissionService',
    'isCommercialUser',
    'isFreeUser',
    'CommercialPermission'
)

Write-Host "--- ICommercialPermissionService Search ---"
foreach ($p in $patterns) {
    $idx = $c.IndexOf($p)
    $count = 0
    $pos = 0
    while (($pos = $c.IndexOf($p, $pos)) -ge 0) { $count++; $pos++ }
    if ($idx -ge 0) {
        Write-Host "  '$p': first=@$idx count=$count (FOUND)"
    } else {
        Write-Host "  '$p': NOT FOUND"
    }
}

Write-Host "`n--- Regenerating beautified.js ---"
. "d:\Test\trae-unlock\scripts\unpack.ps1"
Unpack-TraeIndex -Force
