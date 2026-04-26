<#
.SYNOPSIS
    P1 盲区系统性扫描 — UI下半部分 + 命令注册层 + 文件首尾
.DESCRIPTION
    对 Trae IDE 压缩源码的 4 个盲区区间执行采样扫描：
    - 区间1: UI下半部分 (8930000-9910446)
    - 区间2: 模块入口+命令注册层 (9910446-文件末尾)
      注意: CommandsRegistry 定义在 @2540057 (文件中部)，
      但实际的 registerCommand 调用在 bootstrapApplicationContainer (@10477819+)
    - 区间3: 文件首部 (0-41400) — 含 AMD define 入口、枚举定义
    - 区间4: 文件尾部 — IIFE 闭合、组件导出列表
    对每个区间采样、识别关键模式、双向扩展有趣目标、追加到 discoveries.md
.EXAMPLE
    .\explore-deep-p1-scan.ps1
    执行完整扫描
.EXAMPLE
    .\explore-deep-p1-scan.ps1 -DryRun
    只输出采样计划，不执行扫描
#>

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

$SourceFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$DiscoveriesFile = Join-Path $RootDir "shared\discoveries.md"

function Write-ColorOutput {
    param([string]$Msg, [string]$Color = "White")
    Write-Host $Msg -ForegroundColor $Color
}

function Get-FileContent {
    param([string]$Path, [int]$Offset, [int]$Length)
    $stream = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    try {
        $stream.Position = $Offset
        $buffer = New-Object byte[] $Length
        $read = $stream.Read($buffer, 0, $Length)
        return [System.Text.Encoding]::UTF8.GetString($buffer, 0, $read)
    } finally {
        $stream.Dispose()
    }
}

function Get-FileSize {
    param([string]$Path)
    return (Get-Item $Path).Length
}

$FileSize = Get-FileSize $SourceFile
Write-ColorOutput "`n[P1-Scan] 文件大小: $FileSize 字节" "Cyan"

$Region1Start = 8930000
$Region1End = 9910446
$Region2Start = 9910446
$Region2End = $FileSize
$Region3Start = 0
$Region3End = 41400
$Region4Start = $FileSize - 61
$Region4End = $FileSize

$SampleStep = 51200
$SampleLength = 400
$ExpandRadius = 1000

$r1MB = (($Region1End - $Region1Start) / 1MB).ToString('F2')
$r2KB = (($Region2End - $Region2Start) / 1KB).ToString('F0')
$r3KB = (($Region3End - $Region3Start) / 1KB).ToString('F0')
$r4KB = (($Region4End - $Region4Start) / 1KB).ToString('F0')
Write-ColorOutput "[P1-Scan] 区间规划:" "Cyan"
Write-ColorOutput "  区间1 (UI下半): $Region1Start - $Region1End ($r1MB MB)"
Write-ColorOutput "  区间2 (命令注册): $Region2Start - $Region2End ($r2KB KB)"
Write-ColorOutput "  区间3 (文件首部): $Region3Start - $Region3End ($r3KB KB)"
Write-ColorOutput "  区间4 (文件尾部): $Region4Start - $Region4End ($r4KB KB)"

if ($DryRun) {
    Write-ColorOutput "`n[P1-Scan] DryRun 模式，仅输出采样计划" "Yellow"
    $r1Samples = [Math]::Ceiling(($Region1End - $Region1Start) / $SampleStep)
    $r2Samples = [Math]::Ceiling(($Region2End - $Region2Start) / $SampleStep)
    Write-ColorOutput "  区间1 采样数: $r1Samples"
    Write-ColorOutput "  区间2 采样数: $r2Samples"
    Write-ColorOutput "  区间3: 完整读取"
    Write-ColorOutput "  区间4: 完整读取"
    return
}

$Discoveries = [System.Text.StringBuilder]::new()
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$DiscoveryCount = 0

function Add-Discovery {
    param(
        [string]$Title,
        [int]$Rating,
        [string]$Summary,
        [int64]$Offset,
        [string]$DomainTag,
        [string]$CodeSnippet
    )
    $starRating = "*" * $Rating
    $entry = @"

### [$Timestamp] $Title ⭐$starRating
> $Summary
#### 位置信息
- 偏移量: @$Offset
- 所属域标签: [$DomainTag]
#### 数据/证据
``````
$CodeSnippet
``````

"@
    $null = $Discoveries.Append($entry)
    $script:DiscoveryCount++
    Write-ColorOutput "  [发现 #$script:DiscoveryCount] $Title @$Offset" "Green"
}

$ReactPatterns = @(
    @{ Name = "sX().memo"; Pattern = "sX\(\)\.memo" },
    @{ Name = "sX().createElement"; Pattern = "sX\(\)\.createElement" },
    @{ Name = "function组件"; Pattern = "function\s+[A-Z]\w+\s*\(" },
    @{ Name = "useCallback"; Pattern = "useCallback" },
    @{ Name = "useEffect"; Pattern = "useEffect" },
    @{ Name = "subscribe"; Pattern = "\.subscribe\(" },
    @{ Name = "useState"; Pattern = "useState" },
    @{ Name = "useMemo"; Pattern = "useMemo" },
    @{ Name = "useRef"; Pattern = "useRef" },
    @{ Name = "React.memo"; Pattern = "React\.memo" }
)

$CommandPatterns = @(
    @{ Name = "registerCommand"; Pattern = "registerCommand" },
    @{ Name = "registerAdapter"; Pattern = "registerAdapter" },
    @{ Name = "bootstrapApplicationContainer"; Pattern = "bootstrapApplicationContainer" },
    @{ Name = "module.exports"; Pattern = "module\.exports" },
    @{ Name = "IIFE闭合"; Pattern = "\}\)\(\)" },
    @{ Name = "apis:"; Pattern = "apis:" },
    @{ Name = "components:"; Pattern = "components:\{" },
    @{ Name = "uj.getInstance"; Pattern = "uj\.getInstance" },
    @{ Name = "FW."; Pattern = "FW\." }
)

$DIPatterns = @(
    @{ Name = "DI注入"; Pattern = "inject\s*\(|\.inject\(" },
    @{ Name = "createService"; Pattern = "createService" },
    @{ Name = "ServiceCollection"; Pattern = "ServiceCollection" },
    @{ Name = "Symbol.for"; Pattern = "Symbol\.for\(" },
    @{ Name = "Symbol("; Pattern = "Symbol\(" }
)

function Test-Patterns {
    param([string]$Content, [array]$Patterns)
    $hitList = @()
    foreach ($p in $Patterns) {
        if ($Content -match $p.Pattern) {
            $hitList += $p.Name
        }
    }
    return $hitList
}

function Find-PatternOffsets {
    param([string]$Content, [int64]$BaseOffset, [string]$Pattern, [int]$MaxResults = 5)
    $results = @()
    $searchFrom = 0
    while ($searchFrom -lt $Content.Length -and $results.Count -lt $MaxResults) {
        $idx = $Content.IndexOf($Pattern, $searchFrom)
        if ($idx -eq -1) { break }
        $results += $BaseOffset + $idx
        $searchFrom = $idx + $Pattern.Length
    }
    return $results
}

# ============================================================
# 区间1: UI下半部分 (8930000-9910446)
# ============================================================
Write-ColorOutput "`n========== 区间1: UI下半部分 ($Region1Start-$Region1End) ==========" "Cyan"

$R1Samples = @()
$pos = $Region1Start
while ($pos -lt $Region1End) {
    $len = [Math]::Min($SampleLength, $Region1End - $pos)
    if ($len -le 0) { break }
    $sample = Get-FileContent $SourceFile $pos $len
    $R1Samples += @{ Offset = $pos; Content = $sample }
    $pos += $SampleStep
}

Write-ColorOutput "  采样数: $($R1Samples.Count)" "White"

$R1Interesting = @()
foreach ($s in $R1Samples) {
    $reactHits = Test-Patterns $s.Content $ReactPatterns
    $diHits = Test-Patterns $s.Content $DIPatterns
    $allHits = $reactHits + $diHits
    if ($allHits.Count -gt 0) {
        Write-ColorOutput "  @$($s.Offset): $($allHits -join ', ')" "DarkYellow"
        $R1Interesting += @{ Offset = $s.Offset; Content = $s.Content; Hits = $allHits }
    }
}

Write-ColorOutput "  有趣采样: $($R1Interesting.Count)/$($R1Samples.Count)" "White"

foreach ($item in $R1Interesting) {
    $expStart = [Math]::Max(0, $item.Offset - $ExpandRadius)
    $expLen = $ExpandRadius * 2 + $SampleLength
    $expEnd = [Math]::Min($FileSize, $expStart + $expLen)
    $expLen = $expEnd - $expStart
    if ($expLen -le 0) { continue }
    $expanded = Get-FileContent $SourceFile $expStart $expLen

    foreach ($hit in $item.Hits) {
        $searchStr = switch ($hit) {
            "sX().memo" { "sX().memo" }
            "sX().createElement" { "sX().createElement" }
            "useCallback" { "useCallback" }
            "useEffect" { "useEffect" }
            "subscribe" { ".subscribe(" }
            "useState" { "useState" }
            "useMemo" { "useMemo" }
            "useRef" { "useRef" }
            "React.memo" { "React.memo" }
            "Symbol.for" { "Symbol.for(" }
            "Symbol(" { "Symbol(" }
            default { "" }
        }
        if ([string]::IsNullOrEmpty($searchStr)) { continue }

        $offsets = Find-PatternOffsets $expanded $expStart $searchStr 3
        foreach ($off in $offsets) {
            $localIdx = [int]($off - $expStart)
            $snippetStart = [Math]::Max(0, $localIdx - 150)
            $snippetEnd = [Math]::Min($expanded.Length, $localIdx + 250)
            $snippet = $expanded.Substring($snippetStart, $snippetEnd - $snippetStart)

            $domainTag = if ($hit -in @("Symbol.for", "Symbol(")) { "DI" } else { "React" }
            $rating = if ($hit -in @("sX().memo", "subscribe", "Symbol.for")) { 4 } else { 3 }
            $title = "$hit 发现 @$off"

            Add-Discovery -Title $title -Rating $rating -Summary "区间1采样命中 $hit" -Offset $off -DomainTag $domainTag -CodeSnippet $snippet
        }
    }
}

# ============================================================
# 区间2: 命令注册层 (9910446-文件末尾)
# ============================================================
Write-ColorOutput "`n========== 区间2: 命令注册层 ($Region2Start-$Region2End) ==========" "Cyan"

$R2Samples = @()
$pos = $Region2Start
while ($pos -lt $Region2End) {
    $len = [Math]::Min($SampleLength, $Region2End - $pos)
    if ($len -le 0) { break }
    $sample = Get-FileContent $SourceFile $pos $len
    $R2Samples += @{ Offset = $pos; Content = $sample }
    $pos += $SampleStep
}

Write-ColorOutput "  采样数: $($R2Samples.Count)" "White"

$R2Interesting = @()
foreach ($s in $R2Samples) {
    $cmdHits = Test-Patterns $s.Content $CommandPatterns
    $diHits = Test-Patterns $s.Content $DIPatterns
    $allHits = $cmdHits + $diHits
    if ($allHits.Count -gt 0) {
        Write-ColorOutput "  @$($s.Offset): $($allHits -join ', ')" "DarkYellow"
        $R2Interesting += @{ Offset = $s.Offset; Content = $s.Content; Hits = $allHits }
    }
}

Write-ColorOutput "  有趣采样: $($R2Interesting.Count)/$($R2Samples.Count)" "White"

foreach ($item in $R2Interesting) {
    $expStart = [Math]::Max(0, $item.Offset - $ExpandRadius)
    $expLen = $ExpandRadius * 2 + $SampleLength
    $expEnd = [Math]::Min($FileSize, $expStart + $expLen)
    $expLen = $expEnd - $expStart
    if ($expLen -le 0) { continue }
    $expanded = Get-FileContent $SourceFile $expStart $expLen

    foreach ($hit in $item.Hits) {
        $searchStr = switch ($hit) {
            "registerCommand" { "registerCommand" }
            "registerAdapter" { "registerAdapter" }
            "module.exports" { "module.exports" }
            "IIFE闭合" { "})()" }
            "vscode.commands" { "vscode.commands" }
            "Symbol.for" { "Symbol.for(" }
            "Symbol(" { "Symbol(" }
            default { "" }
        }
        if ([string]::IsNullOrEmpty($searchStr)) { continue }

        $offsets = Find-PatternOffsets $expanded $expStart $searchStr 3
        foreach ($off in $offsets) {
            $localIdx = [int]($off - $expStart)
            $snippetStart = [Math]::Max(0, $localIdx - 150)
            $snippetEnd = [Math]::Min($expanded.Length, $localIdx + 250)
            $snippet = $expanded.Substring($snippetStart, $snippetEnd - $snippetStart)

            $domainTag = if ($hit -in @("registerCommand", "registerAdapter", "vscode.commands")) { "Command" } elseif ($hit -in @("Symbol.for", "Symbol(")) { "DI" } else { "Export" }
            $rating = if ($hit -in @("registerCommand", "registerAdapter")) { 5 } elseif ($hit -eq "IIFE闭合") { 4 } else { 3 }
            $title = "$hit 发现 @$off"

            Add-Discovery -Title $title -Rating $rating -Summary "区间2采样命中 $hit" -Offset $off -DomainTag $domainTag -CodeSnippet $snippet
        }
    }
}

# ============================================================
# 区间3: 文件首部 (0-41400)
# ============================================================
Write-ColorOutput "`n========== 区间3: 文件首部 (0-$Region3End) ==========" "Cyan"

$R3Content = Get-FileContent $SourceFile $Region3Start $Region3End
Write-ColorOutput "  读取长度: $($R3Content.Length) 字符" "White"

$bootstrapPatterns = @(
    @{ Name = "webpackBootstrap"; Pattern = "function\s+\w+\s*\(\w+\s*,\s*\w+\s*,\s*\w+\)" },
    @{ Name = "require函数"; Pattern = "__webpack_require__" },
    @{ Name = "moduleCache"; Pattern = "moduleCache|installedModules|__webpack_module_cache__" },
    @{ Name = "define函数"; Pattern = "\.define\s*=" },
    @{ Name = "IIFE开始"; Pattern = "^\(function" },
    @{ Name = "modules对象"; Pattern = "var\s+\w+=\{" },
    @{ Name = "esModule"; Pattern = "__esModule" },
    @{ Name = "Object.defineProperty"; Pattern = "Object\.defineProperty" }
)

foreach ($p in $bootstrapPatterns) {
    if ($R3Content -match $p.Pattern) {
        Write-ColorOutput "  命中: $($p.Name)" "DarkYellow"
    }
}

$bootstrapSearchTerms = @("__webpack_require__", "moduleCache", "installedModules", "__webpack_module_cache__", "__esModule", "Object.defineProperty")
foreach ($term in $bootstrapSearchTerms) {
    $offsets = Find-PatternOffsets $R3Content $Region3Start $term 3
    foreach ($off in $offsets) {
        $localIdx = [int]($off - $Region3Start)
        $snippetStart = [Math]::Max(0, $localIdx - 150)
        $snippetEnd = [Math]::Min($R3Content.Length, $localIdx + 250)
        $snippet = $R3Content.Substring($snippetStart, $snippetEnd - $snippetStart)

        Add-Discovery -Title "文件首部: $term 发现" -Rating 4 -Summary "webpack bootstrap 结构元素" -Offset $off -DomainTag "Bootstrap" -CodeSnippet $snippet
    }
}

$first500 = $R3Content.Substring(0, [Math]::Min(500, $R3Content.Length))
Add-Discovery -Title "文件首部前500字符" -Rating 4 -Summary "webpack bootstrap 入口代码" -Offset 0 -DomainTag "Bootstrap" -CodeSnippet $first500

# ============================================================
# 区间4: 文件尾部
# ============================================================
Write-ColorOutput "`n========== 区间4: 文件尾部 ($Region4Start-$Region4End) ==========" "Cyan"

$tailLen = [Math]::Min(2000, $FileSize)
$R4Content = Get-FileContent $SourceFile ($FileSize - $tailLen) $tailLen
Write-ColorOutput "  读取尾部 $tailLen 字符" "White"

$tailPatterns = @("})()", "module.exports", "apis:", "export", "default")
foreach ($tp in $tailPatterns) {
    $idx = $R4Content.LastIndexOf($tp)
    if ($idx -ge 0) {
        $absOff = $FileSize - $tailLen + $idx
        $snippetStart = [Math]::Max(0, $idx - 200)
        $snippetEnd = [Math]::Min($R4Content.Length, $idx + 200)
        $snippet = $R4Content.Substring($snippetStart, $snippetEnd - $snippetStart)
        Write-ColorOutput "  尾部命中 '$tp' @绝对偏移 $absOff" "DarkYellow"
    }
}

$last200 = $R4Content.Substring([Math]::Max(0, $R4Content.Length - 200))
Add-Discovery -Title "文件尾部最后200字符" -Rating 5 -Summary "IIFE 闭合与模块导出" -Offset ($FileSize - 200) -DomainTag "Export" -CodeSnippet $last200

# ============================================================
# 区间2深度: 命令ID提取 (bootstrapApplicationContainer)
# ============================================================
Write-ColorOutput "`n========== 区间2深度: 命令ID提取 ==========" "Cyan"

$R2DeepStart = $Region2Start
$R2DeepEnd = $Region2End
$R2DeepContent = Get-FileContent $SourceFile $R2DeepStart ($R2DeepEnd - $R2DeepStart)

$cmdIdPattern = 'registerCommand\s*\(\s*["'']([^"'']+)["'']'
$cmdMatches = [regex]::Matches($R2DeepContent, $cmdIdPattern)
$foundCmdIds = @()
foreach ($m in $cmdMatches) {
    $cmdId = $m.Groups[1].Value
    $absOff = $R2DeepStart + $m.Index
    $foundCmdIds += $cmdId
    Write-ColorOutput "  命令ID: $cmdId @$absOff" "Green"

    $snippetStart = [Math]::Max(0, $m.Index - 100)
    $snippetEnd = [Math]::Min($R2DeepContent.Length, $m.Index + $m.Length + 200)
    $snippet = $R2DeepContent.Substring($snippetStart, $snippetEnd - $snippetStart)

    Add-Discovery -Title "命令注册: $cmdId" -Rating 5 -Summary "VS Code 命令注册" -Offset $absOff -DomainTag "Command" -CodeSnippet $snippet
}

if ($foundCmdIds.Count -eq 0) {
    Write-ColorOutput "  未在区间2找到 registerCommand 模式" "Yellow"
}

$bacIdx = $R2DeepContent.IndexOf("bootstrapApplicationContainer")
if ($bacIdx -ge 0) {
    $absBac = $R2DeepStart + $bacIdx
    Write-ColorOutput "  bootstrapApplicationContainer @$absBac" "Green"
    $bacSnippet = $R2DeepContent.Substring($bacIdx, [Math]::Min(500, $R2DeepContent.Length - $bacIdx))
    Add-Discovery -Title "bootstrapApplicationContainer 入口" -Rating 5 -Summary "模块初始化入口函数" -Offset $absBac -DomainTag "Bootstrap" -CodeSnippet $bacSnippet
}

$eY0Idx = $R2DeepContent.IndexOf("eY0=")
if ($eY0Idx -ge 0) {
    $absEY0 = $R2DeepStart + $eY0Idx
    Write-ColorOutput "  eY0 模块入口对象 @$absEY0" "Green"
    $eY0Snippet = $R2DeepContent.Substring($eY0Idx, [Math]::Min(300, $R2DeepContent.Length - $eY0Idx))
    Add-Discovery -Title "eY0 模块入口对象" -Rating 5 -Summary "registerAdapter + bootstrapApplicationContainer" -Offset $absEY0 -DomainTag "Export" -CodeSnippet $eY0Snippet
}

# ============================================================
# 区间1深度: 关键UI组件搜索
# ============================================================
Write-ColorOutput "`n========== 区间1深度: 关键UI组件搜索 ==========" "Cyan"

$UIKeywords = @(
    @{ Term = "SettingPanel"; Desc = "设置面板" },
    @{ Term = "AgentSelector"; Desc = "Agent选择器" },
    @{ Term = "HistoryList"; Desc = "历史列表" },
    @{ Term = "ChatInput"; Desc = "聊天输入" },
    @{ Term = "ModelSelector"; Desc = "模型选择器" },
    @{ Term = "ConversationList"; Desc = "会话列表" },
    @{ Term = "Sidebar"; Desc = "侧边栏" },
    @{ Term = "TabBar"; Desc = "标签栏" },
    @{ Term = "PromptInput"; Desc = "提示输入" },
    @{ Term = "CodeBlock"; Desc = "代码块" },
    @{ Term = "FileDiff"; Desc = "文件差异" },
    @{ Term = "ToolCall"; Desc = "工具调用" },
    @{ Term = "autoRunMode"; Desc = "自动运行模式" },
    @{ Term = "blockLevel"; Desc = "阻止级别" },
    @{ Term = "confirm_status"; Desc = "确认状态" },
    @{ Term = "RunCommandCard"; Desc = "运行命令卡片" }
)

$R1DeepStart = $Region1Start
$R1DeepEnd = [Math]::Min($Region1End, $Region1Start + 500000)
$R1DeepContent = Get-FileContent $SourceFile $R1DeepStart ($R1DeepEnd - $R1DeepStart)

foreach ($kw in $UIKeywords) {
    $idx = $R1DeepContent.IndexOf($kw.Term)
    if ($idx -ge 0) {
        $absOff = $R1DeepStart + $idx
        Write-ColorOutput "  UI关键词 '$($kw.Term)' ($($kw.Desc)) @$absOff" "Green"

        $snippetStart = [Math]::Max(0, $idx - 200)
        $snippetEnd = [Math]::Min($R1DeepContent.Length, $idx + 300)
        $snippet = $R1DeepContent.Substring($snippetStart, $snippetEnd - $snippetStart)

        Add-Discovery -Title "UI组件: $($kw.Desc) ($($kw.Term))" -Rating 4 -Summary "区间1 UI组件关键词命中" -Offset $absOff -DomainTag "React" -CodeSnippet $snippet
    }
}

# ============================================================
# 写入 discoveries.md
# ============================================================
Write-ColorOutput "`n========== 写入 discoveries.md ==========" "Cyan"

$discoveryText = $Discoveries.ToString()
if ($discoveryText.Length -gt 0) {
    $header = @"

## [$Timestamp] P1盲区系统性扫描

> 区间1(UI下半: $Region1Start-$Region1End) + 区间2(命令注册: $Region2Start-$Region2End) + 区间3(首部: 0-$Region3End) + 区间4(尾部)
> 共发现 $DiscoveryCount 个目标

"@
    $fullAppend = $header + $discoveryText
    Add-Content -Path $DiscoveriesFile -Value $fullAppend -Encoding UTF8
    Write-ColorOutput "  已追加 $DiscoveryCount 个发现到 discoveries.md" "Green"
} else {
    Write-ColorOutput "  无新发现" "Yellow"
}

# ============================================================
# 扫描摘要
# ============================================================
Write-ColorOutput "`n========== 扫描摘要 ==========" "Cyan"
Write-ColorOutput "  文件大小: $FileSize 字节" "White"
Write-ColorOutput "  区间1 采样: $($R1Samples.Count), 有趣: $($R1Interesting.Count)" "White"
Write-ColorOutput "  区间2 采样: $($R2Samples.Count), 有趣: $($R2Interesting.Count)" "White"
Write-ColorOutput "  区间3 长度: $($R3Content.Length)" "White"
Write-ColorOutput "  区间4 尾部长度: $($R4Content.Length)" "White"
Write-ColorOutput "  命令ID发现: $($foundCmdIds.Count)" "White"
if ($foundCmdIds.Count -gt 0) {
    foreach ($cid in $foundCmdIds) {
        Write-ColorOutput "    - $cid" "DarkGray"
    }
}
Write-ColorOutput "  总发现数: $DiscoveryCount" "White"
Write-ColorOutput "`n[P1-Scan] 完成" "Green"
