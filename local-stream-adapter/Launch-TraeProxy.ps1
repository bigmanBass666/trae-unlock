<#
.SYNOPSIS
    Trae2API 自动化启动与环境注入脚本 (红队最终修正版)
#>

$ErrorActionPreference = "Stop"

# --- 1. 自动化路径探测 ---
$PossiblePaths = @(
    (Join-Path $env:APPDATA "Trae\Local Storage\leveldb"),
    (Join-Path $env:LOCALAPPDATA "Trae\Local Storage\leveldb"),
    (Join-Path $env:APPDATA "Trae\User Data\Default\Local Storage\leveldb"),
    (Join-Path $env:LOCALAPPDATA "Trae\User Data\Default\Local Storage\leveldb")
)
$TraeDbPath = $null
foreach ($Path in $PossiblePaths) { if (Test-Path $Path) { $TraeDbPath = $Path; break } }

if ($null -eq $TraeDbPath) {
    Write-Error "[!] 未发现 Trae LevelDB。请确保 Trae 已登录。"
}

# --- 2. 设置工作目录 (解决 go.mod 找不到的问题) ---
# 获取脚本所在的文件夹路径
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Push-Location $ScriptDir  # 临时切换到 local-stream-adapter 目录

try {
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host " [Project Trae2API] 自动化红队控制台" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    
    # --- 新增：自动清理端口冲突 ---
    $TargetPort = 8317
    $Conflict = Get-NetTCPConnection -LocalPort $TargetPort -ErrorAction SilentlyContinue
    if ($Conflict) {
        Write-Host "[!] 检测到端口冲突，正在清理旧进程..." -ForegroundColor Yellow
        Stop-Process -Id $Conflict.OwningProcess -Force
        Start-Sleep -Seconds 1 # 等待系统完全释放端口
    }

    # --- 4. 初始化与启动 ---
    $GoPath = "C:\Program Files\Go\bin\go.exe"
    if (-not (Test-Path $GoPath)) { $GoPath = "go" }

    Write-Host "[+] 正在初始化 Go 模块..." -ForegroundColor Gray
    & $GoPath mod tidy

    Write-Host "[+] 代理服务启动中..." -ForegroundColor Green

    $env:UPSTREAM_URL = "https://api.trae.cn/v1/ai/chat/completions" # 先用官方地址验证，影子域名备用
    $env:LISTEN_ADDR = "127.0.0.1:8317"
    $env:LEVELDB_PATH = $TraeDbPath
    
    Write-Host "[*] 目标上游: $env:UPSTREAM_URL" -ForegroundColor Yellow
    & $GoPath run . server

    Write-Host "[*] 监听地址: http://$env:LISTEN_ADDR/v1"
    Write-Host "[!] 按 Ctrl+C 停止测试"
    
    # 启动服务器
    & $GoPath run . server

} catch {
    Write-Host "`n[!] 运行过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # --- 5. 清理逻辑 ---
    Write-Host "`n[!] 执行红队清理协议..." -ForegroundColor Yellow
    Pop-Location # 切回原来的目录
    $TempDirs = Get-ChildItem $env:TEMP -Filter "leveldb-read-*"
    foreach ($dir in $TempDirs) {
        Remove-Item -Recurse -Force $dir.FullName -ErrorAction SilentlyContinue
    }
    Write-Host "[+] 环境已还原。" -ForegroundColor Green
}