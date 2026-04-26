$sourceFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$c = [System.IO.File]::ReadAllText($sourceFile)

$patterns = @(
    'uJ({identifier',
    'uJ({identifier:',
    'uJ({ identifier',
    'uJ( {identifier',
    'identifier:Symbol',
    'identifier:Symbol.for',
    'identifier:Symbol(',
    '.identifier:'
)

foreach ($p in $patterns) {
    $count = ([regex]::Matches($c, [regex]::Escape($p))).Count
    Write-Host "$p : $count matches"
}

Write-Host "`n--- Searching for uJ usage patterns ---"
$ujMatches = [regex]::Matches($c, 'uJ\(\{')
Write-Host "uJ({ : $($ujMatches.Count) matches"

if ($ujMatches.Count -gt 0) {
    Write-Host "`nFirst 5 uJ({ contexts:"
    foreach ($m in $ujMatches | Select-Object -First 5) {
        $start = $m.Index
        $ctx = $c.Substring($start, [Math]::Min(200, $c.Length - $start))
        Write-Host "  @${start}: $ctx"
        Write-Host ""
    }
}

Write-Host "`n--- Searching for registration-like patterns ---"
$regPatterns = @(
    @('uJ({', 'uJ\(\{'),
    @('registerSingleton', 'registerSingleton'),
    @('registerService', 'registerService'),
    @('addSingleton', 'addSingleton'),
    @('register(', 'register\('),
    @('.provide(', '\.provide\(')
)

foreach ($rp in $regPatterns) {
    $count = ([regex]::Matches($c, $rp[1])).Count
    Write-Host "$($rp[0]) : $count matches"
}
