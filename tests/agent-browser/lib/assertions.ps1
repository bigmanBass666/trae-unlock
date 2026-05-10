<#
.SYNOPSIS
    Trae Agent-Browser 测试框架 - 断言库
.DESCRIPTION
    提供各种断言函数，用于验证测试结果。
    每个断言返回一个结果对象，包含 Pass/Fail 状态和详细信息。
.NOTES
    文件位置: tests/agent-browser/lib/assertions.ps1
    依赖: lib/utils.ps1 (必须先加载)
#>

# 确保工具函数已加载（幂等检查）
if (-not (Get-Command Write-TestLog -ErrorAction SilentlyContinue)) {
    $utilsPath = Join-Path $PSScriptRoot "utils.ps1"
    if (Test-Path $utilsPath) {
        . $utilsPath
    }
}

#region ============================================================
#  内部：创建断言结果
#region ============================================================

function New-AssertionResult {
    <#
    .SYNOPSIS
        创建标准化的断言结果对象
    #>
    param(
        [bool]$Passed,
        [string]$AssertionType,
        [string]$Expected,
        [string]$Actual,
        [string]$Message = "",
        [object]$Evidence = $null
    )

    return [PSCustomObject]@{
        Passed        = $Passed
        AssertionType = $AssertionType
        Expected      = $Expected
        Actual        = $Actual
        Message       = $Message
        Evidence      = $Evidence
        Timestamp     = Get-Timestamp
    }
}

#endregion

#region ============================================================
#  元素存在性断言
#region ============================================================

function Assert-ElementExists {
    <#
    .SYNOPSIS
        断言元素存在于 snapshot 中
    .PARAMETER SnapshotText
        agent-browser snapshot 命令的输出文本
    .PARAMETER Selector
        要查找的选择器或文本模式
    .PARAMETER Description
        断言描述（用于日志）
    .OUTPUTS
        PSCustomObject - 断言结果
    #>
    param(
        [Parameter(Mandatory)][string]$SnapshotText,
        [Parameter(Mandatory)][string]$Selector,
        [string]$Description = "Element exists"
    )

    $exists = $SnapshotText -match [regex]::Escape($Selector)
    $result = New-AssertionResult `
        -Passed $exists `
        -AssertionType "ElementExists" `
        -Expected "contains '$Selector'" `
        -Actual $(if ($exists) { "found" } else { "not found" }) `
        -Message $Description `
        -Evidence $SnapshotText

    $level = if ($result.Passed) { "INFO" } else { "ERROR" }
    $icon  = if ($result.Passed) { "[PASS]" } else { "[FAIL]" }
    Write-TestLog "$icon Assert-ElementExists: $Description ($Selector)" -Level $level

    return $result
}

function Assert-ElementNotExists {
    <#
    .SYNOPSIS
        断言元素不存在于 snapshot 中
    .PARAMETER SnapshotText
        agent-browser snapshot 命令的输出文本
    .PARAMETER Selector
        不应出现的选择器或文本模式
    .PARAMETER Description
        断言描述
    .OUTPUTS
        PSCustomObject - 断言结果
    #>
    param(
        [Parameter(Mandatory)][string]$SnapshotText,
        [Parameter(Mandatory)][string]$Selector,
        [string]$Description = "Element not exists"
    )

    $notExists = -not ($SnapshotText -match [regex]::Escape($Selector))
    $result = New-AssertionResult `
        -Passed $notExists `
        -AssertionType "ElementNotExists" `
        -Expected "not contains '$Selector'" `
        -Actual $(if ($notExists) { "not found" } else { "found (unexpected)" }) `
        -Message $description `
        -Evidence $SnapshotText

    $level = if ($result.Passed) { "INFO" } else { "ERROR" }
    $icon  = if ($result.Passed) { "[PASS]" } else { "[FAIL]" }
    Write-TestLog "$icon Assert-ElementNotExists: $Description ($Selector)" -Level $level

    return $result
}

#endregion

#region ============================================================
#  元素可见性断言
#region ============================================================

function Assert-ElementVisible {
    <#
    .SYNOPSIS
        通过 agent-browser is visible 断言元素可见
    .PARAMETER Selector
        CSS 选择器或 ref
    .PARAMETER Description
        断言描述
    .OUTPUTS
        PSCustomObject - 断言结果
    #>
    param(
        [Parameter(Mandatory)][string]$Selector,
        [string]$Description = "Element visible"
    )

    $r = Invoke-AgentBrowser -Command "is visible `"$Selector`""
    $isVisible = ($r.ExitCode -eq 0) -and ($r.Output -match 'true|visible|1')

    $result = New-AssertionResult `
        -Passed $isVisible `
        -AssertionType "ElementVisible" `
        -Expected "visible" `
        -Actual $r.Output `
        -Message $description

    $level = if ($result.Passed) { "INFO" } else { "ERROR" }
    $icon  = if ($result.Passed) { "[PASS]" } else { "[FAIL]" }
    Write-TestLog "$icon Assert-ElementVisible: $Description ($Selector)" -Level $level

    return $result
}

#endregion

#region ============================================================
#  字符串断言
#region ============================================================

function Assert-StringContains {
    <#
    .SYNOPSIS
        断言字符串包含子串
    .PARAMETER Text
        被搜索的文本
    .PARAMETER SubString
        应包含的子串
    .PARAMETER CaseSensitive
        是否区分大小写（默认 false）
    .PARAMETER Description
        断言描述
    .OUTPUTS
        PSCustomObject - 断言结果
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][string]$SubString,
        [switch]$CaseSensitive,
        [string]$Description = "String contains"
    )

    if ($CaseSensitive) {
        $contains = $Text.Contains($SubString)
    } else {
        $contains = $Text.ToLower().Contains($SubString.ToLower())
    }

    $truncatedActual = if ($Text.Length -gt 200) { $Text.Substring(0, 200) + "..." } else { $Text }

    $result = New-AssertionResult `
        -Passed $contains `
        -AssertionType "StringContains" `
        -Expected "contains '$SubString'" `
        -Actual $truncatedActual `
        -Message $description `
        -Evidence $Text

    $level = if ($result.Passed) { "INFO" } else { "ERROR" }
    $icon  = if ($result.Passed) { "[PASS]" } else { "[FAIL]" }
    Write-TestLog "$icon Assert-StringContains: $Description -> '$SubString'" -Level $level

    return $result
}

function Assert-StringMatch {
    <#
    .SYNOPSIS
        断言字符串匹配正则表达式
    .PARAMETER Text
        被匹配的文本
    .PARAMETER Pattern
        正则表达式模式
    .PARAMETER Description
        断言描述
    .OUTPUTS
        PSCustomObject - 断言结果
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][string]$Pattern,
        [string]$Description = "String matches regex"
    )

    $matches = $Text -match $Pattern

    $result = New-AssertionResult `
        -Passed $matches `
        -AssertionType "StringMatch" `
        -Expected "matches /$Pattern/" `
        -Actual $(if ($matches) { "matched" } else { "no match" }) `
        -Message $description `
        -Evidence $Text

    $level = if ($result.Passed) { "INFO" } else { "ERROR" }
    $icon  = if ($result.Passed) { "[PASS]" } else { "[FAIL]" }
    Write-TestLog "$icon Assert-StringMatch: $Description -> /$Pattern/" -Level $level

    return $result
}

#endregion

#region ============================================================
#  通用条件断言
#region ============================================================

function Assert-Condition {
    <#
    .SYNOPSIS
        通用条件断言
    .PARAMETER Condition
        布尔条件
    .PARAMETER Description
        断言描述
    .PARAMETER FailureMessage
        失败时的详细消息
    .OUTPUTS
        PSCustomObject - 断言结果
    #>
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Description,
        [string]$FailureMessage = ""
    )

    $result = New-AssertionResult `
        -Passed $Condition `
        -AssertionType "Condition" `
        -Expected "\`$true" `
        -Actual "`$Condition" `
        -Message $Description `
        -Evidence $FailureMessage

    $level = if ($result.Passed) { "INFO" } else { "ERROR" }
    $icon  = if ($result.Passed) { "[PASS]" } else { "[FAIL]" }
    Write-TestLog "$icon Assert-Condition: $Description" -Level $level

    if (-not $Condition -and $FailureMessage) {
        Write-TestLog "  Detail: $FailureMessage" -Level ERROR
    }

    return $result
}

#endregion

#region ============================================================
#  超时/等待断言
#region ============================================================

function Assert-Timeout {
    <#
    .SYNOPSIS
        断言操作在超时时间内完成
    .DESCRIPTION
        执行脚本块并验证其在指定时间内完成。
        如果操作在超时前完成且条件满足 -> PASS
        如果超时 -> FAIL
    .PARAMETER ScriptBlock
        要执行的操作（应返回 bool 或值）
    .PARAMETER TimeoutSeconds
        超时时间（秒）
    .PARAMETER PollIntervalMs
        轮询间隔（毫秒，默认 500）
    .PARAMETER Description
        断言描述
    .OUTPUTS
        PSCustomObject - 断言结果
    .EXAMPLE
        Assert-Timeout -ScriptBlock {
            $r = Invoke-AgentBrowser -Command "is visible '.dialog'"
            $r.Output -match 'true'
        } -TimeoutSeconds 10 -Description "Dialog disappears"
    #>
    param(
        [Parameter(Mandatory)][scriptblock]$ScriptBlock,
        [int]$TimeoutSeconds = 10,
        [int]$PollIntervalMs = 500,
        [string]$Description = "Operation within timeout"
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $maxIterations = [math]::Ceiling($TimeoutSeconds * 1000 / $PollIntervalMs)
    $lastResult = $null
    $success = $false

    for ($i = 0; $i -lt $maxIterations; $i++) {
        try {
            $lastResult = & $ScriptBlock
            if ($lastResult -is [bool] -and $lastResult) {
                $success = $true
                break
            }
            # 也支持非布尔真值
            if ($null -ne $lastResult -and $lastResult -isnot [bool]) {
                $success = $true
                break
            }
        } catch {
            Write-TestLog "Poll iteration $($i+1) exception: $($_.Exception.Message)" -Level DEBUG
        }
        Start-Sleep -Milliseconds $PollIntervalMs
    }

    $stopwatch.Stop()
    $elapsed = [math]::Round($stopwatch.Elapsed.TotalSeconds, 2)

    $result = New-AssertionResult `
        -Passed $success `
        -AssertionType "Timeout" `
        -Expected "complete within ${TimeoutSeconds}s" `
        -Actual "elapsed ${elapsed}s, success=$success" `
        -Message $Description `
        -Evidence @{ ElapsedSeconds = $elapsed; Iterations = $i + 1 }

    $level = if ($result.Passed) { "INFO" } else { "ERROR" }
    $icon  = if ($result.Passed) { "[PASS]" } else { "[FAIL]" }
    Write-TestLog "$icon Assert-Timeout: $Description (${elapsed}s / ${TimeoutSeconds}s limit)" -Level $level

    return $result
}

#endregion

#region ============================================================
#  CDP 连接状态断言
#region ============================================================

function Assert-CdpConnected {
    <#
    .SYNOPSIS
        断言 CDP 连接有效
    .DESCRIPTION
        通过获取页面标题来验证连接是否正常工作
    .OUTPUTS
        PSCustomObject - 断言结果
    #>
    param([string]$Description = "CDP connection active")

    $r = Invoke-AgentBrowser -Command "get title"
    $connected = $r.ExitCode -eq 0 -and $r.Output.Length -gt 0

    $result = New-AssertionResult `
        -Passed $connected `
        -AssertionType "CdpConnected" `
        -Expected "valid CDP response" `
        -Actual "exit=$($r.ExitCode), output='$($r.Output)'" `
        -Message $Description

    $level = if ($result.Passed) { "INFO" } else { "ERROR" }
    $icon  = if ($result.Passed) { "[PASS]" } else { "[FAIL]" }
    Write-TestLog "$icon Assert-CdpConnected: $Description (title='$($r.Output)')" -Level $level

    return $result
}

#endregion

#region ============================================================
#  控制台日志断言
#region ============================================================

function Assert-ConsoleLogContains {
    <#
    .SYNOPSIS
        断言浏览器控制台日志包含指定内容
    .PARAMETER Pattern
        要搜索的正则表达式或字符串
    .PARAMETER Description
        断言描述
    .PARAMETER CaseSensitive
        是否区分大小写
    .OUTPUTS
        PSCustomObject - 断言结果
    #>
    param(
        [Parameter(Mandatory)][string]$Pattern,
        [string]$Description = "Console log contains pattern",
        [switch]$CaseSensitive
    )

    $r = Invoke-AgentBrowser -Command "console"

    if ($CaseSensitive) {
        $found = $r.Output -match $Pattern
    } else {
        $found = $r.Output -imatch $Pattern
    }

    $result = New-AssertionResult `
        -Passed $found `
        -AssertionType "ConsoleLogContains" `
        -Expected "console contains /$Pattern/" `
        -Actual $(if ($found) { "found" } else { "not found in console output" }) `
        -Message $Description `
        -Evidence $r.Output

    $level = if ($result.Passed) { "INFO" } else { "ERROR" }
    $icon  = if ($result.Passed) { "[PASS]" } else { "[FAIL]" }
    Write-TestLog "$icon Assert-ConsoleLogContains: $Description -> '$Pattern'" -Level $level

    return $result
}

#endregion

#region ============================================================
#  批量断言汇总
#region ============================================================

function Get-AssertionSummary {
    <#
    .SYNOPSIS
        汇总多个断言的结果
    .PARAMETER Assertions
        断言结果数组
    .OUTPUTS
        PSCustomObject - @{ Total; Passed; Failed; AllPassed }
    #>
    param([PSObject[]]$Assertions)

    $total   = $Assertions.Count
    $passed  = @($Assertions | Where-Object { $_.Passed }).Count
    $failed  = $total - $passed

    return [PSCustomObject]@{
        Total     = $total
        Passed    = $passed
        Failed    = $failed
        AllPassed = ($failed -eq 0)
    }
}

function Format-AssertionReport {
    <#
    .SYNOPSIS
        将断言结果格式化为 Markdown 表格行
    .PARAMETER Assertions
        断言结果数组
    .OUTPUTS
        string[] - Markdown 行数组
    #>
    param([PSObject[]]$Assertions)

    $lines = @()
    $lines += "| Status | Type | Message | Expected | Actual |"
    $lines += "|--------|------|---------|----------|--------|"

    foreach ($a in $Assertions) {
        $statusIcon = if ($a.Passed) { ":white_check_mark:" } else { ":x:" }
        $expected   = $a.Expected -replace '\|', '\|'
        $actual     = $a.Actual -replace '\|', '\|'
        $message    = $a.Message -replace '\|', '\|'
        $lines += "| $statusIcon | $($a.AssertionType) | $message | $expected | $actual |"
    }

    return $lines
}

#endregion

#region ============================================================
#  导出说明
#region ============================================================
# 此脚本通过 dot-source 加载，所有函数自动可用
# 用法: . "$PSScriptRoot\lib\assertions.ps1"
# 前置依赖: 先加载 utils.ps1
#endregion
