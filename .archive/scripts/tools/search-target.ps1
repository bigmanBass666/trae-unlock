<#
.SYNOPSIS
Unified search tool for the Trae mod project's target minified JS file.
Supports plain text search (PowerShell) and AST structural search (ast-grep).
#>

param(
    [string]$Pattern,
    [string]$AstPattern,
    [int]$Context = 200,
    [switch]$AllMatches,
    [int]$MaxMatches = 10,
    [int]$StartOffset = 0
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptDir "..\..")
$DefsFile = Join-Path $ProjectRoot "patches\definitions.json"

if (-not (Test-Path $DefsFile)) {
    Write-Host "ERROR: definitions.json not found at $DefsFile" -ForegroundColor Red
    exit 1
}

$defs = Get-Content $DefsFile -Raw | ConvertFrom-Json
$targetFile = $defs.meta.target_file

if (-not $targetFile -or -not (Test-Path $targetFile)) {
    Write-Host "ERROR: Target file not found: $targetFile" -ForegroundColor Red
    exit 1
}

if ($Pattern -and $AstPattern) {
    Write-Host "ERROR: Specify only one of -Pattern or -AstPattern, not both." -ForegroundColor Red
    exit 1
}

if (-not $Pattern -and -not $AstPattern) {
    Write-Host ""
    Write-Host "Usage: search-target.ps1 [-Pattern <text> | -AstPattern <ast>] [options]" -ForegroundColor White
    Write-Host ""
    Write-Host "Search methods (choose one):" -ForegroundColor Yellow
    Write-Host "  -Pattern <text>       Plain text search via PowerShell IndexOf"
    Write-Host "  -AstPattern <ast>     AST structural search via ast-grep"
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -Context <int>        Context chars around match (text search, default: 200)"
    Write-Host "  -AllMatches           Show all matches (no limit)"
    Write-Host "  -MaxMatches <int>     Max matches to show (default: 10)"
    Write-Host "  -StartOffset <int>    Start searching from offset (text search, default: 0)"
    Write-Host ""
    Write-Host "Target: $targetFile" -ForegroundColor Gray
    exit 1
}

$effectiveMax = if ($AllMatches) { [int]::MaxValue } else { $MaxMatches }

if ($Pattern) {
    Write-Host "Searching (text): " -NoNewline -ForegroundColor White
    Write-Host $Pattern -ForegroundColor Green
    Write-Host "Target: $targetFile" -ForegroundColor Gray
    Write-Host ""

    $content = [System.IO.File]::ReadAllText($targetFile)
    $found = 0
    $searchFrom = $StartOffset

    while ($found -lt $effectiveMax) {
        $idx = $content.IndexOf($Pattern, $searchFrom)
        if ($idx -eq -1) { break }

        $found++
        $start = [Math]::Max(0, $idx - $Context)
        $end = [Math]::Min($content.Length, $idx + $Pattern.Length + $Context)
        $contextStr = $content.Substring($start, $end - $start)

        Write-Host "[$found] Offset: " -NoNewline -ForegroundColor White
        Write-Host $idx -ForegroundColor Cyan

        $prefix = if ($start -gt 0) { "..." } else { "" }
        $suffix = if ($end -lt $content.Length) { "..." } else { "" }

        Write-Host "    " -NoNewline
        Write-Host $prefix -ForegroundColor Gray -NoNewline
        Write-Host $contextStr -ForegroundColor Gray -NoNewline
        Write-Host $suffix -ForegroundColor Gray
        Write-Host ""

        $searchFrom = $idx + 1
    }

    if ($found -eq 0) {
        Write-Host "No matches found." -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Total: $found match(es)" -ForegroundColor Green
    exit 0
}

if ($AstPattern) {
    Write-Host "Searching (AST): " -NoNewline -ForegroundColor White
    Write-Host $AstPattern -ForegroundColor Green
    Write-Host "Target: $targetFile" -ForegroundColor Gray
    Write-Host ""

    $tmpFile = Join-Path $env:TEMP "ast-grep-result-$PID.json"

    try {
        ast-grep -p $AstPattern --lang js --json $targetFile | Out-File -FilePath $tmpFile -Encoding utf8

        $raw = Get-Content $tmpFile -Raw
        $results = $raw | ConvertFrom-Json
        if ($results -isnot [System.Array]) {
            $results = @($results)
        }

        if ($results.Count -eq 0) {
            Write-Host "No matches found." -ForegroundColor Yellow
            exit 1
        }

        $shown = 0
        foreach ($match in $results) {
            if ($shown -ge $effectiveMax) { break }
            $shown++

            $range = $match.range
            $startByte = [int]$range.byteOffset.start
            $endByte = [int]$range.byteOffset.end
            $matchedText = $match.text
            if ($matchedText.Length -gt 100) {
                $matchedText = $matchedText.Substring(0, 100) + "..."
            }

            Write-Host "[$shown] Offset: " -NoNewline -ForegroundColor White
            Write-Host "$startByte-$endByte" -ForegroundColor Cyan

            Write-Host "    " -NoNewline
            Write-Host $matchedText -ForegroundColor Green
            Write-Host ""
        }

        Write-Host "Total: $shown match(es) shown (of $($results.Count))" -ForegroundColor Green
        exit 0
    }
    finally {
        if (Test-Path $tmpFile) {
            Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
        }
    }
}
