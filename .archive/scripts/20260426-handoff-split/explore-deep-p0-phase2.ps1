<#
.SYNOPSIS
P0 盲区 Phase 2 聚焦扫描 — 10KB 级细扫
.DESCRIPTION
对偏移量 54415-6268469 (~6.2MB) 执行 10KB 级采样，每 10240 字符取 400 字符样本，
执行多模式匹配，分类为高/中/低价值命中。
#>

param(
    [string]$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js",
    [int]$StartOffset = 54415,
    [int]$EndOffset = 6268469,
    [int]$StepSize = 10240,
    [int]$SampleSize = 400,
    [string]$OutputFile = "d:\Test\trae-unlock\scripts\explore-deep-p0-phase2-results.txt"
)

$ErrorActionPreference = "Continue"

Write-Host "=== P0 盲区 Phase 2 聚焦扫描 ===" -ForegroundColor Cyan
Write-Host "目标文件: $TargetFile"
Write-Host "扫描范围: $StartOffset - $EndOffset ($([math]::Round(($EndOffset - $StartOffset) / 1MB, 2)) MB)"
Write-Host "步长: $StepSize | 样本: $SampleSize 字符"
Write-Host ""

if (-not (Test-Path $TargetFile)) {
    Write-Host "ERROR: 目标文件不存在: $TargetFile" -ForegroundColor Red
    return
}

Write-Host "[1/3] 读取目标文件..." -ForegroundColor Yellow
$c = [System.IO.File]::ReadAllText($TargetFile)
Write-Host "  文件大小: $($c.Length) 字符" -ForegroundColor Green

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("=== P0 盲区 Phase 2 聚焦扫描结果 ===")
[void]$sb.AppendLine("扫描时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb.AppendLine("文件大小: $($c.Length) 字符")
[void]$sb.AppendLine("扫描范围: $StartOffset - $EndOffset")
[void]$sb.AppendLine("")

$highHits = [System.Collections.ArrayList]::new()
$mediumHits = [System.Collections.ArrayList]::new()
$lowHits = [System.Collections.ArrayList]::new()

$totalSamples = [math]::Floor(($EndOffset - $StartOffset) / $StepSize)
$sampleCount = 0

Write-Host "[2/3] 执行采样扫描 ($totalSamples 个采样点)..." -ForegroundColor Yellow

for ($offset = $StartOffset; $offset -lt $EndOffset; $offset += $StepSize) {
    $sampleCount++
    if ($offset + $SampleSize -gt $c.Length) { break }
    $sample = $c.Substring($offset, $SampleSize)

    $hitDetail = [System.Collections.ArrayList]::new()
    $hitCategory = "none"

    # --- 高价值模式 ---
    # DI 注入: uX( / uJ({identifier:
    if ($sample -match 'uX\(' -or $sample -match 'uJ\(\{identifier:') {
        [void]$hitDetail.Add("[DI] DI注入模式")
        $hitCategory = "high"
    }

    # 类定义: class 
    $classMatches = [regex]::Matches($sample, 'class\s+\w+')
    if ($classMatches.Count -gt 0) {
        $classNames = ($classMatches | ForEach-Object { $_.Value }) -join ", "
        [void]$hitDetail.Add("[CLASS] $classNames")
        $hitCategory = "high"
    }

    # API 方法名
    $apiPatterns = @(
        @{Name="resumeChat"; Pattern="resumeChat"},
        @{Name="sendChatMessage"; Pattern="sendChatMessage"},
        @{Name="provideUserResponse"; Pattern="provideUserResponse"},
        @{Name="cancelChat"; Pattern="cancelChat"},
        @{Name="stopStreaming"; Pattern="stopStreaming"},
        @{Name="handleError"; Pattern="handleError"},
        @{Name="onError"; Pattern="onError"},
        @{Name="registerService"; Pattern="registerService"},
        @{Name="provide"; Pattern="\.provide\("},
        @{Name="getInstance"; Pattern="getInstance"},
        @{Name="resolve"; Pattern="\.resolve\("},
        @{Name="inject"; Pattern="\.inject\("}
    )

    foreach ($p in $apiPatterns) {
        if ($sample -match $p.Pattern) {
            [void]$hitDetail.Add("[API] $($p.Name)")
            if ($hitCategory -ne "high") { $hitCategory = "high" }
        }
    }

    # Symbol 模式
    $symbolMatches = [regex]::Matches($sample, 'Symbol\.for\("([^"]+)"\)')
    if ($symbolMatches.Count -gt 0) {
        $symNames = ($symbolMatches | ForEach-Object { $_.Groups[1].Value }) -join ", "
        [void]$hitDetail.Add("[SYMBOL-FOR] $symNames")
        $hitCategory = "high"
    }

    $symbolMatches2 = [regex]::Matches($sample, 'Symbol\("([^"]+)"\)')
    if ($symbolMatches2.Count -gt 0) {
        $symNames2 = ($symbolMatches2 | ForEach-Object { $_.Groups[1].Value }) -join ", "
        [void]$hitDetail.Add("[SYMBOL] $symNames2")
        $hitCategory = "high"
    }

    # --- 中价值模式 ---
    # 中文字符
    $chineseMatches = [regex]::Matches($sample, '[\u4e00-\u9fff]+')
    if ($chineseMatches.Count -gt 0) {
        $chineseTexts = ($chineseMatches | ForEach-Object { $_.Value } | Select-Object -First 3) -join ", "
        [void]$hitDetail.Add("[CN] $chineseTexts")
        if ($hitCategory -eq "none") { $hitCategory = "medium" }
    }

    # 错误/失败字符串
    $errorPatterns = @("Failed to", "Error:", "Please", "Warning:", "cannot", "invalid", "timeout", "unauthorized", "forbidden")
    foreach ($ep in $errorPatterns) {
        if ($sample -match [regex]::Escape($ep)) {
            [void]$hitDetail.Add("[ERR] $ep")
            if ($hitCategory -eq "none") { $hitCategory = "medium" }
        }
    }

    # URL
    $urlMatches = [regex]::Matches($sample, 'https://[^\s"]{5,50}')
    if ($urlMatches.Count -gt 0) {
        $urls = ($urlMatches | ForEach-Object { $_.Value } | Select-Object -First 2) -join ", "
        [void]$hitDetail.Add("[URL] $urls")
        if ($hitCategory -eq "none") { $hitCategory = "medium" }
    }

    # --- 低价值模式（第三方库标识）---
    $libPatterns = @(
        @{Name="React"; Pattern="react|React\.Component|createElement"},
        @{Name="D3"; Pattern="d3\.|d3Selection|d3Scale"},
        @{Name="Mermaid"; Pattern="mermaid|Mermaid"},
        @{Name="Chevrotain"; Pattern="chevrotain|CstParser|Lexer"},
        @{Name="YAML"; Pattern="yaml\.YAML|YAMLException"},
        @{Name="Markdown"; Pattern="markdown-it|remark|rehype"},
        @{Name="Lodash"; Pattern="lodash|_\.\w+chain"},
        @{Name="Immutable"; Pattern="Immutable\.Map|Immutable\.List"}
    )

    $libDetected = @()
    foreach ($lp in $libPatterns) {
        if ($sample -match $lp.Pattern) {
            $libDetected += $lp.Name
        }
    }

    if ($libDetected.Count -gt 0) {
        [void]$hitDetail.Add("[LIB] $($libDetected -join ', ')")
        if ($hitCategory -eq "none") { $hitCategory = "low" }
    }

    # 记录命中
    if ($hitCategory -ne "none" -and $hitDetail.Count -gt 0) {
        $detail = $hitDetail -join " | "
        $entry = @{Offset=$offset; Detail=$detail; Category=$hitCategory; Sample=$sample}

        switch ($hitCategory) {
            "high"   { [void]$highHits.Add($entry) }
            "medium" { [void]$mediumHits.Add($entry) }
            "low"    { [void]$lowHits.Add($entry) }
        }
    }

    if ($sampleCount % 100 -eq 0) {
        Write-Host "  进度: $sampleCount / $totalSamples (高:$($highHits.Count) 中:$($mediumHits.Count) 低:$($lowHits.Count))" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "扫描完成: $sampleCount 个采样点" -ForegroundColor Green
Write-Host "  高价值命中: $($highHits.Count)" -ForegroundColor Red
Write-Host "  中价值命中: $($mediumHits.Count)" -ForegroundColor Yellow
Write-Host "  低价值命中: $($lowHits.Count)" -ForegroundColor DarkGray
Write-Host ""

# --- 输出高价值命中 ---
[void]$sb.AppendLine("## 高价值命中 (DI/类/API/Symbol) — $($highHits.Count) 个")
[void]$sb.AppendLine("")

$highHitsSorted = $highHits | Sort-Object { $_.Offset }

foreach ($h in $highHitsSorted) {
    $preview = $h.Sample.Substring(0, [math]::Min(120, $h.Sample.Length)) -replace "`n", " " -replace "`r", ""
    $line = "OFFSET=$($h.Offset) | $($h.Detail)"
    [void]$sb.AppendLine($line)
    [void]$sb.AppendLine("  PREVIEW: $preview")
    [void]$sb.AppendLine("")
}

# --- 输出中价值命中 ---
[void]$sb.AppendLine("## 中价值命中 (字符串/URL) — $($mediumHits.Count) 个")
[void]$sb.AppendLine("")

$mediumHitsSorted = $mediumHits | Sort-Object { $_.Offset }

foreach ($m in $mediumHitsSorted) {
    $preview = $m.Sample.Substring(0, [math]::Min(120, $m.Sample.Length)) -replace "`n", " " -replace "`r", ""
    $line = "OFFSET=$($m.Offset) | $($m.Detail)"
    [void]$sb.AppendLine($line)
    [void]$sb.AppendLine("  PREVIEW: $preview")
    [void]$sb.AppendLine("")
}

# --- 输出低价值命中摘要 ---
[void]$sb.AppendLine("## 低价值命中 (第三方库) — $($lowHits.Count) 个 (仅摘要)")
[void]$sb.AppendLine("")

$libSummary = @{}
foreach ($l in $lowHits) {
    if ($l.Detail -match '\[LIB\] ([^|]+)') {
        $libs = $Matches[1].Trim() -split ', '
        foreach ($lib in $libs) {
            if (-not $libSummary.ContainsKey($lib)) { $libSummary[$lib] = 0 }
            $libSummary[$lib]++
        }
    }
}

foreach ($kv in ($libSummary.GetEnumerator() | Sort-Object Value -Descending)) {
    [void]$sb.AppendLine("  $($kv.Key): $($kv.Value) 个采样点")
}

[void]$sb.AppendLine("")

# --- 高价值区间聚类分析 ---
[void]$sb.AppendLine("## 高价值区间聚类分析")
[void]$sb.AppendLine("")

if ($highHitsSorted.Count -gt 0) {
    $clusters = [System.Collections.ArrayList]::new()
    $currentCluster = @{Start=$highHitsSorted[0].Offset; End=$highHitsSorted[0].Offset; Count=1; Details=@($highHitsSorted[0].Detail)}

    for ($i = 1; $i -lt $highHitsSorted.Count; $i++) {
        $h = $highHitsSorted[$i]
        if ($h.Offset - $currentCluster.End -lt 50000) {
            $currentCluster.End = $h.Offset
            $currentCluster.Count++
            $currentCluster.Details += $h.Detail
        } else {
            [void]$clusters.Add($currentCluster)
            $currentCluster = @{Start=$h.Offset; End=$h.Offset; Count=1; Details=@($h.Detail)}
        }
    }
    [void]$clusters.Add($currentCluster)

    $rank = 0
    foreach ($cl in ($clusters | Sort-Object { $_.Count } -Descending)) {
        $rank++
        $size = $cl.End - $cl.Start
        $uniqueDetails = ($cl.Details | Select-Object -Unique) -join " | "
        [void]$sb.AppendLine("  Cluster ${rank}: @ $($cl.Start) - $($cl.End) ($size chars, $($cl.Count) hits)")
        [void]$sb.AppendLine("    特征: $uniqueDetails")
        [void]$sb.AppendLine("")
    }
}

# --- Top 10 高价值目标 ---
[void]$sb.AppendLine("## Top 10 高价值目标 (Phase 3 深挖候选)")
[void]$sb.AppendLine("")

$topTargets = $highHitsSorted | Select-Object -First 10
$rank = 0
foreach ($t in $topTargets) {
    $rank++
    [void]$sb.AppendLine("  #$rank OFFSET=$($t.Offset) | $($t.Detail)")
}

# 写入结果文件
[System.IO.File]::WriteAllText($OutputFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host "[3/3] 结果已写入: $OutputFile" -ForegroundColor Green

# 控制台输出摘要
Write-Host ""
Write-Host "=== 高价值命中摘要 ===" -ForegroundColor Cyan
foreach ($h in $highHitsSorted) {
    Write-Host "  @ $($h.Offset): $($h.Detail)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== 中价值命中摘要 ===" -ForegroundColor Cyan
foreach ($m in ($mediumHitsSorted | Select-Object -First 30)) {
    Write-Host "  @ $($m.Offset): $($m.Detail)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Top 10 深挖候选 ===" -ForegroundColor Magenta
$rank = 0
foreach ($t in $topTargets) {
    $rank++
    Write-Host "  #$rank @ $($t.Offset): $($t.Detail)" -ForegroundColor Magenta
}
