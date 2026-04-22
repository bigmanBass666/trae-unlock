$ErrorActionPreference = "Stop"
$TestResults = @()
$Passed = 0
$Failed = 0

function Test-It {
    param(
        [string]$Name,
        [scriptblock]$Test
    )
    try {
        $result = & $Test
        if ($result) {
            $script:Passed++
            Write-Host "[PASS] $Name" -ForegroundColor Green
            $script:TestResults += @{ Name = $Name; Status = "PASS" }
        } else {
            $script:Failed++
            Write-Host "[FAIL] $Name" -ForegroundColor Red
            $script:TestResults += @{ Name = $Name; Status = "FAIL" }
        }
    } catch {
        $script:Failed++
        Write-Host "[FAIL] $Name : $($_.Exception.Message)" -ForegroundColor Red
        $script:TestResults += @{ Name = $Name; Status = "FAIL"; Error = $_.Exception.Message }
    }
}

$scriptPath = Join-Path $PSScriptRoot "..\scripts\rules-engine.ps1"
. $scriptPath

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "YAML Parser Refactoring Tests" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Test-It "Get-RuleFiles returns YAML files" {
    $files = Get-RuleFiles
    $null -ne $files -and $files.Count -gt 0
}

Test-It "All rule files are .yaml files" {
    $files = Get-RuleFiles
    $allYaml = $true
    foreach ($f in $files) {
        if (-not $f.Name.EndsWith(".yaml")) { $allYaml = $false }
    }
    $allYaml
}

Test-It "Import-RulesFromFile parses core.yaml correctly" {
    $coreFile = Get-RuleFiles | Where-Object { $_.Name -eq "core.yaml" }
    $rules = Import-RulesFromFile -File $coreFile
    $null -ne $rules -and $rules.Count -gt 0
}

Test-It "Imported rule has required fields" {
    $coreFile = Get-RuleFiles | Where-Object { $_.Name -eq "core.yaml" }
    $rules = Import-RulesFromFile -File $coreFile
    $firstRule = $rules[0]
    $null -ne $firstRule['id'] -and
    $null -ne $firstRule['name'] -and
    $null -ne $firstRule['category'] -and
    $null -ne $firstRule['priority'] -and
    $null -ne $firstRule['enabled']
}

Test-It "Imported rule actions is an array" {
    $coreFile = Get-RuleFiles | Where-Object { $_.Name -eq "core.yaml" }
    $rules = Import-RulesFromFile -File $coreFile
    $firstRule = $rules[0]
    $actions = $firstRule['actions']
    $actions -is [array] -or $actions.Count -gt 0
}

Test-It "LoadAllRules returns enabled rules only" {
    $data = LoadAllRules
    $rules = $data.Rules
    $allEnabled = $true
    foreach ($r in $rules) {
        if ($r['enabled'] -ne 'true') { $allEnabled = $false }
    }
    $allEnabled
}

Test-It "LoadAllRules sorts by priority (high first)" {
    $data = LoadAllRules
    $rules = $data.Rules
    $highPriority = $rules | Where-Object { $_['priority'] -eq 'high' }
    $lowPriority = $rules | Where-Object { $_['priority'] -eq 'low' }
    if ($null -eq $highPriority -or $null -eq $lowPriority) { return $true }
    $highIndex = $rules.IndexOf($highPriority[0])
    $lowIndex = $rules.IndexOf($lowPriority[0])
    $highIndex -lt $lowIndex
}

Test-It "Format-RuleAsMarkdown generates valid markdown" {
    $coreFile = Get-RuleFiles | Where-Object { $_.Name -eq "core.yaml" }
    $rules = Import-RulesFromFile -File $coreFile
    $markdown = Format-RuleAsMarkdown -Rule $rules[0]
    $markdown.Contains("### [") -and $markdown.Contains("**强制级别**")
}

Test-It "workflow.yaml has critical priority rules" {
    $wfFile = Get-RuleFiles | Where-Object { $_.Name -eq "workflow.yaml" }
    $rules = Import-RulesFromFile -File $wfFile
    $criticalRules = $rules | Where-Object { $_['priority'] -eq 'critical' }
    $criticalRules.Count -gt 0
}

Test-It "All files have valid structure" {
    $files = Get-RuleFiles
    $allValid = $true
    foreach ($f in $files) {
        $rules = Import-RulesFromFile -File $f
        if ($null -eq $rules -or $rules.Count -eq 0) {
            $allValid = $false
            Write-Host "  Warning: $($f.Name) has no rules" -ForegroundColor Yellow
        }
    }
    $allValid
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Results: $Passed passed, $Failed failed" -ForegroundColor $(if ($Failed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================" -ForegroundColor Cyan

if ($Failed -gt 0) {
    exit 1
} else {
    exit 0
}