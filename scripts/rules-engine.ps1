<#
.SYNOPSIS
    Trae Mod 规则引擎 - 动态规则遵守系统 Phase 2

.DESCRIPTION
    扫描、解析、过滤并输出 rules/ 目录下的 YAML 规则文件。
    支持三种运行模式：默认(Markdown输出)、验证(--check)、列表(--list)。

.PARAMETER Check
    验证模式：检查所有 YAML 文件语法是否正确

.PARAMETER List
    列表模式：显示规则状态摘要表

.PARAMETER Output
    输出模式：将结果写入指定文件而非控制台

.EXAMPLE
    .\rules-engine.ps1
    .\rules-engine.ps1 --check
    .\rules-engine.ps1 --list
    .\rules-engine.ps1 --output "output.md"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)][switch]$Check,
    [Parameter(Mandatory=$false)][switch]$List,
    [Parameter(Mandatory=$false)][string]$Output = ""
)

$ErrorActionPreference = "Stop"

if ($args.Count -gt 0) {
    for ($i = 0; $i -lt $args.Count; $i++) {
        switch ($args[$i]) {
            '--check' { $Check = $true }
            '--list'  { $List = $true }
            '--output' {
                if ($i + 1 -lt $args.Count -and -not $args[$i + 1].StartsWith('-')) {
                    $Output = $args[++$i]
                }
            }
        }
    }
}

# ============================================================
# 全局配置
# ============================================================

$Script:RulesDir = Join-Path $PSScriptRoot "..\rules"
$Script:PriorityOrder = @{ "high" = 0; "medium" = 1; "low" = 2 }
$Script:PriorityIcons = @{ "high" = "🔴"; "medium" = "🟡"; "low" = "🟢" }
$Script:EnforcementIcons = @{ "mandatory" = "⚠️"; "recommended" = "💡"; "optional" = "📌" }

$Script:PowerShellYamlModulePath = "C:\Users\86150\OneDrive\文档\WindowsPowerShell\Modules\powershell-yaml\0.4.12\powershell-yaml.psd1"

if (-not (Test-Path $Script:PowerShellYamlModulePath)) {
    $module = Get-Module -ListAvailable -Name powershell-yaml | Select-Object -First 1
    if ($null -eq $module) {
        Write-Host "❌ 缺少必需模块: powershell-yaml" -ForegroundColor Red
        Write-Host "请运行: Install-Module powershell-yaml -Scope CurrentUser -Force" -ForegroundColor Yellow
        exit 1
    }
    $Script:PowerShellYamlModulePath = $module.ModuleBase + "\powershell-yaml.psd1"
}

Import-Module $Script:PowerShellYamlModulePath -ErrorAction Stop

# ============================================================
# 核心功能：扫描与加载规则
# ============================================================

function Get-RuleFiles {
    <#
    .SYNOPSIS
        获取 rules/ 目录下所有 .yaml 文件路径
    .OUTPUTS
        FileInfo 对象数组；目录不存在时抛出异常
    #>
    $resolvedPath = (Resolve-Path $Script:RulesDir -ErrorAction SilentlyContinue).Path
    if (-not $resolvedPath) {
        throw "❌ rules/ 目录不存在: $($Script:RulesDir)"
    }
    $files = Get-ChildItem -Path $resolvedPath -Filter "*.yaml" -ErrorAction SilentlyContinue
    if (-not $files -or $files.Count -eq 0) {
        throw "❌ rules/ 目录下未找到任何 .yaml 文件"
    }
    return $files
}

function Import-RulesFromFile {
    <#
    .SYNOPSIS
        解析单个 YAML 文件并返回规则对象数组
    .PARAMETER File
        要解析的 FileInfo 对象
    .OUTPUTS
        PSCustomObject 数组；格式错误时返回 $null 并输出警告
    #>
    param($File)

    try {
        $content = Get-Content -Path $File.FullName -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-Warning "⚠️ $($File.Name): 文件内容为空，跳过"
            return $null
        }

        $parsed = $content | ConvertFrom-Yaml
        if ($null -eq $parsed -or $null -eq $parsed.rules) {
            Write-Warning "⚠️ $($File.Name): 未找到 'rules' 键或内容为空"
            return $null
        }

        return $parsed.rules
    } catch {
        Write-Warning "⚠️ $($File.Name): 解析失败 - $($_.Exception.Message)"
        return $null
    }
}

function LoadAllRules {
    <#
    .SYNOPSIS
        加载所有 YAML 文件中的规则并进行过滤和排序
    .OUTPUTS
        已排序的启用规则对象数组
    #>
    $allRules = @()
    $disabledCount = 0
    $fileStats = @{}

    $ruleFiles = Get-RuleFiles
    foreach ($file in $ruleFiles) {
        $rules = Import-RulesFromFile -File $file
        if ($null -eq $rules) { continue }

        $enabledInFile = 0
        $disabledInFile = 0
        foreach ($rule in $rules) {
            $isEnabled = if ($rule['enabled'] -eq 'true') { $true } else { $false }
            if ($isEnabled) {
                $allRules += $rule
                $enabledInFile++
            } else {
                $disabledCount++
                $disabledInFile++
            }
        }
        $fileStats[$file.Name] = @{
            Total   = $rules.Count
            Enabled = $enabledInFile
            Disabled = $disabledInFile
        }
    }

    # 按优先级排序：high > medium > low，同优先级按 ID 升序
    $sortedRules = $allRules | Sort-Object {
        $p = $_['priority']
        if ($null -eq $p) { $p = 'low' }
        if ($Script:PriorityOrder.ContainsKey($p)) { $Script:PriorityOrder[$p] } else { 99 }
    }, {
        $_['id']
    }

    return @{
        Rules          = $sortedRules
        DisabledCount  = $disabledCount
        FileStats      = $fileStats
    }
}

# ============================================================
# 输出生成：Markdown 格式
# ============================================================

function Format-RuleAsMarkdown {
    <#
    .SYNOPSIS
        将单条规则格式化为 Markdown 片段
    #>
    param($Rule)

    $id       = $Rule['id']
    $name     = $Rule['name']
    $category = $Rule['category']
    $priority = $Rule['priority']
    $desc     = $Rule['description']
    $actions  = $Rule['actions']
    $enforce  = $Rule['enforcement']

    $pIcon = if ($Script:PriorityIcons.ContainsKey($priority)) { $Script:PriorityIcons[$priority] } else { "⚪" }
    $eIcon = if ($Script:EnforcementIcons.ContainsKey($enforce)) { $Script:EnforcementIcons[$enforce] } else { "❓" }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("### [$pIcon] $($id): $($name)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("**强制级别**: $($eIcon) $($enforce)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine($desc)
    [void]$sb.AppendLine("")

    if ($null -ne $actions -and $actions.Count -gt 0) {
        [void]$sb.AppendLine("**操作步骤**:")
        for ($i = 0; $i -lt $actions.Count; $i++) {
            [void]$sb.AppendLine("$($i + 1). $($actions[$i])")
        }
        [void]$sb.AppendLine("")
    }

    return $sb.ToString()
}

function Generate-MarkdownOutput {
    <#
    .SYNOPSIS
        生成完整的 Markdown 格式规则报告
    .PARAMETER RuleData
        LoadAllRules 返回的数据结构
    #>
    param($RuleData)

    $rules = $RuleData.Rules
    $disabledCount = $RuleData.DisabledCount
    $totalEnabled = $rules.Count
    $totalCount = $totalEnabled + $disabledCount

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# 📋 Trae Mod 动态规则清单")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("> 由 rules-engine.ps1 自动生成 | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$sb.AppendLine("")

    if ($totalEnabled -eq 0) {
        [void]$sb.AppendLine("⚠️ **当前无有效规则**（所有规则均已禁用）")
        [void]$sb.AppendLine("")
        return $sb.ToString()
    }

    # 按类别分组
    $grouped = @{}
    foreach ($rule in $rules) {
        $cat = $rule['category']
        if (-not $grouped.ContainsKey($cat)) { $grouped[$cat] = @() }
        $grouped[$cat] += $rule
    }

    # 类别标题映射
    $categoryTitles = @{
        "core"     = "🎯 核心规范 (Core)"
        "workflow" = "🔄 工作流程 (Workflow)"
        "git"      = "📦 Git 规范 (Git)"
        "safety"   = "🛡️ 安全原则 (Safety)"
        "anchor"   = "⚓ Anchor 系统维护 (Anchor)"
    }

    $categoryOrder = @("core", "anchor", "workflow", "git", "safety")
    foreach ($cat in $categoryOrder) {
        if (-not $grouped.ContainsKey($cat)) { continue }
        $catRules = $grouped[$cat]
        $title = if ($categoryTitles.ContainsKey($cat)) { $categoryTitles[$cat] } else { $cat.ToUpper() }

        [void]$sb.AppendLine("---")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("## $title")
        [void]$sb.AppendLine("")

        foreach ($rule in $catRules) {
            [void]$sb.Append((Format-RuleAsMarkdown -Rule $rule))
        }
    }

    # 统计信息块
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("")
    $categoryCount = $grouped.Keys.Count
    [void]$sb.AppendLine("📊 **规则统计**: 共 **$totalCount** 条 | ✅ **$totalEnabled** 条启用 | ❌ **$disabledCount** 条禁用 | 📂 **$categoryCount** 个类别")
    [void]$sb.AppendLine("")

    return $sb.ToString()
}

# ============================================================
# 输出生成：--check 验证模式
# ============================================================

function Run-CheckMode {
    <#
    .SYNOPSIS
        验证所有 YAML 文件的语法正确性
    .OUTPUTS
        是否全部通过验证（boolean）
    #>
    $allPassed = $true
    $files = Get-RuleFiles

    foreach ($file in $files) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
            if ([string]::IsNullOrWhiteSpace($content)) {
                Write-Host "❌ $($file.Name): 文件内容为空" -ForegroundColor Red
                $allPassed = $false
                continue
            }

            # 基本结构校验
            $hasRulesKey = $content -match '^rules\s*:'
            if (-not $hasRulesKey) {
                Write-Host "❌ $($file.Name): 缺少顶层 'rules:' 键" -ForegroundColor Red
                $allPassed = $false
                continue
            }

            # 尝试完整解析
            $parsed = $content | ConvertFrom-Yaml
            if ($null -eq $parsed) {
                Write-Host "❌ $($file.Name): YAML 解析失败" -ForegroundColor Red
                $allPassed = $false
                continue
            }
            $rules = $parsed.rules
            $validCount = 0

            if ($rules -and $rules.Count -gt 0) {
                foreach ($r in $rules) {
                    if ($null -ne $r.id -and $null -ne $r.name) { $validCount++ }
                }
            }

            if ($validCount -gt 0) {
                Write-Host "✅ $($file.Name): $validCount rules validated" -ForegroundColor Green
            } else {
                Write-Host "⚠️ $($file.Name): 未找到有效规则" -ForegroundColor Yellow
                $allPassed = $false
            }
        } catch {
            Write-Host "❌ $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
            $allPassed = $false
        }
    }

    return $allPassed
}

# ============================================================
# 输出生成：--list 列表模式
# ============================================================

function Run-ListMode {
    <#
    .SYNOPSIS
        以表格形式列出所有规则的状态摘要
    #>
    $data = LoadAllRules
    $allRules = @()

    # 收集所有规则（包括禁用的）
    $ruleFiles = Get-RuleFiles
    foreach ($file in $ruleFiles) {
        $rules = Import-RulesFromFile -File $file
        if ($null -ne $rules) {
            foreach ($r in $rules) { $allRules += $r }
        }
    }

    # 表头
    Write-Host ("{0,-12} | {1,-24} | {2,-10} | {3,-9} | {4,-7} | {5}" -f `
        "ID", "Name", "Category", "Priority", "Enabled", "Enforcement")
    Write-Host ("{0,-12}-+-{1,-24}-+-{2,-10}-+-{3,-9}-+-{4,-7}-+-{5}" -f `
        ("-" * 12), ("-" * 24), ("-" * 10), ("-" * 9), ("-" * 7), ("-" * 12))

    # 按 ID 排序列出
    $sorted = $allRules | Sort-Object { $_['id'] }
    foreach ($r in $sorted) {
        $id   = $r['id']
        $name = $r['name']
        if ($name.Length -gt 22) { $name = $name.Substring(0, 22) + ".." }
        $cat  = $r['category']
        $pri  = $r['priority']
        $en   = $r['enabled']
        $ef   = $r['enforcement']

        $color = if ($en -eq 'true') { "Green" } else { "DarkGray" }
        Write-Host ("{0,-12} | {1,-24} | {2,-10} | {3,-9} | {4,-7} | {5}" -f `
            $id, $name, $cat, $pri, $en, $ef) -ForegroundColor $color
    }

    Write-Host ""
    Write-Host "总计: $($allRules.Count) 条规则" -ForegroundColor Cyan
}

# ============================================================
# 主入口
# ============================================================

function Main {
    try {
        if ($Check) {
            # --check 验证模式
            $passed = Run-CheckMode
            exit $(if ($passed) { 0 } else { 1 })
        }

        if ($List) {
            # --list 列表模式
            Run-ListMode
            exit 0
        }

        # 默认模式：生成完整 Markdown 输出
        $data = LoadAllRules
        $markdown = Generate-MarkdownOutput -RuleData $data

        if ($Output) {
            $outPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Output)
            $dir = Split-Path $outPath -Parent
            if ($dir -and -not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            Set-Content -Path $outPath -Value $markdown -Encoding UTF8 -NoNewline
            Write-Host "✅ Markdown 已写入: $outPath" -ForegroundColor Green
        } else {
            Write-Host $markdown
        }

        exit 0

    } catch {
        Write-Host "`n$($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Main
