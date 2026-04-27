<#
.SYNOPSIS
    CDP Launcher — 以 remote-debugging 模式启动 Trae 并注入补丁
    
.DESCRIPTION
    替代直接双击 Trae 图标，通过此脚本启动可获得：
    - Chrome DevTools Protocol 端口开放（默认 9222）
    - 自动注入 trae-unlock 补丁（零源码修改）
    
.PARAMETER Port
    CDP 监听端口，默认 9222
    
.PARAMETER InjectScript
    注入脚本路径，默认 scripts/cdp-inject.js
    
.PARAMETER NoInject
    只启动调试模式，不注入补丁（用于调试）
    
.EXAMPLE
    .\cdp-launcher.ps1
    # 启动 Trae + 注入补丁
    
.EXAMPLE
    .\cdp-launcher.ps1 -Port 9333 -NoInject
    # 启动 Trae 在端口 9333，不注入（手动连接 DevTools 调试）
#>

param(
    [int]$Port = 9222,
    [string]$InjectScript = Join-Path $PSScriptRoot "cdp-inject.js",
    [switch]$NoInject
)

$ErrorActionPreference = "Stop"
$traeExe = "D:\apps\Trae CN\Trae CN.exe"

# 检查 Trae 是否已运行
$existing = Get-Process -Name "Trae*" -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "[INFO] 检测到已有 Trae 实例，正在关闭..." -ForegroundColor Yellow
    $existing | Stop-Process -Force
    Start-Sleep -Seconds 2
}

# 启动 Trae 带 CDP 端口
Write-Host "[LAUNCH] 启动 Trae (CDP port=$Port)..." -ForegroundColor Cyan
Start-Process $traeExe -ArgumentList "--remote-debugging-port=$Port"

# 等待 CDP 就绪
Write-Host "[WAIT] 等待 CDP 服务启动..." -ForegroundColor Yellow
$maxWait = 15
$ready = $false
for ($i = 0; $i -lt $maxWait; $i++) {
    Start-Sleep -Milliseconds 500
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:$Port/json/version" -UseBasicParsing -TimeoutSec 2
        Write-Host "[OK] CDP 就绪: $($r.Content)" -ForegroundColor Green
        $ready = $true
        break
    } catch {
        Write-Host "." -NoNewline
    }
}

if (-not $ready) {
    Write-Host "[FAIL] CDP 端口在 ${maxWait}s 内未就绪" -ForegroundColor Red
    Write-Host "[HINT] Trae 可能不支持 --remote-debugging-port，或被安全软件拦截" -ForegroundColor Yellow
    exit 1
}

# 注入补丁
if (-not $NoInject) {
    if (Test-Path $InjectScript) {
        Write-Host "[INJECT] 执行注入脚本: $InjectScript" -ForegroundColor Cyan
        
        # 使用 Trae 自带的 Node.js 运行注入脚本
        $nodeExe = Join-Path (Split-Path $traeExe) "..\resources\app\node_modules\.bin\node.cmd"
        if (-not (Test-Path $nodeExe)) {
            # 回退：尝试系统 PATH 中的 node
            $nodeExe = "node"
        }
        
        & $nodeExe $InjectScript --port $Port
        $injectExitCode = $LASTEXITCODE
        
        if ($injectExitCode -eq 0) {
            Write-Host "[OK] 注入完成！" -ForegroundColor Green
        } else {
            Write-Host "[WARN] 注入脚本退出码: $injectExitCode" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[WARN] 注入脚本不存在: $InjectScript" -ForegroundColor Yellow
        Write-Host "[HINT] 跳过注入，Trae 已以调试模式运行" -ForegroundColor Gray
    }
} else {
    Write-Host "[SKIP] NoInject 模式，未执行注入" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Trae Unlock CDP Launcher ===" -ForegroundColor Cyan
Write-Host "DevTools:   http://localhost:$Port" -ForegroundColor White
Write-Host "Targets:     http://localhost:$Port/json" -ForegroundColor White
Write-Host "可以打开 chrome://inspect 连接远程目标进行调试" -ForegroundColor DarkGray
