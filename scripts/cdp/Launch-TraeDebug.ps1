<#
.SYNOPSIS
    Launch-TraeDebug — 以 CDP 调试模式启动独立 Trae 实例

.DESCRIPTION
    由于 Electron 单实例锁，已有 Trae 运行时必须用 --user-data-dir 指定不同目录。
    使用 robocopy 增量镜像关键数据（登录状态、配置），跳过缓存。
    首次运行复制约 400MB，后续增量复制仅几秒。

.PARAMETER Port
    CDP 监听端口，默认 9222

.PARAMETER SkipSync
    跳过数据同步，直接启动（数据已同步过时使用）

.PARAMETER Clean
    清除调试目录，从头开始（空实例，需手动登录）

.EXAMPLE
    .\Launch-TraeDebug.ps1
    # 增量同步数据 → 启动调试实例

.EXAMPLE
    .\Launch-TraeDebug.ps1 -Clean
    # 空实例启动（无登录状态，但最轻量）
#>

param(
    [int]$Port = 9222,
    [switch]$SkipSync,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$traeExe = "D:\apps\Trae CN\Trae CN.exe"
$srcUserData = "C:\Users\86150\AppData\Roaming\Trae CN"
$debugUserData = "C:\Users\86150\AppData\Roaming\Trae CN - Debug"

$syncDirs = @(
    "User\globalStorage",
    "User\workspaceStorage",
    "User\snippets",
    "extensions",
    "WebStorage",
    "Local Storage",
    "Session Storage",
    "IndexedDB",
    "Network"
)

$syncFiles = @(
    "User\settings.json",
    "User\keybindings.json",
    "storage.json",
    "argv.json"
)

function Write-Status($msg, $color = "White") {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $color
}

if (-not (Test-Path $traeExe)) {
    Write-Status "Trae not found: $traeExe" "Red"
    exit 1
}

try {
    $curlOut = curl.exe -s --connect-timeout 3 "http://localhost:$Port/json/version" 2>$null
    if ($LASTEXITCODE -eq 0 -and $curlOut) {
        Write-Status "CDP already active on port $Port" "Green"
        Write-Status "Connect: agent-browser connect $Port" "Cyan"
        exit 0
    }
} catch {}

if ($Clean) {
    if (Test-Path $debugUserData) {
        Write-Status "Removing debug directory..." "Yellow"
        Remove-Item $debugUserData -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $debugUserData -Force | Out-Null
}

if (-not $SkipSync -and -not $Clean) {
    Write-Status "Incremental sync (robocopy)..." "Cyan"
    $totalBytes = 0
    $totalFiles = 0

    foreach ($dir in $syncDirs) {
        $src = Join-Path $srcUserData $dir
        $dst = Join-Path $debugUserData $dir
        if (Test-Path $src) {
            $result = robocopy $src $dst /MIR /R:1 /W:0 /NFL /NDL /NJH /NJS /NC /NS
            $copied = ($result | Where-Object { $_ -match "^\s*\d+" } | Measure-Object).Count
            $totalFiles += $copied
        }
    }

    foreach ($file in $syncFiles) {
        $src = Join-Path $srcUserData $file
        $dst = Join-Path $debugUserData $file
        if (Test-Path $src) {
            $dstDir = Split-Path $dst -Parent
            if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
            Copy-Item -Path $src -Destination $dst -Force -ErrorAction SilentlyContinue
            $totalFiles++
        }
    }

    Write-Status "Synced $totalFiles items" "Green"
}

Write-Status "Launching Trae (CDP port=$Port)..." "Cyan"
$proc = Start-Process $traeExe -ArgumentList "--remote-debugging-port=$Port", "--user-data-dir=`"$debugUserData`"" -PassThru
Write-Status "PID: $($proc.Id)" "Gray"

Write-Status "Waiting for CDP..." "Yellow"
$maxWait = 120
$ready = $false
for ($i = 0; $i -lt $maxWait; $i++) {
    Start-Sleep -Milliseconds 1000
    # Check if launched process is still alive
    if ($proc -and $proc.HasExited) {
        Write-Status "Trae process (PID $($proc.Id)) exited unexpectedly — aborting CDP wait" "Red"
        break
    }
    try {
        $curlOut = curl.exe -s --connect-timeout 3 "http://localhost:$Port/json/version" 2>$null
        if ($LASTEXITCODE -eq 0 -and $curlOut) {
            $info = $curlOut | ConvertFrom-Json
            Write-Status "CDP ready: $($info.Browser)" "Green"
            $ready = $true
            break
        }
    } catch {}
}

if (-not $ready) {
    Write-Status "CDP not ready after ${maxWait}s — Trae may still be loading" "Yellow"
    Write-Status "Check manually: http://localhost:$Port/json/version" "Gray"
}

Write-Host ""
Write-Host "=== Trae Debug Instance ===" -ForegroundColor Cyan
Write-Host "CDP Port:    $Port" -ForegroundColor White
Write-Host "UserData:    $debugUserData" -ForegroundColor White
Write-Host "Connect:     agent-browser connect $Port" -ForegroundColor Cyan
Write-Host ""
Write-Host "NOTE: Your original Trae windows are NOT affected" -ForegroundColor DarkGray
