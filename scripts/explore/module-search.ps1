param(
    [Parameter(Mandatory=$false)]
    [string]$Keyword,
    [Parameter(Mandatory=$false)]
    [switch]$Regex,
    [Parameter(Mandatory=$false)]
    [int]$ContextLines = 3,
    [Parameter(Mandatory=$false)]
    [int]$MaxResults = 50,
    [Parameter(Mandatory=$false)]
    [ValidateSet("Search","Overview","Find")]
    [string]$Mode = "Search",
    [Parameter(Mandatory=$false)]
    [string]$FileType = "all"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$DefaultUnpackedDir = Join-Path $ProjectRoot "unpacked"
$DefaultFilePath = Join-Path $DefaultUnpackedDir "beautified.js"

function Get-ModuleIdFromLine {
    param([int]$LineNumber, [string]$FilePath)

    $lineCount = 0
    $reader = [System.IO.StreamReader]::new($FilePath)
    try {
        while ($null -ne ($line = $reader.ReadLine())) {
            $lineCount++
            if ($lineCount -gt $LineNumber) { break }
            if ($line -match '^\s*(\d+):\s*function\s*\(') {
                $reader.Close()
                return [int]$Matches[1]
            }
        }
    } finally {
        $reader.Close()
    }

    $searchStart = [Math]::Max(1, $LineNumber - 500)
    $lines = Get-Content $FilePath -TotalCount $LineNumber -Tail ($LineNumber - $searchStart + 1) -Encoding UTF8
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        if ($lines[$i] -match '^\s*(\d+):\s*function\s*\(') {
            return [int]$Matches[1]
        }
    }
    return $null
}

function Get-ModuleLineRange {
    param([int]$ModuleId, [string]$FilePath)

    $moduleStart = 0
    $moduleEnd = 0
    $lineNum = 0
    $reader = [System.IO.StreamReader]::new($FilePath)
    try {
        while ($null -ne ($line = $reader.ReadLine())) {
            $lineNum++
            if ($line -match '^\s*(\d+):\s*function\s*\(') {
                $currentId = [int]$Matches[1]
                if ($currentId -eq $ModuleId) {
                    $moduleStart = $lineNum
                } elseif ($moduleStart -gt 0 -and $moduleEnd -eq 0) {
                    $moduleEnd = $lineNum - 1
                    break
                }
            }
        }
        if ($moduleStart -gt 0 -and $moduleEnd -eq 0) {
            $moduleEnd = $lineNum
        }
    } finally {
        $reader.Close()
    }
    return @{ Start = $moduleStart; End = $moduleEnd }
}

function Search-UnpackedModules {
    param(
        [string]$UnpackedDir = $DefaultUnpackedDir,
        [string]$Keyword,
        [switch]$Regex,
        [int]$ContextLines = 3,
        [int]$MaxResults = 50
    )

    $filePath = Join-Path $UnpackedDir "beautified.js"
    if (-not (Test-Path $filePath)) {
        Write-Host "[ERROR] File not found: $filePath" -ForegroundColor Red
        return
    }

    Write-Host "`n=== Module Search: '$Keyword' ===" -ForegroundColor Cyan
    Write-Host "File: $filePath" -ForegroundColor Gray
    Write-Host "Mode: $(if($Regex){ 'Regex' }else{ 'Literal' }), Context: ${ContextLines} lines, Max: ${MaxResults} results`n" -ForegroundColor Gray

    $searchParams = @{
        Path = $filePath
        Context = $ContextLines
    }
    if ($Regex) {
        $searchParams['Pattern'] = $Keyword
    } else {
        $searchParams['SimpleMatch'] = $true
        $searchParams['Pattern'] = [regex]::Escape($Keyword)
    }

    $results = Select-String @searchParams | Select-Object -First $MaxResults

    if (-not $results) {
        Write-Host "[INFO] No matches found." -ForegroundColor Yellow
        return
    }

    $table = @()
    foreach ($match in $results) {
        $moduleId = Get-ModuleIdFromLine -LineNumber $match.LineNumber -FilePath $filePath

        $preCtx = ""
        $postCtx = ""
        if ($match.Context) {
            $ctxArr = @($match.Context)
            $preContext = $ctxArr | Where-Object { $_.DisplayPosition -eq 'BeforeContext' } |
                        ForEach-Object { $_. Line.Trim() }
            $postContext = $ctxArr | Where-Object { $_.DisplayPosition -eq 'AfterContext' } |
                         ForEach-Object { $_.Line.Trim() }
            if ($preContext) { $preCtx = $preContext[-1] }
            if ($postContext) { $postCtx = $postContext[0] }
        }

        $previewLine = $match.Line.Trim()
        if ($previewLine.Length -gt 120) {
            $previewLine = $previewLine.Substring(0, 117) + "..."
        }

        $table += [PSCustomObject]@{
            Module   = if($moduleId){ "M$moduleId" }else{ "?" }
            Line     = $match.LineNumber
            Preview  = $previewLine
            Before   = if($preCtx.Length -gt 80){ $preCtx.Substring(0,77)+"..." }else{ $preCtx }
            After    = if($postCtx.Length -gt 80){ $postCtx.Substring(0,77)+"..." }else{ $postCtx }
        }
    }

    $table | Format-Table -AutoSize -Wrap -Property Module, Line, Preview, Before, After
    Write-Host "`n[$($table.Count) results shown (max $MaxResults)]" -ForegroundColor DarkGray
}

function Get-ModuleOverview {
    param(
        [string]$FilePath = $DefaultFilePath
    )

    if (-not (Test-Path $FilePath)) {
        Write-Host "[ERROR] File not found: $FilePath" -ForegroundColor Red
        return
    }

    Write-Host "`n=== Webpack Module Overview ===" -ForegroundColor Cyan
    Write-Host "File: $FilePath" -ForegroundColor Gray

    $fileInfo = Get-Item $FilePath
    $fileSizeMB = [Math]::Round($fileInfo.Length / 1MB, 2)
    Write-Host "Size: $fileSizeMB MB`n" -ForegroundColor Gray

    Write-Host "[1/4] Scanning module definitions..." -ForegroundColor Yellow
    $moduleDefs = Select-String -Path $FilePath -Pattern '^\s*(\d+):\s*function\s*\(' |
                  ForEach-Object {
                      $mid = [int]$Matches[1]
                      [PSCustomObject]@{
                          Id      = $mid
                          Line    = $_.LineNumber
                          RawLine = $_.Line.Trim()
                      }
                  }

    $totalModules = $moduleDefs.Count
    Write-Host "  Total modules found: $totalModules`n" -ForegroundColor Green

    Write-Host "[2/4] Calculating module sizes..." -ForegroundColor Yellow
    $moduleSizes = @()
    for ($i = 0; $i -lt $moduleDefs.Count; $i++) {
        $startLine = $moduleDefs[$i].Line
        if ($i -lt $moduleDefs.Count - 1) {
            $endLine = $moduleDefs[$i + 1].Line - 1
        } else {
            $endLine = (Get-Content $FilePath -Encoding UTF8).Count
        }
        $size = $endLine - $startLine + 1
        $moduleSizes += [PSCustomObject]@{
            ModuleId = $moduleDefs[$i].Id
            Start    = $startLine
            End      = $endLine
            Size     = $size
        }
    }

    Write-Host "[3/4] Size distribution:" -ForegroundColor Yellow
    $tiny   = ($moduleSizes | Where-Object { $_.Size -lt 10 }).Count
    $small  = ($moduleSizes | Where-Object { $_.Size -ge 10 -and $_.Size -lt 50 }).Count
    $medium = ($moduleSizes | Where-Object { $_.Size -ge 50 -and $_.Size -lt 200 }).Count
    $large  = ($moduleSizes | Where-Object { $_.Size -ge 200 -and $_.Size -lt 1000 }).Count
    $huge   = ($moduleSizes | Where-Object { $_.Size -ge 1000 }).Count
    Write-Host "  Tiny   (< 10 lines):    $tiny" -ForegroundColor DarkGray
    Write-Host "  Small  (10-49 lines):   $small" -ForegroundColor DarkGray
    Write-Host "  Medium (50-199 lines):  $medium" -ForegroundColor DarkGray
    Write-Host "  Large  (200-999 lines): $large" -ForegroundColor DarkGray
    Write-Host "  Huge   (>= 1000 lines): $huge`n" -ForegroundColor DarkGray

    Write-Host "[4/4] Top 20 largest modules:" -ForegroundColor Yellow
    $top20 = $moduleSizes | Sort-Object Size -Descending | Select-Object -First 20 |
             ForEach-Object {
                 [PSCustomObject]@{
                     Module   = "M$($_.ModuleId)"
                     Lines    = $_.Size
                     Range    = "$($_.Start)-$($_.End)"
                     SizeKB   = "$([Math]::Round($_.Size * 0.05, 1)) KB (est)"
                 }
             }
    $top20 | Format-Table -AutoSize

    $bigModules = $moduleSizes | Where-Object { $_.Size -ge 200 } | Sort-Object Size -Descending
    if ($bigModules.Count -gt 0) {
        Write-Host "`n--- Business Logic Candidates (>= 200 lines) ---" -ForegroundColor Magenta
        foreach ($mod in $bigModules | Select-Object -First 10) {
            $sampleLines = Get-Content $FilePath -TotalCount $mod.End -Tail 5 -Encoding UTF8
            $hasClass = $false
            $hasExport = $false
            $reader = [System.IO.StreamReader]::new($FilePath)
            try {
                $ln = 0
                while ($null -ne ($rl = $reader.ReadLine())) {
                    $ln++
                    if ($ln -gt $mod.End) { break }
                    if ($ln -ge $mod.Start) {
                        if ($rl -match '\bclass\b\s+\w+') { $hasClass = $true }
                        if ($rl -match '\b(module\.exports|export\s+default|exports\.|\b__webpack_require__\.)\b') { $hasExport = $true }
                    }
                }
            } finally { $reader.Close() }

            $tags = @()
            if ($hasClass) { $tags += "class" }
            if ($hasExport) { $tags += "exports" }
            if ($mod.Size -ge 1000) { $tags += "HUGE" }

            Write-Host "  M$($mod.ModuleId) [$($mod.Size) lines L$($mod.Start)-L$($mod.End)] $(if($tags){ '(' + ($tags -join ',') + ')' })" `
                -ForegroundColor $(if($mod.Size -ge 1000){ 'Red' }elseif($mod.Size -ge 500){ 'Yellow' }else{ 'White' })
        }
    }

    Write-Host "`n--- Summary ---" -ForegroundColor Cyan
    Write-Host "  Total Modules : $totalModules"
    Write-Host "  Huge (1K+)    : $huge"
    Write-Host "  Large (200+)  : $($large + $huge)"
    Write-Host "  File Size     : $fileSizeMB MB"
}

function Find-ModuleByContent {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Keyword,
        [ValidateSet("class","function","string","all")]
        [string]$FileType = "all",
        [string]$FilePath = $DefaultFilePath,
        [int]$MaxResults = 20
    )

    if (-not (Test-Path $FilePath)) {
        Write-Host "[ERROR] File not found: $FilePath" -ForegroundColor Red
        return
    }

    $patternMap = @{
        "class"    = '(?:^|\s)(class\s+\w+)'
        "function" = '(?:^|\s)(function\s+\w*|=>\s*\{|\w+\s*[:=]\s*(async\s*)?function)'
        "string"   = '[''"][^''"]*' + [regex]::Escape($Keyword) + '[^''"]*[''"]'
        "all"      = [regex]::Escape($Keyword)
    }
    $pattern = $patternMap[$FileType]

    Write-Host "`n=== Find Module by Content ===" -ForegroundColor Cyan
    Write-Host "Keyword: '$Keyword'  Type: $FileType  Pattern: $($pattern.Substring(0, [Math]::Min(60, $pattern.Length)))...`n" -ForegroundColor Gray

    $results = Select-String -Path $FilePath -Pattern $pattern | Select-Object -First $MaxResults
    if (-not $results) {
        Write-Host "[INFO] No matches found." -ForegroundColor Yellow
        return
    }

    $moduleHits = @{}
    foreach ($match in $results) {
        $moduleId = Get-ModuleIdFromLine -LineNumber $match.LineNumber -FilePath $FilePath
        if ($moduleId -ne $null) {
            if (-not $moduleHits.ContainsKey($moduleId)) {
                $moduleHits[$moduleId] = @{
                    Count = 0
                    Lines = @()
                    FirstLine = $match.LineNumber
                }
            }
            $moduleHits[$moduleId].Count++
            if ($moduleHits[$moduleId].Lines.Count -lt 3) {
                $preview = $match.Line.Trim()
                if ($preview.Length -gt 100) { $preview = $-preview.Substring(0, 97) + "..." }
                $moduleHits[$moduleId].Lines += "L$($match.LineNumber): $preview"
            }
        }
    }

    $sorted = $moduleHits.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending

    Write-Host "Found in $($sorted.Count) modules:`n" -ForegroundColor Green
    foreach ($entry in $sorted) {
        $mid = $entry.Key
        $info = $entry.Value
        $range = Get-ModuleLineRange -ModuleId $mid -FilePath $FilePath
        $modSize = if ($range.Start -gt 0) { $range.End - $range.Start + 1 } else { "?" }

        Write-Host "  M$mid ($($info.Count) hits, ~${modSize} lines, L$($info.FirstLine))" -ForegroundColor White
        foreach ($ctx in $info.Lines) {
            Write-Host "    $ctx" -ForegroundColor DarkGray
        }
    }

    Write-Host "`n[$($sorted.Count) modules, $($results.Count) total hits]" -ForegroundColor DarkGray
}

if ($Mode -eq "Search" -and $Keyword) {
    Search-UnpackedModules -Keyword $Keyword -Regex:$Regex -ContextLines $ContextLines -MaxResults $MaxResults
} elseif ($Mode -eq "Overview") {
    Get-ModuleOverview
} elseif ($Mode -eq "Find" -and $Keyword) {
    Find-ModuleByContent -Keyword $Keyword -FileType $FileType
} else {
    Write-Host @"
module-search.ps1 — Webpack Module Search Tool

Usage:
  .\module-search.ps1 -Keyword "text" [-Regex] [-ContextLines N] [-MaxResults N]
  .\module-search.ps1 -Mode Overview
  .\module-search.ps1 -Mode Find -Keyword "text" [-FileType class|function|string|all]

Modes:
  Search  - Search keyword across all modules (default)
  Overview - Full module statistics report
  Find    - Quick module location by content type

Examples:
  .\module-search.ps1 -Keyword "PlanItemStreamParser"
  .\module-search.ps1 -Keyword "class\s+\w+Stream" -Regex
  .\module-search.ps1 -Mode Overview
  .\module-search.ps1 -Mode Find -Keyword "command" -FileType class
"@ -ForegroundColor Cyan
}
