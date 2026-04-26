param(
    [string]$TargetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js",
    [string]$OutFile = "d:\Test\trae-unlock\scripts\explore-version-results.txt"
)

$ErrorActionPreference = "Continue"
$sb = [System.Text.StringBuilder]::new()

function Append($text) {
    [void]$sb.AppendLine($text)
    Write-Host $text
}

Append "============================================================"
Append "  Trae IDE Version Diff Explorer - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Append "  Target: $TargetFile"
Append "============================================================"
Append ""

# Step 1: Read file
Append "[1] Reading target file..."
$c = [IO.File]::ReadAllText($TargetFile)
Append "  File size: $($c.Length) chars"
Append ""

# Step 2: Check known Symbol.for tokens
Append "============================================================"
Append "[2] Known Symbol.for Token Migration Check"
Append "============================================================"

$knownTokens = @(
    @{ Name = "IPlanItemStreamParser"; OldOffset = 7510424; ExpectedChange = $true },
    @{ Name = "ISessionStore"; OldOffset = 7092843; ExpectedChange = $true },
    @{ Name = "IErrorStreamParser"; OldOffset = 7515383; ExpectedChange = $false },
    @{ Name = "ITeaFacade"; OldOffset = 7140149; ExpectedChange = $false }
)

foreach ($tok in $knownTokens) {
    $symFor = "Symbol.for(`"$($tok.Name)`")"
    $symPlain = "Symbol(`"$($tok.Name)`")"

    $idxFor = $c.IndexOf($symFor)
    $idxPlain = $c.IndexOf($symPlain)

    $status = ""
    if ($idxFor -ge 0) {
        $status = "STILL Symbol.for"
    } elseif ($idxPlain -ge 0) {
        $status = "CHANGED to Symbol"
    } else {
        $status = "NOT FOUND in either form"
    }

    $changeNote = if ($tok.ExpectedChange) { "(expected change)" } else { "(expected same)" }
    Append "  $($tok.Name):"
    Append "    Symbol.for offset: $(if($idxFor -ge 0){$idxFor}else{'NOT FOUND'})"
    Append "    Symbol    offset: $(if($idxPlain -ge 0){$idxPlain}else{'NOT FOUND'})"
    Append "    Status: $status $changeNote"
    Append ""
}

# Step 3: Search ALL Symbol.for("I*") and Symbol("I*") patterns
Append "============================================================"
Append "[3] Complete DI Token Scan: Symbol.for / Symbol with I-prefix"
Append "============================================================"

Append ""
Append "--- Symbol.for(`"I...`") patterns ---"
$regexSymFor = [regex] 'Symbol\.for\("(I[^"]+)"\)'
$matchesFor = $regexSymFor.Matches($c)
foreach ($m in $matchesFor) {
    Append "  Offset $($m.Index): Symbol.for(`"$($m.Groups[1].Value)`")"
}
Append "  Total Symbol.for(I*): $($matchesFor.Count)"

Append ""
Append "--- Symbol(`"I...`") patterns ---"
$regexSymPlain = [regex] 'Symbol\("(I[^"]+)"\)'
$matchesPlain = $regexSymPlain.Matches($c)
foreach ($m in $matchesPlain) {
    Append "  Offset $($m.Index): Symbol(`"$($m.Groups[1].Value)`")"
}
Append "  Total Symbol(I*): $($matchesPlain.Count)"

# Step 3b: Also check non-I-prefix Symbol.for patterns for completeness
Append ""
Append "--- ALL Symbol.for patterns (non-I prefix too) ---"
$regexSymForAll = [regex] 'Symbol\.for\("([^"]+)"\)'
$matchesForAll = $regexSymForAll.Matches($c)
$forNames = @{}
foreach ($m in $matchesForAll) {
    $name = $m.Groups[1].Value
    if (-not $forNames.ContainsKey($name)) {
        $forNames[$name] = @()
    }
    $forNames[$name] += $m.Index
}
foreach ($name in ($forNames.Keys | Sort-Object)) {
    $offsets = $forNames[$name] -join ", "
    Append "  Symbol.for(`"$name`") @ $offsets"
}
Append "  Total unique Symbol.for names: $($forNames.Count)"

Append ""
Append "--- ALL Symbol(`"I...`") patterns (complete list) ---"
$symNames = @{}
foreach ($m in $matchesPlain) {
    $name = $m.Groups[1].Value
    if (-not $symNames.ContainsKey($name)) {
        $symNames[$name] = @()
    }
    $symNames[$name] += $m.Index
}
foreach ($name in ($symNames.Keys | Sort-Object)) {
    $offsets = $symNames[$name] -join ", "
    Append "  Symbol(`"$name`") @ $offsets"
}
Append "  Total unique Symbol(I*) names: $($symNames.Count)"

# Step 4: Expand 500 chars around tokens that changed from Symbol.for to Symbol
Append ""
Append "============================================================"
Append "[4] Context Around Migrated Tokens (Symbol.for -> Symbol)"
Append "============================================================"

$migratedTokens = @("IPlanItemStreamParser", "ISessionStore")
foreach ($tokName in $migratedTokens) {
    $symPlain = "Symbol(`"$tokName`")"
    $idx = $c.IndexOf($symPlain)
    if ($idx -ge 0) {
        $start = [Math]::Max(0, $idx - 250)
        $len = [Math]::Min(500, $c.Length - $start)
        $ctx = $c.Substring($start, $len)
        Append ""
        Append "--- $tokName @ offset $idx (500-char context) ---"
        Append $ctx
    } else {
        Append ""
        Append "--- ${tokName}: NOT FOUND as Symbol ---"
    }
}

# Step 5: ConfirmMode search
Append ""
Append "============================================================"
Append "[5] ConfirmMode / confirmMode / confirm_mode Search"
Append "============================================================"

foreach ($pattern in @("ConfirmMode", "confirmMode", "confirm_mode")) {
    Append ""
    Append "--- Searching: `"$pattern`" ---"
    $idx = 0
    $count = 0
    while (($idx = $c.IndexOf($pattern, $idx)) -ge 0) {
        $count++
        $start = [Math]::Max(0, $idx - 100)
        $len = [Math]::Min(250, $c.Length - $start)
        $ctx = $c.Substring($start, $len)
        Append "  Offset ${idx}:"
        Append "  $ctx"
        Append ""
        $idx += $pattern.Length
        if ($count -ge 10) {
            Append "  ... (stopped after 10 matches)"
            break
        }
    }
    if ($count -eq 0) {
        Append "  NOT FOUND"
    } else {
        Append "  Total matches: $count"
    }
}

# Also search for AutoRunMode and BlockLevel as reference
Append ""
Append "--- Reference: AutoRunMode search ---"
$idx = 0
$count = 0
while (($idx = $c.IndexOf("AutoRunMode", $idx)) -ge 0) {
    $count++
    $start = [Math]::Max(0, $idx - 80)
    $len = [Math]::Min(200, $c.Length - $start)
    $ctx = $c.Substring($start, $len)
    Append "  Offset ${idx}: $ctx"
    $idx += "AutoRunMode".Length
    if ($count -ge 5) { break }
}
if ($count -eq 0) { Append "  NOT FOUND" }

Append ""
Append "--- Reference: BlockLevel search ---"
$idx = 0
$count = 0
while (($idx = $c.IndexOf("BlockLevel", $idx)) -ge 0) {
    $count++
    $start = [Math]::Max(0, $idx - 80)
    $len = [Math]::Min(200, $c.Length - $start)
    $ctx = $c.Substring($start, $len)
    Append "  Offset ${idx}: $ctx"
    $idx += "BlockLevel".Length
    if ($count -ge 5) { break }
}
if ($count -eq 0) { Append "  NOT FOUND" }

# Step 6: kg error enum
Append ""
Append "============================================================"
Append "[6] kg Error Enum (TASK_TURN_EXCEEDED_ERROR context)"
Append "============================================================"

$kgIdx = $c.IndexOf("TASK_TURN_EXCEEDED_ERROR")
if ($kgIdx -ge 0) {
    $start = [Math]::Max(0, $kgIdx - 1000)
    $len = [Math]::Min(3000, $c.Length - $start)
    $ctx = $c.Substring($start, $len)
    Append "  Found TASK_TURN_EXCEEDED_ERROR at offset $kgIdx"
    Append "  3000-char context (1000 before, 2000 after):"
    Append $ctx
} else {
    Append "  TASK_TURN_EXCEEDED_ERROR NOT FOUND"
    # Try alternative search
    foreach ($alt in @("TURN_EXCEEDED", "EXCEEDED_ERROR", "TASK_TURN")) {
        $altIdx = $c.IndexOf($alt)
        if ($altIdx -ge 0) {
            Append "  Found `"$alt`" at offset $altIdx, expanding..."
            $start = [Math]::Max(0, $altIdx - 200)
            $len = [Math]::Min(1000, $c.Length - $start)
            Append $c.Substring($start, $len)
            break
        }
    }
}

# Step 7: efh and J = search
Append ""
Append "============================================================"
Append "[7] efh (recoverable errors) and J = (continuation flag) Search"
Append "============================================================"

Append ""
Append "--- Searching: efh ---"
$idx = 0
$count = 0
while (($idx = $c.IndexOf("efh", $idx)) -ge 0) {
    $count++
    # Check if it's a standalone variable (not part of a longer word)
    $before = if ($idx -gt 0) { $c[$idx - 1] } else { ' ' }
    $after = if ($idx + 3 -lt $c.Length) { $c[$idx + 3] } else { ' ' }
    $isStandalone = ($before -match '[^a-zA-Z0-9_]') -and ($after -match '[^a-zA-Z0-9_]')
    if ($isStandalone) {
        $start = [Math]::Max(0, $idx - 200)
        $len = [Math]::Min(500, $c.Length - $start)
        $ctx = $c.Substring($start, $len)
        Append "  Offset ${idx} (standalone):"
        Append "  $ctx"
        Append ""
    }
    $idx += 3
    if ($count -ge 30) {
        Append "  ... (stopped after 30 raw matches)"
        break
    }
}

Append ""
Append "--- Searching: `",J =`" pattern ---"
$idx = 0
$count = 0
while (($idx = $c.IndexOf(",J =", $idx)) -ge 0) {
    $count++
    $start = [Math]::Max(0, $idx - 200)
    $len = [Math]::Min(500, $c.Length - $start)
    $ctx = $c.Substring($start, $len)
    Append "  Offset ${idx}:"
    Append "  $ctx"
    Append ""
    $idx += 4
    if ($count -ge 5) { break }
}

Append ""
Append "--- Searching: `";J =`" pattern ---"
$idx = 0
$count = 0
while (($idx = $c.IndexOf(";J =", $idx)) -ge 0) {
    $count++
    $start = [Math]::Max(0, $idx - 200)
    $len = [Math]::Min(500, $c.Length - $start)
    $ctx = $c.Substring($start, $len)
    Append "  Offset ${idx}:"
    Append "  $ctx"
    Append ""
    $idx += 4
    if ($count -ge 5) { break }
}

# Step 8: Additional version-change observations
Append ""
Append "============================================================"
Append "[8] Additional Version-Change Observations"
Append "============================================================"

# Check for any new DI patterns
Append ""
Append "--- Symbol.for count vs Symbol count ---"
$allSymFor = ([regex] 'Symbol\.for\(').Matches($c).Count
$allSymPlain = ([regex] 'Symbol\("').Matches($c).Count
Append "  Total Symbol.for(...): $allSymFor"
Append "  Total Symbol(`"...`"): $allSymPlain"

# Check for version string
Append ""
Append "--- Version strings ---"
$verPatterns = @('"version"', 'version:', 'VERSION')
foreach ($vp in $verPatterns) {
    $vIdx = $c.IndexOf($vp)
    if ($vIdx -ge 0) {
        $start = [Math]::Max(0, $vIdx - 50)
        $len = [Math]::Min(200, $c.Length - $start)
        Append "  Found `"$vp`" at offset ${vIdx}: $($c.Substring($start, $len))"
    }
}

# Check for package name patterns
Append ""
Append "--- Package identity ---"
$pkgPatterns = @("@byted-icube/ai-modules-chat", "ai-modules-chat")
foreach ($pp in $pkgPatterns) {
    $pIdx = $c.IndexOf($pp)
    if ($pIdx -ge 0) {
        Append "  Found `"$pp`" at offset $pIdx"
    } else {
        Append "  `"$pp`" NOT FOUND in source"
    }
}

# Save results
Append ""
Append "============================================================"
Append "  Exploration Complete - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Append "============================================================"

[IO.File]::WriteAllText($OutFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host ""
Write-Host "Results saved to: $OutFile"
Write-Host "Result size: $($sb.Length) chars"
