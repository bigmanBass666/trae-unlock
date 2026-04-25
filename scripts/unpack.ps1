<#
.SYNOPSIS
    Unpack (beautify) Trae's minified index.js for analysis and patching
.DESCRIPTION
    Reads the compressed ai-modules-chat/dist/index.js, beautifies it using
    js-beautify, and outputs a readable file to the unpacked directory.
    Also provides tool availability checks and stats reporting.
.EXAMPLE
    .\unpack.ps1
    Unpack with default paths
.EXAMPLE
    .\unpack.ps1 -Force
    Overwrite existing output without prompting
.EXAMPLE
    .\unpack.ps1 -SourcePath "C:\custom\path\index.js"
.EXAMPLE
    Test-ToolAvailability
    Check which unpacking tools are installed
.EXAMPLE
    Get-UnpackStats
    Show stats of last unpacked file
#>

$ErrorActionPreference = "Stop"

function Write-ColorOutput {
    param([string]$Msg, [string]$Color = "White")
    Write-Host $Msg -ForegroundColor $Color
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

$DefaultSource = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$DefaultOutputDir = Join-Path $RootDir "unpacked"

function Test-ToolAvailability {
    <#
    .SYNOPSIS
        Check availability of unpacking tools
    #>
    $tools = @(
        @{ Name = "node";       Cmd = "node";        TestArg = "--version" },
        @{ Name = "js-beautify"; Cmd = "js-beautify"; TestArg = "--version" },
        @{ Name = "webcrack";   Cmd = "webcrack";    TestArg = "--version" },
        @{ Name = "reverse-sourcemap"; Cmd = "reverse-sourcemap"; TestArg = "--version" }
    )

    Write-ColorOutput "`n[unpack] Tool Availability Check" "Cyan"
    Write-ColorOutput ("{0,-22} {1,-10} {2}" -f "Tool", "Status", "Version") "White"
    Write-ColorOutput ("- * 22) + (- * 10) + (- * 30)" -replace ".", "-") "DarkGray"

    $results = @()
    foreach ($tool in $tools) {
        try {
            $output = & $tool.Cmd $tool.TestArg 2>&1 | Out-String
            $exitCode = $LASTEXITCODE
            if ($exitCode -eq 0) {
                $version = ($output.Trim() -split "`n")[0]
                $status = "OK"
                $color = "Green"
                $results += [PSCustomObject]@{
                    Tool    = $tool.Name
                    Status  = $status
                    Version = $version
                    Path    = (Get-Command $tool.Cmd).Source
                }
            } else {
                $status = "FAIL"
                $color = "Red"
                $results += [PSCustomObject]@{
                    Tool    = $tool.Name
                    Status  = $status
                    Version = "-"
                    Path    = "-"
                }
            }
        } catch {
            $status = "MISSING"
            $color = "DarkGray"
            $results += [PSCustomObject]@{
                Tool    = $tool.Name
                Status  = $status
                Version = "-"
                Path    = "-"
            }
        }
        $displayVer = if ($status -eq "OK") { $version } else { "-" }
        Write-ColorOutput ("{0,-22} {1,-10} {2}" -f $tool.Name, $status, $displayVer) $color
    }

    $okCount = ($results | Where-Object { $_.Status -eq "OK" }).Count
    $summaryColor = if ($okCount -ge 2) { "Green" } else { "Yellow" }
    Write-ColorOutput "`n  Summary: $okCount / $($tools.Count) tools available" $summaryColor

    return $results
}

function Get-UnpackStats {
    <#
    .SYNOPSIS
        Read stats from an already-unpacked beautified file
    .PARAMETER Path
        Path to the beautified file (default: unpacked/index.beautified.js)
    .PARAMETER OutputDir
        Directory containing the beautified file
    #>
    param(
        [string]$Path = "",
        [string]$OutputDir = $DefaultOutputDir
    )

    if (-not $Path) {
        $Path = Join-Path $OutputDir "index.beautified.js"
    }

    if (-not [System.IO.File]::Exists($Path)) {
        Write-ColorOutput "[ERROR] File not found: $Path" "Red"
        return $null
    }

    $fi = New-Object System.IO.FileInfo($Path)
    $lines = [System.IO.File]::ReadAllLines($Path)
    $lineCount = $lines.Length
    $sizeMB = [math]::Round($fi.Length / 1MB, 2)

    $stats = [PSCustomObject]@{
        Path         = $Path
        SizeBytes    = $fi.Length
        SizeMB       = $sizeMB
        LineCount    = $lineCount
        LastModified = $fi.LastWriteTime
        Created      = $fi.CreationTime
    }

    Write-ColorOutput "`n[unpack] File Statistics: $([System.IO.Path]::GetFileName($Path))" "Cyan"
    Write-ColorOutput ("  Size:          {0} MB ({1} bytes)" -f $stats.SizeMB, $stats.SizeBytes) "White"
    Write-ColorOutput ("  Lines:         {0:N0}" -f $stats.LineCount) "White"
    Write-ColorOutput ("  Last Modified: {0}" -f $stats.LastModified) "Gray"
    Write-ColorOutput ("  Created:       {0}" -f $stats.Created) "Gray"

    return $stats
}

function Unpack-TraeIndex {
    <#
    .SYNOPSIS
        Beautify Trae's minified index.js using js-beautify
    .PARAMETER SourcePath
        Path to the minified source index.js
    .PARAMETER OutputDir
        Directory to write beautified output
    .PARAMETER Force
        Overwrite existing output without prompting
    #>
    param(
        [string]$SourcePath = $DefaultSource,
        [string]$OutputDir = $DefaultOutputDir,
        [switch]$Force
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    Write-ColorOutput "[unpack] Starting unpack process..." "Cyan"
    Write-ColorOutput ("  Source: {0}" -f $SourcePath) "Gray"

    if (-not [System.IO.File]::Exists($SourcePath)) {
        Write-ColorOutput "[ERROR] Source file not found: $SourcePath" "Red"
        return $false
    }

    $srcFi = New-Object System.IO.FileInfo($SourcePath)
    $srcSizeMB = [math]::Round($srcFi.Length / 1MB, 2)

    if ($srcSizeMB -lt 9 -or $srcSizeMB -gt 11) {
        Write-ColorOutput ("[WARN] Source file size ({0} MB) is outside expected range (9-11 MB)" -f $srcSizeMB) "Yellow"
        Write-ColorOutput "  This may not be the correct file or version has changed." "Yellow"
        if (-not $Force) {
            $confirm = Read-Host "  Continue anyway? (y/N)"
            if ($confirm -ne "y") {
                Write-ColorOutput "  Aborted." "Yellow"
                return $false
            }
        }
    } else {
        Write-ColorOutput ("  Size: {0} MB (within expected range)" -f $srcSizeMB) "Green"
    }

    if (-not [System.IO.Directory]::Exists($OutputDir)) {
        [System.IO.Directory]::CreateDirectory($OutputDir) | Out-Null
        Write-ColorOutput ("  Created output dir: {0}" -f $OutputDir) "Gray"
    }

    $outFile = Join-Path $OutputDir "index.beautified.js"

    if ([System.IO.File]::Exists($outFile) -and -not $Force) {
        Write-ColorOutput ("  Output already exists: {0}" -f $outFile) "Yellow"
        $confirm = Read-Host "  Overwrite? (y/N)"
        if ($confirm -ne "y") {
            Write-ColorOutput "  Aborted." "Yellow"
            return $false
        }
    }

    Write-ColorOutput "`n[unpack] Running js-beautify..." "Cyan"

    try {
        & js-beautify --indent-size 4 --preserve-newlines true --max-preserve-newlines 2 `
            --space-in-paren false --break-chained-methods false `
            "$SourcePath" -o "$outFile" 2>&1 | ForEach-Object { Write-ColorOutput "  $_" "DarkGray" }

        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "[ERROR] js-beautify failed with exit code $LASTEXITCODE" "Red"
            return $false
        }
    } catch {
        Write-ColorOutput "[ERROR] js-beautify execution failed: $_" "Red"
        return $false
    }

    $sw.Stop()
    $elapsed = [math]::Round($sw.Elapsed.TotalSeconds, 1)

    if (-not [System.IO.File]::Exists($outFile)) {
        Write-ColorOutput "[ERROR] Output file was not created" "Red"
        return $false
    }

    $stats = Get-UnpackStats -Path $outFile

    $ratio = [math]::Round(($stats.SizeBytes / $srcFi.Length), 2)
    Write-ColorOutput "`n[unpack] Done!" "Green"
    Write-ColorOutput ("  Compression ratio: {0}:1 (minified -> beautified)" -f $ratio) "White"
    Write-ColorOutput ("  Time elapsed:     {0}s" -f $elapsed) "White"
    Write-ColorOutput ("  Output:           {0}" -f $outFile) "Green"

    return $true
}

if ($MyInvocation.InvocationName -eq ".") {
    Write-ColorOutput "`n[unpack] Module loaded. Available functions:" "Cyan"
    Write-ColorOutput "  Unpack-TraeIndex       - Beautify index.js" "White"
    Write-ColorOutput "  Test-ToolAvailability   - Check tool status" "White"
    Write-ColorOutput "  Get-UnpackStats         - View file stats" "White"
} elseif (-not ($MyInvocation.Line -match '\.')) {
    Unpack-TraeIndex @args
}
