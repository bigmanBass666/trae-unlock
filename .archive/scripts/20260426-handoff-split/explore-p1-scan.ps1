param(
    [switch]$DiagnoseOnly
)

$p = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$outFile = "d:\Test\trae-unlock\scripts\explore-p1-results.txt"

$start = 8930000
$end = 10489266
$step = 51200
$sampleLen = 400
$focusLen = 2000

if (-not (Test-Path $p)) {
    Write-Host "ERROR: Target file not found: $p" -ForegroundColor Red
    exit 1
}

Write-Host "Reading file..." -ForegroundColor Cyan
$c = [IO.File]::ReadAllText($p)
$totalLen = $c.Length
Write-Host "File size: $totalLen chars" -ForegroundColor Green

if ($end -gt $totalLen) {
    Write-Host "WARNING: end offset $end > file size $totalLen, adjusting" -ForegroundColor Yellow
    $end = $totalLen
}

$sb = [System.Text.StringBuilder]::new()

[void]$sb.AppendLine("============================================================")
[void]$sb.AppendLine("P1 Blind Spot Scan Results")
[void]$sb.AppendLine("Range: $start - $end ($($end - $start) chars)")
[void]$sb.AppendLine("File: $p")
[void]$sb.AppendLine("File total size: $totalLen chars")
[void]$sb.AppendLine("Scan date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb.AppendLine("============================================================")
[void]$sb.AppendLine("")

function Classify-Sample {
    param([string]$text)
    
    $score = @{
        business   = 0
        react      = 0
        thirdparty = 0
        webpack    = 0
    }
    
    if ($text -match 'createElement|useCallback|useMemo|useEffect|useRef|useState|\.memo\(') { $score.react += 3 }
    if ($text -match 'sX\(\)') { $score.react += 2 }
    if ($text -match 'registerCommand|registerAdapter|IChatListService|ITasksHubService|AgentStore|AgentService') { $score.business += 4 }
    if ($text -match 'settings_|_config|ConfigurationStore|agent_|DI token') { $score.business += 3 }
    try { if ($text -match '[\u4e00-\u9fff]') { $score.business += 2 } } catch {}
    if ($text -match 'class [A-Z]') { $score.business += 2 }
    if ($text -match 'registerCommand|CommandRegistration|commands\.') { $score.business += 2 }
    if ($text -match 'Symbol\.for\(') { $score.business += 3 }
    if ($text -match 'resolve\(|getInstance\(\)|provideSingleton|provideInstance') { $score.business += 2 }
    if ($text -match 'webpack|__webpack_require__|__webpack_modules__') { $score.webpack += 5 }
    if ($text -match 'module\.exports|require\(') { $score.webpack += 2 }
    if ($text -match 'node_modules|\.d\.ts|declare module') { $score.thirdparty += 3 }
    if ($text -match 'lodash|underscore|rxjs|mobx|immer|zustand') { $score.thirdparty += 3 }
    if ($text -match 'tslib|__extends|__assign|__decorate|__awaiter') { $score.thirdparty += 3 }
    if ($text -match 'prototype\.|Object\.defineProperty|hasOwnProperty') { $score.thirdparty += 1 }
    
    $maxScore = ($score.Values | Measure-Object -Maximum).Maximum
    if ($maxScore -eq 0) { return "unknown" }
    
    $candidates = $score.Keys | Where-Object { $score[$_] -eq $maxScore }
    if ($candidates -contains "business") { return "business-logic" }
    if ($candidates -contains "react") { return "thirdparty-react" }
    if ($candidates -contains "webpack") { return "webpack" }
    if ($candidates -contains "thirdparty") { return "thirdparty-other" }
    return "unknown"
}

function Find-Patterns {
    param([string]$text)
    
    $patterns = @()
    
    if ($text -match 'createElement') { $patterns += "createElement" }
    if ($text -match 'useCallback') { $patterns += "useCallback" }
    if ($text -match 'useMemo') { $patterns += "useMemo" }
    if ($text -match 'useEffect') { $patterns += "useEffect" }
    if ($text -match 'sX\(\)') { $patterns += "sX()" }
    if ($text -match '\.memo\(') { $patterns += ".memo(" }
    if ($text -match 'registerCommand') { $patterns += "registerCommand" }
    if ($text -match 'registerAdapter') { $patterns += "registerAdapter" }
    if ($text -match 'settings_') { $patterns += "settings_" }
    if ($text -match '_config') { $patterns += "_config" }
    if ($text -match 'ConfigurationStore') { $patterns += "ConfigurationStore" }
    if ($text -match 'agent_') { $patterns += "agent_" }
    if ($text -match 'AgentStore') { $patterns += "AgentStore" }
    if ($text -match 'AgentService') { $patterns += "AgentService" }
    if ($text -match 'class [A-Z]') { $patterns += "class-def" }
    if ($text -match 'Symbol\.for\(') { $patterns += "Symbol.for" }
    if ($text -match 'resolve\(') { $patterns += "resolve()" }
    if ($text -match 'getInstance\(\)') { $patterns += "getInstance()" }
    if ($text -match 'https?://') { $patterns += "URL" }
    try { if ($text -match '[\u4e00-\u9fff]') { $patterns += "Chinese-text" } } catch {}
    
    $englishWords = [regex]::Matches($text, '"[A-Z][a-z]+(?:\s+[A-Z]?[a-z]+){2,}"')
    if ($englishWords.Count -gt 0) { $patterns += "English-strings($($englishWords.Count))" }
    
    return $patterns
}

[void]$sb.AppendLine("========== SECTION 1: 50KB INTERVAL SAMPLING ==========")
[void]$sb.AppendLine("")

$businessOffsets = @()

for ($off = $start; $off -lt $end; $off += $step) {
    $actualStart = $off
    $actualEnd = [Math]::Min($off + $sampleLen, $end)
    $sampleLenActual = $actualEnd - $actualStart
    if ($sampleLenActual -le 0) { continue }
    
    $sample = $c.Substring($actualStart, $sampleLenActual)
    $classification = Classify-Sample -text $sample
    $patterns = Find-Patterns -text $sample
    
    $patternStr = if ($patterns.Count -gt 0) { $patterns -join ", " } else { "none" }
    
    [void]$sb.AppendLine("--- Offset $actualStart ---")
    [void]$sb.AppendLine("  Classification: $classification")
    [void]$sb.AppendLine("  Patterns: $patternStr")
    [void]$sb.AppendLine("  Sample: $($sample.Substring(0, [Math]::Min(200, $sample.Length)))...")
    [void]$sb.AppendLine("")
    
    if ($classification -eq "business-logic") {
        $businessOffsets += $actualStart
    }
    
    $pct = [Math]::Round(($off - $start) / ($end - $start) * 100)
    Write-Host "`r  Sampling: $pct% (offset $actualStart) - $classification" -NoNewline
}

Write-Host ""
[void]$sb.AppendLine("")

[void]$sb.AppendLine("========== SECTION 2: FOCUSED SCANS ON BUSINESS-LOGIC ==========")
[void]$sb.AppendLine("")

foreach ($boff in $businessOffsets) {
    $focusStart = $boff
    $focusEnd = [Math]::Min($boff + $focusLen, $end)
    $focusActual = $focusEnd - $focusStart
    if ($focusActual -le 0) { continue }
    
    $focusSample = $c.Substring($focusStart, $focusActual)
    
    [void]$sb.AppendLine("--- FOCUSED: Offset $focusStart ($focusActual chars) ---")
    [void]$sb.AppendLine($focusSample)
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("--- END FOCUSED ---")
    [void]$sb.AppendLine("")
    
    Write-Host "  Focused scan at $boff" -ForegroundColor Yellow
}

[void]$sb.AppendLine("========== SECTION 3: TARGETED STRING SEARCHES ==========")
[void]$sb.AppendLine("")

$searches = @(
    @{ name = "registerCommand"; pattern = "registerCommand"; maxResults = -1 },
    @{ name = "registerAdapter"; pattern = "registerAdapter"; maxResults = -1 },
    @{ name = "IChatListService"; pattern = "IChatListService"; maxResults = -1 },
    @{ name = "ITasksHubService"; pattern = "ITasksHubService"; maxResults = -1 },
    @{ name = "settings"; pattern = "settings"; maxResults = 20 }
)

foreach ($search in $searches) {
    $name = $search.name
    $pattern = $search.pattern
    $maxRes = $search.maxResults
    
    [void]$sb.AppendLine("--- Search: '$name' in P1 range ---")
    
    $found = @()
    $searchOff = $start
    $count = 0
    
    while ($searchOff -lt $end) {
        $idx = $c.IndexOf($pattern, $searchOff)
        if ($idx -lt 0 -or $idx -ge $end) { break }
        
        $ctxStart = [Math]::Max($idx - 80, 0)
        $ctxEnd = [Math]::Min($idx + $pattern.Length + 80, $totalLen)
        $context = $c.Substring($ctxStart, $ctxEnd - $ctxStart)
        
        $found += @{ offset = $idx; context = $context }
        $count++
        
        if ($maxRes -gt 0 -and $count -ge $maxRes) { break }
        
        $searchOff = $idx + $pattern.Length
    }
    
    [void]$sb.AppendLine("  Total found in P1: $($found.Count)")
    
    foreach ($f in $found) {
        [void]$sb.AppendLine("  Offset $($f.offset):")
        [void]$sb.AppendLine("    ...$($f.context)...")
    }
    
    [void]$sb.AppendLine("")
    Write-Host "  Search '$name': $($found.Count) occurrences" -ForegroundColor Cyan
}

[void]$sb.AppendLine("--- Search: DI token names containing 'agent' in P1 range ---")

$agentDiPatterns = @(
    "IChatAgent",
    "AgentService",
    "AgentStore",
    "agentService",
    "agentStore",
    "_agent",
    "AgentManager",
    "AgentController",
    "IAgentService",
    "IAgentStore"
)

foreach ($ap in $agentDiPatterns) {
    $searchOff = $start
    $count = 0
    
    while ($searchOff -lt $end) {
        $idx = $c.IndexOf($ap, $searchOff)
        if ($idx -lt 0 -or $idx -ge $end) { break }
        
        $ctxStart = [Math]::Max($idx - 80, 0)
        $ctxEnd = [Math]::Min($idx + $ap.Length + 80, $totalLen)
        $context = $c.Substring($ctxStart, $ctxEnd - $ctxStart)
        
        [void]$sb.AppendLine("  DI-agent '$ap' at offset ${idx}:")
        [void]$sb.AppendLine("    ...$($context)...")
        
        $count++
        $searchOff = $idx + $ap.Length
    }
    
    if ($count -gt 0) {
        Write-Host "  DI-agent '$ap': $count occurrences" -ForegroundColor Magenta
    }
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("========== SECTION 4: SUMMARY ==========")
[void]$sb.AppendLine("")

$totalSamples = [Math]::Ceiling(($end - $start) / $step)
$classCounts = @{}
$allClassifications = @()

for ($off = $start; $off -lt $end; $off += $step) {
    $actualStart = $off
    $actualEnd = [Math]::Min($off + $sampleLen, $end)
    $sampleLenActual = $actualEnd - $actualStart
    if ($sampleLenActual -le 0) { continue }
    
    $sample = $c.Substring($actualStart, $sampleLenActual)
    $cls = Classify-Sample -text $sample
    $allClassifications += @{ offset = $actualStart; cls = $cls }
    
    if (-not $classCounts.ContainsKey($cls)) { $classCounts[$cls] = 0 }
    $classCounts[$cls]++
}

[void]$sb.AppendLine("Total sample points: $($allClassifications.Count)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Classification distribution:")
foreach ($key in $classCounts.Keys | Sort-Object) {
    $pct = [Math]::Round($classCounts[$key] / $allClassifications.Count * 100, 1)
    [void]$sb.AppendLine("  $key : $($classCounts[$key]) ($pct%)")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("Business-logic sample points (for focused investigation):")
foreach ($ac in $allClassifications) {
    if ($ac.cls -eq "business-logic") {
        [void]$sb.AppendLine("  Offset $($ac.offset)")
    }
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("All sample points classification:")
foreach ($ac in $allClassifications) {
    [void]$sb.AppendLine("  $($ac.offset): $($ac.cls)")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("========== END OF SCAN ==========")

[IO.File]::WriteAllText($outFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host ""
Write-Host "Results saved to: $outFile" -ForegroundColor Green
Write-Host "Total output size: $($sb.Length) chars" -ForegroundColor Green
