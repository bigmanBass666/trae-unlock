<#
.SYNOPSIS
    11 域交叉验证 + 潜在新域探索
.DESCRIPTION
    对 Trae AI 聊天模块的 11 个已知域执行 L0 锚点交叉验证，
    并对 5 个候选新域执行锚点搜索以评估是否满足新域判定标准。
    结果追加到 shared/discoveries.md
.EXAMPLE
    .\explore-deep-cross-validate.ps1
    执行完整验证
.EXAMPLE
    .\explore-deep-cross-validate.ps1 -PartAOnly
    仅执行 Part A 交叉验证
.EXAMPLE
    .\explore-deep-cross-validate.ps1 -PartBOnly
    仅执行 Part B 新域探索
#>
param(
    [switch]$PartAOnly,
    [switch]$PartBOnly
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$DiscoveriesFile = Join-Path $RootDir "shared\discoveries.md"

function Write-ColorOutput {
    param([string]$Msg, [string]$Color = "White")
    Write-Host $Msg -ForegroundColor $Color
}

function Write-Section {
    param([string]$Title, [string]$Color = "Cyan")
    Write-Host ""
    Write-ColorOutput ("=" * 70) $Color
    Write-ColorOutput "  $Title" $Color
    Write-ColorOutput ("=" * 70) $Color
}

function Write-SubSection {
    param([string]$Title, [string]$Color = "Yellow")
    Write-Host ""
    Write-ColorOutput "--- $Title ---" $Color
}

function Count-Occurrences {
    param([string]$Content, [string]$Pattern)
    $count = 0
    $pos = 0
    while (($pos = $Content.IndexOf($Pattern, $pos)) -ge 0) {
        $count++
        $pos += $Pattern.Length
    }
    return $count
}

function Find-AllPositions {
    param([string]$Content, [string]$Pattern, [int]$MaxResults = 20)
    $positions = @()
    $pos = 0
    while ((($idx = $Content.IndexOf($Pattern, $pos)) -ge 0) -and ($positions.Count -lt $MaxResults)) {
        $positions += $idx
        $pos = $idx + $Pattern.Length
    }
    return $positions
}

function Get-Context {
    param([string]$Content, [int]$Position, [int]$Before = 40, [int]$After = 60)
    $start = [Math]::Max(0, $Position - $Before)
    $end = [Math]::Min($Content.Length, $Position + $After)
    $ctx = $Content.Substring($start, $end - $start) -replace "`n", " " -replace "`r", ""
    return "...$ctx..."
}

function Test-Position {
    param([string]$Content, [string]$Pattern, [int]$ExpectedOffset, [int]$Tolerance = 500)
    $pos = $Content.IndexOf($Pattern)
    if ($pos -lt 0) {
        return @{ Found = $false; Position = -1; Match = $false; Delta = 0 }
    }
    $delta = [Math]::Abs($pos - $ExpectedOffset)
    return @{
        Found = $true
        Position = $pos
        Match = ($delta -le $Tolerance)
        Delta = $delta
    }
}

function Append-Discovery {
    param([string]$Content)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $header = "### [$timestamp] 11域交叉验证 + 新域探索"
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine($header)
    [void]$sb.AppendLine($Content)
    Add-Content -Path $DiscoveriesFile -Value $sb.ToString() -Encoding UTF8
    Write-ColorOutput "[discoveries] 已追加到 $DiscoveriesFile" "Green"
}

Write-Section "11 域交叉验证 + 潜在新域探索" "Magenta"
Write-ColorOutput "目标文件: $TargetFile" "Gray"

if (-not (Test-Path $TargetFile)) {
    Write-ColorOutput "[ERROR] 目标文件不存在: $TargetFile" "Red"
    exit 1
}

$fileInfo = Get-Item $TargetFile
Write-ColorOutput "文件大小: $([Math]::Round($fileInfo.Length / 1MB, 2)) MB" "Gray"

Write-ColorOutput "正在加载文件内容..." "Gray"
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$content = [System.IO.File]::ReadAllText($TargetFile, [System.Text.Encoding]::UTF8)
$sw.Stop()
Write-ColorOutput "加载完成: $($content.Length) chars, 耗时 $($sw.ElapsedMilliseconds)ms" "Gray"

$results = [System.Text.StringBuilder]::new()
[void]$results.AppendLine("")
[void]$results.AppendLine("> 自动化交叉验证结果，由 explore-deep-cross-validate.ps1 生成")
[void]$results.AppendLine("")

$totalPass = 0
$totalFail = 0
$totalWarn = 0

# ============================================================
# Part A: 关键域交叉验证
# ============================================================

if (-not $PartBOnly) {

    # ----------------------------------------------------------
    # [DI] 域验证
    # ----------------------------------------------------------
    Write-Section "[DI] 域交叉验证" "Cyan"

    [void]$results.AppendLine("## [DI] 域交叉验证")
    [void]$results.AppendLine("")

    # 1. uJ({identifier: 注册数
    Write-SubSection "uJ({identifier: 注册数统计"
    $ujCount = Count-Occurrences $content "uJ({identifier:"
    $ujExpected = 51
    $ujMatch = ($ujCount -eq $ujExpected)
    if ($ujMatch) { $totalPass++ } else { $totalFail++ }
    Write-ColorOutput "  uJ({identifier: 出现次数: $ujCount (预期: $ujExpected) $(if($ujMatch){'✅ PASS'}else{'❌ FAIL'})" $(if($ujMatch){'Green'}else{'Red'})
    [void]$results.AppendLine("| 检查项 | 预期 | 实际 | 结果 |")
    [void]$results.AppendLine("|--------|------|------|------|")
    [void]$results.AppendLine("| uJ({identifier: 注册数 | $ujExpected | $ujCount | $(if($ujMatch){'✅ PASS'}else{'❌ FAIL'}) |")

    # 2. uX( 注入数
    Write-SubSection "uX( 注入数统计"
    $uxCount = Count-Occurrences $content "uX("
    $uxExpected = 101
    $uxMatch = ($uxCount -eq $uxExpected)
    if ($uxMatch) { $totalPass++ } else { $totalFail++ }
    Write-ColorOutput "  uX( 出现次数: $uxCount (预期: $uxExpected) $(if($uxMatch){'✅ PASS'}else{'❌ FAIL'})" $(if($uxMatch){'Green'}else{'Red'})
    [void]$results.AppendLine("| uX( 注入数 | $uxExpected | $uxCount | $(if($uxMatch){'✅ PASS'}else{'❌ FAIL'}) |")

    # 3. 验证关键服务 Symbol
    Write-SubSection "关键服务 Symbol 验证"
    $diSymbols = @(
        @{ Name = "ISessionStore"; Pattern = 'Symbol("ISessionStore")'; ExpectedOffset = 7092843 },
        @{ Name = "IPlanItemStreamParser"; Pattern = 'Symbol("IPlanItemStreamParser")'; ExpectedOffset = 7510931 }
    )
    foreach ($sym in $diSymbols) {
        $test = Test-Position $content $sym.Pattern $sym.ExpectedOffset
        if ($test.Found -and $test.Match) { $totalPass++ } elseif ($test.Found) { $totalWarn++ } else { $totalFail++ }
        $status = if ($test.Match) { "✅ PASS" } elseif ($test.Found) { "⚠️ DRIFT" } else { "❌ FAIL" }
        Write-ColorOutput "  $($sym.Name) @pos=$($test.Position) (预期: $($sym.ExpectedOffset), delta=$($test.Delta)) $status" $(if($test.Match){'Green'}elseif($test.Found){'Yellow'}else{'Red'})
        [void]$results.AppendLine("| $($sym.Name) | $($sym.ExpectedOffset) | $($test.Position) | $status |")
    }

    [void]$results.AppendLine("")

    # ----------------------------------------------------------
    # [SSE] 域验证
    # ----------------------------------------------------------
    Write-Section "[SSE] 域交叉验证" "Cyan"

    [void]$results.AppendLine("## [SSE] 域交叉验证")
    [void]$results.AppendLine("")

    # 1. eventHandlerFactory 出现次数
    Write-SubSection "eventHandlerFactory 统计"
    $ehfCount = Count-Occurrences $content "eventHandlerFactory"
    Write-ColorOutput "  eventHandlerFactory 出现次数: $ehfCount" "White"
    [void]$results.AppendLine("| 检查项 | 实际值 |")
    [void]$results.AppendLine("|--------|--------|")
    [void]$results.AppendLine("| eventHandlerFactory 出现次数 | $ehfCount |")

    # 2. handleSteamingResult 位置
    Write-SubSection "handleSteamingResult 验证"
    $hsrPositions = Find-AllPositions $content "handleSteamingResult" 10
    Write-ColorOutput "  handleSteamingResult 出现次数: $($hsrPositions.Count)" "White"
    foreach ($p in $hsrPositions) {
        Write-ColorOutput "    @pos=$p" "Gray"
    }
    [void]$results.AppendLine("| handleSteamingResult 出现次数 | $($hsrPositions.Count) |")
    if ($hsrPositions.Count -gt 0) {
        [void]$results.AppendLine("| handleSteamingResult 位置 | $($hsrPositions -join ', ') |")
    }

    # 3. SSE 事件类型枚举
    Write-SubSection "SSE 事件类型枚举验证"
    $sseEvents = @(
        @{ Pattern = 'Ot.PlanItem'; Name = "PlanItem" },
        @{ Pattern = 'Ot.Error'; Name = "Error" },
        @{ Pattern = 'Ot.Done'; Name = "Done" },
        @{ Pattern = 'Ot.Metadata'; Name = "Metadata" },
        @{ Pattern = 'Ot.Notification'; Name = "Notification" },
        @{ Pattern = 'Ot.TextMessage'; Name = "TextMessage" },
        @{ Pattern = 'Ot.UserMessage'; Name = "UserMessage" },
        @{ Pattern = 'Ot.TokenUsage'; Name = "TokenUsage" },
        @{ Pattern = 'Ot.Queueing'; Name = "Queueing" },
        @{ Pattern = 'Ot.FeeUsage'; Name = "FeeUsage" },
        @{ Pattern = 'Ot.SessionTitle'; Name = "SessionTitle" }
    )
    [void]$results.AppendLine("")
    [void]$results.AppendLine("| 事件类型 | 出现次数 | 位置 |")
    [void]$results.AppendLine("|---------|---------|------|")
    $sseFound = 0
    foreach ($evt in $sseEvents) {
        $evtCount = Count-Occurrences $content $evt.Pattern
        $evtPos = Find-AllPositions $content $evt.Pattern 3
        if ($evtCount -gt 0) { $sseFound++ }
        Write-ColorOutput "  $($evt.Name): $evtCount 次 $(if($evtPos.Count -gt 0){'@' + ($evtPos -join ', ')})" $(if($evtCount -gt 0){'Green'}else{'Red'})
        [void]$results.AppendLine("| $($evt.Name) | $evtCount | $($evtPos -join ', ') |")
    }
    if ($sseFound -ge 8) { $totalPass++ } else { $totalWarn++ }
    Write-ColorOutput "  SSE 事件枚举覆盖率: $sseFound/$($sseEvents.Count) $(if($sseFound -ge 8){'✅'}else{'⚠️'})" $(if($sseFound -ge 8){'Green'}else{'Yellow'})

    [void]$results.AppendLine("")

    # ----------------------------------------------------------
    # [Store] 域验证
    # ----------------------------------------------------------
    Write-Section "[Store] 域交叉验证" "Cyan"

    [void]$results.AppendLine("## [Store] 域交叉验证")
    [void]$results.AppendLine("")

    # 1. setCurrentSession
    Write-SubSection "setCurrentSession 统计"
    $scsCount = Count-Occurrences $content "setCurrentSession"
    Write-ColorOutput "  setCurrentSession 出现次数: $scsCount" "White"
    [void]$results.AppendLine("| 检查项 | 实际值 |")
    [void]$results.AppendLine("|--------|--------|")
    [void]$results.AppendLine("| setCurrentSession 出现次数 | $scsCount |")

    # 2. .subscribe( 统计
    Write-SubSection ".subscribe( 统计"
    $subCount = Count-Occurrences $content ".subscribe("
    Write-ColorOutput "  .subscribe( 出现次数: $subCount" "White"
    [void]$results.AppendLine("| .subscribe( 出现次数 | $subCount |")

    # 3. .getState() 统计
    Write-SubSection ".getState() 统计"
    $gsCount = Count-Occurrences $content ".getState()"
    Write-ColorOutput "  .getState() 出现次数: $gsCount" "White"
    [void]$results.AppendLine("| .getState() 出现次数 | $gsCount |")

    # 4. Store Symbol 验证
    Write-SubSection "Store DI Token 验证"
    $storeTokens = @(
        @{ Name = "ISessionStore"; Pattern = 'Symbol("ISessionStore")' },
        @{ Name = "IInlineSessionStore"; Pattern = 'Symbol("IInlineSessionStore")' },
        @{ Name = "IModelStore"; Pattern = 'Symbol("IModelStore")' },
        @{ Name = "IEntitlementStore"; Pattern = 'Symbol("IEntitlementStore")' },
        @{ Name = "ISessionRelationStoreInternal"; Pattern = 'Symbol("ISessionRelationStoreInternal")' }
    )
    [void]$results.AppendLine("")
    [void]$results.AppendLine("| Store Token | 存在 | 位置 |")
    [void]$results.AppendLine("|------------|------|------|")
    $storeFound = 0
    foreach ($st in $storeTokens) {
        $pos = $content.IndexOf($st.Pattern)
        if ($pos -ge 0) { $storeFound++ }
        Write-ColorOutput "  $($st.Name): $(if($pos -ge 0){'✅ @'+$pos}else{'❌'})" $(if($pos -ge 0){'Green'}else{'Red'})
        [void]$results.AppendLine("| $($st.Name) | $(if($pos -ge 0){'✅'}else{'❌'}) | $(if($pos -ge 0){$pos}else{'N/A'}) |")
    }
    if ($storeFound -ge 4) { $totalPass++ } else { $totalWarn++ }

    [void]$results.AppendLine("")

    # ----------------------------------------------------------
    # [Error] 域验证
    # ----------------------------------------------------------
    Write-Section "[Error] 域交叉验证" "Cyan"

    [void]$results.AppendLine("## [Error] 域交叉验证")
    [void]$results.AppendLine("")

    # 1. kg. 错误码穷举
    Write-SubSection "kg. 错误码枚举穷举"
    $kgPattern = [regex]'kg\.([A-Z][A-Za-z_0-9]*)'
    $kgMatches = $kgPattern.Matches($content)
    $kgCodes = @{}
    foreach ($m in $kgMatches) {
        $code = $m.Groups[1].Value
        if (-not $kgCodes.ContainsKey($code)) {
            $kgCodes[$code] = @()
        }
        $kgCodes[$code] += $m.Index
    }
    $kgSorted = $kgCodes.Keys | Sort-Object
    Write-ColorOutput "  发现 $($kgSorted.Count) 个 kg. 错误码枚举值:" "White"
    [void]$results.AppendLine("| 错误码枚举 | 出现次数 | 首次位置 |")
    [void]$results.AppendLine("|-----------|---------|---------|")
    foreach ($code in $kgSorted) {
        $count = $kgCodes[$code].Count
        $firstPos = $kgCodes[$code][0]
        Write-ColorOutput "    kg.$code ×$count @~$firstPos" "Gray"
        [void]$results.AppendLine("| kg.$code | $count | $firstPos |")
    }

    # 2. 验证关键错误码
    Write-SubSection "关键错误码验证"
    $keyErrors = @(
        @{ Name = "TASK_TURN_EXCEEDED"; Pattern = "kg.TASK_TURN_EXCEEDED" },
        @{ Name = "PREMIUM_MODE_USAGE_LIMIT"; Pattern = "kg.PREMIUM_MODE_USAGE_LIMIT" },
        @{ Name = "STANDARD_MODE_USAGE_LIMIT"; Pattern = "kg.STANDARD_MODE_USAGE_LIMIT" },
        @{ Name = "FIREWALL_BLOCKED"; Pattern = "kg.FIREWALL_BLOCKED" }
    )
    [void]$results.AppendLine("")
    [void]$results.AppendLine("| 关键错误码 | 存在 | 位置 |")
    [void]$results.AppendLine("|-----------|------|------|")
    $errFound = 0
    foreach ($ke in $keyErrors) {
        $pos = $content.IndexOf($ke.Pattern)
        if ($pos -ge 0) { $errFound++ }
        Write-ColorOutput "  $($ke.Name): $(if($pos -ge 0){'✅ @'+$pos}else{'❌'})" $(if($pos -ge 0){'Green'}else{'Red'})
        [void]$results.AppendLine("| $($ke.Name) | $(if($pos -ge 0){'✅'}else{'❌'}) | $(if($pos -ge 0){$pos}else{'N/A'}) |")
    }
    if ($errFound -eq 4) { $totalPass++ } else { $totalFail++ }

    # 3. J=!![ 验证
    Write-SubSection "J=!![ 变量定义验证"
    $jDefPositions = Find-AllPositions $content "J=!![" 5
    Write-ColorOutput "  J=!![ 出现次数: $($jDefPositions.Count)" "White"
    foreach ($p in $jDefPositions) {
        $ctx = Get-Context $content $p 20 80
        Write-ColorOutput "    @pos=$p $ctx" "Gray"
    }
    [void]$results.AppendLine("| J=!![ 出现次数 | $($jDefPositions.Count) |")
    if ($jDefPositions.Count -gt 0) {
        [void]$results.AppendLine("| J=!![ 位置 | $($jDefPositions -join ', ') |")
    }

    # 4. handleCommonError 验证
    Write-SubSection "handleCommonError 验证"
    $hcePositions = Find-AllPositions $content "handleCommonError" 5
    Write-ColorOutput "  handleCommonError 出现次数: $($hcePositions.Count)" "White"
    foreach ($p in $hcePositions) {
        $ctx = Get-Context $content $p 30 60
        Write-ColorOutput "    @pos=$p $ctx" "Gray"
    }
    [void]$results.AppendLine("| handleCommonError 出现次数 | $($hcePositions.Count) |")
    if ($hcePositions.Count -gt 0) {
        [void]$results.AppendLine("| handleCommonError 位置 | $($hcePositions -join ', ') |")
    }

    [void]$results.AppendLine("")

    # ----------------------------------------------------------
    # [Commercial] 域验证
    # ----------------------------------------------------------
    Write-Section "[Commercial] 域交叉验证" "Cyan"

    [void]$results.AppendLine("## [Commercial] 域交叉验证")
    [void]$results.AppendLine("")

    # 1. ICommercialPermissionService 注册方式
    Write-SubSection "ICommercialPermissionService 注册验证"
    $comSymFor = 'Symbol.for("aiAgent.ICommercialPermissionService")'
    $comSym = 'Symbol("aiAgent.ICommercialPermissionService")'
    $comForPos = $content.IndexOf($comSymFor)
    $comSymPos = $content.IndexOf($comSym)
    Write-ColorOutput "  Symbol.for 模式: $(if($comForPos -ge 0){'✅ @'+$comForPos}else{'❌'})" $(if($comForPos -ge 0){'Green'}else{'Red'})
    Write-ColorOutput "  Symbol 模式:     $(if($comSymPos -ge 0){'✅ @'+$comSymPos}else{'❌'})" $(if($comSymPos -ge 0){'Green'}else{'Red'})
    [void]$results.AppendLine("| 注册模式 | 存在 | 位置 |")
    [void]$results.AppendLine("|---------|------|------|")
    [void]$results.AppendLine("| Symbol.for | $(if($comForPos -ge 0){'✅'}else{'❌'}) | $(if($comForPos -ge 0){$comForPos}else{'N/A'}) |")
    [void]$results.AppendLine("| Symbol | $(if($comSymPos -ge 0){'✅'}else{'❌'}) | $(if($comSymPos -ge 0){$comSymPos}else{'N/A'}) |")
    if ($comForPos -ge 0) { $totalPass++ } else { $totalWarn++ }

    # 2. isCommercialUser
    Write-SubSection "isCommercialUser 验证"
    $icuPositions = Find-AllPositions $content "isCommercialUser" 10
    Write-ColorOutput "  isCommercialUser 出现次数: $($icuPositions.Count)" "White"
    foreach ($p in $icuPositions) {
        $ctx = Get-Context $content $p 30 50
        Write-ColorOutput "    @pos=$p $ctx" "Gray"
    }
    [void]$results.AppendLine("| isCommercialUser 出现次数 | $($icuPositions.Count) |")
    if ($icuPositions.Count -gt 0) {
        [void]$results.AppendLine("| isCommercialUser 位置 | $($icuPositions -join ', ') |")
    }

    # 3. entitlementInfo
    Write-SubSection "entitlementInfo 验证"
    $eiPositions = Find-AllPositions $content "entitlementInfo" 10
    Write-ColorOutput "  entitlementInfo 出现次数: $($eiPositions.Count)" "White"
    foreach ($p in $eiPositions) {
        $ctx = Get-Context $content $p 25 50
        Write-ColorOutput "    @pos=$p $ctx" "Gray"
    }
    [void]$results.AppendLine("| entitlementInfo 出现次数 | $($eiPositions.Count) |")
    if ($eiPositions.Count -gt 0) {
        [void]$results.AppendLine("| entitlementInfo 位置 | $($eiPositions -join ', ') |")
    }

    # 4. isFreeUser
    Write-SubSection "isFreeUser 验证"
    $ifuPositions = Find-AllPositions $content "isFreeUser" 10
    Write-ColorOutput "  isFreeUser 出现次数: $($ifuPositions.Count)" "White"
    foreach ($p in $ifuPositions) {
        $ctx = Get-Context $content $p 25 50
        Write-ColorOutput "    @pos=$p $ctx" "Gray"
    }
    [void]$results.AppendLine("| isFreeUser 出现次数 | $($ifuPositions.Count) |")
    if ($ifuPositions.Count -gt 0) {
        [void]$results.AppendLine("| isFreeUser 位置 | $($ifuPositions -join ', ') |")
    }

    [void]$results.AppendLine("")

} # end Part A

# ============================================================
# Part B: 潜在新域探索
# ============================================================

if (-not $PartAOnly) {

    Write-Section "Part B: 潜在新域探索" "Magenta"

    [void]$results.AppendLine("## 潜在新域探索")
    [void]$results.AppendLine("")

    $newDomains = @(
        @{
            Name = "Network"
            Anchors = @("fetch(", "XMLHttpRequest", "axios", "interceptor")
            MinEntities = 3
        },
        @{
            Name = "Model"
            Anchors = @("IModelService", "IModelStorageService", "computeSelectedModel", "modelList")
            MinEntities = 3
        },
        @{
            Name = "History"
            Anchors = @("IPastChatExporter", "chatHistory", "exportChat", "pastChat")
            MinEntities = 3
        },
        @{
            Name = "Auth"
            Anchors = @("ICredentialFacade", "login", "logout", "authenticate", "token")
            MinEntities = 3
        },
        @{
            Name = "Telemetry"
            Anchors = @("ITeaFacade", "ISlardarFacade", "TeaReporter", "slardar")
            MinEntities = 3
        }
    )

    foreach ($domain in $newDomains) {
        Write-SubSection "[$($domain.Name)] 候选域探索" "Yellow"

        [void]$results.AppendLine("### [$($domain.Name)] 候选域")
        [void]$results.AppendLine("")
        [void]$results.AppendLine("| 锚点 | 出现次数 | 位置 |")
        [void]$results.AppendLine("|------|---------|------|")

        $entityCount = 0
        $domainDetail = @()

        foreach ($anchor in $domain.Anchors) {
            $positions = Find-AllPositions $content $anchor 5
            $count = Count-Occurrences $content $anchor
            if ($count -gt 0) { $entityCount++ }

            Write-ColorOutput "  `"$anchor`": $count 次" $(if($count -gt 0){'Green'}else{'DarkGray'})
            if ($positions.Count -gt 0) {
                foreach ($p in $positions) {
                    $ctx = Get-Context $content $p 20 40
                    Write-ColorOutput "    @pos=$p $ctx" "DarkGray"
                }
            }

            [void]$results.AppendLine("| $anchor | $count | $(if($positions.Count -gt 0){$positions -join ', '}else{'N/A'}) |")
            $domainDetail += @{ Anchor = $anchor; Count = $count; Positions = $positions }
        }

        $qualifies = $entityCount -ge $domain.MinEntities
        $score = 0
        if ($entityCount -ge 3) { $score += 1 }
        $totalHits = ($domainDetail | Measure-Object -Property Count -Sum).Sum
        if ($totalHits -ge 5) { $score += 1 }
        $hasDI = $false
        foreach ($d in $domainDetail) {
            if ($d.Anchor -match "^I[A-Z]" -and $d.Count -gt 0) { $hasDI = $true }
        }
        if ($hasDI) { $score += 1 }
        $hasFunctional = $false
        foreach ($d in $domainDetail) {
            if ($d.Anchor -notmatch "^I[A-Z]" -and $d.Count -gt 0) { $hasFunctional = $true }
        }
        if ($hasFunctional) { $score += 1 }
        if ($totalHits -ge 10) { $score += 1 }

        $verdict = if ($qualifies) { "🟢 新域候选 (≥3 独立实体)" } else { "🔴 不满足 (＜3 独立实体)" }
        Write-ColorOutput "  独立实体: $entityCount / $($domain.Anchors.Count) | 总命中: $totalHits | 新域评分: $score/5 | $verdict" $(if($qualifies){'Green'}else{'Red'})

        [void]$results.AppendLine("")
        [void]$results.AppendLine("| 评估维度 | 结果 |")
        [void]$results.AppendLine("|---------|------|")
        [void]$results.AppendLine("| 独立实体数 | $entityCount / $($domain.Anchors.Count) |")
        [void]$results.AppendLine("| 总命中数 | $totalHits |")
        [void]$results.AppendLine("| DI 接口存在 | $(if($hasDI){'是'}else{'否'}) |")
        [void]$results.AppendLine("| 功能性锚点存在 | $(if($hasFunctional){'是'}else{'否'}) |")
        [void]$results.AppendLine("| 新域评分 | $score / 5 |")
        [void]$results.AppendLine("| 判定 | $verdict |")
        [void]$results.AppendLine("")

        if ($qualifies) {
            $totalPass++
        }
    }

} # end Part B

# ============================================================
# 汇总
# ============================================================

Write-Section "验证汇总" "Green"

$summary = @"
## 验证汇总

| 指标 | 值 |
|------|-----|
| 目标文件大小 | $([Math]::Round($content.Length / 1MB, 2)) MB |
| 目标文件字符数 | $($content.Length) |
| ✅ PASS | $totalPass |
| ⚠️ WARN/DRIFT | $totalWarn |
| ❌ FAIL | $totalFail |
| 总检查项 | $($totalPass + $totalWarn + $totalFail) |
"@

Write-ColorOutput $summary "White"
[void]$results.AppendLine($summary)

Append-Discovery $results.ToString()

Write-Host ""
Write-ColorOutput "验证完成！结果已追加到 shared/discoveries.md" "Green"
