$IndexPath = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'

if (-not (Test-Path $IndexPath)) {
    Write-Error "index.js not found at: $IndexPath"
    exit 1
}

$c = [IO.File]::ReadAllText($IndexPath)
$totalLen = $c.Length
Write-Host "File loaded: $totalLen chars" -ForegroundColor Cyan

$templates = @(
    @{ID='DI-01'; Pattern='uX('},
    @{ID='DI-02'; Pattern='uJ({identifier:'},
    @{ID='DI-03'; Pattern='Symbol.for("'},
    @{ID='DI-04'; Pattern='Symbol("'},
    @{ID='SSE-01'; Pattern='eventHandlerFactory'},
    @{ID='SSE-02'; Pattern='Symbol.for("IPlanItemStreamParser")'},
    @{ID='SSE-07'; Pattern='handleSteamingResult'},
    @{ID='STO-01'; Pattern='Symbol("ISessionStore")'},
    @{ID='STO-04'; Pattern='.subscribe('},
    @{ID='STO-05'; Pattern='.getState()'},
    @{ID='ERR-01'; Pattern='4000002'},
    @{ID='ERR-06'; Pattern='getErrorInfo'},
    @{ID='ERR-07'; Pattern='handleCommonError'},
    @{ID='ERR-11'; Pattern='teaEventChatFail'},
    @{ID='RCT-01'; Pattern='sX().memo('},
    @{ID='RCT-08'; Pattern='getRunCommandCardBranch'},
    @{ID='RCT-10'; Pattern='"unconfirmed"'},
    @{ID='EVT-01'; Pattern='Symbol.for("ITeaFacade")'},
    @{ID='EVT-02'; Pattern='visibilitychange'},
    @{ID='EVT-05'; Pattern='icube.shellExec'},
    @{ID='COM-01'; Pattern='ICommercialPermissionService'},
    @{ID='COM-02'; Pattern='isCommercialUser'},
    @{ID='COM-03'; Pattern='IEntitlementStore'},
    @{ID='GEN-06'; Pattern='provideUserResponse'},
    @{ID='GEN-07'; Pattern='ToolCallName'},
    @{ID='GEN-08'; Pattern='BlockLevel'}
)

$results = @()
$okCount = 0
$emptyCount = 0

foreach ($t in $templates) {
    $firstOffset = $c.IndexOf($t.Pattern)
    $count = 0
    if ($firstOffset -ge 0) {
        $pos = 0
        while (($pos = $c.IndexOf($t.Pattern, $pos)) -ge 0) {
            $count++
            $pos += $t.Pattern.Length
        }
        $status = 'OK'
        $okCount++
    } else {
        $firstOffset = -1
        $status = 'EMPTY'
        $emptyCount++
    }
    $results += [PSCustomObject]@{
        ID = $t.ID
        Pattern = $t.Pattern
        FirstOffset = $firstOffset
        Count = $count
        Status = $status
    }
}

Write-Host "`n===== Search Template Availability Report =====" -ForegroundColor Yellow
Write-Host "File: $IndexPath"
Write-Host "File size: $totalLen chars"
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Host ""

$results | Format-Table -Property ID, Pattern, FirstOffset, Count, Status -AutoSize

Write-Host ""
Write-Host "Summary: OK=$okCount EMPTY=$emptyCount Total=$($templates.Count)" -ForegroundColor $(if ($emptyCount -gt 0) {'Red'} else {'Green'})

$report = @"
`n## [$(Get-Date -Format 'yyyy-MM-dd HH:mm')] 搜索模板可用性验证报告 ⭐⭐⭐⭐

> 自动化验证 explorer-protocol.md 附录A搜索模板在当前版本 ($totalLen chars) 上的可用性

### 验证结果

| 模板ID | 搜索模式 | 首次偏移量 | 总命中数 | 状态 |
|--------|---------|-----------|---------|------|
$(foreach ($r in $results) { "| $($r.ID) | ``$($r.Pattern)`` | $($r.FirstOffset) | $($r.Count) | $($r.Status) |" })

### 汇总

| 指标 | 值 |
|------|-----|
| 目标文件 | index.js |
| 文件字符数 | $totalLen |
| OK (命中>0) | $okCount |
| EMPTY (命中=0) | $emptyCount |
| 总模板数 | $($templates.Count) |
| 验证时间 | $(Get-Date -Format 'yyyy-MM-dd HH:mm') |

### EMPTY 模板分析

$(if ($emptyCount -gt 0) {
    $emptyOnes = $results | Where-Object { $_.Status -eq 'EMPTY' }
    foreach ($e in $emptyOnes) {
        "- **$($e.ID)**: ``$($e.Pattern)`` — 当前版本中未找到，可能已重命名或移除"
    }
} else {
    "无 — 所有模板均可用 ✅"
})

### 关键偏移量变化

$(foreach ($r in $results | Where-Object { $_.Status -eq 'OK' -and $_.FirstOffset -gt 0 }) {
    "| $($r.ID) | $($r.FirstOffset) |"
})
"@

Write-Host $report

$appendPath = "d:\Test\trae-unlock\shared\discoveries.md"
Add-Content -Path $appendPath -Value $report -Encoding UTF8
Write-Host "`nReport appended to: $appendPath" -ForegroundColor Green
