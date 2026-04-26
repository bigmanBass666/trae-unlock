$sourceFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$c = [System.IO.File]::ReadAllText($sourceFile)

$dollarVars = @('E\$', 'M\$', 'I\$', 'B\$', 'T\$')
foreach ($dv in $dollarVars) {
    $pattern = "(${dv})=Symbol\.for\(`"([^`"]+)`"\)"
    $matches = [regex]::Matches($c, $pattern)
    Write-Host "$dv = Symbol.for: $($matches.Count) matches"
    foreach ($m in $matches) {
        Write-Host "  $($m.Groups[1].Value) = Symbol.for(`"$($m.Groups[2].Value)`") @offset $($m.Index)"
    }
    
    $pattern2 = "(${dv})=Symbol\(`"([^`"]+)`"\)"
    $matches2 = [regex]::Matches($c, $pattern2)
    Write-Host "$dv = Symbol: $($matches2.Count) matches"
    foreach ($m in $matches2) {
        Write-Host "  $($m.Groups[1].Value) = Symbol(`"$($m.Groups[2].Value)`") @offset $($m.Index)"
    }
    Write-Host ""
}

Write-Host "=== WK.IDocsetService ==="
$idx = $c.IndexOf('WK.IDocsetService')
if ($idx -ge 0) {
    $ctx = $c.Substring([Math]::Max(0, $idx - 200), [Math]::Min(400, $c.Length - [Math]::Max(0, $idx - 200)))
    Write-Host $ctx
}

Write-Host "`n=== ITokenService ==="
$idx = $c.IndexOf('"ITokenService"')
if ($idx -ge 0) {
    $ctx = $c.Substring([Math]::Max(0, $idx - 200), [Math]::Min(400, $c.Length - [Math]::Max(0, $idx - 200)))
    Write-Host $ctx
}

Write-Host "`n=== Do variable definition ==="
$doMatches = [regex]::Matches($c, '([^a-zA-Z])Do=Symbol')
foreach ($m in $doMatches) {
    Write-Host "  Do=Symbol @offset $($m.Index)"
    $ctx = $c.Substring($m.Index, [Math]::Min(100, $c.Length - $m.Index))
    Write-Host "  $ctx"
}

$doMatches2 = [regex]::Matches($c, '([^a-zA-Z])Do="')
foreach ($m in $doMatches2) {
    Write-Host "  Do=`" @offset $($m.Index)"
    $ctx = $c.Substring($m.Index, [Math]::Min(100, $c.Length - $m.Index))
    Write-Host "  $ctx"
}

Write-Host "`n=== jP variable definition ==="
$jpMatches = [regex]::Matches($c, '([^a-zA-Z])jP=Symbol')
foreach ($m in $jpMatches) {
    Write-Host "  jP=Symbol @offset $($m.Index)"
    $ctx = $c.Substring($m.Index, [Math]::Min(100, $c.Length - $m.Index))
    Write-Host "  $ctx"
}

$jpMatches2 = [regex]::Matches($c, '([^a-zA-Z])jP="')
foreach ($m in $jpMatches2) {
    Write-Host "  jP=`" @offset $($m.Index)"
    $ctx = $c.Substring($m.Index, [Math]::Min(100, $c.Length - $m.Index))
    Write-Host "  $ctx"
}
