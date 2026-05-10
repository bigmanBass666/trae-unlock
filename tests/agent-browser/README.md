# Trae Agent-Browser 自动化测试框架

基于 [agent-browser](https://github.com/anthropics/agent-browser) 的 Trae Electron 应用自动化测试框架，用于验证 trae-unlock 补丁功能（命令自动确认、思考自动续接等）。

## 目录结构

```
tests/
├── agent-browser/
│   ├── connect.ps1              # CDP 连接模块
│   ├── test-runner.ps1          # 测试运行器（主入口）
│   ├── test-auto-confirm.ps1    # 命令确认测试
│   ├── test-auto-continue.ps1   # 自动续接测试
│   ├── lib/
│   │   ├── utils.ps1            # 工具函数库
│   │   └── assertions.ps1       # 断言库
│   └── README.md                # 本文档
├── screenshots/                 # 截图输出
│   └── YYYY-MM-DD/
│       ├── auto-confirm/
│       └── auto-continue/
├── logs/                        # 测试日志
│   └── test-run_YYYYMMDD-HHMMSS.log
└── reports/                     # Markdown 测试报告
    └── report_YYYYMMDD-HHMMSS.md
```

## 前置条件

| 依赖 | 版本 | 验证命令 |
|------|------|----------|
| PowerShell | 7+ | `$PSVersionTable.PSVersion` |
| agent-browser | 0.27.0+ | `agent-browser --version` |
| Trae CN | 3.3.x | 运行中 |
| CDP 端口 | 可访问 (9222) | 见下方启动方式 |

### 启动 Trae 调试模式

**方式 A: 使用 cdp-launcher（推荐）**

```powershell
.\scripts\cdp\cdp-launcher.ps1 -Port 9222
```

**方式 B: 手动启动**

```powershell
# 关闭已有 Trae 实例
Get-Process -Name "Trae*" | Stop-Process -Force

# 以调试模式启动
Start-Process "D:\apps\Trae CN\Trae CN.exe" -ArgumentList "--remote-debugging-port=9222"

# 验证端口可用
Invoke-WebRequest http://localhost:9222/json/version
```

**方式 C: CDP Bootstrap（永久生效）**

```powershell
# 安装后每次启动自动开启 CDP
.\scripts\cdp\cdp-bootstrap.ps1 -Action install

# 正常启动 Trae 即可
```

## 快速开始

### 1. 独立连接测试

```powershell
cd tests\agent-browser

# 指定端口连接
.\connect.ps1 -Port 9222

# 或自动发现端口
.\connect.ps1 -AutoDiscover
```

成功输出示例：

```
=== Trae Agent-Browser Connection ===

[2026-05-09 23:56:00] [INFO] Checking agent-browser availability...
[2026-05-09 23:56:00] [INFO] agent-browser available: agent-browser 0.27.0
[2026-05-09 23:56:00] [INFO] Testing CDP endpoint at localhost:9222...
[2026-05-09 23:56:01] [INFO] Executing: agent-browser connect localhost:9222
[2026-05-09 23:56:02] [INFO] agent-browser connected successfully
[2026-05-09 23:56:02] [INFO] Connected to: Visual Studio Code
[OK] Connection state saved to: ...\trae-test-connection.json

--- Connection Summary ---
Status:     CONNECTED
Port:       9222
Title:      Visual Studio Code
Timestamp:  2026-05-09 23:56:02
```

### 2. 运行全部测试

```powershell
cd tests\agent-browser

.\test-runner.ps1 -TestName all -Verbose
```

### 3. 运行单个测试

```powershell
# 只运行命令确认测试
.\test-runner.ps1 -TestName auto-confirm

# 只运行自动续接测试
.\test-runner.ps1 -TestName auto-continue

# 详细模式 + 自定义端口
.\test-runner.ps1 -TestName auto-confirm -Port 9333 -Verbose
```

## 可用测试场景

| 测试名称 | 文件 | 验证目标 | 当前状态 |
|----------|------|----------|----------|
| auto-confirm | test-auto-confirm.ps1 | 命令自动确认补丁是否拦截/自动确认弹窗 | 骨架 |
| auto-continue | test-auto-continue.ps1 | 思考续接 [AC] 机制是否正常工作 | 骨架 |

### auto-confirm 测试详情

**目的**: 验证命令确认弹窗被补丁自动处理

**流程**:
1. 准备：验证 CDP 连接，截取初始状态
2. 触发：发送会触发命令确认的消息（如 "请帮我运行 npm test"）
3. 监控：轮询 UI snapshot 检测确认弹窗关键词（8秒窗口）
4. 断言：
   - 弹窗从未出现 -> **PASS**（补丁完全拦截）
   - 弹窗出现但 <3秒消失 -> **PASS**（补丁自动确认）
   - 弹窗持续 >3秒 -> **FAIL**（补丁未生效）
5. 清理：截图 + 控制台日志收集

### auto-continue 测试详情

**目的**: 验证思考上限时自动续接机制正常工作

**流程**:
1. 准备：验证连接，记录初始控制台日志基线
2. 触发：发送复杂问题触发长思考链
3. 监控：轮询控制台日志检测 `[AC]` 前缀消息（30秒窗口）
4. 断言：
   - 至少 1 条 `[AC]` 消息出现
   - 首 AC 消息响应延迟 <5秒
   - 控制台包含续接相关关键词
   - 日志行数有增长（说明有活动）
5. 清理：截图 + AC 日志归档

## 配置选项

### connect.ps1 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| Port | int | 9222 | CDP 端口号 |
| AutoDiscover | switch | - | 自动发现 Trae 调试端口 |
| Timeout | int | 10 | 连接超时（秒） |

### test-runner.ps1 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| TestName | enum | all | 测试名: auto-confirm, auto-continue, all |
| OutputDir | string | tests/reports/ | 报告输出目录 |
| ScreenshotsDir | string | tests/screenshots/ | 截图目录 |
| Port | int | 9222 | CDP 端口 |
| AutoDiscover | switch | - | 自动发现端口 |
| NoConnect | switch | - | 跳过连接（使用已有） |
| Verbose | switch | - | 详细日志输出 |

### 测试脚本内部配置

每个测试脚本顶部的 `$script:Config` 哈希表可调整：

```powershell
$script:Config = @{
    TriggerMessage     = "..."     # 触发消息内容
    MonitorDurationSec = 30        # 监控时长
    PollIntervalMs     = 1000      # 轮询间隔
    DialogThresholdSec = 3         # 弹窗阈值（auto-confirm）
    MinAcMessages      = 1         # 最少AC消息数（auto-continue）
    MaxResponseDelayMs = 5000      # 最大延迟（auto-continue）
}
```

## 输出文件

### 日志文件 (`tests/logs/`)

格式: `test-run_YYYYMMDD-HHMMSS.log`

```
[2026-05-09 23:56:00] [INFO] === Test Run Started ===
[2026-05-09 23:56:00] [INFO] TestName:   all
[2026-05-09 23:56:01] [INFO] Phase 1: Establishing CDP connection...
[2026-05-09 23:56:02] [PASS] Assert-CdpConnected: Connection valid before test
[2026-05-09 23:56:03] [DEBUG] Screenshot saved: tests\screenshots\...\initial-state.png
...
```

### 截图文件 (`tests/screenshots/YYYY-MM-DD/<scenario>/`)

命名规则: `YYYYMMDD-HHMMSS_<scenario>_<step>.png`

示例:
- `20260509-235600_auto-confirm_initial-state.png`
- `20260509-235605_auto-confirm_final-state.png`
- `20260509-235610_auto-continue_initial-state.png`

> 截图自动保留最近 7 天，更早的会被清理。

### 测试报告 (`tests/reports/`)

格式: Markdown (`report_YYYYMMDD-HHMMSS.md`)

包含：
- 元数据（时间、耗时、目标信息）
- 结果总表（状态、耗时、错误摘要）
- 每个测试的详细断言结果
- 截图链接列表
- 控制台日志证据片段

## 常见问题 FAQ

### Q: 提示 "CDP endpoint not reachable"

**A**: Trae 未以调试模式启动。执行以下之一：
```powershell
# 方式 A: 使用 launcher
.\scripts\cdp\cdp-launcher.ps1

# 方式 B: 手动带参数启动
Start-Process "Trae CN.exe" -ArgumentList "--remote-debugging-port=9222"
```

### Q: 提示 "agent-browser not found in PATH"

**A**: 安装 agent-browser CLI：
```bash
npm install -g @anthropic-ai/agent-browser
```

### Q: 端口 9222 被占用

**A**: 使用其他端口：
```powershell
.\connect.ps1 -Port 9333
# 或
.\test-runner.ps1 -TestName all -Port 9333
```

### Q: 测试全部显示 SKIP

**A**: 测试脚本文件缺失或路径不正确。检查 `tests/agent-browser/` 下是否存在对应 `.ps1` 文件。

### Q: 如何调试单个测试？

**A**: 直接运行测试脚本（需先手动连接）：
```powershell
# 先连接
.\connect.ps1 -Port 9222

# 再单独运行测试（使用 -NoConnect 跳过重复连接）
.\test-runner.ps1 -TestName auto-confirm -NoConnect -Verbose
```

### Q: 如何查看 Trae 的 DOM 结构？

**A**: 连接后使用 agent-browser inspect：
```powershell
agent-browser snapshot          # 查看 accessibility tree
agent-browser inspect           # 打开 DevTools
agent-browser screenshot debug.png  # 截图分析
```

### Q: 测试选择器如何填充？

**A**: 当前为骨架实现，选择器标记为 TODO。填充步骤：
1. 启动 Trae 调试模式并连接
2. 执行 `agent-browser snapshot` 获取 accessibility tree
3. 定位目标元素（输入框、按钮、弹窗等）的 ref 或 selector
4. 更新各测试脚本中的 `$script:Config` 选择器字段
5. 重新运行测试验证

## 开发指南

### 添加新测试场景

1. 在 `tests/agent-browser/` 创建 `test-<name>.ps1`
2. 参照现有骨架结构（Phase 1-5）
3. 在 `test-runner.ps1` 的 `$script:TestRegistry` 中注册：
   ```powershell
   $script:TestRegistry["my-new-test"] = Join-Path $PSScriptRoot "test-my-new-test.ps1"
   ```
4. 更新 `-TestName` 的 ValidateSet
5. 在本 README 的测试场景表中添加条目

### 工具函数参考

**lib/utils.ps1**:

| 函数 | 说明 |
|------|------|
| `Write-TestLog` | 写入带时间戳的日志（控制台+文件） |
| `Save-Screenshot` | 通过 agent-browser 截图保存 |
| `Get-Timestamp` / `Get-FilenameTimestamp` | 时间戳工具 |
| `Invoke-AgentBrowser` | 封装 agent-browser CLI 调用 |
| `New-TestResult` / `Complete-TestResult` | 测试结果对象生命周期 |
| `Remove-StaleScreenshots` | 清理过期截图 |

**lib/assertions.ps1**:

| 函数 | 说明 |
|------|------|
| `Assert-ElementExists` | 元素存在于 snapshot 中 |
| `Assert-ElementNotExists` | 元素不存在 |
| `Assert-ElementVisible` | 元素可见性 |
| `Assert-StringContains` | 字符串包含子串 |
| `Assert-StringMatch` | 正则匹配 |
| `Assert-Condition` | 通用条件断言 |
| `Assert-Timeout` | 操作在超时内完成 |
| `Assert-CdpConnected` | CDP 连接有效 |
| `Assert-ConsoleLogContains` | 控制台日志包含内容 |
| `Get-AssertionSummary` | 批量汇总 |
| `Format-AssertionReport` | Markdown 格式化 |
