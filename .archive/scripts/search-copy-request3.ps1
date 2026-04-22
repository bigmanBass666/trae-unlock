param()
$c = [System.IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")
$sz = $c.Length
$o = [System.Text.StringBuilder]::new()

function ctx($m, $pre=150, $post=200) {
    $s = [Math]::Max(0, $m.Index - $pre)
    $e = [Math]::Min($sz, $m.Index + $m.Length + $post)
    $txt = $c.Substring($s, $e - $s).Replace("`n"," ").Replace("`r","")
    if ($txt.Length -gt 450) { $txt = $txt.Substring(0,450) }
    return $txt
}

[void]$o.AppendLine("=== copy_request_details / copyRequestDetails ===")
$m = [regex]::Matches($c, 'copy_request_details|copyRequestDetails|CopyRequestDetails')
[void]$o.AppendLine("Count: $($m.Count)")
foreach ($x in $m) {
    [void]$o.AppendLine("  OFFSET: $($x.Index) | VAL: [$($x.Value)]")
    [void]$o.AppendLine("  CTX: ...$(ctx $x)...")
}

[void]$o.AppendLine("")
[void]$o.AppendLine("=== RISK_REQUEST (enum def area) ===")
$m2 = [regex]::Matches($c, 'RISK_REQUEST[^_V]')
[void]$o.AppendLine("Count: $($m2.Count)")
foreach ($x in $m2[0..9]) {
    $s = [Math]::Max(0,$x.Index - 40); $e = [Math]::Min($sz, $x.Index + $x.Length + 60)
    [void]$o.AppendLine("  OFFSET: $($x.Index) | VAL: [$($x.Value)] | NEARBY: $($c.Substring($s,$e-$s).Replace('`n',' '))")
}

[void]$o.AppendLine("")
[void]$o.AppendLine("=== error code enum definitions near RISK_REQUEST ===")
$idx = -1
if ($m2.Count -gt 0) { $idx = $m2[0].Index }
if ($idx -gt 0) {
    $regionStart = [Math]::Max(0, $idx - 2000)
    $regionEnd = [Math]::Min($sz, $idx + 3000)
    $region = $c.Substring($regionStart, $regionEnd - $regionStart)
    [void]$o.AppendLine("Region: $regionStart - $regionEnd")
    [void]$o.AppendLine($region)
}

$o.ToString() | Out-File -Encoding UTF8 "d:\Test\trae-unlock\scripts\search-copy-request-output3.txt"
Write-Host "Done. Size: $(($o.ToString()).Length)"
