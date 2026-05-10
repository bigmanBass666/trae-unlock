<#
.SYNOPSIS
    测试命令自动确认补丁是否生效
.DESCRIPTION
    通过 agent-browser 在 Trae 中触发命令确认弹窗，验证补丁是否自动确认。
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
      Phase 1: 准备 - 连接、初始状态截图
      Phase 2: 触发 - 输入触发命令确认的消息并发送
      Phase 3: 监控 - 轮询 UI snapshot 检测弹窗
      Phase 4: 断言 - 弹窗出现且持续 >3s = FAIL, 不出现/立即消失 = PASS
      Phase 5: 清理 - 截图、日志收集、返回结果
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

# TODO: 待 CDP 连接后，通过 inspect 获取实际选择器
$script:Config = @{
    # 触发命令确认的测试消息
    TriggerMessage     = "请帮我运行 npm test -- --watch=false"

    # 弹窗检测关键词（用于 snapshot 文本匹配）
    DialogKeywords     = @("确认", "Confirm", "Execute", "执行", "Command", "命令")

    # 确认按钮选择器（待填充）
    ConfirmButtonSel   = ""  # TODO: 填充实际选择器

    # 取消按钮选择器（待填充）
    CancelButtonSel    = ""  # TODO: 填充实际选择器

    # 输入框/聊天区域选择器（待填充）
    ChatInputSelector  = ""  # TODO: 填充实际选择器

    # 发送按钮选择器（待填充）
    SendButtonSelector = ""  # TODO: 填充实际选择器

    # 监控参数
    MonitorDurationSec = 8       # 总监控时长
    PollIntervalMs     = 500     # 轮询间隔
    DialogThresholdSec = 3       # 弹窗持续超过此时间视为未处理
}

# ============================================================
#  主测试逻辑
# ============================================================

$result = New-TestResult -TestName "auto-confirm"

Write-Host ""
Write-Host "[auto-confirm] Starting test..." -ForegroundColor Magenta
Write-TestLog "[auto-confirm] === Test Start ===" -Level INFO

try {

    # ----------------------------------------------------------
    # Phase 1: 准备
    # ----------------------------------------------------------
    Write-TestLog "Phase 1: Preparation" -Level INFO

    # 1.1 验证连接仍然有效
    $connAssert = Assert-CdpConnected -Description "Connection valid before test"
    $result.Assertions.Add($connAssert)
    if (-not $connAssert.Passed) {
        throw "CDP connection lost before test execution"
    }

    # 1.2 截取初始状态
    $initialScreenshot = Save-Screenshot -Scenario "auto-confirm" -Step "initial-state" `
        -ScreenshotsDir $ScreenshotsDir
    if ($initialScreenshot) { [void]$result.Screenshots.Add($initialScreenshot) }
    Write-TestLog "Initial screenshot saved" -Level INFO

    # 1.3 获取初始 snapshot 作为基线
    $baselineSnapshot = Invoke-AgentBrowser -Command "snapshot"
    if ($baselineSnapshot.ExitCode -ne 0) {
        throw "Failed to get baseline snapshot: $($baselineSnapshot.Output)"
    }
    Write-TestLog "Baseline snapshot captured ($(($baselineSnapshot.Output.Length)) chars)" -Level DEBUG


    # ----------------------------------------------------------
    # Phase 2: 触发命令确认
    # ----------------------------------------------------------
    Write-TestLog "Phase 2: Triggering command confirmation dialog..." -Level INFO

    # TODO: 实际 UI 交互代码待填充
    # 以下为骨架逻辑，需要根据 Trae 实际 DOM 结构调整选择器

    # Step 2.1: 定位并点击输入框
    # $r = Invoke-AgentBrowser -Command "click `"$($script:Config.ChatInputSelector)`""
    # Write-TestLog "Clicked chat input" -Level DEBUG

    # Step 2.2: 输入触发消息
    # $r = Invoke-AgentBrowser -Command "type `"$($script:Config.ChatInputSelector)`" `"$($script:Config.TriggerMessage)`""
    # Write-TestLog "Typed trigger message" -Level DEBUG

    # Step 2.3: 发送消息
    # $r = Invoke-AgentBrowser -Command "click `"$($script:Config.SendButtonSelector)`""
    # 或者使用键盘发送
    # $r = Invoke-AgentBrowser -Command "press Enter"
    # Write-TestLog "Sent trigger message" -Level INFO

    # 当前骨架：记录触发动作（实际交互待完善）
    Write-TestLog "[SKEL] Trigger action: would send '$($script:Config.TriggerMessage)'" -Level WARN
    Write-TestLog "[SKEL] TODO: Fill in ChatInputSelector and SendButtonSelector after CDP inspection" -Level WARN

    # 占位：模拟触发后的等待
    Start-Sleep -Milliseconds 1000


    # ----------------------------------------------------------
    # Phase 3: 监控弹窗状态
    # ----------------------------------------------------------
    Write-TestLog "Phase 3: Monitoring for dialog appearance ($($script:Config.MonitorDurationSec)s)..." -Level INFO

    $dialogDetected   = $false
    $dialogFirstSeen  = $null
    $dialogLastSeen   = $null
    $dialogSnapshot   = $null
    $pollCount        = [math]::Ceiling($script:Config.MonitorDurationSec * 1000 / $script:Config.PollIntervalMs)
    $monitorStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    for ($i = 0; $i -lt $pollCount; $i++) {
        # 获取当前 snapshot
        $snapR = Invoke-AgentBrowser -Command "snapshot"
        $currentSnapText = $snapR.Output

        # 检查是否有弹窗关键词出现
        foreach ($keyword in $script:Config.DialogKeywords) {
            if ($currentSnapText -imatch [regex]::Escape($keyword)) {
                if (-not $dialogDetected) {
                    $dialogDetected  = $true
                    $dialogFirstSeen = $monitorStopwatch.Elapsed
                    $dialogSnapshot = $currentSnapText
                    Write-TestLog "Dialog detected at +$([math]::Round($dialogFirstSeen.TotalSeconds, 2))s keyword='$keyword'" -Level WARN
                }
                $dialogLastSeen = $monitorStopwatch.Elapsed
                break
            }
        }

        # 如果弹窗已消失（不再包含任何关键词），记录
        if ($dialogDetected) {
            $stillVisible = $false
            foreach ($keyword in $script:Config.DialogKeywords) {
                if ($currentSnapText -imatch [regex]::Escape($keyword)) {
                    $stillVisible = $true; break
                }
            }
            if (-not $stillVisible) {
                Write-TestLog "Dialog disappeared at +$([math]::Round($monitorStopwatch.Elapsed.TotalSeconds, 2))s" -Level INFO
                # 继续监控以防再次出现
            }
        }

        Start-Sleep -Milliseconds $script:Config.PollIntervalMs
    }

    $monitorStopwatch.Stop()


    # ----------------------------------------------------------
    # Phase 4: 断言
    # ----------------------------------------------------------
    Write-TestLog "Phase 4: Assertions" -Level INFO

    # 截取最终状态
    $finalScreenshot = Save-Screenshot -Scenario "auto-confirm" -Step "final-state" `
        -ScreenshotsDir $ScreenshotsDir
    if ($finalScreenshot) { [void]$result.Screenshots.Add($finalScreenshot) }

    # 核心断言: 补丁生效时，弹窗不应持续超过阈值
    $testPassed = $false
    $assertDetail = ""

    if (-not $dialogDetected) {
        # 场景 A: 从未检测到弹窗 -> PASS（补丁完全拦截了弹窗）
        $testPassed = $true
        $assertDetail = "No dialog detected during monitoring period. Patch appears to intercept command confirmation."
        Write-TestLog "ASSERT PASS: No dialog detected - patch intercepts confirmation" -Level INFO
    } elseif ($dialogFirstSeen -and $dialogLastSeen) {
        $duration = ($dialogLastSeen - $dialogFirstSeen).TotalSeconds
        if ($duration -lt $script:Config.DialogThresholdSec) {
            # 场景 B: 弹窗出现但很快消失 -> PASS（补丁自动确认）
            $testPassed = $true
            $assertDetail = "Dialog appeared but auto-dismissed in ${duration}s (< threshold ${$script:Config.DialogThresholdSec}s). Patch auto-confirms."
            Write-TestLog "ASSERT PASS: Dialog auto-dismissed in ${duration}s" -Level INFO
        } else {
            # 场景 C: 弹窗持续存在 -> FAIL（补丁未生效）
            $testPassed = $false
            $assertDetail = "Dialog persisted for ${duration}s (> threshold ${$script:Config.DialogThresholdSec}s). Patch did NOT auto-confirm."
            Write-TestLog "ASSERT FAIL: Dialog persisted for ${duration}s - patch not effective" -Level ERROR
        }
    } else {
        # 边缘情况
        $testPassed = $false
        $assertDetail = "Unexpected dialog detection state."
        Write-TestLog "ASSERT FAIL: Unexpected state" -Level ERROR
    }

    # 记录断言结果
    $mainAssertion = Assert-Condition `
        -Condition $testPassed `
        -Description "Auto-confirm patch effectiveness" `
        -FailureMessage $assertDetail
    $result.Assertions.Add($mainAssertion)

    # 如果检测到弹窗，附加证据快照
    if ($dialogSnapshot) {
        $dialogEvidenceAssert = Assert-StringContains `
            -Text $dialogSnapshot `
            -SubString $($script:Config.DialogKeywords[0]) `
            -Description "Dialog evidence captured"
        $result.Assertions.Add($dialogEvidenceAssert)
    }


    # ----------------------------------------------------------
    # Phase 5: 清理与数据收集
    # ----------------------------------------------------------
    Write-TestLog "Phase 5: Cleanup & data collection" -Level INFO

    # 5.1 收集控制台日志（检查 PlanItemStreamParser 相关输出）
    $consoleResult = Invoke-AgentBrowser -Command "console"
    if ($consoleResult.ExitCode -eq 0) {
        # 过滤相关日志
        $relevantLogs = @($consoleResult.Output -split "`n" | Where-Object {
            $_ -match 'PlanItemStreamParser|confirm|command|execute|patch'
        })
        if ($relevantLogs.Count -gt 0) {
            Write-TestLog "Relevant console logs found ($($relevantLogs.Count) lines):" -Level INFO
            foreach ($logLine in $relevantLogs | Select-Object -First 10) {
                Write-TestLog "  CONSOLE: $logLine.Trim()" -Level DEBUG
            }
            $result.Details += "Console logs: $($relevantLogs.Count) relevant entries`n"
        } else {
            Write-TestLog "No relevant console log entries found" -Level DEBUG
        }
    }

    # 5.2 最终断言汇总
    $summary = Get-AssertionSummary -Assertions $result.Assertions
    Write-TestLog "Assertion summary: $($summary.Passed)/$(summary.Total) passed" -Level $(if ($summary.AllPassed) { "INFO" } else { "ERROR" })


    # ----------------------------------------------------------
    # 完成
    # ----------------------------------------------------------
    $finalStatus = if ($mainAssertion.Passed) { "PASS" } else { "FAIL" }
    $errorMsg = if (-not $mainAssertion.Passed) { $assertDetail } else { "" }

    $result = Complete-TestResult -TestResult $result -FinalStatus $finalStatus -ErrorMessage $errorMsg

    Write-Host "[auto-complete] Test completed: $finalStatus ($($result.DurationMs)ms)" `
        -ForegroundColor $(if ($finalStatus -eq "PASS") { "Green" } else { "Red" })

    return $result

} catch {
    $errorMsg = $_.Exception.Message
    Write-TestLog "[auto-confirm] FATAL: $errorMsg" -Level ERROR
    Write-TestLog "Stack: $($_.ScriptStackTrace)" -Level ERROR

    $result = Complete-TestResult -TestResult $result -FinalStatus "FAIL" -ErrorMessage $errorMsg
    return $result
}
