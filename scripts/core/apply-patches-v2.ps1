<#
.SYNOPSIS
    Apply patches to Trae AI module using beautify->modify->minify workflow (v2)
.DESCRIPTION
    New version of patch application that works with Trae v3.3.55+ by:
    1. Applying text-based patches on beautified.js (readable format)
    2. Minifying the patched file using terser
    3. Replacing the original index.mjs with the new version
    4. Verifying output integrity
.PARAMETER PatchId
    ID of a single patch to apply (from definitions.json)
.PARAMETER All
    Apply all enabled patches
.PARAMETER DryRun
    Simulate the process without modifying any files
.PARAMETER Verbose
    Show detailed output including file contents and diffs
.PARAMETER Config
    Path to alternative terser config file (default: scripts/config/minify-config.json)
.EXAMPLE
    .\apply-patches-v2.ps1 -PatchId efh-resume-list -Verbose
.EXAMPLE
    .\apply-patches-v2.ps1 -All
.EXAMPLE
    .\apply-patches-v2.ps1 -PatchId auto-confirm-commands -DryRun
#>

param(
    [string]$PatchId = "",
    [switch]$All,
    [switch]$DryRun,
    [switch]$Verbose,
    [string]$Config = ""
)

$ErrorActionPreference = "Stop"

# ============================================================
# Key Path Constants
# ============================================================
$script:ProjectRoot        = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:DefinitionsPath    = Join-Path $script:ProjectRoot "patches\definitions.json"
$script:BeautifiedPath     = Join-Path $script:ProjectRoot "unpacked\index.beautified.js"
$script:TargetMjsPath      = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.mjs"
$script:BackupDir          = Join-Path $script:ProjectRoot "backups"
$script:ManifestPath       = Join-Path $script:BackupDir "manifest.json"
$script:DefaultConfigPath  = Join-Path $script:ProjectRoot "scripts\config\minify-config.json"
$script:TempDir            = Join-Path $env:TEMP "trae-patch-v2"

# ============================================================
# Function 1: Write-Log - Timestamped logging to console + file
# ============================================================
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$LogFile = ""
    )

    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [$Level] $Message"

    # Console color mapping
    $colorMap = @{
        "INFO"    = "White"
        "SUCCESS" = "Green"
        "WARN"    = "Yellow"
        "ERROR"   = "Red"
        "DEBUG"   = "DarkGray"
    }
    $fg = if ($colorMap[$Level]) { $colorMap[$Level] } else { "White" }
    Write-Host $line -ForegroundColor $fg

    # Optional file logging
    if ($LogFile -and (Test-Path (Split-Path $LogFile -Parent))) {
        Add-Content -Path $LogFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
    }
}

# ============================================================
# Function 2: Read-DefinitionsJson - Parse definitions.json
# ============================================================
function Read-DefinitionsJson {
    if (-not (Test-Path $script:DefinitionsPath)) {
        throw "definitions.json not found at: $($script:DefinitionsPath)"
    }

    try {
        $raw = [System.IO.File]::ReadAllText($script:DefinitionsPath)
        $data = $raw | ConvertFrom-Json

        # Validate structure
        if (-not $data.meta -or -not $data.patches) {
            throw "Invalid definitions.json: missing 'meta' or 'patches' root keys"
        }

        return $data
    }
    catch {
        throw "Failed to parse definitions.json: $($_.Exception.Message)"
    }
}

# ============================================================
# Function 3: Apply-SinglePatch - Core string-level patching
# ============================================================
function Apply-SinglePatch {
    param(
        [PSCustomObject]$Patch,
        [string]$Content,
        [bool]$VerboseMode = $false
    )

    $result = @{
        Success    = $false
        Error      = ""
        LineNumber = 0
        Content    = $Content
    }

    $pid_label = $Patch.id
    $anchor    = $Patch.anchor
    $findOrig  = $Patch.find_original
    $replace   = $Patch.replace_with
    $fingerprint = ""

    if ($Patch.PSObject.Properties.Name -contains "check_fingerprint") {
        $fingerprint = $Patch.check_fingerprint
    }

    Write-Log "Applying patch: $pid_label" "INFO"

    $anchorFound = $false
    $anchorLineNum = 0

    if ($Content.Contains($anchor)) {
        $anchorFound = $true
        $idx = $Content.IndexOf($anchor)
        $before = $Content.Substring(0, $idx)
        $anchorLineNum = ($before -split "`n").Count
        if ($VerboseMode) {
            Write-Log "  Anchor located near line $anchorLineNum" "DEBUG"
        }
    }

    if (-not $anchorFound) {
        $result.Error = "Anchor not found in content: '$($anchor.Substring(0, [Math]::Min(60, $anchor.Length)))...'"
        Write-Log "  FAIL: $($result.Error)" "ERROR"
        return $result
    }

    # Step 2: Verify find_original exists in content
    if (-not $Content.Contains($findOrig)) {
        $result.Error = "find_original not found near anchor. Source code may have changed."
        Write-Log "  FAIL: $($result.Error)" "ERROR"
        return $result
    }

    # Step 3: Execute replacement (string level, not file)
    try {
        $newContent = $Content.Replace($findOrig, $replace)

        # Guard against no-op replace (identical strings)
        if ($newContent -eq $Content) {
            $result.Error = "Replacement produced identical content (no change detected)"
            Write-Log "  WARN: $($result.Error)" "WARN"
            return $result
        }

        $result.Content = $newContent
    }
    catch {
        $result.Error = "String replacement failed: $($_.Exception.Message)"
        Write-Log "  FAIL: $($result.Error)" "ERROR"
        return $result
    }

    # Step 4: Verify check_fingerprint exists in result
    if ($fingerprint) {
        if (-not $result.Content.Contains($fingerprint)) {
            $result.Error = "Fingerprint verification FAILED after replacement"
            Write-Log "  FAIL: $($result.Error)" "ERROR"
            # Revert content
            $result.Content = $Content
            return $result
        }
        if ($VerboseMode) {
            Write-Log "  Fingerprint verified OK" "DEBUG"
        }
    }

    $result.Success = $true
    $result.LineNumber = $anchorLineNum
    Write-Log "Patch applied at line $anchorLineNum" "SUCCESS"

    return $result
}

# ============================================================
# Function 4: Invoke-TerserMinify - Run terser compression
# ============================================================
function Invoke-TerserMinify {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [string]$ConfigPath,
        [int]$TimeoutSeconds = 120
    )

    $result = @{
        Success       = $false
        Error         = ""
        ExitCode      = -1
        StdOut        = ""
        StdErr        = ""
        InputSizeMB   = 0
        OutputSizeMB  = 0
        DurationSec   = 0
    }

    if (-not (Test-Path $InputPath)) {
        $result.Error = "Input file not found: $InputPath"
        return $result
    }

    if (-not (Test-Path $ConfigPath)) {
        $result.Error = "Terser config not found: $ConfigPath"
        return $result
    }

    $inputFile = Get-Item $InputPath
    $result.InputSizeMB = [Math]::Round($inputFile.Length / 1MB, 2)

    # Build terser command
    $terserCmd = "npx terser `"$InputPath`" -c -m -o `"$OutputPath`" --config-file `"$ConfigPath`""

    Write-Log "Running terser minification..." "INFO"

    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo.FileName               = "powershell.exe"
        $proc.StartInfo.Arguments              = "-NoProfile -Command `$OutputEncoding=[System.Text.Encoding]::UTF8; $terserCmd 2>&1"
        $proc.StartInfo.UseShellExecute        = $false
        $proc.StartInfo.RedirectStandardOutput = $true
        $proc.StartInfo.RedirectStandardError  = $true
        $proc.StartInfo.CreateNoWindow         = $true
        $proc.Start() | Out-Null

        # Read output async to avoid deadlock
        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $stderrTask = $proc.StandardError.ReadToEndAsync()

        $completed = $proc.WaitForExit($TimeoutSeconds * 1000)

        $sw.Stop()
        $result.DurationSec = [Math]::Round($sw.Elapsed.TotalSeconds, 1)

        if (-not $completed) {
            $proc.Kill()
            $result.Error = "Terser timed out after ${TimeoutSeconds}s"
            Write-Log "  FAIL: $($result.Error)" "ERROR"
            return $result
        }

        $result.ExitCode = $proc.ExitCode
        $result.StdOut   = $stdoutTask.Result
        $result.StdErr   = $stderrTask.Result

        if ($result.ExitCode -ne 0) {
            $errMsg = if ($result.StdErr) { $result.StdErr.Trim() } else { "exit code $($result.ExitCode)" }
            $result.Error = "Terser failed: $errMsg"
            Write-Log "  FAIL: $($result.Error)" "ERROR"
            return $result
        }

        if (Test-Path $OutputPath) {
            $outFile = Get-Item $OutputPath
            $result.OutputSizeMB = [Math]::Round($outFile.Length / 1MB, 2)
        }

        $result.Success = $true
        Write-Log "Minification complete ($($result.InputSizeMB)MB -> $($result.OutputSizeMB)MB, $($result.DurationSec)s)" "SUCCESS"
    }
    catch {
        $result.Error = "Terser execution exception: $($_.Exception.Message)"
        Write-Log "  FAIL: $($result.Error)" "ERROR"
    }

    return $result
}

# ============================================================
# Function 5: Backup-OriginalFile - Create timestamped backup
# ============================================================
function Backup-OriginalFile {
    param(
        [string]$SourcePath
    )

    $result = @{
        Success    = $false
        Error      = ""
        BackupPath = ""
    }

    if (-not (Test-Path $SourcePath)) {
        $result.Error = "Source file not found: $SourcePath"
        return $result
    }

    # Ensure backup directory exists
    if (-not (Test-Path $script:BackupDir)) {
        New-Item -ItemType Directory -Path $script:BackupDir -Force | Out-Null
    }

    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupName = "index.mjs.pre-v2-${ts}.mjs"
    $backupPath = Join-Path $script:BackupDir $backupName

    try {
        Copy-Item -Path $SourcePath -Destination $backupPath -Force
        $result.Success    = $true
        $result.BackupPath = $backupPath
        Write-Log "Backup created: $backupName" "INFO"
    }
    catch {
        $result.Error = "Backup failed: $($_.Exception.Message)"
        Write-Log "  FAIL: $($result.Error)" "ERROR"
    }

    return $result
}

# ============================================================
# Function 6: Update-Manifest - Maintain manifest.json
# ============================================================
function Update-Manifest {
    param(
        [string]$BackupPath,
        [array]$PatchesApplied,
        [string]$Operation = "apply-v2"
    )

    $manifest = $null
    $manifestExists = Test-Path $script:ManifestPath

    # Load existing or create new
    if ($manifestExists) {
        try {
            $raw = [System.IO.File]::ReadAllText($script:ManifestPath)
            $manifest = $raw | ConvertFrom-Json
        }
        catch {
            Write-Log "Manifest corrupt, creating fresh: $($_.Exception.Message)" "WARN"
            $manifest = $null
        }
    }

    if (-not $manifest) {
        $manifest = @{
            version  = "2.0"
            entries  = @()
        }
    }

    # Ensure entries is an array
    if (-not $manifest.entries) {
        $manifest.entries = @()
    }

    # Compute MD5s
    $sourceMd5 = ""
    $backupMd5 = ""
    try {
        $sourceMd5 = (Get-FileHash -Path $script:TargetMjsPath -Algorithm MD5).Hash
        if (Test-Path $BackupPath) {
            $backupMd5 = (Get-FileHash -Path $BackupPath -Algorithm MD5).Hash
        }
    }
    catch {
        Write-Log "MD5 computation warning: $($_.Exception.Message)" "WARN"
    }

    $ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

    $entry = @{
        timestamp      = $ts
        operation      = $Operation
        patches_applied = @($PatchesApplied)
        source_md5     = $sourceMd5
        backup_md5     = $backupMd5
        backup_path    = $BackupPath
    }

    # Prepend newest entry
    $manifest.entries = @(, $entry) + @($manifest.entries)

    # Keep only last 10 entries
    if ($manifest.entries.Count -gt 10) {
        $manifest.entries = $manifest.entries[0..9]
    }

    # Write back
    try {
        $jsonStr = $manifest | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText($script:ManifestPath, $jsonStr, (New-Object System.Text.UTF8Encoding $false))
        Write-Log "Manifest updated ($($manifest.entries.Count) entries)" "INFO"
    }
    catch {
        Write-Log "Manifest write failed: $($_.Exception.Message)" "WARN"
    }
}

# ============================================================
# Function 7: Test-FileIntegrity - Validate output file
# ============================================================
function Test-FileIntegrity {
    param([string]$FilePath)

    $result = @{
        Pass   = $false
        Issues = @()
        Md5    = ""
        SizeMB = 0
    }

    # Check existence
    if (-not (Test-Path $FilePath)) {
        $result.Issues += "File does not exist: $FilePath"
        return $result
    }

    $fi = Get-Item $FilePath
    $result.SizeMB = [Math]::Round($fi.Length / 1MB, 2)

    # Size check (8-20MB range for index.mjs)
    if ($fi.Length -lt 8MB) {
        $result.Issues += "File too small: $($result.SizeMB)MB (expected >= 8MB)"
    }
    elseif ($fi.Length -gt 20MB) {
        $result.Issues += "File too large: $($result.SizeMB)MB (expected <= 20MB)"
    }

    # MD5
    try {
        $result.Md5 = (Get-FileHash -Path $FilePath -Algorithm MD5).Hash
    }
    catch {
        $result.Issues += "MD5 computation failed: $($_.Exception.Message)"
    }

    # node --check syntax validation
    try {
        $syntaxProc = New-Object System.Diagnostics.Process
        $syntaxProc.StartInfo.FileName               = "node.exe"
        $syntaxProc.StartInfo.Arguments              = "--check `"$FilePath`""
        $syntaxProc.StartInfo.UseShellExecute        = $false
        $syntaxProc.StartInfo.RedirectStandardError  = $true
        $syntaxProc.StartInfo.RedirectStandardOutput = $true
        $syntaxProc.StartInfo.CreateNoWindow         = $true
        $syntaxProc.Start() | Out-Null
        $syntaxProc.WaitForExit(30000) | Out-Null

        if ($syntaxProc.ExitCode -ne 0) {
            $errText = $syntaxProc.StandardError.ReadToEnd().Trim()
            $result.Issues += "JS syntax check failed (node --check): exit code $($syntaxProc.ExitCode) - $errText"
        }
    }
    catch {
        $result.Issues += "Syntax check error: $($_.Exception.Message)"
    }

    $result.Pass = ($result.Issues.Count -eq 0)
    return $result
}

# ============================================================
# Function 8: Format-ResultsTable - Pretty-print results
# ============================================================
function Format-ResultsTable {
    param([array]$Results)

    $maxIdLen = 28
    $maxStatusLen = 10
    $separatorWidth = $maxIdLen + $maxStatusLen + 7  # "| " + id + " | " + status + " |"

    Write-Host ""
    Write-Host ("=" * $separatorWidth) -ForegroundColor White
    Write-Host "Patch Application Results (v2)" -ForegroundColor White
    Write-Host ("=" * $separatorWidth) -ForegroundColor White

    # Header
    $headerId = "{0,-$maxIdLen}" -f "ID"
    $headerStatus = "{0,-$maxStatusLen}" -f "Status"
    Write-Host "| $headerId | $headerStatus |" -ForegroundColor White
    Write-Host ("-" * $separatorWidth) -ForegroundColor DarkGray

    foreach ($r in $Results) {
        $idCol  = "{0,-$maxIdLen}" -f $r.Id
        $statusColor = switch ($r.Status) {
            "SUCCESS" { "Green"; break }
            "FAIL"    { "Red"; break }
            "SKIP"    { "DarkGray"; break }
            default   { "Yellow" }
        }
        $statusCol = "{0,-$maxStatusLen}" -f $r.Status
        Write-Host "| $idCol | $statusCol |" -ForegroundColor $statusColor
    }

    Write-Host ("=" * $separatorWidth) -ForegroundColor White
    Write-Host ""
}


# ============================================================
# MAIN WORKFLOW
# ============================================================

# --- Step 1: Parameter resolution & initialization ---
$configPath = if ($Config) { $Config } else { $script:DefaultConfigPath }
$logFile = Join-Path $script:TempDir "apply-log-$((Get-Date -Format 'yyyyMMdd-HHmmss')).log"

if (-not (Test-Path $script:TempDir)) {
    New-Item -ItemType Directory -Path $script:TempDir -Force | Out-Null
}

# --- Step 2: Banner ---
Write-Host ""
Write-Host ("=" * 56) -ForegroundColor Cyan
Write-Host "  apply-patches v2  |  beautify -> modify -> minify" -ForegroundColor Cyan
Write-Host ("=" * 56) -ForegroundColor Cyan
Write-Host ""
if ($DryRun) {
    Write-Log "*** DRY RUN MODE - No files will be modified ***" "WARN"
}
Write-Log "Project root : $($script:ProjectRoot)" "INFO"
Write-Log "Target mjs   : $($script:TargetMjsPath)" "INFO"
Write-Log "Beautified   : $($script:BeautifiedPath)" "INFO"
Write-Log "Config       : $configPath" "INFO"
Write-Host ""

# --- Step 3: Read definitions.json ---
try {
    $defData = Read-DefinitionsJson
    $allPatches = @($defData.patches)
    Write-Log "Loaded $($allPatches.Count) patch definitions from definitions.json" "INFO"
    Write-Log "Target version: $($defData.meta.target_version)" "INFO"
}
catch {
    Write-Log $_.Exception.Message "ERROR"
    exit 2
}

# --- Step 4: Determine which patches to apply ---
$targetPatches = @()

if ($All) {
    $targetPatches = @($allPatches | Where-Object { $_.enabled -eq $true })
    Write-Log "Mode: ALL enabled patches ($($targetPatches.Count) selected)" "INFO"
}
elseif ($PatchId) {
    $found = @($allPatches | Where-Object { $_.id -eq $PatchId })
    if ($found.Count -eq 0) {
        Write-Log "Patch ID not found: $PatchId" "ERROR"
        exit 2
    }
    if ($found[0].enabled -eq $false) {
        Write-Log "Patch '$PatchId' is DISABLED in definitions.json. Use -Force to override." "WARN"
    }
    $targetPatches = $found
    Write-Log "Mode: Single patch '$PatchId'" "INFO"
}
else {
    Write-Log "No patch specified. Use -PatchId <id> or -All." "ERROR"
    Write-Log "Available enabled patches:" "INFO"
    foreach ($p in $allPatches | Where-Object { $_.enabled }) {
        Write-Log "  $($p.id)  ::  $($p.name)" "INFO"
    }
    exit 2
}

# --- Step 5: Read beautified.js into memory ---
if (-not (Test-Path $script:BeautifiedPath)) {
    Write-Log "Beautified file not found: $($script:BeautifiedPath)" "ERROR"
    Write-Log "Run unpack.ps1 first to generate it." "WARN"
    exit 2
}

Write-Log "Reading beautified.js ..." "INFO"
try {
    # Use .NET StreamReader for large files (>100MB potential)
    $sr = New-Object System.IO.StreamReader($script:BeautifiedPath, (New-Object System.Text.UTF8Encoding $false))
    $workingContent = $sr.ReadToEnd()
    $sr.Close()

    $contentSizeMB = [Math]::Round($workingContent.Length / 1MB, 2)
    Write-Log "Beautified content loaded: ${contentSizeMB} MB ($($workingContent.Length) chars)" "INFO"
}
catch {
    Write-Log "Failed to read beautified.js: $($_.Exception.Message)" "ERROR"
    exit 2
}

# --- Step 6: Show target info (unless DryRun) ---
if (-not $DryRun) {
    if (Test-Path $script:TargetMjsPath) {
        $targetFi = Get-Item $script:TargetMjsPath
        Write-Log "Target file exists: $([Math]::Round($targetFi.Length / 1MB, 2)) MB" "INFO"
    }
    else {
        Write-Log "WARNING: Target mjs file does NOT exist yet: $($script:TargetMjsPath)" "WARN"
    }
}

# --- Step 7: Apply patches one by one ---
$results = @()
$successCount = 0
$failCount    = 0
$skipCount    = 0

foreach ($patch in $targetPatches) {
    # Skip disabled patches (unless single mode where user explicitly asked)
    if ($patch.enabled -eq $false -and -not $PatchId) {
        $results += @{ Id = $patch.id; Status = "DISABLED" }
        $skipCount++
        continue
    }

    # Check if already applied via fingerprint
    $fp = ""
    if ($patch.PSObject.Properties.Name -contains "check_fingerprint") {
        $fp = $patch.check_fingerprint
    }
    $detectStr = if ($fp) { $fp } else { $patch.replace_with }

    if ($workingContent.Contains($detectStr)) {
        Write-Log "$($patch.id): Already applied, skipping" "INFO"
        $results += @{ Id = $patch.id; Status = "SKIP" }
        $skipCount++
        continue
    }

    # Apply the patch
    $patchResult = Apply-SinglePatch -Patch $patch -Content $workingContent -VerboseMode:$Verbose

    if ($patchResult.Success) {
        $workingContent = $patchResult.Content
        $successCount++
        $results += @{
            Id     = $patch.id
            Status = "SUCCESS"
            Line   = $patchResult.LineNumber
        }
    }
    else {
        $failCount++
        $results += @{
            Id     = $patch.id
            Status = "FAIL"
            Error  = $patchResult.Error
        }
        # Continue applying remaining patches even if one fails
    }
}

# --- Step 8: Collect results summary ---
Write-Host ""
Write-Log "Results: $successCount applied, $failCount failed, $skipCount skipped" $(if($failCount -gt 0){"WARN"}else{"INFO"})

# --- Step 9: If successes and not DryRun -> minify pipeline ---
$finalExitCode = 0
$rollbackDone = $false

if ($successCount -gt 0 -and -not $DryRun) {

    # 9a. Write modified content to temp file
    $tempPatchedFile = Join-Path $script:TempDir "patched-beautified-$((Get-Date -Format 'yyyyMMdd-HHmmss')).js"

    try {
        # Use StreamWriter for large file output
        $sw = New-Object System.IO.StreamWriter($tempPatchedFile, $false, (New-Object System.Text.UTF8Encoding $false))
        $sw.Write($workingContent)
        $sw.Close()
        Write-Log "Modified content written to temp file: $(Split-Path $tempPatchedFile -Leaf)" "INFO"
    }
    catch {
        Write-Log "Failed to write temp patched file: $($_.Exception.Message)" "ERROR"
        exit 1
    }

    # 9b. Backup original file
    $backupResult = Backup-OriginalFile -SourcePath $script:TargetMjsPath
    if (-not $backupResult.Success) {
        Write-Log "CRITICAL: Backup failed, aborting minification to preserve original." "ERROR"
        Remove-Item $tempPatchedFile -Force -ErrorAction SilentlyContinue
        exit 1
    }

    # 9c. Terser minification
    $minifiedOutput = Join-Path $script:TempDir "output-minified-$((Get-Date -Format 'yyyyMMdd-HHmmss')).mjs"
    $minifyResult = Invoke-TerserMinify `
        -InputPath $tempPatchedFile `
        -OutputPath $minifiedOutput `
        -ConfigPath $configPath

    if (-not $minifyResult.Success) {
        Write-Log "Minification FAILED. Original file preserved (backup at: $($backupResult.BackupPath))" "ERROR"
        Remove-Item $tempPatchedFile -Force -ErrorAction SilentlyContinue
        Remove-Item $minifiedOutput -Force -ErrorAction SilentlyContinue
        Format-ResultsTable -Results $results
        exit 1
    }

    # 9d. Integrity test
    Write-Log "Running integrity checks on minified output..." "INFO"
    $integrity = Test-FileIntegrity -FilePath $minifiedOutput

    if ($integrity.Pass) {
        Write-Log "Integrity check PASSED (MD5: $($integrity.Md5), Size: $($integrity.SizeMB)MB)" "SUCCESS"

        # 9e. Replace original file
        try {
            Copy-Item -Path $minifiedOutput -Destination $script:TargetMjsPath -Force
            Write-Log "Original file replaced with minified patched version" "SUCCESS"
        }
        catch {
            Write-Log "FAILED to replace original file: $($_.Exception.Message)" "ERROR"
            Write-Log "Attempting rollback from backup..." "WARN"
            try {
                Copy-Item -Path $backupResult.BackupPath -Destination $script:TargetMjsPath -Force
                Write-Log "Rollback successful - original restored from backup" "WARN"
                $rollbackDone = $true
            }
            catch {
                Write-Log "ROLLBACK ALSO FAILED! Manual intervention required!" "ERROR"
                Write-Log "Backup available at: $($backupResult.BackupPath)" "ERROR"
            }
            $finalExitCode = 1
        }
    }
    else {
        # 9f. Rollback on failure
        Write-Log "Integrity check FAILED:" "ERROR"
        foreach ($issue in $integrity.Issues) {
            Write-Log "  - $issue" "ERROR"
        }
        Write-Log "Rolling back to backup: $($backupResult.BackupPath)" "WARN"
        try {
            Copy-Item -Path $backupResult.BackupPath -Destination $script:TargetMjsPath -Force
            Write-Log "Rollback successful - original restored" "SUCCESS"
            $rollbackDone = $true
        }
        catch {
            Write-Log "Rollback FAILED! Manual intervention needed. Backup: $($backupResult.BackupPath)" "ERROR"
        }
        $finalExitCode = 1
    }

    # Update manifest regardless of success/failure (record what happened)
    $appliedIds = @($results | Where-Object { $_.Status -eq "SUCCESS" } | ForEach-Object { $_.Id })
    Update-Manifest -BackupPath $backupResult.BackupPath -PatchesApplied $appliedIds -Operation "apply-v2"

    # Cleanup temp files
    Remove-Item $tempPatchedFile -Force -ErrorAction SilentlyContinue
    Remove-Item $minifiedOutput -Force -ErrorAction SilentlyContinue

}
elseif ($successCount -gt 0 -and $DryRun) {
    Write-Log "[DRY RUN] Would have written patched+minified file. No changes made." "WARN"
}

# --- Step 10: Display final results table ---
Format-ResultsTable -Results $results

# --- Step 11: Exit code ---
if ($failCount -gt 0) {
    $finalExitCode = 1
}
if ($successCount -eq 0 -and $failCount -gt 0) {
    $finalExitCode = 2
}

if ($finalExitCode -eq 0) {
    Write-Log "All done. Restart Trae window to take effect." "SUCCESS"
}
elseif ($rollbackDone) {
    Write-Log "Completed with rollback applied. Original file restored." "WARN"
}
else {
    Write-Log "Completed with errors (exit code $finalExitCode)." $(if($finalExitCode -eq 2){"ERROR"}else{"WARN"})
}

exit $finalExitCode
