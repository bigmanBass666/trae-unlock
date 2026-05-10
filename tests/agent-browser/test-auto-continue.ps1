<#
.SYNOPSIS
    测试自动续接（Auto-Continue）补丁是否生效
.DESCRIPTION
    通过 agent-browser 在 Trae 中触发思考上限场景，验证 [AC] 续接机制是否正常工作。
    监控控制台日志中的 [AC] 前缀消息，验证消息数量增长和响应时间。

    此脚本由 test-runner.ps1 调用，不应直接执行（除非调试）。
.PARAMETER ScreenshotsDir
    截图保存目录
.PARAMETER Verbose
    详细输出模式
.OUTPUTS
    PSCustomObject - 测试结果对象（供 test-runner 收集）
.NOTES
    状态: 骨架实现 - UI 交互选择器待 CDP 连接验证后填充

    测试流程:
      Phase 1: 准备 - 连接验证、基线截图、初始日志快照
      Phase 2: 触发 - 发送会触发长思考的消息
      Phase 3: 监控 - 轮询控制台日志，检测 [AC] 前缀消息
      Phase 4: 断言 - 验证 [AC] 消息出现、数量增长、响应延迟合理
      Phase 5: 清理 - 截图、日志归档、返回结果

    关键指标:
      - [AC] 消息是否出现 (必须)
      - [AC] 消息数量 >= 1 (至少一次续接)
      - 续接响应时间 < 5s (可配置阈值)
#>

[CmdletBinding()]
param(
    [string]$ScreenshotsDir,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# ============================================================
#  加载依赖库
# ============================================================
$libDir = Join-Path $PSScriptRoot "lib"
. (Join-Path $libDir "utils.ps1")
. (Join-Path $libDir "assertions.ps1")

if ($Verbose) { Set-VerboseLogging -Enabled $true }

# ============================================================
#  测试配置
# ============================================================

$script:Config = @{
    # 触发长思考的测试消息（需要足够复杂以触发思考上限）
    TriggerMessage     = "请详细分析当前项目的架构设计，包括所有模块的职责划分、数据流向、依赖关系，并给出改进建议。请尽可能详尽地展开每一个细节。"

    # [AC] 日志前缀（auto-continue 标记）
    AcLogPrefix        = "[AC]"
    AcAltPrefixes       = @("[auto-continue]", "[continue-thinking]", "AC:")

    # 控制台日志中与思考续接相关的关键词
    ContinueKeywords   = @("continuation", "resume", "thinking", "token_limit", "max_tokens")

    # UI 选择器（待 CDP inspect 后填充）
    ChatInputSelector  = ""   # TODO: 填充实际选择器
    SendButtonSelector = ""   # TODO: 填充实际选择器
    ResponseAreaSel    = ""   # TODO: AI 回复区域选择器

    # 监控参数
    MonitorDurationSec = 30       # 总监控时长（续接可能需要较长时间）
    PollIntervalMs     = 1000     # 轮询间隔（1秒检查一次日志）

    # 阈值
    MinAcMessages      = 1        # 最少需要检测到的 [AC] 消息数
    MaxResponseDelayMs = 5000     # 最大允许的续接响应延迟（毫秒）
}

# ============================================================
#  主测试逻辑
# ============================================================

$result = New-TestResult -TestName "auto-continue"

Write-Host ""
Write-Host "[auto-continue] Starting test..." -ForegroundColor Magenta
Write-TestLog "[auto-continue] === Test Start ===" -Level INFO

try {

    # ----------------------------------------------------------
    # Phase 1: 准备
    # ----------------------------------------------------------
    Write-TestLog "Phase 1: Preparation" -Level INFO

    # 1.1 验证连接有效
    $connAssert = Assert-CdpConnected -Description "Connection valid before auto-continue test"
    $result.Assertions.Add($connAssert)
    if (-not $connAssert.Passed) {
        throw "CDP connection lost before test execution"
    }

    # 1.2 截取初始状态
    $initialScreenshot = Save-Screenshot -Scenario "auto-continue" -Step "initial-state" `
        -ScreenshotsDir $ScreenshotsDir
    if ($initialScreenshot) { [void]$result.Screenshots.Add($initialScreenshot) }

    # 1.3 记录初始控制台日志行数（作为基线）
    $initialConsole = Invoke-AgentBrowser -Command "console"
    $initialLineCount = if ($initialConsole.ExitCode -eq 0) {
        @($initialConsole.Output -split "`n").Count
    } else { 0 }
    Write-TestLog "Initial console log lines: $initialLineCount" -Level DEBUG


    # ----------------------------------------------------------
    # Phase 2: 触发长思考
    # ----------------------------------------------------------
    Write-TestLog "Phase 2: Triggering long-thinking message..." -Level INFO

    # TODO: 实际 UI 交互代码待填充
    #
    # Step 2.1: 点击输入框
    # Step 2.2: 输入触发消息（使用 keyboard type 更可靠）
    # Step 2.3: 发送消息

    Write-TestLog "[SKEL] Would send trigger message to trigger long thinking chain" -Level WARN
    Write-TestLog "[SKEL] Message length: $($script:Config.TriggerMessage.Length) chars" -Level DEBUG
    Write-TestLog "[SKEL] TODO: Fill in ChatInputSelector and SendButtonSelector after CDP inspection" -Level WARN

    # 占位：模拟触发后的等待
    Start-Sleep -Milliseconds 1500


    # ----------------------------------------------------------
    # Phase 3: 监控 [AC] 日志
    # ----------------------------------------------------------
    Write-TestLog "Phase 3: Monitoring for [AC] log entries ($($script:Config.MonitorDurationSec)s)..." -Level INFO

    $acMessages         = [System.Collections.ArrayList]::new()
    $firstAcTimestamp   = $null
    $lastAcTimestamp    = $null
    $pollCount          = [math]::Ceiling($script:Config.MonitorDurationSec * 1000 / $script:Config.PollIntervalMs)
    $monitorStopwatch   = [System.Diagnostics.Stopwatch]::StartNew()
    $prevConsoleLength  = 0

    for ($i = 0; $i -lt $pollCount; $i++) {
        # 获取当前控制台日志
        $consoleR = Invoke-AgentBrowser -Command "console"
        if ($consoleR.ExitCode -ne 0) {
            Write-TestLog "Console fetch failed at iteration $($i+1), skipping..." -Level WARN
            Start-Sleep -Milliseconds $script:Config.PollIntervalMs
            continue
        }

        $logLines = $consoleR.Output -split "`n"
        $currentElapsed = [math]::Round($monitorStopwatch.Elapsed.TotalSeconds, 2)

        # 只处理新增的日志行
        $newLinesCount = $logLines.Count - $prevConsoleLength
        if ($newLinesCount -gt 0) {
            $newLines = $logLines[($prevConsoleLength)..($logLines.Count - 1)]

            foreach ($line in $newLines) {
                $trimmedLine = $line.Trim()

                # 检测 [AC] 前缀或替代前缀
                $isAcMessage = $false
                if ($trimmedLine -match '\[AC\]') {
                    $isAcMessage = $true
                } else {
                    foreach ($alt in $script:Config.AltPrefixes) {
                        if ($trimmedLine -match [regex]::Escape($alt)) {
                            $isAcMessage = $true; break
                        }
                    }
                }

                if ($isAcMessage) {
                    $entry = [PSCustomObject]@{
                        Index     = $acMessages.Count + 1
                        Timestamp = $currentElapsed
                        Content   = $trimmedLine.Substring(0, [math]::Min(200, $trimmedLine.Length))
                    }
                    [void]$acMessages.Add($entry)

                    if (-not $firstAcTimestamp) {
                        $firstAcTimestamp = $currentElapsed
                        Write-TestLog "[AC] First message detected at +${firstAcTimestamp}s: $($entry.Content)" -Level INFO
                    }
                    $lastAcTimestamp = $currentElapsed

                    Write-TestLog "[AC] #$($entry.Index) at +${currentElapsed}s: $($entry.Content)" -Level DEBUG
                }
            }
        }

        $prevConsoleLength = $logLines.Count

        # 如果已经检测到足够多的 AC 消息且超过最小值，可以提前结束监控
        if ($acMessages.Count -ge ($script:Config.MinAcMessages + 2) -and $currentElapsed -gt 10) {
            Write-TestLog "Early stop: sufficient AC messages collected ($($acMessages.Count)) at ${currentElapsed}s" -Level INFO
            break
        }

        Start-Sleep -Milliseconds $script:Config.PollIntervalMs
    }

    $monitorStopwatch.Stop()
    $totalMonitorSec = [math]::Round($monitorStopwatch.Elapsed.TotalSeconds, 2)


    # ----------------------------------------------------------
    # Phase 4: 断言
    # ----------------------------------------------------------
    Write-TestLog "Phase 4: Assertions" -Level INFO

    # 截取最终状态
    $finalScreenshot = Save-Screenshot -Scenario "auto-continue" -Step "final-state" `
        -ScreenshotsDir $ScreenshotsDir
    if ($finalScreenshot) { [void]$result.Screenshots.Add($finalScreenshot) }


    # 断言 1: 至少检测到 N 条 [AC] 消息
    $hasEnoughAc = ($acMessages.Count -ge $script:Config.MinAcMessages)
    $assert1 = Assert-Condition `
        -Condition $hasEnoughAc `
        -Description "[$($script:Config.MinAcMessages)+] AC messages detected" `
        -FailureMessage "Expected at least $($script:Config.MinAcMessages) [AC] messages, got $($acMessages.Count)"
    $result.Assertions.Add($assert1)


    # 断言 2: 如果有 AC 消息，响应延迟在阈值内
    $delayOk = $true
    if ($firstAcTimestamp -and $firstAcTimestamp -gt $script:Config.MaxResponseDelayMs / 1000) {
        $delayOk = $false
    }
    $assert2 = Assert-Condition `
        -Condition $delayOk `
        -Description "First AC response within threshold" `
        -FailureMessage "First [AC] appeared at ${firstAcTimestamp}s, exceeds $($script:Config.MaxResponseDelayMs/1000)s threshold"
    $result.Assertions.Add($assert2)


    # 断言 3: 控制台日志中有续接相关内容（即使没有 [AC] 前缀）
    $finalConsole = Invoke-AgentBrowser -Command "console"
    $hasContinueKeywords = $false
    if ($finalConsole.ExitCode -eq 0) {
        foreach ($kw in $script:Config.ContinueKeywords) {
            if ($finalConsole.Output -imatch $kw) {
                $hasContinueKeywords = $true
                break
            }
        }
    }
    $assert3 = Assert-Condition `
        -Condition $hasContinueKeywords `
        -Description "Console contains continue-related keywords" `
        -FailureMessage "No continue-related keywords found in console logs"
    $result.Assertions.Add($assert3)


    # 断言 4: 控制台日志行数增加（说明有活动发生）
    $finalLineCount = if ($finalConsole.ExitCode -eq 0) {
        @($finalConsole.Output -split "`n").Count
    } else { $initialLineCount }
    $linesIncreased = ($finalLineCount -gt $initialLineCount + 5)
    $assert4 = Assert-Condition `
        -Condition $linesIncreased `
        -Description "Console log activity detected" `
        -FailureMessage "Console logs did not grow significantly (before=$initialLineCount, after=$finalLineCount)"
    $result.Assertions.Add($assert4)


    # 汇总测试结论
    $summary = Get-AssertionSummary -Assertions $result.Assertions
    $testPassed = $summary.AllPassed

    if ($testPassed) {
        Write-TestLog "AUTO-CONTINUE TEST PASSED: $($summary.Passed)/$(summary.Total) assertions passed" -Level INFO
        Write-TestLog "  AC messages: $($acMessages.Count)" -Level INFO
        if ($firstAcTimestamp) { Write-TestLog "  First AC at: +${firstAcTimestamp}s" -Level INFO }
    } else {
        Write-TestLog "AUTO-CONTINUE TEST FAILED: $($summary.Failed)/$(summary.Total) assertions failed" -Level ERROR
        Write-TestLog "  AC messages: $($acMessages.Count) (need $($script:Config.MinAcMessages)+)" -Level ERROR
    }


    # ----------------------------------------------------------
    # Phase 5: 清理与数据收集
    # ----------------------------------------------------------
    Write-TestLog "Phase 5: Cleanup & data collection" -Level INFO

    # 收集所有 [AC] 相关日志作为证据
    if ($acMessages.Count -gt 0) {
        $result.Details += "AC Messages ($($acMessages.Count)):`n"
        foreach ($msg in $acMessages) {
            $result.Details += "  [#$(msg.Index)] +$($msg.Timestamp)s: $(msg.Content)`n"
        }
    }

    # 收集最终控制台日志片段
    if ($finalConsole.ExitCode -eq 0) {
        $allLines = $finalConsole.Output -split "`n"
        $relevantLines = @($allLines | Where-Object {
            $_ -imatch 'AC|continue|thinking|token|limit|PlanItemStreamParser'
        })
        if ($relevantLines.Count -gt 0) {
            $result.Details += "`nRelevant Console Entries ($($relevantLines.Count)):`n"
            foreach ($rl in $relevantLines | Select-Object -First 15) {
                $result.Details += "  $rl.Trim()`n"
            }
        }
    }


    # ----------------------------------------------------------
    # 完成
    # ----------------------------------------------------------
    $finalStatus = if ($testPassed) { "PASS" } else { "FAIL" }
    $errorMsg = if (-not $testPassed) {
        "Auto-continue assertions failed. AC messages: $($acMessages.Count), required: $($script:Config.MinAcMessages)+"
    } else { "" }

    $result = Complete-TestResult -TestResult $result -FinalStatus $finalStatus -ErrorMessage $errorMsg

    Write-Host "[auto-continue] Test completed: $finalStatus ($($result.DurationMs)ms, AC msgs: $($acMessages.Count))" `
        -ForegroundColor $(if ($finalStatus -eq "PASS") { "Green" } else { "Red" })

    return $result

} catch {
    $errorMsg = $_.Exception.Message
    Write-TestLog "[auto-continue] FATAL: $errorMsg" -Level ERROR
    Write-TestLog "Stack: $($_.ScriptStackTrace)" -Level ERROR

    $result = Complete-TestResult -TestResult $result -FinalStatus "FAIL" -ErrorMessage $errorMsg
    return $result
}
