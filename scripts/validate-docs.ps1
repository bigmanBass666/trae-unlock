param(
    [string]$Path = (Get-Location).Path,
    [switch]$Verbose
)

$ErrorActionPreference = "SilentlyContinue"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

$excludeDirs = @('.archive', 'node_modules', 'unpacked', '.trae', '.git', '.templates', 'backups', 'tools')
$excludePathPatterns = @(
    'docs\plans\*',
    'docs\achievements\*',
    'docs\reports\*',
    'tests\*'
)
$requiredFields = @('module', 'description', 'read_priority', 'format')

Write-ColorOutput "=========================================="
Write-ColorOutput "  📋 Document Quality Validator v1.0" -ForegroundColor Cyan
Write-ColorOutput "==========================================
" -ForegroundColor Cyan

$mdFiles = Get-ChildItem -Path $Path -Filter "*.md" -Recurse | Where-Object {
    $relativePath = $_.FullName.Substring($Path.Length + 1)
    $dirExcluded = $excludeDirs | Where-Object { $relativePath -like "$_*\*" -or $relativePath -like "$_*" }
    $pathExcluded = $excludePathPatterns | Where-Object { $relativePath -like $_ }
    (-not $dirExcluded) -and (-not $pathExcluded)
}

$totalFiles = $mdFiles.Count
$filesWithFrontMatter = @()
$filesWithoutFrontMatter = @()

$rule1Errors = @()
$rule1PassCount = 0

foreach ($file in $mdFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    
    if ($content -match '^---\s*\n') {
        $filesWithFrontMatter += $file
        
        $frontMatterMatch = [regex]::Match($content, '(?s)^---\s*\n(.*?)\n---')
        
        if ($frontMatterMatch.Success) {
            $fmContent = $frontMatterMatch.Groups[1].Value
            $missingFields = @()
            
            foreach ($field in $requiredFields) {
                if ($fmContent -notmatch "(?m)^\s*$field\s*:") {
                    $missingFields += $field
                }
            }
            
            if ($missingFields.Count -gt 0) {
                $relativePath = $file.FullName.Substring($Path.Length + 1)
                $missingStr = $missingFields -join ", "
                $rule1Errors += "[ERROR] $relativePath`: 缺少字段: $missingStr"
            } else {
                $rule1PassCount++
            }
        } else {
            $relativePath = $file.FullName.Substring($Path.Length + 1)
            $rule1Errors += "[ERROR] $relativePath`: YAML front matter 格式错误"
        }
    } else {
        $filesWithoutFrontMatter += $file
        $relativePath = $file.FullName.Substring($Path.Length + 1)
        $rule1Errors += "[ERROR] $relativePath`: 无 YAML front matter"
    }
}

$withFMPercent = if ($totalFiles -gt 0) { [math]::Round(($filesWithFrontMatter.Count / $totalFiles) * 100) } else { 0 }

Write-ColorOutput "📊 扫描统计:"
Write-Host "  总文件数: $totalFiles"
Write-Host "  有 front matter: $($filesWithFrontMatter.Count) ($withFMPercent%)"
if ($filesWithoutFrontMatter.Count -gt 0) {
    Write-ColorOutput "  无 front matter: $($filesWithoutFrontMatter.Count) ⚠️" -ForegroundColor Yellow
} else {
    Write-Host "  无 front matter: 0"
}
Write-Host ""

$rule1Score = 1.0
if ($rule1Errors.Count -gt 0) { $rule1Score -= 0.5 }

if ($rule1Errors.Count -eq 0) {
    Write-ColorOutput "✅ Rule 1: 元数据完整性 — 通过 $rule1PassCount/$($filesWithFrontMatter.Count)" -ForegroundColor Green
} else {
    Write-ColorOutput "❌ Rule 1: 元数据完整性 — 通过 $rule1PassCount/$($filesWithFrontMatter.Count)" -ForegroundColor Red
    Write-ColorOutput "❌ Rule 1 失败详情:" -ForegroundColor Red
    foreach ($err in $rule1Errors) {
        Write-Host "   - $err" -ForegroundColor Red
    }
}
Write-Host ""

$sharedFiles = $mdFiles | Where-Object { $_.DirectoryName -like "*\shared" -or $_.DirectoryName -like "*\shared*" }
$rule2Warnings = @()
$rule2Score = 1.0

if ($sharedFiles.Count -ge 2) {
    for ($i = 0; $i -lt $sharedFiles.Count; $i++) {
        for ($j = $i + 1; $j -lt $sharedFiles.Count; $j++) {
            $contentI = Get-Content $sharedFiles[$i].FullName -Raw -Encoding UTF8
            $contentJ = Get-Content $sharedFiles[$j].FullName -Raw -Encoding UTF8
            
            $wordsI = ($contentI -split '\s+') | Where-Object { $_.Length -gt 2 }
            $wordsJ = ($contentJ -split '\s+') | Where-Object { $_.Length -gt 2 }
            
            if ($wordsI.Count -eq 0 -or $wordsJ.Count -eq 0) { continue }
            
            $commonWords = ($wordsI | Where-Object { $wordsJ -contains $_ })
            $similarity = [math]::Round(($commonWords.Count / [math]::Min($wordsI.Count, $wordsJ.Count)) * 100)
            
            if ($similarity -gt 30) {
                $pathI = $sharedFiles[$i].FullName.Substring($Path.Length + 1)
                $pathJ = $sharedFiles[$j].FullName.Substring($Path.Length + 1)
                
                $isSpecialPair = (($pathI -match 'status\.md' -and $pathJ -match 'handoff-developer\.md') -or `
                                   ($pathJ -match 'status\.md' -and $pathI -match 'handoff-developer\.md'))
                
                if ($isSpecialPair) {
                    $rule2Warnings += "[WARNING] $pathI 与 $pathJ 重叠 ${similarity}% ⭐ (重点关注)"
                } else {
                    $rule2Warnings += "[WARNING] $pathI 与 $pathJ 重叠 ${similarity}%"
                }
                $rule2Score -= 0.2
            }
        }
    }
}

if ($rule2Warnings.Count -eq 0) {
    Write-ColorOutput "✅ Rule 2: 信息唯一性 — 通过 ✅ (无严重重复)" -ForegroundColor Green
} else {
    Write-ColorOutput "⚠️ Rule 2: 信息唯一性 — 发现重复内容" -ForegroundColor Yellow
    Write-ColorOutput "⚠️ Rule 2 告警:" -ForegroundColor Yellow
    foreach ($warn in $rule2Warnings) {
        Write-Host "   - $warn" -ForegroundColor Yellow
    }
}
Write-Host ""

$allLinks = @()
$deadLinks = @()

foreach ($file in $mdFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $linkPattern = '\[([^\]]*)\]\(([^)]+)\)'
    $matches = [regex]::Matches($content, $linkPattern)
    
    foreach ($match in $matches) {
        $linkText = $match.Groups[1].Value
        $linkTarget = $match.Groups[2].Value
        
        if ($linkTarget -match '^http[s]?://' -or $linkTarget -match '^#') { continue }
        
        $targetPath = $linkTarget
        $anchor = ""
        
        if ($targetPath -match '^(.+?)(#.+)?$') {
            $targetPath = $Matches[1]
            $anchor = if ($Matches[2]) { $Matches[2] } else { "" }
        }
        
        if ([string]::IsNullOrEmpty($targetPath)) { continue }
        
        $fullTargetPath = Join-Path $file.DirectoryName $targetPath
        
        if (-not (Test-Path $fullTargetPath)) {
            $altTarget = Join-Path $Path $targetPath
            if (Test-Path $altTarget) {
                $fullTargetPath = $altTarget
            }
        }
        
        $sourceRelative = $file.FullName.Substring($Path.Length + 1)
        
        if (-not (Test-Path $fullTargetPath)) {
            $deadLinks += "[ERROR] $sourceRelative`: [$linkText]($linkTarget) → 目标不存在"
        } elseif ($anchor -ne "") {
            $sectionName = $anchor.TrimStart('#')
            $targetContent = Get-Content $fullTargetPath -Raw -Encoding UTF8
            $escapedSection = [regex]::Escape($sectionName)
            
            if ($targetContent -notmatch "(?m)^#+\s*.*$escapedSection") {
                $deadLinks += "[ERROR] $sourceRelative`: [$linkText]($linkTarget) → section '$sectionName' 不存在"
            }
        }
    }
}

$rule3Score = 1.0
if ($deadLinks.Count -gt 0) { $rule3Score -= 0.5 }

$linkCheckTotal = $allLinks.Count + $deadLinks.Count
$linkPassCount = if ($linkCheckTotal -gt 0) { $linkCheckTotal - $deadLinks.Count } else { 0 }

if ($deadLinks.Count -eq 0) {
    Write-ColorOutput "✅ Rule 3: 交叉引用 — 通过 $linkPassCount/$linkCheckTotal" -ForegroundColor Green
} else {
    Write-ColorOutput "❌ Rule 3: 交叉引用 — 通过 $linkPassTotal/$linkCheckTotal" -ForegroundColor Red
    Write-ColorOutput "❌ Rule 3 死链:" -ForegroundColor Red
    foreach ($link in $deadLinks) {
        Write-Host "   - $link" -ForegroundColor Red
    }
}
Write-Host ""

$rule4Warnings = @()
$rule4Score = 1.0

foreach ($file in $filesWithFrontMatter) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $fmMatch = [regex]::Match($content, '(?s)^---\s*\n(.*?)\n---')
    
    if (-not $fmMatch.Success) { continue }
    
    $fmContent = $fmMatch.Groups[1].Value
    $formatMatch = [regex]::Match($fmContent, '(?m)^\s*format\s*:\s*(\w+)')
    
    if (-not $formatMatch.Success) { continue }
    
    $format = $formatMatch.Groups[1].Value.Trim()
    $bodyContent = $content.Substring($fmMatch.Index + $fmMatch.Length).Trim()
    $relativePath = $file.FullName.Substring($Path.Length + 1)
    
    switch ($format) {
        'registry' {
            if ($bodyContent -notmatch '\|.*\|.*\|') {
                $rule4Warnings += "[WARNING] $relativePath`: format=registry 但未包含表格结构"
                $rule4Score -= 0.2
            }
        }
        'log' {
            if ($bodyContent -notmatch '### \[\d{4}') {
                $rule4Warnings += "[WARNING] $relativePath`: format=log 但未包含时间戳章节 (### [20XX)"
                $rule4Score -= 0.2
            }
        }
        'reference' {
            $sections = [regex]::Matches($bodyContent, '(?m)^#{2,}\s+.+')
            if ($sections.Count -lt 2) {
                $rule4Warnings += "[WARNING] $relativePath`: format=reference 但缺少明确的 section 结构"
                $rule4Score -= 0.2
            }
        }
    }
}

if ($rule4Warnings.Count -eq 0) {
    Write-ColorOutput "✅ Rule 4: 结构合规性 — 通过 ✅" -ForegroundColor Green
} else {
    Write-ColorOutput "⚠️ Rule 4: 结构合规性 — 发现问题" -ForegroundColor Yellow
    Write-ColorOutput "⚠️ Rule 4 告警:" -ForegroundColor Yellow
    foreach ($warn in $rule4Warnings) {
        Write-Host "   - $warn" -ForegroundColor Yellow
    }
}
Write-Host ""

$rule5Warnings = @()
$rule5Score = 1.0

foreach ($file in $mdFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $lines = ($content -split "`n").Count
    $fileName = $file.Name
    $relativePath = $file.FullName.Substring($Path.Length + 1)
    
    $h1Count = ([regex]::Matches($content, '(?m)^#\s+.+')).Count
    if ($h1Count -gt 1) {
        $rule5Warnings += "[WARNING] $relativePath`: H1 标题数量为 $h1Count（应为 1）"
        $rule5Score -= 0.2
    }
    
    switch ($fileName) {
        'AGENTS.md' {
            if ($lines -gt 100) {
                $rule5Warnings += "[WARNING] $relativePath`: 行数 $lines 超过建议值 100"
                $rule5Score -= 0.2
            }
        }
        { $_ -match '^handoff.*\.md$' } {
            if ($lines -gt 300) {
                $rule5Warnings += "[WARNING] $relativePath`: 行数 $lines 超过建议值 300"
                $rule5Score -= 0.2
            }
        }
        'status.md' {
            if ($lines -gt 500) {
                $rule5Warnings += "[WARNING] $relativePath`: 行数 $lines 超过建议值 500"
                $rule5Score -= 0.2
            }
        }
    }
}

if ($rule5Warnings.Count -eq 0) {
    Write-ColorOutput "✅ Rule 5: AI 友好性 — 通过 ✅" -ForegroundColor Green
} else {
    Write-ColorOutput "⚠️ Rule 5: AI 友好性 — 发现问题" -ForegroundColor Yellow
    Write-ColorOutput "⚠️ Rule 5 告警:" -ForegroundColor Yellow
    foreach ($warn in $rule5Warnings) {
        Write-Host "   - $warn" -ForegroundColor Yellow
    }
}
Write-Host ""

$errorCount = $rule1Errors.Count + $deadLinks.Count
$warningCount = $rule2Warnings.Count + $rule4Warnings.Count + $rule5Warnings.Count
$infoCount = 0

$scores = @($rule1Score, $rule2Score, $rule3Score, $rule4Score, $rule5Score)
$passedRules = ($scores | Where-Object { $_ -ge 0.9 }).Count
$totalScore = [math]::Round(($scores | Measure-Object -Sum).Sum / $scores.Count * 10) / 10

Write-ColorOutput "=========================================="
if ($totalScore -ge 4.0) {
    Write-ColorOutput "  📈 文档质量评分: $totalScore/5 🌟" -ForegroundColor Green
} elseif ($totalScore -ge 3.0) {
    Write-ColorOutput "  📈 文档质量评分: $totalScore/5 👍" -ForegroundColor Yellow
} elseif ($totalScore -ge 2.0) {
    Write-ColorOutput "  📈 文档质量评分: $totalScore/5 ⚠️" -ForegroundColor Yellow
} else {
    Write-ColorOutput "  📈 文档质量评分: $totalScore/5 ❌" -ForegroundColor Red
}
Write-Host "  通过规则: $passedRules/5"
Write-Host "  ERROR: $errorCount | WARNING: $warningCount | INFO: $infoCount"
Write-ColorOutput "==========================================" -ForegroundColor Cyan

if ($errorCount -gt 0) {
    exit 1
} else {
    exit 0
}
