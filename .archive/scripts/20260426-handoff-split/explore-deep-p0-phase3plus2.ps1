<#
.SYNOPSIS
P0 盲区 Phase 3++ — 新发现 DI token 精确上下文 + API 端点分析
#>

param(
    [string]$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
)

$ErrorActionPreference = "Continue"
$c = [System.IO.File]::ReadAllText($TargetFile)
Write-Host "文件大小: $($c.Length) 字符" -ForegroundColor Green

$sb = [System.Text.StringBuilder]::new()

# --- 1. ai.IDocsetService 完整上下文（更大范围）---
Write-Host "=== 1. ai.IDocsetService 完整模块上下文 ===" -ForegroundColor Cyan
$idx = $c.IndexOf('IDocsetService')
if ($idx -ge 0) {
    $ctx = $c.Substring([math]::Max(0, $idx - 200), 600)
    [void]$sb.AppendLine("## IDocsetService 定义 @ $idx")
    [void]$sb.AppendLine($ctx)
    [void]$sb.AppendLine("")
    Write-Host "  @ $idx" -ForegroundColor Green
}

# --- 2. ai.IDocsetStore 完整上下文 ---
Write-Host "=== 2. ai.IDocsetStore 完整模块上下文 ===" -ForegroundColor Cyan
$idx = $c.IndexOf('IDocsetStore')
if ($idx -ge 0) {
    $ctx = $c.Substring([math]::Max(0, $idx - 200), 600)
    [void]$sb.AppendLine("## IDocsetStore 定义 @ $idx")
    [void]$sb.AppendLine($ctx)
    [void]$sb.AppendLine("")
    Write-Host "  @ $idx" -ForegroundColor Green
}

# --- 3. ai.IDocsetCkgLocalApiService ---
Write-Host "=== 3. ai.IDocsetCkgLocalApiService ===" -ForegroundColor Cyan
$idx = $c.IndexOf('IDocsetCkgLocalApiService')
if ($idx -ge 0) {
    $ctx = $c.Substring([math]::Max(0, $idx - 200), 600)
    [void]$sb.AppendLine("## IDocsetCkgLocalApiService 定义 @ $idx")
    [void]$sb.AppendLine($ctx)
    [void]$sb.AppendLine("")
    Write-Host "  @ $idx" -ForegroundColor Green
}

# --- 4. ai.IDocsetOnlineApiService ---
Write-Host "=== 4. ai.IDocsetOnlineApiService ===" -ForegroundColor Cyan
$idx = $c.IndexOf('IDocsetOnlineApiService')
if ($idx -ge 0) {
    $ctx = $c.Substring([math]::Max(0, $idx - 200), 600)
    [void]$sb.AppendLine("## IDocsetOnlineApiService 定义 @ $idx")
    [void]$sb.AppendLine($ctx)
    [void]$sb.AppendLine("")
    Write-Host "  @ $idx" -ForegroundColor Green
}

# --- 5. ai.IWebCrawlerFacade ---
Write-Host "=== 5. ai.IWebCrawlerFacade ===" -ForegroundColor Cyan
$idx = $c.IndexOf('IWebCrawlerFacade')
if ($idx -ge 0) {
    $ctx = $c.Substring([math]::Max(0, $idx - 200), 600)
    [void]$sb.AppendLine("## IWebCrawlerFacade 定义 @ $idx")
    [void]$sb.AppendLine($ctx)
    [void]$sb.AppendLine("")
    Write-Host "  @ $idx" -ForegroundColor Green
}

# --- 6. a0ai-api 端点上下文 ---
Write-Host "=== 6. a0ai-api 端点上下文 ===" -ForegroundColor Cyan
$idx = $c.IndexOf('a0ai-api.byteintlapi.com')
if ($idx -ge 0) {
    $ctx = $c.Substring([math]::Max(0, $idx - 500), 1200)
    [void]$sb.AppendLine("## a0ai-api.byteintlapi.com @ $idx")
    [void]$sb.AppendLine($ctx)
    [void]$sb.AppendLine("")
    Write-Host "  @ $idx" -ForegroundColor Green
}

# --- 7. bytegate-sg 端点上下文 ---
Write-Host "=== 7. bytegate-sg 端点上下文 ===" -ForegroundColor Cyan
$idx = $c.IndexOf('bytegate-sg.byteintlapi.com')
if ($idx -ge 0) {
    $ctx = $c.Substring([math]::Max(0, $idx - 500), 1200)
    [void]$sb.AppendLine("## bytegate-sg.byteintlapi.com @ $idx")
    [void]$sb.AppendLine($ctx)
    [void]$sb.AppendLine("")
    Write-Host "  @ $idx" -ForegroundColor Green
}

# --- 8. mcs-nontt 端点上下文 ---
Write-Host "=== 8. mcs-nontt 端点上下文 ===" -ForegroundColor Cyan
$idx = $c.IndexOf('mcs-nontt.byteintlapi.com')
if ($idx -ge 0) {
    $ctx = $c.Substring([math]::Max(0, $idx - 500), 1200)
    [void]$sb.AppendLine("## mcs-nontt.byteintlapi.com @ $idx")
    [void]$sb.AppendLine($ctx)
    [void]$sb.AppendLine("")
    Write-Host "  @ $idx" -ForegroundColor Green
}

# --- 9. __instance__ Symbol 上下文 ---
Write-Host "=== 9. __instance__ Symbol ===" -ForegroundColor Cyan
$idx = $c.IndexOf('Symbol("__instance__")')
if ($idx -ge 0) {
    $ctx = $c.Substring([math]::Max(0, $idx - 300), 800)
    [void]$sb.AppendLine("## __instance__ Symbol @ $idx")
    [void]$sb.AppendLine($ctx)
    [void]$sb.AppendLine("")
    Write-Host "  @ $idx" -ForegroundColor Green
}

# --- 10. iCubeApi / iCubeAgentApi 枚举上下文 ---
Write-Host "=== 10. iCubeApi / iCubeAgentApi 枚举 ===" -ForegroundColor Cyan
$idx = $c.IndexOf('iCubeAgentApi')
if ($idx -ge 0) {
    $ctx = $c.Substring([math]::Max(0, $idx - 300), 800)
    [void]$sb.AppendLine("## iCubeAgentApi @ $idx")
    [void]$sb.AppendLine($ctx)
    [void]$sb.AppendLine("")
    Write-Host "  @ $idx" -ForegroundColor Green
}

# --- 11. 搜索所有 ai.I* DI tokens ---
Write-Host "=== 11. 所有 ai.I* DI tokens ===" -ForegroundColor Cyan
$aiTokens = [regex]::Matches($c, 'Symbol\.for\("(ai\.I[^"]+)"\)')
$aiTokenList = @{}
foreach ($m in $aiTokens) {
    $name = $m.Groups[1].Value
    $offset = $m.Index
    if (-not $aiTokenList.ContainsKey($name)) {
        $aiTokenList[$name] = $offset
    }
}
foreach ($kv in ($aiTokenList.GetEnumerator() | Sort-Object Value)) {
    Write-Host "  Symbol.for(`"$($kv.Key)`") @ $($kv.Value)" -ForegroundColor Red
    [void]$sb.AppendLine("Symbol.for(`"$($kv.Key)`") @ $($kv.Value)")
}
Write-Host "  总计: $($aiTokenList.Count) 个 ai.I* DI tokens" -ForegroundColor Green

# --- 12. 搜索所有 I* Service 接口名 ---
Write-Host "=== 12. 所有 I*Service DI tokens ===" -ForegroundColor Cyan
$svcTokens = [regex]::Matches($c, 'Symbol\.for\("(I[A-Z][^"]*Service[^"]*)"\)')
$svcList = @{}
foreach ($m in $svcTokens) {
    $name = $m.Groups[1].Value
    $offset = $m.Index
    if (-not $svcList.ContainsKey($name)) {
        $svcList[$name] = $offset
    }
}
foreach ($kv in ($svcList.GetEnumerator() | Sort-Object Value)) {
    Write-Host "  Symbol.for(`"$($kv.Key)`") @ $($kv.Value)" -ForegroundColor Red
    [void]$sb.AppendLine("Symbol.for(`"$($kv.Key)`") @ $($kv.Value)")
}
Write-Host "  总计: $($svcList.Count) 个 I*Service DI tokens" -ForegroundColor Green

# 写入结果
$outputFile = "d:\Test\trae-unlock\scripts\explore-deep-p0-phase3plus2-results.txt"
[System.IO.File]::WriteAllText($outputFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host ""
Write-Host "结果已写入: $outputFile" -ForegroundColor Green
