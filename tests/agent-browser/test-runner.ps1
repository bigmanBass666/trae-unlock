<#
.SYNOPSIS
    Trae Agent-Browser 测试运行器
.DESCRIPTION
    加载并执行指定的测试脚本，收集结果并生成 Markdown 格式的测试报告。
    支持运行单个测试或全部测试。
.PARAMETER TestName
    要运行的测试名称: auto-confirm, auto-continue, all (默认 all)
.PARAMETER OutputDir
    报告输出目录（默认 tests/reports/）
.PARAMETER ScreenshotsDir
    截图保存目录（默认 tests/screenshots/）
.PARAMETER Port
    CDP 端口号（默认 9222）
.PARAMETER AutoDiscover
    自动发现 Trae 的调试端口
.PARAMETER NoConnect
    跳过连接步骤（使用已有连接）
.PARAMETER Verbose
    详细输出模式
.EXAMPLE
    .\test-runner.ps1 -TestName auto-confirm
    运行命令确认测试
.EXAMPLE
    .\test-runner.ps1 -TestName all -Verbose
    运行全部测试，详细输出
.EXAMPLE
    .\test-runner.ps1 -TestName auto-continue -Port 9333
    使用指定端口运行自动续接测试
.OUTPUTS
    int - 退出码 (0=全部通过, 1=有失败)
.NOTES
    依赖: connect.ps1, lib/utils.ps1, lib/assertions.ps1
#>

[CmdletBinding()]
param(
    [ValidateSet("auto-confirm", "auto-continue", "all")][string]$TestName = "all",
    [string]$OutputDir = "",
    [string]$ScreenshotsDir = "",
    [int]$Port = 9222,
    [switch]$AutoDiscover,
    [switch]$NoConnect,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# 解析默认路径
if (-not $OutputDir)      { $OutputDir      = Join-Path (Split-Path (Split-Path $PSScriptRoot)) "reports" }
if (-not $ScreenshotsDir) { $ScreenshotsDir = Join-Path (Split-Path (Split-Path $PSScriptRoot)) "screenshots" }

# ============================================================
#  加载依赖库
# ============================================================
$libDir = Join-Path $PSScriptRoot "lib"
. (Join-Path $libDir "utils.ps1")
. (Join-Path $libDir "assertions.ps1")

# ============================================================
#  配置
# ============================================================
if ($Verbose) { Set-VerboseLogging -Enabled $true }

$logDir      = Join-Path $PSScriptRoot "..\logs"
$dateStr     = Get-DateDirectory
$ts          = Get-FilenameTimestamp
$logFile     = Join-Path $logDir "test-run_${ts}.log"
$reportFile  = Join-Path $OutputDir "report_${ts}.md"

Set-TestLogPath -Path $logFile

# 确保输出目录存在
Test-PathExists -Path $OutputDir -CreateIfMissing | Out-Null
Test-PathExists -Path $ScreenshotsDir -CreateIfMissing | Out-Null
Test-PathExists -Path $logDir -CreateIfMissing | Out-Null

# 清理过期截图
Remove-StaleScreenshots -ScreenshotsDir $ScreenshotsDir -RetainDays 7

# 测试注册表：名称 -> 脚本路径的映射
$script:TestRegistry = @{
    "auto-confirm"  = Join-Path $PSScriptRoot "test-auto-confirm.ps1"
    "auto-continue" = Join-Path $PSScriptRoot "test-auto-continue.ps1"
}

# ============================================================
#  主流程
# ============================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Trae Agent-Browser Test Runner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-TestLog "=== Test Run Started ===" -Level INFO
Write-TestLog "TestName:   $TestName" -Level INFO
Write-TestLog "OutputDir:  $OutputDir" -Level INFO
Write-TestLog "LogFile:    $logFile" -Level INFO
Write-TestLog "Timestamp:  $(Get-Timestamp)" -Level INFO

# 收集结果
$results = [System.Collections.Generic.List[PSObject]]::new()
$overallStart = Get-Date

try {

    # ----------------------------------------------------------
    # Phase 1: 连接
    # ----------------------------------------------------------
    if (-not $NoConnect) {
        Write-Host "--- Phase 1: Connection ---" -ForegroundColor Yellow
        Write-TestLog "Phase 1: Establishing CDP connection..." -Level INFO

        $connectParams = @{
            Port         = $Port
            AutoDiscover = $AutoDiscover.IsPresent
            Timeout      = 15
        }

        # dot-source connect.ps1 并获取返回值
        $connectScript = Join-Path $PSScriptRoot "connect.ps1"
        $connectionInfo = & $connectScript @connectParams

        if (-not $connectionInfo -or -not $connectionInfo.Connected) {
            throw "Failed to establish CDP connection. Aborting test run."
        }
        Write-TestLog "CDP connected: $($connectionInfo.Title) (port $($connectionInfo.Port))" -Level INFO
    } else {
        Write-TestLog "Skipping connection (-NoConnect specified)" -Level INFO
        $connectionInfo = $null
    }

    # ----------------------------------------------------------
    # Phase 2: 确定要运行的测试
    # ----------------------------------------------------------
    $testsToRun = if ($TestName -eq "all") {
        @("auto-confirm", "auto-continue")
    } else {
        @($TestName)
    }

    Write-Host ""
    Write-Host "--- Phase 2: Running Tests ---" -ForegroundColor Yellow
    Write-TestLog "Tests to run: ($($testsToRun -join ', '))" -Level INFO

    # ----------------------------------------------------------
    # Phase 3: 执行每个测试
    # ----------------------------------------------------------
    foreach ($test in $testsToRun) {
        $testScript = $script:TestRegistry[$test]
        if (-not (Test-Path $testScript)) {
            Write-TestLog "Test script not found: $testScript" -Level WARN
            $skipResult = New-TestResult -TestName $test -Status "SKIP"
            $skipResult = Complete-TestResult -TestResult $skipResult -FinalStatus "SKIP" `
                -ErrorMessage "Test script not found: $testScript"
            $results.Add($skipResult)
            continue
        }

        Write-Host ""
        Write-Host ">> Running: $test" -ForegroundColor Magenta
        Write-TestLog ">>> Executing test: $test" -Level INFO

        try {
            # 执行测试脚本，传入公共参数
            $testParams = @{
                ScreenshotsDir = $ScreenshotsDir
                Verbose        = $Verbose.IsPresent
            }

            $testResult = & $testScript @testParams
            $results.Add($testResult)

            $statusColor = switch ($testResult.Status) {
                "PASS" { "Green" }
                "FAIL" { "Red" }
                "SKIP" { "Yellow" }
                default { "DarkGray" }
            }
            Write-Host "   [$($testResult.Status)] $($testResult.TestName) ($($testResult.DurationMs)ms)" `
                -ForegroundColor $statusColor

        } catch {
            $errorMsg = $_.Exception.Message
            Write-TestLog "Test '$test' threw exception: $errorMsg" -Level ERROR
            $failResult = New-TestResult -TestName $test
            $failResult = Complete-TestResult -TestResult $failResult -FinalStatus "FAIL" `
                -ErrorMessage $errorMsg
            $results.Add($failResult)
            Write-Host "   [FAIL] $test - Exception: $errorMsg" -ForegroundColor Red
        }
    }

} catch {
    $fatalError = $_.Exception.Message
    Write-TestLog "FATAL ERROR in test runner: $fatalError" -Level ERROR
    Write-Host ""
    Write-Host "[FATAL] $fatalError" -ForegroundColor Red
    exit 2
}

# ----------------------------------------------------------
# Phase 4: 汇总与报告
# ----------------------------------------------------------
$overallEnd = Get-Date
$overallDuration = [math]::Round(($overallEnd - $overallStart).TotalSeconds, 2)

$totalTests = $results.Count
$passedCount = @($results | Where-Object { $_.Status -eq "PASS" }).Count
$failedCount = @($results | Where-Object { $_.Status -eq "FAIL" }).Count
$skippedCount = @($results | Where-Object { $_.Status -eq "SKIP" }).Count
$allPassed = ($failedCount -eq 0)

Write-Host ""
Write-Host "========================================" -ForegroundColor $(if ($allPassed) { "Green" } else { "Red" })
Write-Host "  Results: ${passedCount}/${totalTests} passed, ${failedCount} failed, ${skippedCount} skipped" `
    -ForegroundColor $(if ($allPassed) { "Green" } else { "Red" })
Write-Host "  Duration: ${overallDuration}s" -ForegroundColor White
Write-Host "========================================" -ForegroundColor $(if ($allPassed) { "Green" } else { "Red" })

Write-TestLog "=== Test Run Complete ===" -Level INFO
Write-TestLog "Summary: ${passedCount} PASS, ${failedCount} FAIL, ${skippedCount} SKIP (of $totalTests)" -Level INFO
Write-TestLog "Duration: ${overallDuration}s" -Level INFO

# ----------------------------------------------------------
# Phase 5: 生成 Markdown 报告
# ----------------------------------------------------------
$reportContent = New-MarkdownReport -Results $results -OverallDuration $overallDuration `
    -ReportFile $reportFile -ConnectionInfo $connectionInfo
Set-Content -Path $reportFile -Value $reportContent -Encoding UTF8

Write-Host ""
Write-Host "[REPORT] $reportFile" -ForegroundColor Cyan

# 返回退出码
exit (0, 1)[$failedCount -gt 0]

# ============================================================
#  报告生成函数
# ============================================================

function New-MarkdownReport {
    <#
    .SYNOPSIS
        生成 Markdown 格式的测试报告
    #>
    param(
        [Parameter(Mandatory)][PSObject[]]$Results,
        [double]$OverallDuration,
        [string]$ReportFile,
        [PSObject]$ConnectionInfo
    )

    $lines = [System.Text.StringBuilder]::new()

    [void]$lines.AppendLine("# Trae Agent-Browser Test Report")
    [void]$lines.AppendLine("")
    [void]$lines.AppendLine("## Metadata")
    [void]$lines.AppendLine("")
    [void]$lines.AppendLine("| Property | Value |")
    [void]$lines.AppendLine("|----------|-------|")
    [void]$lines.AppendLine("| Generated | $(Get-Timestamp) |")
    [void]$lines.AppendLine("| Duration  | ${OverallDuration}s |")
    [void]$lines.AppendLine("| Total     | $($Results.Count) tests |")

    if ($ConnectionInfo) {
        [void]$lines.AppendLine("| Target    | $($ConnectionInfo.Title) (port $($ConnectionInfo.Port)) |")
    } else {
        [void]$lines.AppendLine("| Target    | (no connection info) |")
    }

    [void]$lines.AppendLine("| Log File  | $logFile |")
    [void]$lines.AppendLine("")

    # 结果表格
    [void]$lines.AppendLine("## Test Results")
    [void]$lines.AppendLine("")
    [void]$lines.AppendLine("| # | Test | Status | Duration | Error |")
    [void]$lines.AppendLine("|---|------|--------|----------|-------|")

    $idx = 1
    foreach ($r in $Results) {
        $statusIcon = switch ($r.Status) {
            "PASS" { ":white_check_mark:" }
            "FAIL" { ":x:" }
            "SKIP" { ":leftwards_arrow_with_hook:" }
            default { "?" }
        }
        $errMsg = if ($r.ErrorMessage) { $r.ErrorMessage.Substring(0, [math]::Min(80, $r.ErrorMessage.Length)) } else { "-" }
        [void]$lines.AppendLine("| $idx | $($r.TestName) | $statusIcon $($r.Status) | $($r.DurationMs)ms | $errMsg |")
        $idx++
    }
    [void]$lines.AppendLine("")

    # 详细断言信息
    [void]$lines.AppendLine("## Details")
    [void]$lines.AppendLine("")

    foreach ($r in $Results) {
        [void]$lines.AppendLine("### $($r.TestName)")
        [void]$lines.AppendLine("")
        [void]$lines.AppendLine("- **Status**: $($r.Status)")
        [void]$lines.AppendLine("- **Duration**: $($r.DurationMs)ms")

        if ($r.ErrorMessage) {
            [void]$lines.AppendLine("- **Error**: $($r.ErrorMessage)")
        }

        if ($r.Assertions -and $r.Assertions.Count -gt 0) {
            [void]$lines.AppendLine("")
            [void]$lines.AppendLine("**Assertions:**")
            [void]$lines.AppendLine("")
            $assertionLines = Format-AssertionReport -Assertions $r.Assertions
            foreach ($al in $assertionLines) {
                [void]$lines.AppendLine($al)
            }
            [void]$lines.AppendLine("")
        }

        if ($r.Screenshots -and $r.Screenshots.Count -gt 0) {
            [void]$lines.AppendLine("")
            [void]$lines.AppendLine("**Screenshots:**")
            foreach ($s in $r.Screenshots) {
                [void]$lines.AppendLine("- $s")
            }
            [void]$lines.AppendLine("")
        }

        [void]$lines.AppendLine("---")
        [void]$lines.AppendLine("")
    }

    return $lines.ToString()
}
