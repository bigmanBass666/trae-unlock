<#
.SYNOPSIS
    Trae Agent-Browser 测试框架 - 工具函数库
.DESCRIPTION
    提供日志记录、截图保存、时间戳生成等通用工具函数，
    供测试脚本和连接模块调用。
.NOTES
    文件位置: tests/agent-browser/lib/utils.ps1
    依赖: PowerShell 7+, agent-browser CLI
#>

$script:LogFilePath = $null
$script:VerboseMode = $false

#region ============================================================
#  配置函数
#region ============================================================

function Set-TestLogPath {
    <#
    .SYNOPSIS
        设置日志文件路径
    .PARAMETER Path
        日志文件完整路径
    #>
    param([string]$Path)
    $script:LogFilePath = $Path
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Set-VerboseLogging {
    <#
    .SYNOPSIS
        启用或禁用详细日志模式
    .PARAMETER Enabled
        是否启用详细模式
    #>
    param([bool]$Enabled = $true)
    $script:VerboseMode = $Enabled
}

#endregion

#region ============================================================
#  日志函数
#region ============================================================

function Write-TestLog {
    <#
    .SYNOPSIS
        写入带时间戳的测试日志
    .DESCRIPTION
        格式: [YYYY-MM-DD HH:MM:SS] [LEVEL] Message
        同时输出到控制台和日志文件
    .PARAMETER Message
        日志消息内容
    .PARAMETER Level
        日志级别: INFO, WARN, ERROR, DEBUG (默认 INFO)
    .PARAMETER ForegroundColor
        控制台前景色（可选）
    .EXAMPLE
        Write-TestLog "连接成功" -Level INFO -ForegroundColor Green
    #>
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")][string]$Level = "INFO",
        [string]$ForegroundColor = $null
    )

    $timestamp = Get-Timestamp
    $logLine = "[$timestamp] [$Level] $Message"

    # 控制台输出
    $color = switch ($Level) {
        "INFO"  { "White" }
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "DarkGray" }
    }
    if ($ForegroundColor) { $color = $ForegroundColor }

    if ($Level -eq "DEBUG" -and -not $script:VerboseMode) {
        # DEBUG 模式下非详细模式不输出到控制台
    } else {
        Write-Host $logLine -ForegroundColor $color
    }

    # 文件输出
    if ($script:LogFilePath) {
        Add-Content -Path $script:LogFilePath -Value $logLine -Encoding UTF8
    }
}

#endregion

#region ============================================================
#  时间戳函数
#region ============================================================

function Get-Timestamp {
    <#
    .SYNOPSIS
        获取格式化的当前时间戳
    .OUTPUTS
        string - 格式: YYYY-MM-DD HH:MM:SS
    #>
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

function Get-FilenameTimestamp {
    <#
    .SYNOPSIS
        获取用于文件名的时间戳
    .OUTPUTS
        string - 格式: YYYYMMDD-HHMMSS
    #>
    return Get-Date -Format "yyyyMMdd-HHmmss"
}

function Get-DateDirectory {
    <#
    .SYNOPSIS
        获取日期目录名
    .OUTPUTS
        string - 格式: YYYY-MM-DD
    #>
    return Get-Date -Format "yyyy-MM-dd"
}

#endregion

#region ============================================================
#  截图函数
#region ============================================================

function Save-Screenshot {
    <#
    .SYNOPSIS
        通过 agent-browser 截图并保存到指定目录
    .DESCRIPTION
        自动按 日期/时间戳_场景_步骤.png 格式命名
    .PARAMETER Scenario
        场景名称（如 auto-confirm, connection-test）
    .PARAMETER Step
        步骤描述（如 initial-state, after-click）
    .PARAMETER ScreenshotsDir
        截图根目录（默认 tests/screenshots/）
    .OUTPUTS
        string - 保存的截图完整路径
    .EXAMPLE
        Save-Screenshot -Scenario "auto-confirm" -Step "initial-state"
    #>
    param(
        [Parameter(Mandatory)][string]$Scenario,
        [Parameter(Mandatory)][string]$Step,
        [string]$ScreenshotsDir = ""
    )

    if (-not $ScreenshotsDir) {
        $ScreenshotsDir = Join-Path (Split-Path (Split-Path $PSScriptRoot)) "screenshots"
    }

    $dateDir = Get-DateDirectory
    $targetDir = Join-Path $ScreenshotsDir "$dateDir\$Scenario"
    Test-PathExists -Path $targetDir -CreateIfMissing

    $ts = Get-FilenameTimestamp
    $safeStep = $Step -replace '[\\/:*?"<>|]', '_'
    $filename = "${ts}_${Scenario}_${safeStep}.png"
    $fullPath = Join-Path $targetDir $filename

    try {
        $result = Invoke-AgentBrowser -Command "screenshot `"$fullPath`""
        if ($result.ExitCode -eq 0) {
            Write-TestLog "Screenshot saved: $fullPath" -Level DEBUG
            return $fullPath
        } else {
            Write-TestLog "Screenshot failed: $($result.Output)" -Level WARN
            return $null
        }
    } catch {
        Write-TestLog "Screenshot exception: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

#endregion

#region ============================================================
#  路径工具
#region ============================================================

function Test-PathExists {
    <#
    .SYNOPSIS
        测试路径是否存在，不存在则创建
    .PARAMETER Path
        要检查的路径
    .PARAMETER CreateIfMissing
        是否在缺失时自动创建
    .OUTPUTS
        bool - 路径是否存在
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$CreateIfMissing
    )

    if (Test-Path $Path) {
        return $true
    }

    if ($CreateIfMissing) {
        try {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            Write-TestLog "Created directory: $Path" -Level DEBUG
            return $true
        } catch {
            Write-TestLog "Failed to create directory $Path : $($_.Exception.Message)" -Level ERROR
            return $false
        }
    }

    return $false
}

#endregion

#region ============================================================
#  agent-browser 封装
#region ============================================================

function Invoke-AgentBrowser {
    <#
    .SYNOPSIS
        封装 agent-browser 命令调用，统一错误处理
    .PARAMETER Command
        要执行的 agent-browser 命令和参数
    .PARAMETER Timeout
        执行超时时间（秒，默认 30）
    .OUTPUTS
        PSCustomObject - @{ ExitCode; Output; Error }
    .EXAMPLE
        $r = Invoke-AgentBrowser -Command "get title"
        if ($r.ExitCode -eq 0) { "Title: $($r.Output)" }
    #>
    param(
        [Parameter(Mandatory)][string]$Command,
        [int]$Timeout = 30
    )

    $fullCommand = "agent-browser $Command"
    Write-TestLog "EXEC: $fullCommand" -Level DEBUG

    try {
        $output = & agent-browser ($Command -split ' ') 2>&1 | Out-String
        $exitCode = $LASTEXITCODE

        $result = [PSCustomObject]@{
            ExitCode = $exitCode
            Output   = $output.Trim()
            Error    = ""
        }

        if ($exitCode -ne 0) {
            Write-TestLog "agent-browser failed (exit=$exitCode): $($result.Output)" -Level WARN
        }

        return $result
    } catch {
        $errorMsg = $_.Exception.Message
        Write-TestLog "agent-browser exception: $errorMsg" -Level ERROR
        return [PSCustomObject]@{
            ExitCode = -1
            Output   = ""
            Error    = $errorMsg
        }
    }
}

function Test-AgentBrowserAvailable {
    <#
    .SYNOPSIS
        检查 agent-browser CLI 是否可用
    .OUTPUTS
        bool - 是否可用
    #>
    try {
        $null = Get-Command agent-browser -ErrorAction Stop
        $version = Invoke-AgentBrowser -Command "--version"
        Write-TestLog "agent-browser available: $($version.Output)" -Level INFO
        return $true
    } catch {
        Write-TestLog "agent-browser not found in PATH" -Level ERROR
        return $false
    }
}

#endregion

#region ============================================================
#  测试结果对象
#region ============================================================

function New-TestResult {
    <#
    .SYNOPSIS
        创建新的测试结果对象
    .PARAMETER TestName
        测试名称
    .PARAMETER Status
        初始状态: PASS, FAIL, SKIP, PENDING (默认 PENDING)
    .OUTPUTS
        PSCustomObject - 测试结果对象
    #>
    param(
        [Parameter(Mandatory)][string]$TestName,
        [ValidateSet("PASS", "FAIL", "SKIP", "PENDING")][string]$Status = "PENDING"
    )

    return [PSCustomObject]@{
        TestName     = $TestName
        Status       = $Status
        StartTime    = Get-Date
        EndTime      = $null
        DurationMs   = 0
        Assertions   = [System.Collections.Generic.List[PSObject]]::new()
        Screenshots  = [System.Collections.ArrayList]::new()
        Logs         = [System.Collections.ArrayList]::new()
        ErrorMessage = ""
        Details      = ""
    }
}

function Complete-TestResult {
    <#
    .SYNOPSIS
        标记测试完成，计算耗时
    .PARAMETER TestResult
        New-TestResult 创建的对象
    .PARAMETER FinalStatus
        最终状态
    .PARAMETER ErrorMessage
        错误消息（如有）
    #>
    param(
        [Parameter(Mandatory)][PSObject]$TestResult,
        [ValidateSet("PASS", "FAIL", "SKIP")][string]$FinalStatus = "PASS",
        [string]$ErrorMessage = ""
    )

    $TestResult.EndTime = Get-Date
    $TestResult.DurationMs = [math]::Round(($TestResult.EndTime - $TestResult.StartTime).TotalMilliseconds, 0)
    $TestResult.Status = $FinalStatus
    $TestResult.ErrorMessage = $ErrorMessage
    return $TestResult
}

#endregion

#region ============================================================
#  截图清理
#region ============================================================

function Remove-StaleScreenshots {
    <#
    .SYNOPSIS
        清理超过保留天数的截图
    .PARAMETER ScreenshotsDir
        截图根目录
    .PARAMETER RetainDays
        保留天数（默认 7）
    #>
    param(
        [string]$ScreenshotsDir = "",
        [int]$RetainDays = 7
    )

    if (-not $ScreenshotsDir) {
        $ScreenshotsDir = Join-Path (Split-Path (Split-Path $PSScriptRoot)) "screenshots"
    }

    if (-not (Test-Path $ScreenshotsDir)) { return }

    $cutoff = (Get-Date).AddDays(-$RetainDays)
    $removed = 0

    Get-ChildItem -Path $ScreenshotsDir -Recurse -Filter "*.png" -ErrorAction SilentlyContinue | Where-Object {
        $_.LastWriteTime -lt $cutoff
    } | ForEach-Object {
        Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
        $removed++
    }

    if ($removed -gt 0) {
        Write-TestLog "Cleaned up $removed stale screenshot(s) (older than ${RetainDays} days)" -Level INFO
    }
}

#endregion

#region ============================================================
#  导出说明
#region ============================================================
# 此脚本通过 dot-source 加载，所有函数自动可用
# 用法: . "$PSScriptRoot\lib\utils.ps1"
#endregion
