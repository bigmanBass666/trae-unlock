<#
.SYNOPSIS
P0 盲区 Phase 3+ 精确深挖 — 对关键目标做更精确的上下文提取
#>

param(
    [string]$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
)

$ErrorActionPreference = "Continue"
$c = [System.IO.File]::ReadAllText($TargetFile)
Write-Host "文件大小: $($c.Length) 字符" -ForegroundColor Green

$sb = [System.Text.StringBuilder]::new()

# --- 1. ai.IDocsetService 完整定义 ---
Write-Host "=== 1. ai.IDocsetService 完整定义 ===" -ForegroundColor Cyan
$idx = $c.IndexOf('ai.IDocsetService')
if ($idx -ge 0) {
    $ctx = $c.Substring([math]::Max(0, $idx - 500), 1000)
    [void]$sb.AppendLine("## ai.IDocsetService @ $idx")
    [void]$sb.AppendLine($ctx)
    [void]$sb.AppendLine("")
    Write-Host "  找到 @ $idx" -ForegroundColor Green
    Write-Host "  上下文: $($ctx.Substring(0, [math]::Min(200, $ctx.Length)))" -ForegroundColor DarkGray
}

# --- 2. 所有 Symbol.for("ai.*") DI tokens ---
Write-Host "=== 2. 所有 Symbol.for(`"ai.*`") DI tokens ===" -ForegroundColor Cyan
$aiTokenMatches = [regex]::Matches($c, 'Symbol\.for\("(ai\.[^"]+)"\)')
foreach ($m in $aiTokenMatches) {
    $name = $m.Groups[1].Value
    $offset = $m.Index
    Write-Host "  Symbol.for(`"$name`") @ $offset" -ForegroundColor Yellow
    [void]$sb.AppendLine("Symbol.for(`"$name`") @ $offset")
}
Write-Host "  总计: $($aiTokenMatches.Count) 个 ai.* DI tokens" -ForegroundColor Green

# --- 3. HaltChainable 完整上下文 ---
Write-Host "=== 3. HaltChainable 完整上下文 ===" -ForegroundColor Cyan
$idx = $c.IndexOf('HaltChainable')
if ($idx -ge 0) {
    $ctx = $c.Substring([math]::Max(0, $idx - 300), 800)
    [void]$sb.AppendLine("## HaltChainable @ $idx")
    [void]$sb.AppendLine($ctx)
    [void]$sb.AppendLine("")
    Write-Host "  找到 @ $idx" -ForegroundColor Green
}

# --- 4. undefined_placeholder / Optional 完整上下文 ---
Write-Host "=== 4. undefined_placeholder 完整上下文 ===" -ForegroundColor Cyan
$idx = $c.IndexOf('undefined_placeholder')
if ($idx -ge 0) {
    $ctx = $c.Substring([math]::Max(0, $idx - 500), 1200)
    [void]$sb.AppendLine("## undefined_placeholder @ $idx")
    [void]$sb.AppendLine($ctx)
    [void]$sb.AppendLine("")
    Write-Host "  找到 @ $idx" -ForegroundColor Green
}

# --- 5. GitGraph 类完整定义 ---
Write-Host "=== 5. GitGraph 类完整定义 ===" -ForegroundColor Cyan
$idx = $c.IndexOf('GitGraph')
if ($idx -ge 0) {
    $ctx = $c.Substring([math]::Max(0, $idx - 300), 1500)
    [void]$sb.AppendLine("## GitGraph @ $idx")
    [void]$sb.AppendLine($ctx)
    [void]$sb.AppendLine("")
    Write-Host "  找到 @ $idx" -ForegroundColor Green
}

# --- 6. bytegate API 端点完整上下文 ---
Write-Host "=== 6. bytegate API 端点 ===" -ForegroundColor Cyan
$bytegateMatches = [regex]::Matches($c, 'https://[a-z0-9-]+\.byteintlapi\.com[^\s"]*')
$bytegateUrls = @{}
foreach ($m in $bytegateMatches) {
    $url = $m.Value
    $offset = $m.Index
    if (-not $bytegateUrls.ContainsKey($url)) {
        $bytegateUrls[$url] = $offset
        Write-Host "  $url @ $offset" -ForegroundColor Yellow
        [void]$sb.AppendLine("URL: $url @ $offset")
    }
}

# --- 7. libraweb API 端点 ---
Write-Host "=== 7. libraweb API 端点 ===" -ForegroundColor Cyan
$libraMatches = [regex]::Matches($c, 'https://[a-z0-9-]+\.tiktok\.com[^\s"]*')
$libraUrls = @{}
foreach ($m in $libraMatches) {
    $url = $m.Value
    $offset = $m.Index
    if (-not $libraUrls.ContainsKey($url)) {
        $libraUrls[$url] = $offset
        Write-Host "  $url @ $offset" -ForegroundColor Yellow
        [void]$sb.AppendLine("URL: $url @ $offset")
    }
}

# --- 8. P0 区间所有 Symbol.for 搜索（不限大写开头）---
Write-Host "=== 8. P0 区间所有 Symbol.for tokens ===" -ForegroundColor Cyan
$p0Content = $c.Substring(54415, 6268469 - 54415)
$allSymbolFor = [regex]::Matches($p0Content, 'Symbol\.for\("([^"]+)"\)')
$symbolForList = @{}
foreach ($m in $allSymbolFor) {
    $name = $m.Groups[1].Value
    $absOffset = 54415 + $m.Index
    if (-not $symbolForList.ContainsKey($name)) {
        $symbolForList[$name] = $absOffset
    }
}
foreach ($kv in ($symbolForList.GetEnumerator() | Sort-Object Value)) {
    Write-Host "  Symbol.for(`"$($kv.Key)`") @ $($kv.Value)" -ForegroundColor Magenta
    [void]$sb.AppendLine("Symbol.for(`"$($kv.Key)`") @ $($kv.Value)")
}
Write-Host "  总计: $($symbolForList.Count) 个 Symbol.for tokens" -ForegroundColor Green

# --- 9. P0 区间所有 Symbol() 搜索 ---
Write-Host "=== 9. P0 区间所有 Symbol() tokens ===" -ForegroundColor Cyan
$allSymbol = [regex]::Matches($p0Content, 'Symbol\("([^"]+)"\)')
$symbolList = @{}
foreach ($m in $allSymbol) {
    $name = $m.Groups[1].Value
    $absOffset = 54415 + $m.Index
    if (-not $symbolList.ContainsKey($name)) {
        $symbolList[$name] = $absOffset
    }
}
foreach ($kv in ($symbolList.GetEnumerator() | Sort-Object Value)) {
    Write-Host "  Symbol(`"$($kv.Key)`") @ $($kv.Value)" -ForegroundColor DarkYellow
    [void]$sb.AppendLine("Symbol(`"$($kv.Key)`") @ $($kv.Value)")
}
Write-Host "  总计: $($symbolList.Count) 个 Symbol() tokens" -ForegroundColor Green

# --- 10. class tu HTTP Transport 完整定义 ---
Write-Host "=== 10. class tu HTTP Transport ===" -ForegroundColor Cyan
$idx = $c.IndexOf('class tu extends')
if ($idx -ge 0) {
    $ctx = $c.Substring([math]::Max(0, $idx - 200), 2000)
    [void]$sb.AppendLine("## class tu extends @ $idx")
    [void]$sb.AppendLine($ctx)
    [void]$sb.AppendLine("")
    Write-Host "  找到 @ $idx" -ForegroundColor Green
}

# --- 11. 搜索 provide( 模式（DI 注册）在 P0 ---
Write-Host "=== 11. P0 区间 .provide( DI 注册 ===" -ForegroundColor Cyan
$provideMatches = [regex]::Matches($p0Content, '\.provide\(\s*Symbol')
$provideList = @()
foreach ($m in $provideMatches) {
    $absOffset = 54415 + $m.Index
    $ctx = $p0Content.Substring($m.Index, [math]::Min(100, $p0Content.Length - $m.Index))
    Write-Host "  .provide(Symbol...) @ $absOffset" -ForegroundColor Yellow
    Write-Host "    $ctx" -ForegroundColor DarkGray
    [void]$sb.AppendLine(".provide(Symbol...) @ $absOffset : $ctx")
}

# --- 12. 搜索 uJ( DI 注入模式在 P0 ---
Write-Host "=== 12. P0 区间 uJ( DI 注入 ===" -ForegroundColor Cyan
$uJMatches = [regex]::Matches($p0Content, 'uJ\(\{identifier:')
$uJList = @()
foreach ($m in $uJMatches) {
    $absOffset = 54415 + $m.Index
    $ctx = $p0Content.Substring($m.Index, [math]::Min(150, $p0Content.Length - $m.Index))
    Write-Host "  uJ({identifier:...}) @ $absOffset" -ForegroundColor Red
    Write-Host "    $ctx" -ForegroundColor DarkGray
    [void]$sb.AppendLine("uJ({identifier:...}) @ $absOffset : $ctx")
}
Write-Host "  总计: $($uJMatches.Count) 个 uJ 注入" -ForegroundColor Green

# --- 13. 搜索 uX( DI 注入模式在 P0 ---
Write-Host "=== 13. P0 区间 uX( DI 注入 ===" -ForegroundColor Cyan
$uXMatches = [regex]::Matches($p0Content, 'uX\(')
$uXList = @()
foreach ($m in $uXMatches) {
    $absOffset = 54415 + $m.Index
    $ctx = $p0Content.Substring($m.Index, [math]::Min(100, $p0Content.Length - $m.Index))
    Write-Host "  uX(...) @ $absOffset" -ForegroundColor Red
    Write-Host "    $ctx" -ForegroundColor DarkGray
    [void]$sb.AppendLine("uX(...) @ $absOffset : $ctx")
}
Write-Host "  总计: $($uXMatches.Count) 个 uX 注入" -ForegroundColor Green

# 写入结果
$outputFile = "d:\Test\trae-unlock\scripts\explore-deep-p0-phase3plus-results.txt"
[System.IO.File]::WriteAllText($outputFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host ""
Write-Host "结果已写入: $outputFile" -ForegroundColor Green
