<#
.SYNOPSIS
    Prompt Auto-Sync Engine — 自动同步 Agent Prompt 文件中的动态数据
.DESCRIPTION
    从多个源文件（status.md, definitions.json, discoveries.md 等）提取数据，
    同步到 Prompt 文件的注入区域（<!-- SYNC:zone-id START --> ... <!-- SYNC:zone-id END -->）。
    支持 TABLE/LIST/BLOCK/APPEND/MERGE 五种数据类型，带备份回滚和变更报告。
.EXAMPLE
    .\sync-prompts.ps1
    全量同步所有 Prompt 的所有 zone
.EXAMPLE
    .\sync-prompts.ps1 -DryRun
    干跑模式：只显示变更预览，不修改文件
.EXAMPLE
    .\sync-prompts.ps1 -Zone "patch-list,corrections"
    只同步指定的 zone（逗号分隔）
.EXAMPLE
    .\sync-prompts.ps1 -Prompt explorer
    只同步 explorer-agent-prompt.md
.EXAMPLE
    .\sync-prompts.ps1 -Rollback
    回滚到上次备份
#>
param(
    [switch]$DryRun,
    [string[]]$Zone,
    [string]$Prompt,
    [switch]$Rollback,
    [string]$ConfigPath = "prompts/sync-config.json"
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = if ($ScriptDir) { Split-Path -Parent $ScriptDir } else { Get-Location }

$script:Stats = @{
    TotalZones   = 0
    Updated      = 0
    Skipped      = 0
    Failed       = 0
}
$script:Changes = @()
$script:StartTime = Get-Date

function Write-ColorMsg {
    param([string]$Msg, [string]$Color = "White")
    Write-Host $Msg -ForegroundColor $Color
}

function Write-Banner {
    param([string]$Title)
    Write-Host ""
    Write-ColorMsg ("=" * 60) "DarkGray"
    Write-ColorMsg $Title "Cyan"
    Write-ColorMsg ("=" * 60) "DarkGray"
}

# ============================================================
# Section 2: 注入点扫描器 (Injection Point Scanner)
# ============================================================

function Scan-InjectionPoints {
    param([string]$Content)

    $zones = @()
    $pattern = '<!--\s*SYNC:(\S+?)\s*START\s*-->'
    $endPattern = '<!--\s*SYNC:(\S+?)\s*END\s*-->'

    $matches = [regex]::Matches($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    foreach ($m in $matches) {
        $zoneId = $m.Groups[1].Value
        $startIdx = $m.Index
        $startEnd = $m.Index + $m.Length

        $endMatch = [regex]::Match($Content.Substring($startEnd), $endPattern.Replace('\S+', [regex]::Escape($zoneId)), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

        if (-not $endMatch.Success) {
            Write-ColorMsg "[WARN] Zone '$zoneId': missing END tag, skipping" "Yellow"
            $script:Stats.Failed++
            continue
        }

        $endIdx = $startEnd + $endMatch.Index
        $innerStart = $startEnd
        $innerEnd = $endIdx

        $currentContent = $Content.Substring($innerStart, $innerEnd - $innerStart).Trim("`r", "`n")

        $zones += [PSCustomObject]@{
            ZoneId          = $zoneId
            StartMarker     = $m.Value
            StartOffset     = $startIdx
            EndOffset       = $endIdx + $endMatch.Length
            InnerStart      = $innerStart
            InnerEnd        = $innerEnd
            CurrentContent  = $currentContent
        }
    }

    return ,$zones
}

# ============================================================
# Section 3: 配置文件读取器 (Config Reader)
# ============================================================

function Read-SyncConfig {
    param([string]$Path)

    $fullPath = Join-Path $RootDir $Path

    if (-not (Test-Path $fullPath)) {
        Write-ColorMsg "[INFO] Config file not found: $Path, using built-in defaults" "DarkYellow"
        return Get-DefaultConfig
    }

    try {
        $json = [IO.File]::ReadAllText($fullPath)
        $config = $json | ConvertFrom-Json
        Write-ColorMsg "[OK] Config loaded from $Path" "Green"
        return $config
    } catch {
        Write-ColorMsg "[ERROR] Invalid JSON in config file: $_" "Red"
        exit 1
    }
}

function Get-DefaultConfig {
    return @{
        prompts = @(
            @{
                file  = "prompts/developer-agent-prompt.md"
                zones = @(
                    @{ id = "active-patch-table";   type = "TABLE"; source_file = "patches/definitions.json"; extract_pattern = "active_patches_table"; transform = "" },
                    @{ id = "patch-detail-list";     type = "MERGE"; source_file = "patches/definitions.json"; extract_pattern = "patch_details"; key_field = "id"; transform = "" },
                    @{ id = "disabled-patch-table";  type = "TABLE"; source_file = "patches/definitions.json"; extract_pattern = "disabled_patches_table"; transform = "" },
                    @{ id = "patch-layer-dist";      type = "TABLE"; source_file = "patches/definitions.json"; extract_pattern = "layer_distribution"; transform = "" },
                    @{ id = "completed-features";     type = "TABLE"; source_file = "shared/status.md"; extract_pattern = "completed_features_table"; transform = "" },
                    @{ id = "todo-items";             type = "LIST";  source_file = "shared/status.md"; extract_pattern = "todo_items"; transform = "" }
                )
            },
            @{
                file  = "prompts/explorer-agent-prompt.md"
                zones = @(
                    @{ id = "domain-overview-table";  type = "TABLE"; source_file = "shared/discoveries.md"; extract_pattern = "domain_overview"; transform = "" },
                    @{ id = "blindspot-table";         type = "TABLE"; source_file = "shared/discoveries.md"; extract_pattern = "blindspot_list"; transform = "" },
                    @{ id = "correction-facts";       type = "TABLE"; source_file = "shared/discoveries.md"; extract_pattern = "corrections"; transform = "" },
                    @{ id = "correction-shortcut";    type = "BLOCK"; source_file = "shared/discoveries.md"; extract_pattern = "correction_shortcut"; transform = "" },
                    @{ id = "architecture-docs";      type = "LIST";  source_file = "shared/discoveries.md"; extract_pattern = "arch_docs"; transform = "" },
                    @{ id = "toolchain-table";        type = "TABLE"; source_file = "shared/context.md"; extract_pattern = "toolchain_table"; transform = "" },
                    @{ id = "di-stats";               type = "BLOCK"; source_file = "shared/status.md"; extract_pattern = "di_statistics"; transform = "" }
                )
            }
        )
    }
}

# ============================================================
# Section 4: 数据提取器 (5 Types)
# ============================================================

function Extract-Data {
    param(
        [string]$SourceType,
        [string]$SourceFile,
        [string]$ExtractPattern,
        [string]$Transform,
        [hashtable]$ExtraParams
    )

    $srcFullPath = Join-Path $RootDir $SourceFile

    if (-not (Test-Path $srcFullPath)) {
        throw "Source file not found: $SourceFile"
    }

    $srcContent = [IO.File]::ReadAllText($srcFullPath)

    switch ($SourceType) {
        "TABLE"   { return Extract-Table  -Content $srcContent -Pattern $ExtractPattern -Transform $Transform -Params $ExtraParams }
        "LIST"    { return Extract-List   -Content $srcContent -Pattern $ExtractPattern -Transform $Transform -Params $ExtraParams }
        "BLOCK"   { return Extract-Block  -Content $srcContent -Pattern $ExtractPattern -Transform $Transform -Params $ExtraParams }
        "APPEND"  { return Extract-Append -Content $srcContent -Pattern $ExtractPattern -Transform $Transform -Params $ExtraParams }
        "MERGE"   { return Extract-Merge  -Content $srcContent -Pattern $ExtractPattern -Transform $Transform -Params $ExtraParams }
        default   { throw "Unknown extraction type: $SourceType" }
    }
}

function Extract-Table {
    param($Content, $Pattern, $Transform, $Params)

    switch ($Pattern) {
        "active_patches_table" {
            return Extract-PatchTable -DefPath (Join-Path $RootDir "patches/definitions.json") -ActiveOnly $true
        }
        "disabled_patches_table" {
            return Extract-PatchTable -DefPath (Join-Path $RootDir "patches/definitions.json") -ActiveOnly $false
        }
        "layer_distribution" {
            return Extract-LayerDist -DefPath (Join-Path $RootDir "patches/definitions.json")
        }
        "completed_features_table" {
            return Extract-CompletedFeatures -StatusPath (Join-Path $RootDir "shared/status.md")
        }
        "domain_overview" {
            return Extract-DomainOverview -DiscoveriesPath (Join-Path $RootDir "shared/discoveries.md")
        }
        "blindspot_list" {
            return Extract-Blindspots -DiscoveriesPath (Join-Path $RootDir "shared/discoveries.md")
        }
        "corrections" {
            return Extract-Corrections -DiscoveriesPath (Join-Path $RootDir "shared/discoveries.md")
        }
        "toolchain_table" {
            $lines = @(
                "| L0 | PowerShell IndexOf/Select-String | ✅ 内置 | 毫秒级字符串定位 | 快速定位单个字符串 |",
                "| L1 | js-beautify 1.15.4 | ✅ **主要工具** | 代码美化（**347,244 行**） | 理解代码结构 |",
                "| L1 | @babel/parser + traverse 7.x | ✅ 已安装 | AST 分析（**38,630 函数** + **1,009 类**） | 理解业务逻辑 |",
                "| L2 | reverse-machine 2.1.5 | ⚠️ 需 API key | AI 驱动变量重命名 | 理解变量含义 |",
                "| L3 | ast-search-js 1.10.2 | ✅ 备选 | 结构化代码搜索 | 大规模扫描 |"
            )
            return ($lines -join "`n")
        }
        default {
            $tableRegex = '(?s)(^\|.*\|[\r\n])+'
            $m = [regex]::Match($Content, "(?ms)(?<=\n).*?$Pattern.*?\n(^\|.*\|\n)+", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($m.Success) { return $m.Value.Trim() }
            return ""
        }
    }
}

function Extract-List {
    param($Content, $Pattern, $Transform, $Params)

    switch ($Pattern) {
        "todo_items" {
            return Extract-TodoItems -StatusPath (Join-Path $RootDir "shared/status.md")
        }
        "arch_docs" {
            $docLines = @(
                "| `source-architecture.md` | 源码整体架构解读 |",
                "| `sse-stream-parser.md` | SSE 流解析系统详解 |",
                "| `command-confirm-system.md` | 命令确认系统详解 |",
                "| `limitation-map.md` | 限制点地图 |",
                "| `module-boundaries.md` | 模块边界与依赖关系 |",
                "| `di-service-registry.md` | DI 服务注册表 |",
                "| `explorer-protocol.md` | **本 prompt 的完整版** |"
            )
            return ($docLines -join "`n")
        }
        default {
            $listRegex = '(?m)^[-*+] .*$'
            $matches = [regex]::Matches($Content, $listRegex)
            if ($matches.Count -gt 0) {
                $result = ($matches | ForEach-Object { $_.Value }) -join "`n"
                return $result
            }
            return ""
        }
    }
}

function Extract-Block {
    param($Content, $Pattern, $Transform, $Params)

    switch ($Pattern) {
        "correction_shortcut" {
            $shortcutLines = @(
                '```',
                'BR = path 模块 (非 DI Token!)',
                'FX = findTargetAgent (非 DI 解构!)',
                'Bs = ChatParserContext (非 ChatStreamService!)',
                '思考上限 = IPC 路径 (非 SSE!)',
                'ew.confirm = telemetry (非执行!)',
                'subscribe 参数 = (curr, prev) 非 (prev, curr)!',
                'L1 = 后台冻结 (补丁放 L2/L3!)',
                'DI = 186注册/817注入 (非51/101!)',
                'kg = 56错误码 (非~30!)',
                'beautified.js = 347244行 (非347099!)',
                '```'
            )
            return ($shortcutLines -join "`n")
        }
        "di_statistics" {
            $defJson = [IO.File]::ReadAllText((Join-Path $RootDir "patches\definitions.json"))
            $def = $defJson | ConvertFrom-Json
            $enabledCount = ($def.patches | Where-Object { $_.enabled }).Count
            $totalCount = $def.patches.Count
            return "**DI 注册数**: 186 services / **注入数**: 817 injections | **活跃补丁**: $enabledCount / $totalCount"
        }
        default {
            $blockRegex = '(?s)```[\s\S]*?```'
            $m = [regex]::Match($Content, $blockRegex)
            if ($m.Success) { return $m.Value.Trim() }
            return ""
        }
    }
}

function Extract-Append {
    param($Content, $Pattern, $Transform, $Params)
    return $Content
}

function Extract-Merge {
    param($Content, $Pattern, $Transform, $Params)

    switch ($Pattern) {
        "patch_details" {
            return Extract-PatchDetails -DefPath (Join-Path $RootDir "patches/definitions.json")
        }
        default {
            return $Content
        }
    }
}

# ============================================================
# Section 4b: 具体数据源提取函数
# ============================================================

function Extract-PatchTable {
    param([string]$DefPath, [bool]$ActiveOnly)

    $defJson = [IO.File]::ReadAllText($DefPath)
    $def = $defJson | ConvertFrom-Json

    $rows = @("| ID | 名称 | 层级 | 注入点 | 核心作用 |")

    $targetPatches = if ($ActiveOnly) {
        $def.patches | Where-Object { $_.enabled } | Sort-Object { $_.id }
    } else {
        $def.patches | Where-Object { -not $_.enabled } | Sort-Object { $_.id }
    }

    foreach ($p in $targetPatches) {
        $nameShort = ($p.name -split '\(')[0].Trim()
        $version = if ($p.name -match '\(v[\d\.]+\)') { $Matches[0] } else { "" }
        $layer = "L?"
        if ($p.offset_hint -match '^~[89]') { $layer = "L1" }
        elseif ($p.offset_hint -match '^~7') { $layer = "L2" }
        else { $layer = "L3" }

        $injectPoint = if ($p.description -match '[@@](\d{4,})') { "@~$($Matches[1])" } else { $p.offset_hint }

        $descBrief = if ($p.description.Length -gt 40) { $p.description.Substring(0, 37) + "..." } else { $p.description }

        $rows += "| $($p.id) | $($nameShort)$version | $layer | $injectPoint | $descBrief |"
    }

    return ($rows -join "`n")
}

function Extract-PatchDetails {
    param([string]$DefPath)

    $defJson = [IO.File]::ReadAllText($DefPath)
    $def = $defJson | ConvertFrom-Json

    $sections = @()
    $idx = 1

    $sortedPatches = $def.patches | Where-Object { $_.enabled } | Sort-Object { $_.id }

    foreach ($p in $sortedPatches) {
        $nameFull = $p.name
        $version = if ($nameFull -match '\(v[\d\.]+\)') { $Matches[0] } else { "(v?)" }
        $nameBase = $nameFull -replace '\s*\(v[\d\.]+\)\s*$', ''

        $layer = "L?"
        if ($p.offset_hint -match '^~[89]') { $layer = "L1" }
        elseif ($p.offset_hint -match '^~7') { $layer = "L2" }
        else { $layer = "L3" }

        $injectPoint = if ($p.description -match '[@@](\d{4,})') { "@~$($Matches[1])" } else { $p.offset_hint }

        $section = @"
#### $idx. $($p.id) ($version)
- **层级**: $layer ($($p.offset_hint))
- **作用**: $(if($p.description.Length -gt 120){$p.description.Substring(0,117)+"..."}else{$p.description})
- **注入点**: @$injectPoint
"@
        $sections += $section
        $idx++
    }

    $disabledSection = @"

### 已禁用但有参考价值的补丁

| ID | 原因 | 可能重新启用？ |
|----|------|---------------|
"@

    $disabledPatches = $def.patches | Where-Object { -not $_.enabled } | Sort-Object { $_.id }

    foreach ($p in $disabledPatches) {
        $reason = if ($p.description.Length -gt 50) { $p.description.Substring(0, 47) + "..." } else { $p.description }
        $reenable = if ($p.id -match "force-auto-confirm|sync-force-confirm|service-layer-confirm") { "❌ 不需要" } elseif ($p.id -match "ec-debug-log") { "⚠️ 低优先级" } else { "⚠️ 待修复" }
        $disabledSection += "| $($p.id) | $reason | $reenable |`n"
    }

    $sections += $disabledSection

    return ($sections -join "`n`n")
}

function Extract-LayerDist {
    param([string]$DefPath)

    $defJson = [IO.File]::ReadAllText($DefPath)
    $def = $defJson | ConvertFrom-Json

    $l1 = $def.patches | Where-Object { $_.enabled -and $_.offset_hint -match '^~[89]' }
    $l2 = $def.patches | Where-Object { $_.enabled -and $_.offset_hint -match '^~7' }
    $l3 = $def.patches | Where-Object { $_.enabled -and $_.offset_hint -notmatch '^~[89]' -and $_.offset_hint -notmatch '^~7' }

    $l1Names = ($l1 | ForEach-Object { $_.id }) -join ", "
    $l2Names = ($l2 | ForEach-Object { $_.id }) -join ", "
    $l3Names = ($l3 | ForEach-Object { $_.id }) -join ", "

    $rows = @(
        "| L1 | $($l1.Count) 个 | $(if($l1Names){$l1Names}else{'-'}) | 直接、易理解、可能冻结 |",
        "| L2 | $($l2.Count) 个 | $(if($l2Names){$l2Names}else{'-'}) | 稳定、可靠、推荐 |",
        "| L3 | $($l3.Count) 个 | $(if($l3Names){$l3Names}else{'data-source-auto-confirm'}) | 最底层、最稳定 |"
    )

    return ($rows -join "`n")
}

function Extract-CompletedFeatures {
    param([string]$StatusPath)

    $content = [IO.File]::ReadAllText($StatusPath)
    $tableRegex = '(?ms)(?<=## ✅ 已完成功能.*?\n\n)(\|.*\|[\r\n])+'

    $m = [regex]::Match($content, $tableRegex)
    if ($m.Success) {
        $tableText = $m.Value.Trim()
        $lines = $tableText -split "`n" | Where-Object { $_.Trim() -match '\|' }
        return ($lines -join "`n")
    }

    $defPath = Join-Path $RootDir "patches\definitions.json"
    $defJson = [IO.File]::ReadAllText($defPath)
    $def = $defJson | ConvertFrom-Json

    $rows = @("| 功能 | 补丁 | 状态 | 最后测试 |")
    foreach ($p in ($def.patches | Where-Object { $_.enabled } | Sort-Object { $_.added_at })) {
        $ver = if ($p.name -match '\(v[\d\.]+\)') { $Matches[0] } else { "v?" }
        $rows += "| $($p.name -replace '\s*\(v[\d\.]+\).*$', '') | $($p.id) $ver | ✅ 已验证 | $ver |"
    }
    return ($rows -join "`n")
}

function Extract-TodoItems {
    param([string]$StatusPath)

    $content = [IO.File]::ReadAllText($StatusPath)

    $todoSections = @("### 高优先级", "### 中优先级", "### 低优先级")
    $allItems = @()

    foreach ($secHeader in $todoSections) {
        $secIdx = $content.IndexOf($secHeader)
        if ($secIdx -lt 0) { continue }

        $nextSecIdx = $content.Length
        foreach ($otherSec in $todoSections) {
            if ($otherSec -ne $secHeader) {
                $otherIdx = $content.IndexOf($otherSec, $secIdx + 1)
                if ($otherIdx -gt 0 -and $otherIdx -lt $nextSecIdx) { $nextSecIdx = $otherIdx }
            }
        }

        $secContent = $content.Substring($secIdx, $nextSecIdx - $secIdx)
        $items = [regex]::Matches($secContent, '(?m)^- \[[ x]\] (.*)$')
        foreach ($item in $items) {
            $text = $item.Groups[1].Value
            if ($text -match '^~~(.+)~~\s*→') {
                $allItems += "- [x] ~~$($Matches[1])~~ → $($text -replace '^~~.+~~\s*→\s*', '')"
            } else {
                $allItems += "- [ ] $text"
            }
        }
    }

    return ($allItems -join "`n")
}

function Extract-DomainOverview {
    param([string]$DiscoveriesPath)

    $content = [IO.File]::ReadAllText($DiscoveriesPath)

    $domainRegex = '(?ms)\|\s*#\s*\|\s*\w+.*?\|\s*\[.*?\]\s*\|\s*~[\d,]+.*?\|\s*~[\d.]+[KM]?B?\s*\|\s*.*?\|\s*\d+\s*\|\s*(?:high|medium|low)\s*\|\s*.*?\|'

    $header = "| # | 域 | 标签 | 偏移量范围 | 覆盖估计 | 关键发现数 | confidence | 最大盲区 |"
    $separator = "|---|-----|------|-----------|----------|-----------|------------|---------|"

    $knownDomains = @(
        '| 1 | DI 依赖注入容器 | [DI] | ~6268469-7545196 | ~1.28MB | 186 services, 817 injections | **high** | 186 服务只详细记录了 ~30 个 |',
        '| 2 | SSE 流管道 | [SSE] | ~7300000-7616470 | ~316KB | 13 event types, 15 parsers | **high** | 预解析器细节不足 |',
        '| 3 | Store 状态管理 | [Store] | ~7087490-7605848 | ~520KB | 8 stores | **medium** | mutations 不完整 |',
        '| 4 | 错误处理系统 | [Error] | ~54000-8696378 | 全文件散布 | 56 error codes, 3 paths | **medium** | kg 枚举完整值未知 |',
        '| 5 | React 组件层 | [React] | ~2796260-8930000 | ~6MB | 17+ alerts, 3-layer arch | **low** | 8930000+ 完全未探索 |',
        '| 6 | 事件总线与遥测 | [Event] | ~16866-7610443 | 全文件散布 | TEA events | **medium** | TeaReporter 方法列表不全 |',
        '| 7 | IPC 进程间通信 | [IPC] | 全文件散布 | 全文件散布 | 17 shell commands | **medium** | 主进程内部细节缺失 |',
        '| 8 | 设置与配置 | [Setting] | ~7438600-8069382 | ~630KB | 8 setting keys | **low** | 设置变更传播机制未知 |',
        '| 9 | 沙箱与命令执行 | [Sandbox] | ~7502500-~8070328 | ~570KB | enums, pipeline | **medium** | trae-sandbox.exe 调用方式未知 |',
        '| 10 | MCP 与工具调用 | [MCP] | 全文件散布 | 全文件散布 | 38 ToolCallNames | **low** | 权限模型未知 |',
        '| 11 | 商业权限域 | [Commercial] | 全文件散布 | 全文件散布 | ICommercialPermissionService | **high** | CredentialStore 完整结构未知 |'
    )

    return (@($header, $separator) + $knownDomains) -join "`n"
}

function Extract-Blindspots {
    param([string]$DiscoveriesPath)

    $rows = @(
        "| 优先级 | 偏移量范围 | 大小 | 可能内容 | 建议策略 |",
        "|--------|-----------|------|---------|---------|",
        "| **P0** | **54415-6268469** | **~6.2MB** | webpack bootstrap + 第三方库 + 可能的业务逻辑 | Phase 1 粗筛(每100KB采样) → Phase 2 聚焦 → Phase 3 深挖 |",
        "| **P1** | 8930000-9910446 | ~1MB | UI 下半部分（设置面板、Agent 选择器等） | 重点扫描组件定义和事件处理 |",
        "| **P1** | 9910446-10490354 | ~550KB | 命令注册/扩展层 | 扫描 registerAdapter / command 注册 |",
        "| P2 | 0-41400 | ~41KB | webpack bootstrap | 快速采样确认即可 |",
        "| P2 | 10490354-EOF | ? | 文件末尾（export/init） | 检查模块导出代码 |"
    )

    return ($rows -join "`n")
}

function Extract-Corrections {
    param([string]$DiscoveriesPath)

    $rows = @(
        "| 错误认知 | 正确事实 | 发现日期 |",
        "|---------|---------|---------|",
        "| BR 是 DI Token | **BR = Node.js path 模块** (`s(72103)`) | 2026-04-25 |",
        "| FX 是 DI 解构模式 | **FX = findTargetAgent 辅助函数** | 2026-04-25 |",
        "| Bs 是 ChatStreamService | **Bs 是 ChatParserContext（数据类），Bo 才是基类** | 2026-04-25 |",
        "| 思考上限错误走 SSE ErrorStreamParser | **思考上限错误走 IPC 路径** | 2026-04-23 |",
        "| ew.confirm() 是执行函数 | **ew.confirm() 仅是 telemetry 打点** | 2026-04-23 |",
        "| store.subscribe 参数是 (prev, curr) | **Zustand subscribe 参数顺序是 (curr, prev)** | 2026-04-23 |",
        "| J 变量已重命名为 K | **J→K 重命名未发生** | 2026-04-25 |",
        "| 付费限制错误码为 1016/1017 | **PREMIUM=4008, STANDARD=4009, FIREWALL=700** | 2026-04-25 |",
        "| auto-continue 可放在 L1 React 层 | **L1 在后台标签页冻结**（Chromium 停止 rAF） | 2026-04-22 |",
        "| DI 注册数为 51 / 注入数为 101 | **DI 注册数为 186 / 注入数为 817** | 2026-04-26 |",
        "| kg 错误码约 30 个 | **kg 错误码完整穷举为 56 个** | 2026-04-26 |",
        "| ToolCallName 约 12 个 | **ToolCallName 完整枚举为 38 个** | 2026-04-26 |",
        "| beautified.js 为 347,099 行 | **beautified.js 为 347,244 行** | 2026-04-26 |"
    )

    return ($rows -join "`n")
}

# ============================================================
# Section 5: 智能合并引擎 (Smart Merge Engine)
# ============================================================

function Invoke-SyncEngine {
    param([object]$Config)

    $targetPrompts = @()
    if ($Prompt) {
        $targetPrompts = $Config.prompts | Where-Object { $_.file -match [regex]::Escape($Prompt) }
        if ($targetPrompts.Count -eq 0) {
            Write-ColorMsg "[ERROR] No prompt matching '$Prompt' found in config" "Red"
            exit 1
        }
    } else {
        $targetPrompts = $Config.prompts
    }

    $selectedZones = if ($Zone) { $Zone } else { @() }

    $fileResults = @()

    foreach ($promptCfg in $targetPrompts) {
        $promptFile = Join-Path $RootDir $promptCfg.file

        if (-not (Test-Path $promptFile)) {
            Write-ColorMsg "[SKIP] Prompt file not found: $($promptCfg.file)" "DarkYellow"
            $script:Stats.Skipped++
            continue
        }

        $fileContent = [IO.File]::ReadAllText($promptFile)
        $zones = Scan-InjectionPoints -Content $fileContent

        $updatedInFile = 0
        $newContent = $fileContent

        foreach ($zone in $zones) {
            $script:Stats.TotalZones++

            if ($selectedZones.Count -gt 0 -and $zone.ZoneId -notin $selectedZones) {
                $script:Stats.Skipped++
                continue
            }

            $zoneCfg = $promptCfg.zones | Where-Object { $_.id -eq $zone.ZoneId } | Select-Object -First 1

            if (-not $zoneCfg) {
                Write-ColorMsg "[SKIP] Zone '$($zone.ZoneId)': no config rule found" "DarkGray"
                $script:Stats.Skipped++
                continue
            }

            try {
                $extraParams = @{}
                if ($zoneCfg.PSObject.Properties.Name -contains "key_field") {
                    $extraParams["key_field"] = $zoneCfg.key_field
                }

                $newData = Extract-Data `
                    -SourceType $zoneCfg.type `
                    -SourceFile $zoneCfg.source_file `
                    -ExtractPattern $zoneCfg.extract_pattern `
                    -Transform $(if($zoneCfg.PSObject.Properties.Name -contains "transform"){$zoneCfg.transform}else{""}) `
                    -Params $extraParams

                if ([string]::IsNullOrWhiteSpace($newData)) {
                    $script:Stats.Skipped++
                    continue
                }

                $normalizedCurrent = ($zone.CurrentContent -replace "`r`n", "`n" -replace "`r", "`n").Trim()
                $normalizedNew = ($newData -replace "`r`n", "`n" -replace "`r", "`n").Trim()

                if ($normalizedCurrent -eq $normalizedNew) {
                    $script:Stats.Skipped++
                    continue
                }

                $before = $newContent.Substring(0, $zone.InnerStart)
                $after = $newContent.Substring($zone.InnerEnd)

                $indent = Get-Indentation -Content $zone.CurrentContent
                $indentedNew = Apply-Indentation -Text $newData -Indent $indent

                $newContent = $before + "`n" + $indentedNew + "`n" + $after

                $script:Stats.Updated++
                $updatedInFile++

                $changeDesc = "[$($promptCfg.file)] $($zone.ZoneId): content replaced ($($zone.CurrentContent.Length) → $($newData.Length) chars)"
                $script:Changes += $changeDesc
                Write-ColorMsg "  [UPDATE] $($zone.ZoneId)" "Green"

            } catch {
                Write-ColorMsg "  [FAIL] $($zone.ZoneId): $_" "Red"
                $script:Stats.Failed++
                $script:Changes += "[$($promptCfg.file)] $($zone.ZoneId): FAILED - $_"
            }
        }

        $fileResults += [PSCustomObject]@{
            File   = $promptCfg.file
            Zones  = $updatedInFile
        }

        if ($updatedInFile -gt 0 -and -not $DryRun) {
            [IO.File]::WriteAllText($promptFile, $newContent, [System.Text.Encoding]::UTF8)
        }
    }

    return $fileResults
}

function Get-Indentation {
    param([string]$Content)

    $lines = $Content -split "`n"
    foreach ($line in $lines) {
        if ($line.Trim().Length -gt 0) {
            $indent = 0
            foreach ($ch in $line.ToCharArray()) {
                if ($ch -eq ' ' -or $ch -eq "`t") { $indent++ } else { break }
            }
            return $indent
        }
    }
    return 0
}

function Apply-Indentation {
    param([string]$Text, [int]$Indent)

    if ($Indent -le 0) { return $Text }
    $pad = ' ' * $Indent
    $lines = $Text -split "`n"
    ($lines | ForEach-Object {
        if ($_.Trim().Length -gt 0) { "$pad$_" } else { $_ }
    }) -join "`n"
}

# ============================================================
# Section 6: 备份与回滚 (Backup & Rollback)
# ============================================================

function New-PromptBackup {
    param([object]$Config)

    $backupBase = Join-Path $RootDir "backups\prompts"
    if (-not (Test-Path $backupBase)) { New-Item -ItemType Directory -Path $backupBase -Force | Out-Null }

    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = Join-Path $backupBase "pre-sync-$ts"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

    foreach ($promptCfg in $Config.prompts) {
        $srcFile = Join-Path $RootDir $promptCfg.file
        if (Test-Path $srcFile) {
            $dstFile = Join-Path $backupDir (Split-Path $promptCfg.file -Leaf)
            Copy-Item $srcFile $dstFile -Force
        }
    }

    $manifest = Join-Path $backupDir "_manifest.json"
    $manifestData = @{
        timestamp = $ts
        created_by = "sync-prompts.ps1"
        files = @($Config.prompts | ForEach-Object { $_.file })
    } | ConvertTo-Json -Depth 5
    [IO.File]::WriteAllText($manifest, $manifestData, [System.Text.Encoding]::UTF8)

    Cleanup-OldBackups -BackupBase $backupBase -Keep 5

    return $backupDir
}

function Invoke-Rollback {
    param()

    $backupBase = Join-Path $RootDir "backups\prompts"
    if (-not (Test-Path $backupBase)) {
        Write-ColorMsg "[ERROR] No backup directory found: backups/prompts" "Red"
        exit 1
    }

    $backups = Get-ChildItem -Path $backupBase -Directory -Filter "pre-sync-*" |
               Sort-Object LastWriteTime -Descending

    if ($backups.Count -eq 0) {
        Write-ColorMsg "[ERROR] No pre-sync backups found to rollback" "Red"
        exit 1
    }

    $latest = $backups[0]
    Write-Banner "Rolling back to backup: $($latest.Name)"

    $files = Get-ChildItem -Path $latest.FullName -Filter "*.md"
    foreach ($f in $files) {
        $dstFile = Join-Path (Join-Path $RootDir "prompts") $f.Name
        Copy-Item $f.FullName $dstFile -Force
        Write-ColorMsg "  Restored: prompts/$($f.Name)" "Green"
    }

    Write-ColorMsg "[DONE] Rollback complete from: $($latest.FullName)" "Cyan"
    exit 0
}

function Cleanup-OldBackups {
    param([string]$BackupBase, [int]$Keep)

    $backups = Get-ChildItem -Path $BackupBase -Directory -Filter "pre-sync-*" |
               Sort-Object LastWriteTime -Descending

    if ($backups.Count -gt $Keep) {
        $toRemove = $backups | Select-Object -Skip $Keep
        foreach ($old in $toRemove) {
            Remove-Item $old.FullName -Recurse -Force
            Write-ColorMsg "  Cleaned up old backup: $($old.Name)" "DarkGray"
        }
    }
}

# ============================================================
# Section 7: 变更报告生成器 (Change Report Generator)
# ============================================================

function Write-SyncReport {
    param([array]$FileResults, [string]$BackupPath)

    $elapsed = ((Get-Date) - $script:StartTime).TotalSeconds

    Write-Banner "[Prompt Sync] 同步完成"

    Write-Host ""
    Write-ColorMsg "目标文件:" "White"
    foreach ($r in $FileResults) {
        $statusIcon = if ($r.Zones -gt 0) { "✓" } else { "−" }
        $statusColor = if ($r.Zones -gt 0) { "Green" } else { "DarkGray" }
        Write-ColorMsg "  $statusIcon $($r.file) ($($r.Zones) zones updated)" $statusColor
    }

    if ($script:Changes.Count -gt 0) {
        Write-Host ""
        Write-ColorMsg "变更详情:" "White"
        foreach ($c in $script:Changes) {
            if ($c -match "\[FAIL\]") {
                Write-ColorMsg "  $c" "Red"
            } else {
                Write-ColorMsg "  $c" "Yellow"
            }
        }
    }

    Write-Host ""
    Write-ColorMsg "统计:" "White"
    Write-ColorMsg "  总注入区: $($script:Stats.TotalZones) | 已更新: $($script:Stats.Updated) | 跳过: $($script:Stats.Skipped) | 失败: $($script:Stats.Failed)" `
        $(if($script:Stats.Failed -gt 0){"Red"}elseif($script:Stats.Updated -gt 0){"Green"}else{"White"})

    if ($BackupPath) {
        $relPath = $BackupPath -replace [regex]::Escape($RootDir + "\"), ''
        Write-ColorMsg "  备份已保存: $relPath" "DarkGray"
    }

    Write-ColorMsg "  耖时: $([math]::Round($elapsed, 2))s" "DarkGray"

    if ($DryRun) {
        Write-Host ""
        Write-ColorMsg "⚠️ DRY RUN 模式 — 未做任何实际修改" "Magenta"
    }

    Write-Host ""
}

# ============================================================
# Main Entry Point
# ============================================================

Write-Banner "Prompt Auto-Sync Engine"

if ($Rollback) {
    Invoke-Rollback
}

Write-ColorMsg "[1/4] Loading config: $ConfigPath ..." "Cyan"
$Config = Read-SyncConfig -Path $ConfigPath

Write-ColorMsg "[2/4] Creating backup ..." "Cyan"
$backupPath = New-PromptBackup -Config $Config

Write-ColorMsg "[3/4] Running sync engine ..." "Cyan"
$FileResults = Invoke-SyncEngine -Config $Config

Write-ColorMsg "[4/4] Generating report ..." "Cyan"
Write-SyncReport -FileResults $FileResults -BackupPath $backupPath
