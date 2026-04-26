<#
.SYNOPSIS
P0 盲区 Phase 3 深挖 — 对高价值目标执行双向扩展分析
#>

param(
    [string]$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js",
    [int]$ContextSize = 2000,
    [string]$OutputFile = "d:\Test\trae-unlock\scripts\explore-deep-p0-phase3-results.txt"
)

$ErrorActionPreference = "Continue"

$targets = @(
    @{Name="ai.IDocsetService DI Token"; Offset=3546255; Domain="[DI]"},
    @{Name="HaltChainable Symbol"; Offset=2317455; Domain="[Event]"},
    @{Name="undefined_placeholder Utility"; Offset=2501775; Domain="[Store]"},
    @{Name="GitGraph class"; Offset=3628175; Domain="[IPC]"},
    @{Name="class tu HTTP Transport"; Offset=371855; Domain="[IPC]"},
    @{Name="TEA 埋点错误处理"; Offset=535695; Domain="[Event]"},
    @{Name="文件上传验证"; Offset=2737295; Domain="[Sandbox]"},
    @{Name="知识库初始化"; Offset=6147215; Domain="[Setting]"},
    @{Name="支付相关UI"; Offset=6157455; Domain="[Commercial]"},
    @{Name="TikTok API 端点"; Offset=5870735; Domain="[IPC]"}
)

Write-Host "=== P0 盲区 Phase 3 深挖 ===" -ForegroundColor Cyan
Write-Host "目标数量: $($targets.Count)"
Write-Host "上下文大小: 前后各 $ContextSize 字符"
Write-Host ""

if (-not (Test-Path $TargetFile)) {
    Write-Host "ERROR: 目标文件不存在" -ForegroundColor Red
    return
}

Write-Host "[1/3] 读取目标文件..." -ForegroundColor Yellow
$c = [System.IO.File]::ReadAllText($TargetFile)
Write-Host "  文件大小: $($c.Length) 字符" -ForegroundColor Green

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("=== P0 盲区 Phase 3 深挖结果 ===")
[void]$sb.AppendLine("分析时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb.AppendLine("")

$findings = [System.Collections.ArrayList]::new()

foreach ($t in $targets) {
    Write-Host "[2/3] 分析: $($t.Name) @ $($t.Offset)..." -ForegroundColor Yellow

    $start = [math]::Max(0, $t.Offset - $ContextSize)
    $end = [math]::Min($c.Length, $t.Offset + $ContextSize)
    $length = $end - $start
    $context = $c.Substring($start, $length)

    [void]$sb.AppendLine("## $($t.Name) @ $($t.Offset)")
    [void]$sb.AppendLine("域标签: $($t.Domain)")
    [void]$sb.AppendLine("上下文范围: $start - $end")
    [void]$sb.AppendLine("")

    # 分析模式
    $analysis = @()

    # DI 注入模式
    $diMatches = [regex]::Matches($context, 'Symbol\.for\("([^"]+)"\)')
    $diMatches2 = [regex]::Matches($context, 'Symbol\("([^"]+)"\)')
    $allSymbols = @()
    foreach ($m in $diMatches) { $allSymbols += "Symbol.for(`"$($m.Groups[1].Value)`")" }
    foreach ($m in $diMatches2) { $allSymbols += "Symbol(`"$($m.Groups[1].Value)`")" }
    if ($allSymbols.Count -gt 0) {
        $analysis += "DI/Symbol tokens: $($allSymbols -join ', ')"
    }

    # 类定义
    $classMatches = [regex]::Matches($context, 'class\s+(\w+)(?:\s+extends\s+(\w+))?')
    $classes = @()
    foreach ($m in $classMatches) {
        if ($m.Groups[2].Success) {
            $classes += "$($m.Groups[1].Value) extends $($m.Groups[2].Value)"
        } else {
            $classes += $m.Groups[1].Value
        }
    }
    if ($classes.Count -gt 0) {
        $analysis += "类定义: $($classes -join ', ')"
    }

    # 方法签名
    $methodMatches = [regex]::Matches($context, '(\w+)\s*\([^)]*\)\s*\{')
    $methods = ($methodMatches | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_.Length -gt 2 } | Select-Object -First 10 | Select-Object -Unique)
    if ($methods.Count -gt 0) {
        $analysis += "方法签名: $($methods -join ', ')"
    }

    # API 方法
    $apiKeywords = @("resumeChat", "sendChatMessage", "provideUserResponse", "cancelChat", "stopStreaming", "handleError", "provide", "resolve", "getInstance", "inject")
    $foundApis = @()
    foreach ($ak in $apiKeywords) {
        if ($context -match [regex]::Escape($ak)) { $foundApis += $ak }
    }
    if ($foundApis.Count -gt 0) {
        $analysis += "API方法: $($foundApis -join ', ')"
    }

    # 中文字符串
    $cnMatches = [regex]::Matches($context, '[\u4e00-\u9fff]{2,}')
    $cnTexts = ($cnMatches | ForEach-Object { $_.Value } | Select-Object -First 5 | Select-Object -Unique)
    if ($cnTexts.Count -gt 0) {
        $analysis += "中文: $($cnTexts -join ', ')"
    }

    # URL
    $urlMatches = [regex]::Matches($context, 'https://[^\s"]{5,80}')
    $urls = ($urlMatches | ForEach-Object { $_.Value } | Select-Object -First 3 | Select-Object -Unique)
    if ($urls.Count -gt 0) {
        $analysis += "URL: $($urls -join ', ')"
    }

    # 错误码
    $errMatches = [regex]::Matches($context, '(?:errorCode|error_code|errCode)\s*[=:]\s*(\d+)')
    $errCodes = ($errMatches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
    if ($errCodes.Count -gt 0) {
        $analysis += "错误码: $($errCodes -join ', ')"
    }

    # provide/register 模式
    if ($context -match '\.provide\(' -or $context -match 'registerService' -or $context -match 'uJ\(') {
        $analysis += "DI注册模式检测"
    }

    # 判断域归属
    $domainLabel = $t.Domain
    if ($context -match 'ICommercialPermissionService|isFreeUser|entitlementInfo|payment|billing|subscription') {
        $domainLabel = "[Commercial]"
    }
    if ($context -match 'ISessionStore|ISessionService|IPlanItemStreamParser|IErrorStreamParser') {
        $domainLabel = "[SSE]"
    }
    if ($context -match 'Zustand|create\(|useStore|subscribe') {
        $domainLabel = "[Store]"
    }

    [void]$sb.AppendLine("### 分析结果")
    foreach ($a in $analysis) {
        [void]$sb.AppendLine("  - $a")
    }
    [void]$sb.AppendLine("  - 域归属: $domainLabel")
    [void]$sb.AppendLine("")

    # 上下文代码（截断长行）
    [void]$sb.AppendLine("### 上下文代码 (前后各 $ContextSize 字符)")
    $contextPreview = $context -replace "(?<=.{200})", "`n"
    $lines = $contextPreview -split "`n" | Select-Object -First 60
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -gt 0) {
            [void]$sb.AppendLine("  $trimmed")
        }
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("")

    $finding = @{
        Name = $t.Name
        Offset = $t.Offset
        Domain = $domainLabel
        Analysis = $analysis
    }
    [void]$findings.Add($finding)

    Write-Host "  分析完成: $($analysis.Count) 个特征" -ForegroundColor Green
}

# 额外搜索：在 P0 区间搜索所有 Symbol.for DI tokens
Write-Host ""
Write-Host "[3/3] 额外搜索: P0 区间所有 DI tokens..." -ForegroundColor Yellow

$diTokenPattern = 'Symbol\.for\("([A-Z][^"]+)"\)'
$diTokens = [regex]::Matches($c.Substring(54415, 6268469 - 54415), $diTokenPattern)

[void]$sb.AppendLine("## P0 区间 DI Token 扫描")
[void]$sb.AppendLine("")

$tokenList = @{}
foreach ($m in $diTokens) {
    $tokenName = $m.Groups[1].Value
    $absOffset = 54415 + $m.Index
    if (-not $tokenList.ContainsKey($tokenName)) {
        $tokenList[$tokenName] = $absOffset
    }
}

foreach ($kv in ($tokenList.GetEnumerator() | Sort-Object Value)) {
    [void]$sb.AppendLine("  Symbol.for(`"$($kv.Key)`") @ $($kv.Value)")
}

Write-Host "  找到 $($tokenList.Count) 个 DI tokens" -ForegroundColor Green

# 额外搜索：P0 区间所有 Symbol() tokens
$symbolPattern = 'Symbol\("([A-Z][^"]+)"\)'
$symbolTokens = [regex]::Matches($c.Substring(54415, 6268469 - 54415), $symbolPattern)

[void]$sb.AppendLine("")
[void]$sb.AppendLine("## P0 区间 Symbol() Token 扫描")
[void]$sb.AppendLine("")

$symbolList = @{}
foreach ($m in $symbolTokens) {
    $tokenName = $m.Groups[1].Value
    $absOffset = 54415 + $m.Index
    if (-not $symbolList.ContainsKey($tokenName)) {
        $symbolList[$tokenName] = $absOffset
    }
}

foreach ($kv in ($symbolList.GetEnumerator() | Sort-Object Value)) {
    [void]$sb.AppendLine("  Symbol(`"$($kv.Key)`") @ $($kv.Value)")
}

Write-Host "  找到 $($symbolList.Count) 个 Symbol() tokens" -ForegroundColor Green

# 额外搜索：P0 区间关键业务方法
Write-Host ""
Write-Host "搜索关键业务方法..." -ForegroundColor Yellow

$bizMethods = @(
    "resumeChat",
    "sendChatMessage",
    "provideUserResponse",
    "cancelChat",
    "stopStreaming",
    "handleCommonError",
    "teaEventChatFail",
    "computeSelectedModelAndMode"
)

[void]$sb.AppendLine("")
[void]$sb.AppendLine("## P0 区间关键业务方法搜索")
[void]$sb.AppendLine("")

$p0Content = $c.Substring(54415, 6268469 - 54415)

foreach ($bm in $bizMethods) {
    $idx = $p0Content.IndexOf($bm)
    if ($idx -ge 0) {
        $absIdx = 54415 + $idx
        [void]$sb.AppendLine("  $bm @ $absIdx")
        Write-Host "  $bm @ $absIdx" -ForegroundColor Green
    } else {
        [void]$sb.AppendLine("  $bm — 未找到")
    }
}

# 写入结果
[System.IO.File]::WriteAllText($OutputFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host ""
Write-Host "结果已写入: $OutputFile" -ForegroundColor Green

# 控制台摘要
Write-Host ""
Write-Host "=== Phase 3 发现摘要 ===" -ForegroundColor Cyan
foreach ($f in $findings) {
    Write-Host "  $($f.Name) @ $($f.Offset) [$($f.Domain)]" -ForegroundColor Yellow
    foreach ($a in $f.Analysis) {
        Write-Host "    - $a" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "=== DI Token 发现 ===" -ForegroundColor Cyan
foreach ($kv in ($tokenList.GetEnumerator() | Sort-Object Value)) {
    Write-Host "  Symbol.for(`"$($kv.Key)`") @ $($kv.Value)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Symbol() Token 发现 ===" -ForegroundColor Cyan
foreach ($kv in ($symbolList.GetEnumerator() | Sort-Object Value)) {
    Write-Host "  Symbol(`"$($kv.Key)`") @ $($kv.Value)" -ForegroundColor Magenta
}
