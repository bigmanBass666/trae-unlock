$TargetPath = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$c = [IO.File]::ReadAllText($TargetPath)

foreach ($kw in @('bJ.Free', 'bJ.Lite', 'bJ.Ultra', 'bJ.Express', 'bJ.Pro', 'var bJ', 'let bJ', 'bJ=')) {
    $idx = $c.IndexOf($kw)
    if ($idx -ge 0) {
        Write-Host "=== '$kw' at offset: $idx ==="
        $start = [Math]::Max(0, $idx - 300)
        $end = [Math]::Min($c.Length, $idx + 600)
        Write-Host $c.Substring($start, $end - $start)
        Write-Host ""
    }
}

Write-Host "=== efi function ==="
$efiIdx = $c.IndexOf('function efi')
if ($efiIdx -ge 0) {
    Write-Host "efi at: $efiIdx"
    Write-Host $c.Substring($efiIdx, [Math]::Min(2000, $c.Length - $efiIdx))
} else {
    $efiIdx2 = $c.IndexOf('efi=')
    if ($efiIdx2 -ge 0) {
        Write-Host "efi= at: $efiIdx2"
        Write-Host $c.Substring($efiIdx2, [Math]::Min(2000, $c.Length - $efiIdx2))
    }
}

Write-Host ""
Write-Host "=== kP function (isInternal check) ==="
$kpIdx = $c.IndexOf('function kP')
if ($kpIdx -ge 0) {
    Write-Host "kP at: $kpIdx"
    Write-Host $c.Substring($kpIdx, [Math]::Min(500, $c.Length - $kpIdx))
}

Write-Host ""
Write-Host "=== entitlementInfo fields ==="
$eiIdx = $c.IndexOf('entitlementInfo?.')
$seen = @{}
while ($eiIdx -ge 0) {
    $fieldStart = $eiIdx + 'entitlementInfo?.'.Length
    $fieldEnd = [Math]::Min($fieldStart + 40, $c.Length)
    $field = $c.Substring($fieldStart, $fieldEnd - $fieldStart) -replace '[^a-zA-Z0-9_].*',''
    if (-not $seen.ContainsKey($field)) {
        $seen[$field] = $eiIdx
        Write-Host "  entitlementInfo?.${field} at offset: $eiIdx"
    }
    $eiIdx = $c.IndexOf('entitlementInfo?.', $eiIdx + 1)
}
