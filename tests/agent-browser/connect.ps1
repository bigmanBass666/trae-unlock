<#
.SYNOPSIS
    连接到 Trae Electron 应用的 CDP 调试端口
.DESCRIPTION
    通过 agent-browser 连接到 Trae IDE，支持自动发现端口或手动指定。
    连接成功后，将连接信息保存到临时文件供其他测试脚本使用。
.PARAMETER Port
    CDP 端口号（默认 9222）
.PARAMETER AutoDiscover
    自动发现 Trae 的调试端口（扫描常见端口范围）
.PARAMETER Timeout
    连接超时时间（秒，默认 10）
.EXAMPLE
    .\connect.ps1 -Port 9222
    使用指定端口连接
.EXAMPLE
    .\connect.ps1 -AutoDiscover
    自动发现 Trae 的调试端口并连接
.OUTPUTS
    PSCustomObject - 连接状态对象 @{ Connected; Port; Title; Timestamp }
.NOTES
    依赖: agent-browser CLI, PowerShell 7+
#>

[CmdletBinding()]
param(
    [int]$Port = 9222,
    [switch]$AutoDiscover,
    [int]$Timeout = 10
)

$ErrorActionPreference = "Stop"

# ============================================================
#  加载依赖库
# ============================================================
$libDir = Join-Path $PSScriptRoot "lib"
. (Join-Path $libDir "utils.ps1")

# ============================================================
#  全局配置
# ============================================================
$script:ConnectionStateFile = Join-Path $env:TEMP "trae-test-connection.json"
$script:DefaultPorts = @(9222, 9223, 9224, 9333, 9444)

# ============================================================
#  端口发现函数
# ============================================================

function Find-TraeCdpPort {
    <#
    .SYNOPSIS
        自动发现 Trae Electron 的 CDP 调试端口
    .DESCRIPTION
        策略:
          1. 检查进程命令行中的 --remote-debugging-port 参数
          2. 扫描常用端口范围的 /json/version 端点
    #>
    Write-TestLog "Auto-discovering Trae CDP port..." -Level INFO

    # 策略 1: 从进程命令行提取
    Write-TestLog "Strategy 1: Scanning Trae process command line..." -Level DEBUG
    $traeProcesses = Get-Process -Name "Trae*" -ErrorAction SilentlyContinue
    if ($traeProcesses) {
        foreach ($proc in $traeProcesses) {
            try {
                $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.Id)").CommandLine
                if ($cmdLine -match '--remote-debugging-port=(\d+)') {
                    $foundPort = [int]$Matches[1]
                    Write-TestLog "Found port from process command line: $foundPort" -Level INFO
                    return $foundPort
                }
            } catch {
                Write-TestLog "Cannot read process $($proc.Id) command line: $($_.Exception.Message)" -Level DEBUG
            }
        }
    }

    # 策略 2: 扫描常用端口
    Write-TestLog "Strategy 2: Scanning default ports ($($script:DefaultPorts -join ', '))..." -Level DEBUG
    foreach ($candidatePort in $script:DefaultPorts) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$candidatePort/json/version" `
                -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
            Write-TestLog "Port $candidatePort responds: $($response.Content)" -Level INFO
            return $candidatePort
        } catch {
            continue
        }
    }

    # 策略 3: 扩展扫描 9200-9300 范围（较慢）
    Write-TestLog "Strategy 3: Extended scan 9200-9300..." -Level WARN
    for ($p = 9200; $p -le 9300; $p++) {
        try {
            $r = Invoke-WebRequest -Uri "http://localhost:$p/json/version" `
                -UseBasicParsing -TimeoutSec 1 -ErrorAction Stop
            Write-TestLog "Found on extended scan: port $p" -Level INFO
            return $p
        } catch { continue }
    }

    throw "Cannot discover Trae CDP port. Ensure Trae is running with --remote-debugging-port"
}

function Test-CdpEndpoint {
    <#
    .SYNOPSIS
        测试 CDP 端点是否可用
    .PARAMETER TestPort
        要测试的端口号
    .PARAMETER TestTimeout
        超时秒数
    .OUTPUTS
    bool
    #>
    param([int]$TestPort, [int]$TestTimeout = 5)
    try {
        $null = Invoke-WebRequest -Uri "http://localhost:$TestPort/json/version" `
            -UseBasicParsing -TimeoutSec $TestTimeout -ErrorAction Stop
        return $true
    } catch { return $false }
}

# ============================================================
#  连接函数
# ============================================================

function Connect-ToTrae {
    <#
    .SYNOPSIS
        执行实际的 CDP 连接
    .PARAMETER TargetPort
        目标端口
    .PARAMETER ConnectTimeout
        连接超时
    .OUTPUTS
    PSCustomObject - 连接结果
    #>
    param(
        [Parameter(Mandatory)][int]$TargetPort,
        [int]$ConnectTimeout = 10
    )

    # Step 1: 验证 agent-browser 可用
    Write-TestLog "Checking agent-browser availability..." -Level INFO
    if (-not (Test-AgentBrowserAvailable)) {
        throw "agent-browser CLI not found. Install it first: npm i -g @anthropic-ai/agent-browser"
    }

    # Step 2: 验证 CDP 端点可达
    Write-TestLog "Testing CDP endpoint at localhost:$TargetPort..." -Level INFO
    if (-not (Test-CdpEndpoint -TestPort $TargetPort -TestTimeout $ConnectTimeout)) {
        throw "CDP endpoint not reachable at localhost:$TargetPort. Is Trae running with --remote-debugging-port=$TargetPort ?"
    }

    # Step 3: 执行 agent-browser connect
    Write-TestLog "Executing: agent-browser connect $TargetPort" -Level INFO
    $connectResult = Invoke-AgentBrowser -Command "connect localhost:$TargetPort" -Timeout $ConnectTimeout

    if ($connectResult.ExitCode -ne 0) {
        throw "agent-browser connect failed (exit code $($connectResult.ExitCode)): $($connectResult.Output)"
    }
    Write-TestLog "agent-browser connected successfully" -Level INFO -ForegroundColor Green

    # Step 4: 验证连接有效（获取标题）
    Write-TestLog "Validating connection by getting page title..." -Level INFO
    $titleResult = Invoke-AgentBrowser -Command "get title" -Timeout 10

    if ($titleResult.ExitCode -ne 0) {
        throw "Connection validation failed - cannot get page title: $($titleResult.Output)"
    }

    $pageTitle = $titleResult.Output.Trim()
    Write-TestLog "Connected to: $pageTitle" -Level INFO -ForegroundColor Cyan

    # Step 5: 构建连接状态对象
    $connectionInfo = [PSCustomObject]@{
        Connected = $true
        Port      = $TargetPort
        Title     = $pageTitle
        Timestamp = Get-Timestamp
        Url       = "http://localhost:$TargetPort"
    }

    # Step 6: 保存到临时文件供其他脚本使用
    Save-ConnectionState -State $connectionInfo

    return $connectionInfo
}

function Save-ConnectionState {
    <#
    .SYNOPSIS
        将连接状态保存到临时 JSON 文件
    #>
    param([PSObject]$State)
    $json = $State | ConvertTo-Json -Depth 3
    Set-Content -Path $script:ConnectionStateFile -Value $json -Encoding UTF8
    Write-TestLog "Connection state saved to: $($script:ConnectionStateFile)" -Level DEBUG
}

function Get-SavedConnectionState {
    <#
    .SYNOPSIS
        读取已保存的连接状态
    .OUTPUTS
    PSCustomObject or null
    #>
    if (Test-Path $script:ConnectionStateFile) {
        try {
            $json = Get-Content -Path $script:ConnectionStateFile -Raw -Encoding UTF8
            return $json | ConvertFrom-Json
        } catch {
            return $null
        }
    }
    return $null
}

# ============================================================
#  主逻辑
# ============================================================

Write-Host ""
Write-Host "=== Trae Agent-Browser Connection ===" -ForegroundColor Cyan
Write-Host ""

try {
    # 确定目标端口
    $targetPort = if ($AutoDiscover) {
        Find-TraeCdpPort
    } else {
        $Port
    }

    Write-TestLog "Target CDP port: $targetPort" -Level INFO

    # 执行连接
    $result = Connect-ToTrae -TargetPort $targetPort -Timeout $Timeout

    # 输出摘要
    Write-Host ""
    Write-Host "--- Connection Summary ---" -ForegroundColor Green
    Write-Host "Status:     CONNECTED" -ForegroundColor Green
    Write-Host "Port:       $($result.Port)" -ForegroundColor White
    Write-Host "Title:      $($result.Title)" -ForegroundColor White
    Write-Host "Timestamp:  $($result.Timestamp)" -ForegroundColor DarkGray
    Write-Host "State file: $($script:ConnectionStateFile)" -ForegroundColor DarkGray
    Write-Host ""

    # 返回连接对象（供其他脚本 dot-source 时使用）
    $result

} catch {
    $errorMsg = $_.Exception.Message
    Write-TestLog "Connection failed: $errorMsg" -Level ERROR
    Write-Host ""
    Write-Host "[FAIL] Connection failed: $errorMsg" -ForegroundColor Red
    Write-Host ""
    Write-Host "[HINT] Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Restart Trae with --remote-debugging-port=9222" -ForegroundColor DarkGray
    Write-Host "  2. Or run: .\scripts\cdp\cdp-launcher.ps1" -ForegroundColor DarkGray
    Write-Host "  3. Check that port $Port is not blocked by firewall" -ForegroundColor DarkGray
    Write-Host ""

    exit 1
}
