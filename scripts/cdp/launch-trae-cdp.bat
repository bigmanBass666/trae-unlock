@echo off
:: Trae Unlock Launcher — 带 CDP 远程调试端口启动 Trae
:: 用法: 双击此文件代替 Trae 图标

set TRAE_CDP_PORT=9222

start "" "D:\apps\Trae CN\Trae CN.exe" --remote-debugging-port=%TRAE_CDP_PORT%

echo.
echo Trae 启动中，CDP 端口: %TRAE_CDP_PORT%
echo 等待 10 秒后检查...
timeout /t 10 /nobreak >nul

curl -s http://localhost:%TRAE_CDP_PORT%/json/version >nul 2>&1
if %ERRORLEVEL%==0 (
    echo.
    echo ========================================
    echo   SUCCESS! CDP 已启用!
    echo   DevTools: http://localhost:%TRAE_CDP_PORT%
    echo ========================================
    echo.
    echo 现在运行注入器:
    echo   node scripts\cdp-inject.js --port %TRAE_CDP_PORT%
) else (
    echo.
    echo [WARN] CDP 端口未响应，Trae 可能使用了其他方式启动
)
pause
