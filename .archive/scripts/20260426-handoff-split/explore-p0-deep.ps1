param(
    [string]$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js",
    [int]$P0Start = 54415,
    [int]$P0End = 6268469,
    [int]$ContextChars = 500,
    [int]$ExpandChars = 2000,
    [int]$TopN = 10,
    [string]$OutputDir = "d:\Test\trae-unlock\scripts"
)

$ErrorActionPreference = "Continue"
$resultsFile = Join-Path $OutputDir "explore-p0-deep-results.txt"
$expandFile = Join-Path $OutputDir "explore-p0-deep-expand.txt"

Write-Host "=== P0 Deep Exploration ===" -ForegroundColor Cyan
Write-Host "Target: $TargetFile"
Write-Host "P0 Range: $P0Start - $P0End ($(($P0End - $P0Start) / 1MB).2 MB)"

if (-not (Test-Path $TargetFile)) {
    Write-Host "ERROR: Target file not found: $TargetFile" -ForegroundColor Red
    exit 1
}

Write-Host "`n[Phase 1] Reading P0 range..." -ForegroundColor Yellow
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$fs = [System.IO.FileStream]::new($TargetFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
$buffer = New-Object byte[] ($P0End - $P0Start)
$fs.Position = $P0Start
[void]$fs.Read($buffer, 0, $buffer.Length)
$fs.Close()
$p0Text = [System.Text.Encoding]::UTF8.GetString($buffer)
$sw.Stop()
Write-Host "  Read $($p0Text.Length) chars in $($sw.ElapsedMilliseconds)ms"

$searches = @(
    @{ Name = "DI_REG"; Pattern = 'uJ({identifier:'; Cat = "business_logic" },
    @{ Name = "DI_INJECT"; Pattern = 'uX('; Cat = "business_logic" },
    @{ Name = "CLASS_DEF"; Pattern = 'class '; Cat = "business_logic" },
    @{ Name = "ASYNC_FUNC"; Pattern = 'async function '; Cat = "business_logic" },
    @{ Name = "RESUME_CHAT"; Pattern = 'resumeChat'; Cat = "business_logic" },
    @{ Name = "SEND_CHAT"; Pattern = 'sendChatMessage'; Cat = "business_logic" },
    @{ Name = "PROVIDE_USER"; Pattern = 'provideUserResponse'; Cat = "business_logic" },
    @{ Name = "AI_AGENT_SYM"; Pattern = 'Symbol.for("aiAgent.'; Cat = "business_logic" },
    @{ Name = "SERVICE_IFACE"; Pattern = 'Symbol("I'; Cat = "business_logic" },
    @{ Name = "REG_CMD"; Pattern = 'registerCommand'; Cat = "business_logic" },
    @{ Name = "REG_ADAPTER"; Pattern = 'registerAdapter'; Cat = "business_logic" },
    @{ Name = "HTTPS_URL"; Pattern = 'https://'; Cat = "api_endpoint" },
    @{ Name = "HTTP_URL"; Pattern = 'http://'; Cat = "api_endpoint" },
    @{ Name = "CN_CHARS"; Pattern = '[\u4e00-\u9fff]'; Cat = "i18n" },
    @{ Name = "CONSOLE_LOG"; Pattern = 'console.log'; Cat = "telemetry" },
    @{ Name = "CONSOLE_WARN"; Pattern = 'console.warn'; Cat = "telemetry" },
    @{ Name = "CONSOLE_ERR"; Pattern = 'console.error'; Cat = "telemetry" },
    @{ Name = "SUBSCRIBE"; Pattern = '.subscribe('; Cat = "business_logic" },
    @{ Name = "GET_STATE"; Pattern = '.getState()'; Cat = "business_logic" },
    @{ Name = "SET_STATE"; Pattern = '.setState('; Cat = "business_logic" },
    @{ Name = "TOOL_CONFIRM"; Pattern = 'tool_confirm'; Cat = "business_logic" }
)

$allHits = @()
$summary = @{}

foreach ($search in $searches) {
    Write-Host "`n  Searching: $($search.Name) [$($search.Pattern)]..." -ForegroundColor Gray
    $positions = @()
    $startIdx = 0
    
    if ($search.Pattern -match '\\u[0-9a-fA-F]{4}' -or $search.Pattern -match '\[' -or $search.Pattern -match '\.') {
        try {
            $regex = New-Object System.Text.RegularExpressions.Regex($search.Pattern, [System.Text.RegularExpressions.RegexOptions]::Compiled)
            $matches = $regex.Matches($p0Text)
            foreach ($m in $matches) {
                $positions += $m.Index
            }
        } catch {
            $idx = $p0Text.IndexOf($search.Pattern.Replace('\u4e00-\u9fff', '').Replace('[', '').Replace(']', '').Replace('\', ''), [System.StringComparison]::Ordinal)
            if ($idx -ge 0) { $positions += $idx }
        }
    } else {
        while (($idx = $p0Text.IndexOf($search.Pattern, $startIdx, [System.StringComparison]::Ordinal)) -ge 0) {
            $positions += $idx
            $startIdx = $idx + 1
            if ($positions.Count -ge 200) { break }
        }
    }
    
    $count = $positions.Count
    $summary[$search.Name] = @{ Count = $count; Category = $search.Cat }
    Write-Host "    Found: $count hits"
    
    foreach ($pos in $positions) {
        $ctxStart = [Math]::Max(0, $pos - [int]($ContextChars / 2))
        $ctxLen = [Math]::Min($ContextChars, $p0Text.Length - $ctxStart)
        $context = $p0Text.Substring($ctxStart, $ctxLen) -replace "`n", " " -replace "`r", ""
        
        $actualCat = $search.Cat
        if ($search.Name -eq "CLASS_DEF") {
            $afterClass = $p0Text.Substring($pos, [Math]::Min(80, $p0Text.Length - $pos))
            if ($afterClass -match 'class [A-Z]') {
                $actualCat = "business_logic"
            } elseif ($afterClass -match 'class [a-z]') {
                $actualCat = "third_party"
            } else {
                $actualCat = "unknown"
            }
        }
        if ($search.Name -eq "ASYNC_FUNC") {
            $afterAsync = $p0Text.Substring($pos, [Math]::Min(100, $p0Text.Length - $pos))
            if ($afterAsync -match 'async function [a-z]') {
                $actualCat = "third_party"
            } else {
                $actualCat = "business_logic"
            }
        }
        if ($search.Name -eq "HTTPS_URL" -or $search.Name -eq "HTTP_URL") {
            $urlCtx = $p0Text.Substring($pos, [Math]::Min(120, $p0Text.Length - $pos))
            if ($urlCtx -match 'byteintlapi|bytegate|bytedance|volcengine|volces|icube|trae|tiktok|douyin|mcs-nontt|pc-mon|libraweb') {
                $actualCat = "api_endpoint"
            } elseif ($urlCtx -match 'github|npmjs|mozilla|w3\.org|schema\.org|example\.com|localhost') {
                $actualCat = "third_party"
            } else {
                $actualCat = "unknown"
            }
        }
        if ($search.Name -eq "DI_INJECT") {
            $injectCtx = $p0Text.Substring($pos, [Math]::Min(60, $p0Text.Length - $pos))
            if ($injectCtx -match 'uX\([A-Z]') {
                $actualCat = "business_logic"
            } else {
                $actualCat = "third_party"
            }
        }
        
        $allHits += [PSCustomObject]@{
            SearchName = $search.Name
            Offset = $P0Start + $pos
            RelativeOffset = $pos
            Category = $actualCat
            Context = $context
        }
    }
}

$blHits = $allHits | Where-Object { $_.Category -eq "business_logic" -or $_.Category -eq "api_endpoint" }
$blHits = $blHits | Sort-Object -Property RelativeOffset -Unique

Write-Host "`n=== Phase 1 Summary ===" -ForegroundColor Cyan
foreach ($key in ($summary.Keys | Sort-Object)) {
    $s = $summary[$key]
    Write-Host "  $($key.PadRight(18)) $($s.Count.ToString().PadLeft(4)) hits  [$($s.Category)]"
}

Write-Host "`n  Business Logic + API Endpoint hits: $($blHits.Count)"

$blGrouped = $blHits | Group-Object -Property SearchName | Sort-Object Count -Descending
Write-Host "`n  By search type:"
foreach ($g in $blGrouped) {
    Write-Host "    $($g.Name.PadRight(18)) $($g.Count) hits"
}

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("=== P0 Deep Exploration Results ===")
[void]$sb.AppendLine("Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb.AppendLine("P0 Range: $P0Start - $P0End")
[void]$sb.AppendLine("P0 Size: $([Math]::Round(($P0End - $P0Start) / 1MB, 2)) MB")
[void]$sb.AppendLine("")

[void]$sb.AppendLine("=== Search Summary ===")
foreach ($key in ($summary.Keys | Sort-Object)) {
    $s = $summary[$key]
    [void]$sb.AppendLine("  $($key.PadRight(18)) $($s.Count.ToString().PadLeft(4)) hits  [$($s.Category)]")
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Business Logic + API Endpoint hits: $($blHits.Count)")
[void]$sb.AppendLine("")

[void]$sb.AppendLine("=== All Business Logic + API Endpoint Hits ===")
[void]$sb.AppendLine("(Sorted by offset)")
foreach ($hit in ($blHits | Sort-Object RelativeOffset)) {
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("--- [$($hit.SearchName)] @$($hit.Offset) [$($hit.Category)] ---")
    [void]$sb.AppendLine($hit.Context)
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("=== All Hits (Full) ===")
foreach ($hit in ($allHits | Sort-Object RelativeOffset)) {
    [void]$sb.AppendLine("[$($hit.SearchName)] @$($hit.Offset) [$($hit.Category)] | $($hit.Context.Substring(0, [Math]::Min(200, $hit.Context.Length)))")
}

$sb.ToString() | Out-File -FilePath $resultsFile -Encoding UTF8 -Force
Write-Host "`n  Results saved to: $resultsFile"

Write-Host "`n[Phase 2] Bidirectional expansion of Top $TopN business logic hits..." -ForegroundColor Yellow

$topHits = $blHits | Sort-Object RelativeOffset | Select-Object -First $TopN
$expandSb = [System.Text.StringBuilder]::new()
[void]$expandSb.AppendLine("=== P0 Deep Exploration - Bidirectional Expansion ===")
[void]$expandSb.AppendLine("Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$expandSb.AppendLine("")

$hitNum = 0
foreach ($hit in $topHits) {
    $hitNum++
    $relOff = $hit.RelativeOffset
    $expStart = [Math]::Max(0, $relOff - $ExpandChars)
    $expEnd = [Math]::Min($p0Text.Length, $relOff + $ExpandChars)
    $expLen = $expEnd - $expStart
    $expanded = $p0Text.Substring($expStart, $expLen)
    
    $methodSigs = @()
    $methodMatches = [System.Text.RegularExpressions.Regex]::Matches($expanded, '(?:async\s+)?(?:function\s+)?(\w+)\s*\([^)]*\)\s*\{')
    foreach ($mm in $methodMatches) {
        $methodSigs += $mm.Value.Substring(0, [Math]::Min(80, $mm.Value.Length))
    }
    
    $classMatches = [System.Text.RegularExpressions.Regex]::Matches($expanded, 'class\s+(\w+)')
    $classNames = @()
    foreach ($cm in $classMatches) {
        $classNames += $cm.Groups[1].Value
    }
    
    $arrowMatches = [System.Text.RegularExpressions.Regex]::Matches($expanded, '(\w+)\s*=\s*(?:async\s*)?\([^)]*\)\s*=>')
    $arrowSigs = @()
    foreach ($am in $arrowMatches) {
        $arrowSigs += "$($am.Groups[1].Value) = () =>"
    }
    
    [void]$expandSb.AppendLine("=== Hit No${hitNum}: [$($hit.SearchName)] @$($hit.Offset) [$($hit.Category)] ===")
    [void]$expandSb.AppendLine("Expansion: $($ExpandChars) chars before + $($ExpandChars) chars after")
    [void]$expandSb.AppendLine("Classes: $($classNames -join ', ')")
    [void]$expandSb.AppendLine("Method signatures: $($methodSigs.Count) found")
    foreach ($sig in $methodSigs) {
        [void]$expandSb.AppendLine("  $sig")
    }
    [void]$expandSb.AppendLine("Arrow functions: $($arrowSigs.Count) found")
    foreach ($sig in $arrowSigs) {
        [void]$expandSb.AppendLine("  $sig")
    }
    [void]$expandSb.AppendLine("")
    [void]$expandSb.AppendLine("--- Expanded Context ---")
    [void]$expandSb.AppendLine($expanded)
    [void]$expandSb.AppendLine("")
    [void]$expandSb.AppendLine("--- End Hit #$hitNum ---")
    [void]$expandSb.AppendLine("")
    
    Write-Host "  #$hitNum [$($hit.SearchName)] @$($hit.Offset) - Classes: $($classNames -join ',') - Methods: $($methodSigs.Count)"
}

$expandSb.ToString() | Out-File -FilePath $expandFile -Encoding UTF8 -Force
Write-Host "`n  Expansion saved to: $expandFile"

Write-Host "`n=== P0 Deep Exploration Complete ===" -ForegroundColor Green
Write-Host "  Total hits: $($allHits.Count)"
Write-Host "  Business logic + API: $($blHits.Count)"
Write-Host "  Top $TopN expanded to: $expandFile"
