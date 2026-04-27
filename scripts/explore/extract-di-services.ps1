param(
    [string]$SourceFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js",
    [string]$OutputDir = "d:\Test\trae-unlock\scripts\extract-output"
)

if (-not (Test-Path $SourceFile)) {
    Write-Error "Source file not found: $SourceFile"
    exit 1
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Write-Host "=== DI Service Extraction Script v2 ===" -ForegroundColor Cyan
$content = [System.IO.File]::ReadAllText($SourceFile)
Write-Host "Content loaded: $($content.Length) chars"

# ============================================================
# STEP 0: Build Token variable → Symbol definition map
# ============================================================
Write-Host "`n--- STEP 0: Building Token variable map ---" -ForegroundColor Yellow

$tokenVarMap = @{}

$symbolForMatches = [regex]::Matches($content, '(\w{1,3})=Symbol\.for\("([^"]+)"\)')
Write-Host "Symbol.for definitions: $($symbolForMatches.Count)"
foreach ($m in $symbolForMatches) {
    $varName = $m.Groups[1].Value
    $symStr = $m.Groups[2].Value
    if (-not $tokenVarMap.ContainsKey($varName)) {
        $tokenVarMap[$varName] = @{ Type = "Symbol.for"; String = $symStr; Offset = $m.Index }
    }
}

$symbolMatches = [regex]::Matches($content, '(\w{1,3})=Symbol\("([^"]+)"\)')
Write-Host "Symbol definitions: $($symbolMatches.Count)"
foreach ($m in $symbolMatches) {
    $varName = $m.Groups[1].Value
    $symStr = $m.Groups[1].Value
    if (-not $tokenVarMap.ContainsKey($varName)) {
        $tokenVarMap[$varName] = @{ Type = "Symbol"; String = $m.Groups[2].Value; Offset = $m.Index }
    }
}

Write-Host "Token variable map size: $($tokenVarMap.Count)"

# ============================================================
# PART 1: Extract uJ({identifier:XXX}) registrations
# ============================================================
Write-Host "`n--- PART 1: Extracting uJ({identifier:XXX}) registrations ---" -ForegroundColor Yellow

$ujLiteralPattern = 'uJ({identifier:'
$ujResults = @()
$ujSearchStart = 0
$ujCount = 0

while (($ujSearchStart = $content.IndexOf($ujLiteralPattern, $ujSearchStart)) -ge 0) {
    $ujCount++
    $contextAfter = $content.Substring($ujSearchStart, [Math]::Min(500, $content.Length - $ujSearchStart))
    
    $tokenVar = ""
    $tokenType = ""
    $tokenString = ""
    $className = ""
    
    if ($contextAfter -match 'uJ\(\{identifier:(\w+)\}') {
        $tokenVar = $Matches[1]
    }
    
    if ($tokenVar -and $tokenVarMap.ContainsKey($tokenVar)) {
        $tokenType = $tokenVarMap[$tokenVar].Type
        $tokenString = $tokenVarMap[$tokenVar].String
    }
    
    $contextExtended = $content.Substring($ujSearchStart, [Math]::Min(2000, $content.Length - $ujSearchStart))
    if ($contextExtended -match 'class\s+(\w+)') {
        $className = $Matches[1]
    }
    
    $ujResults += [PSCustomObject]@{
        Index = $ujCount
        Offset = $ujSearchStart
        TokenVar = $tokenVar
        TokenType = $tokenType
        TokenString = $tokenString
        ClassName = $className
    }
    
    $ujSearchStart += $ujLiteralPattern.Length
}

Write-Host "Found $ujCount uJ registrations" -ForegroundColor Green

$ujResults | ForEach-Object {
    "$($_.Index)|$($_.Offset)|$($_.TokenVar)|$($_.TokenType)|$($_.TokenString)|$($_.ClassName)"
} | Out-File -FilePath "$OutputDir\uj-registrations.txt" -Encoding UTF8

$ujResults | Export-Csv -Path "$OutputDir\uj-registrations.csv" -NoTypeInformation -Encoding UTF8

Write-Host "`nRegistration breakdown by token type:" -ForegroundColor Cyan
$ujResults | Group-Object TokenType | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor White
}

Write-Host "`nRegistrations with resolved Symbol:" -ForegroundColor Cyan
$resolved = $ujResults | Where-Object { $_.TokenString }
Write-Host "  Resolved: $($resolved.Count)"
$unresolved = $ujResults | Where-Object { -not $_.TokenString }
Write-Host "  Unresolved: $($unresolved.Count)"

if ($unresolved.Count -gt 0) {
    Write-Host "`n  Unresolved token vars (first 20):" -ForegroundColor DarkYellow
    $unresolved | Select-Object -First 20 | ForEach-Object {
        Write-Host "    $($_.TokenVar) @offset $($_.Offset) class=$($_.ClassName)" -ForegroundColor DarkYellow
    }
}

# ============================================================
# PART 2: Extract uX(XXX) injections with target property
# ============================================================
Write-Host "`n--- PART 2: Extracting uX(XXX) injections ---" -ForegroundColor Yellow

$uxLiteralPattern = 'uX('
$uxResults = @()
$uxSearchStart = 0
$uxCount = 0

while (($uxSearchStart = $content.IndexOf($uxLiteralPattern, $uxSearchStart)) -ge 0) {
    $uxCount++
    $contextAfter = $content.Substring($uxSearchStart, [Math]::Min(300, $content.Length - $uxSearchStart))
    
    $tokenVar = ""
    $targetProp = ""
    $tokenType = ""
    $tokenString = ""
    
    if ($contextAfter -match 'uX\((\w+)\)') {
        $tokenVar = $Matches[1]
    }
    
    $contextExtended = $content.Substring($uxSearchStart, [Math]::Min(600, $content.Length - $uxSearchStart))
    
    if ($contextExtended -match 'this\.(_\w+)') {
        $targetProp = $Matches[1]
    }
    
    if ($tokenVar -and $tokenVarMap.ContainsKey($tokenVar)) {
        $tokenType = $tokenVarMap[$tokenVar].Type
        $tokenString = $tokenVarMap[$tokenVar].String
    }
    
    $uxResults += [PSCustomObject]@{
        Index = $uxCount
        Offset = $uxSearchStart
        TokenVar = $tokenVar
        TargetProp = $targetProp
        TokenType = $tokenType
        TokenString = $tokenString
    }
    
    $uxSearchStart += $uxLiteralPattern.Length
}

Write-Host "Found $uxCount uX injections" -ForegroundColor Green

$uxResults | ForEach-Object {
    "$($_.Index)|$($_.Offset)|$($_.TokenVar)|$($_.TargetProp)|$($_.TokenType)|$($_.TokenString)"
} | Out-File -FilePath "$OutputDir\ux-injections.txt" -Encoding UTF8

$uxResults | Export-Csv -Path "$OutputDir\ux-injections.csv" -NoTypeInformation -Encoding UTF8

Write-Host "`nInjection breakdown by Token variable (top 30):" -ForegroundColor Cyan
$uxResults | Group-Object TokenVar | Sort-Object Count -Descending | Select-Object -First 30 | ForEach-Object {
    $symStr = if ($tokenVarMap.ContainsKey($_.Name)) { $tokenVarMap[$_.Name].String } else { "?" }
    Write-Host "  $($_.Name) ($symStr): $($_.Count) injections" -ForegroundColor White
}

# ============================================================
# PART 3: Cross-reference
# ============================================================
Write-Host "`n--- PART 3: Cross-reference registrations <-> injections ---" -ForegroundColor Yellow

$regByToken = @{}
foreach ($reg in $ujResults) {
    if ($reg.TokenVar -and -not $regByToken.ContainsKey($reg.TokenVar)) {
        $regByToken[$reg.TokenVar] = $reg
    }
}

$injByToken = @{}
foreach ($inj in $uxResults) {
    if ($inj.TokenVar) {
        if (-not $injByToken.ContainsKey($inj.TokenVar)) {
            $injByToken[$inj.TokenVar] = @()
        }
        $injByToken[$inj.TokenVar] += $inj
    }
}

$allTokenVars = ($regByToken.Keys + $injByToken.Keys | Sort-Object -Unique)
$crossRef = @()

foreach ($tv in $allTokenVars) {
    $reg = $regByToken[$tv]
    $injs = $injByToken[$tv]
    
    $regTokenString = if ($reg) { $reg.TokenString } else { "" }
    $regTokenType = if ($reg) { $reg.TokenType } else { "" }
    $className = if ($reg) { $reg.ClassName } else { "" }
    $regOffset = if ($reg) { $reg.Offset } else { 0 }
    $injCount = if ($injs) { $injs.Count } else { 0 }
    $targets = if ($injs) { ($injs | ForEach-Object { $_.TargetProp } | Where-Object { $_ } | Sort-Object -Unique) -join ", " } else { "" }
    
    if (-not $regTokenString -and $tokenVarMap.ContainsKey($tv)) {
        $regTokenType = $tokenVarMap[$tv].Type
        $regTokenString = $tokenVarMap[$tv].String
    }
    
    $crossRef += [PSCustomObject]@{
        TokenVar = $tv
        TokenType = $regTokenType
        TokenString = $regTokenString
        ClassName = $className
        RegOffset = $regOffset
        InjectionCount = $injCount
        TargetProps = $targets
        HasRegistration = [bool]$reg
    }
}

$crossRef | Sort-Object InjectionCount -Descending | Export-Csv -Path "$OutputDir\cross-reference.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Cross-reference: $($crossRef.Count) unique token variables" -ForegroundColor Green

$registered = $crossRef | Where-Object { $_.HasRegistration }
$unregInj = $crossRef | Where-Object { -not $_.HasRegistration -and $_.InjectionCount -gt 0 }
$regNoInj = $crossRef | Where-Object { $_.HasRegistration -and $_.InjectionCount -eq 0 }

Write-Host "  Registered + Injected: $($registered.Count)"
Write-Host "  Injected only (no uJ): $($unregInj.Count)"
Write-Host "  Registered only (no uX): $($regNoInj.Count)"

Write-Host "`nTop 30 injected tokens:" -ForegroundColor Cyan
$crossRef | Sort-Object InjectionCount -Descending | Select-Object -First 30 | ForEach-Object {
    Write-Host "  $($_.TokenVar) [$($_.TokenType):$($_.TokenString)] class=$($_.ClassName) inj=$($_.InjectionCount) → $($_.TargetProps)" -ForegroundColor White
}

# ============================================================
# PART 4: Domain grouping
# ============================================================
Write-Host "`n--- PART 4: Domain grouping ---" -ForegroundColor Yellow

$domains = @{
    "Session" = @()
    "Store" = @()
    "Stream/Parser" = @()
    "Credential" = @()
    "Agent" = @()
    "Command" = @()
    "Commercial" = @()
    "Log/Telemetry" = @()
    "File/Doc" = @()
    "UI/View" = @()
    "Network/API" = @()
    "Config" = @()
    "Other" = @()
}

foreach ($cr in $crossRef) {
    $ts = $cr.TokenString
    $cn = $cr.ClassName
    $domain = "Other"
    
    if ($ts -match 'Session|session') { $domain = "Session" }
    elseif ($ts -match 'Store|store') { $domain = "Store" }
    elseif ($ts -match 'Stream|Parser|parser') { $domain = "Stream/Parser" }
    elseif ($ts -match 'Credential|credential') { $domain = "Credential" }
    elseif ($ts -match 'Agent|agent') { $domain = "Agent" }
    elseif ($ts -match 'Command|command') { $domain = "Command" }
    elseif ($ts -match 'Commercial|commercial|Entitlement|entitlement|Permission|permission') { $domain = "Commercial" }
    elseif ($ts -match 'Log|log|Tea|tea|Telemetry|telemetry|Slardar|slardar') { $domain = "Log/Telemetry" }
    elseif ($ts -match 'File|file|Doc|doc|Docset|docset') { $domain = "File/Doc" }
    elseif ($ts -match 'View|view|UI|ui|Native|native') { $domain = "UI/View" }
    elseif ($ts -match 'Api|api|Http|http|Client|client|Network|network') { $domain = "Network/API" }
    elseif ($ts -match 'Config|config|Setting|setting|Preference|preference') { $domain = "Config" }
    
    $domains[$domain] += $cr
}

foreach ($d in ($domains.Keys | Sort-Object)) {
    $items = $domains[$d]
    if ($items.Count -gt 0) {
        Write-Host "  $d ($($items.Count) services):" -ForegroundColor Cyan
        foreach ($item in $items | Sort-Object TokenString) {
            Write-Host "    $($item.TokenVar) | $($item.TokenType) | $($item.TokenString) | class=$($item.ClassName) | inj=$($item.InjectionCount)" -ForegroundColor White
        }
    }
}

# ============================================================
# Summary
# ============================================================
Write-Host "`n=== EXTRACTION SUMMARY ===" -ForegroundColor Cyan
Write-Host "Source file size: $($content.Length) chars"
Write-Host "uJ registrations: $($ujResults.Count)"
Write-Host "uX injections: $($uxResults.Count)"
Write-Host "Unique token vars (registrations): $(($ujResults | Where-Object { $_.TokenVar } | Select-Object -ExpandProperty TokenVar | Sort-Object -Unique).Count)"
Write-Host "Unique token vars (injections): $(($uxResults | Where-Object { $_.TokenVar } | Select-Object -ExpandProperty TokenVar | Sort-Object -Unique).Count)"
Write-Host "Token var map (Symbol definitions): $($tokenVarMap.Count)"
Write-Host "Resolved registrations: $(($ujResults | Where-Object { $_.TokenString }).Count)"
Write-Host "Unresolved registrations: $(($ujResults | Where-Object { -not $_.TokenString }).Count)"
Write-Host "Cross-referenced tokens: $($crossRef.Count)"

Write-Host "`nOutput files:"
Write-Host "  $OutputDir\uj-registrations.txt"
Write-Host "  $OutputDir\uj-registrations.csv"
Write-Host "  $OutputDir\ux-injections.txt"
Write-Host "  $OutputDir\ux-injections.csv"
Write-Host "  $OutputDir\cross-reference.csv"
