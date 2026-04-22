param()

$ErrorActionPreference = "Continue"
$f = "D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js"
$out = "d:\Test\trae-unlock\scripts\search-copy-request-output2.txt"
$c = [System.IO.File]::ReadAllText($f)
$sz = $c.Length
$o = [System.Text.StringBuilder]::new()

function ctx($m, $pre=100, $post=150) {
    $s = [Math]::Max(0, $m.Index - $pre)
    $e = [Math]::Min($sz, $m.Index + $m.Length + $post)
    $txt = $c.Substring($s, $e - $s).Replace("`n"," ").Replace("`r","")
    if ($txt.Length -gt 350) { $txt = $txt.Substring(0,350) + "..." }
    return $txt
}

[void]$o.AppendLine("=== Search 1: exact Chinese text '复制请求' ===")
$m1 = [regex]::Matches($c, '复制请求')
[void]$o.AppendLine("Matches: $($m1.Count)")
foreach ($x in $m1) {
    [void]$o.AppendLine("  Offset: $($x.Index) | Val: [$($x.Value)]")
    [void]$o.AppendLine("  Ctx: ...$(ctx $x)...")
}

[void]$o.AppendLine("")
[void]$o.AppendLine("=== Search 2: broader ID format (dot + long digits + colon + word) ===")
$m2 = [regex]::Matches($c, '\.\d{10,}:\w+')
[void]$o.AppendLine("Matches: $($m2.Count)")
foreach ($x in $m2[0..([Math]::Min(19,$m2.Count-1))]) {
    [void]$o.AppendLine("  Offset: $($x.Index) | Val: [$($x.Value)]")
    [void]$o.AppendLine("  Ctx: ...$(ctx $x 60 100)...")
}

[void]$o.AppendLine("")
[void]$o.AppendLine("=== Search 3: requestInfo / RequestInfo / request_info ===")
$m3 = [regex]::Matches($c, '(?i)request[_-]?info|requestInfo|RequestInfo')
[void]$o.AppendLine("Matches: $($m3.Count)")
foreach ($x in $m3) {
    [void]$o.AppendLine("  Offset: $($x.Index) | Val: [$($x.Value)]")
    [void]$o.AppendLine("  Ctx: ...$(ctx $x 80 150)...")
}

[void]$o.AppendLine("")
[void]$o.AppendLine("=== Search 4: copy request / request info button ===")
$m4 = [regex]::Matches($c, '(?i)copy.*request|request.*info.*button|infoButton|detailButton|复制.*信息|复制.*详情')
[void]$o.AppendLine("Matches: $($m4.Count)")
foreach ($x in $m4) {
    [void]$o.AppendLine("  Offset: $($x.Index) | Val: [$($x.Value)]")
    [void]$o.AppendLine("  Ctx: ...$(ctx $x 80 150)...")
}

[void]$o.AppendLine("")
[void]$o.AppendLine("=== Search 5: Alert component with action/copy near error area (8700000-8720000) ===")
$rs = 8700000; $re = [Math]::Min($sz, 8720000)
if ($sz -gt $re) {
    $region = $c.Substring($rs, $re - $rs)
    [void]$o.AppendLine("Region size: $($region.Length) chars")
    $am = [regex]::Matches($region, '(?i)(actionText|buttonAction|onActionClick|onCopy|copyDetail|detailText|showDetail)')
    [void]$o.AppendLine("Alert-area action-related matches: $($am.Count)")
    foreach ($x in $am) {
        $abs = $rs + $x.Index
        [void]$o.AppendLine("  AbsOffset: $abs | Val: [$($x.Value)]")
        $cs = [Math]::Max(0, $x.Index - 80); $ce = [Math]::Min($region.Length, $x.Index + $x.Length + 120)
        $ctx2 = $region.Substring($cs, $ce - $cs).Replace("`n"," ").Replace("`r","")
        if ($ctx2.Length -gt 300) { $ctx2 = $ctx2.Substring(0,300) }
        [void]$o.AppendLine("  Ctx: ...$ctx2...")
    }
}

[void]$o.AppendLine("")
[void]$o.AppendLine("Done.")
$o.ToString() | Out-File -Encoding UTF8 $out
Write-Host "Saved to $out ($(($o.ToString()).Length) chars)"
