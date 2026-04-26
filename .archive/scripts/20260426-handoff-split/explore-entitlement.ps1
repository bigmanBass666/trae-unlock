param()

$TargetPath = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$OutFile = 'd:\Test\trae-unlock\scripts\explore-entitlement-results.txt'

if (-not (Test-Path $TargetPath)) {
    Write-Error "Target file not found: $TargetPath"
    exit 1
}

$sb = [System.Text.StringBuilder]::new()

function Append {
    param([string]$Text)
    [void]$sb.AppendLine($Text)
}

function Get-Context {
    param(
        [string]$Content,
        [int]$Offset,
        [int]$ContextSize = 200
    )
    $start = [Math]::Max(0, $Offset - $ContextSize)
    $end = [Math]::Min($Content.Length, $Offset + $ContextSize)
    $prefix = if ($start -gt 0) { '...' } else { '' }
    $suffix = if ($end -lt $Content.Length) { '...' } else { '' }
    $snippet = $Content.Substring($start, $end - $start) -replace '\r?\n', ' '
    "${prefix}${snippet}${suffix}"
}

Append "============================================================"
Append "  IEntitlementStore & ICommercialPermissionService 深度探索"
Append "  生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Append "============================================================"
Append ""

Write-Host "Reading target file..."
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$c = [IO.File]::ReadAllText($TargetPath)
$sw.Stop()
Write-Host "File loaded: $($c.Length) chars in $($sw.ElapsedMilliseconds)ms"
Append "File size: $($c.Length) chars"
Append ""

# ============================================================
# 1. IEntitlementStore token + class definition
# ============================================================
Append "============================================================"
Append "  1. IEntitlementStore Token & Class Definition"
Append "============================================================"
Append ""

$entStoreToken = 'IEntitlementStore'
$idx = $c.IndexOf($entStoreToken)
if ($idx -ge 0) {
    Append "IEntitlementStore found at offset: $idx"
    Append "Context (5000 chars before, 5000 chars after):"
    Append ""
    $start = [Math]::Max(0, $idx - 5000)
    $end = [Math]::Min($c.Length, $idx + 5000)
    $bigCtx = $c.Substring($start, $end - $start) -replace '\r?\n', ' '
    Append $bigCtx
    Append ""
    Append "--- End of IEntitlementStore 10000-char context ---"
    Append ""
} else {
    Append "IEntitlementStore NOT FOUND!"
    Append ""
}

# Also search for Symbol("IEntitlementStore")
$symToken = 'Symbol("IEntitlementStore")'
$idx2 = $c.IndexOf($symToken)
if ($idx2 -ge 0) {
    Append "Symbol('IEntitlementStore') found at offset: $idx2"
    Append "Context (200 chars): $(Get-Context -Content $c -Offset $idx2 -ContextSize 200)"
    Append ""
} else {
    Append "Symbol('IEntitlementStore') NOT FOUND"
    Append ""
}

# Search for Nc token (the minified name from discoveries.md)
$ncToken = '"IEntitlementStore"'
$idx3 = $c.IndexOf($ncToken)
while ($idx3 -ge 0) {
    Append """IEntitlementStore"" at offset: $idx3"
    Append "  Context: $(Get-Context -Content $c -Offset $idx3 -ContextSize 150)"
    Append ""
    $idx3 = $c.IndexOf($ncToken, $idx3 + $ncToken.Length)
}

# ============================================================
# 2. ICommercialPermissionService token + class definition
# ============================================================
Append "============================================================"
Append "  2. ICommercialPermissionService Token & Class Definition"
Append "============================================================"
Append ""

$commToken = 'ICommercialPermissionService'
$idx4 = $c.IndexOf($commToken)
if ($idx4 -ge 0) {
    Append "ICommercialPermissionService found at offset: $idx4"
    Append "Context (5000 chars before, 5000 chars after):"
    Append ""
    $start = [Math]::Max(0, $idx4 - 5000)
    $end = [Math]::Min($c.Length, $idx4 + 5000)
    $bigCtx = $c.Substring($start, $end - $start) -replace '\r?\n', ' '
    Append $bigCtx
    Append ""
    Append "--- End of ICommercialPermissionService 10000-char context ---"
    Append ""
} else {
    Append "ICommercialPermissionService NOT FOUND!"
    Append ""
}

# Also search for Symbol.for version
$symForToken = 'aiAgent.ICommercialPermissionService'
$idx5 = $c.IndexOf($symForToken)
if ($idx5 -ge 0) {
    Append "Symbol.for('aiAgent.ICommercialPermissionService') found at offset: $idx5"
    Append "Context (200 chars): $(Get-Context -Content $c -Offset $idx5 -ContextSize 200)"
    Append ""
} else {
    Append "Symbol.for('aiAgent.ICommercialPermissionService') NOT FOUND"
    Append ""
}

# Search all occurrences of ICommercialPermissionService
$idx5b = $c.IndexOf($commToken)
while ($idx5b -ge 0) {
    Append """$commToken"" at offset: $idx5b"
    Append "  Context: $(Get-Context -Content $c -Offset $idx5b -ContextSize 150)"
    Append ""
    $idx5b = $c.IndexOf($commToken, $idx5b + $commToken.Length)
}

# ============================================================
# 3. All "entitlement" occurrences (case-insensitive)
# ============================================================
Append "============================================================"
Append "  3. All 'entitlement' Occurrences (case-insensitive)"
Append "============================================================"
Append ""

$entKw = 'entitlement'
$entIdx = 0
$entCount = 0
while (($entIdx = $c.IndexOf($entKw, $entIdx, [System.StringComparison]::OrdinalIgnoreCase)) -ge 0) {
    $entCount++
    $ctx = Get-Context -Content $c -Offset $entIdx -ContextSize 100
    Append "[$entCount] offset=$entIdx : $ctx"
    $entIdx += $entKw.Length
}
Append ""
Append "Total 'entitlement' occurrences: $entCount"
Append ""

# ============================================================
# 4. All "commercial" occurrences (case-insensitive)
# ============================================================
Append "============================================================"
Append "  4. All 'commercial' Occurrences (case-insensitive)"
Append "============================================================"
Append ""

$commKw = 'commercial'
$commIdx = 0
$commCount = 0
while (($commIdx = $c.IndexOf($commKw, $commIdx, [System.StringComparison]::OrdinalIgnoreCase)) -ge 0) {
    $commCount++
    $ctx = Get-Context -Content $c -Offset $commIdx -ContextSize 100
    Append "[$commCount] offset=$commIdx : $ctx"
    $commIdx += $commKw.Length
}
Append ""
Append "Total 'commercial' occurrences: $commCount"
Append ""

# ============================================================
# 5. IEntitlementStore uJ({identifier:Nc}) registrations
# ============================================================
Append "============================================================"
Append "  5. uJ({identifier:...}) Registrations Near IEntitlementStore"
Append "============================================================"
Append ""

# Find the Nc variable that holds IEntitlementStore token
# From discoveries.md: Nc = "IEntitlementStore", registered as uJ({identifier:Nc})
# Search for uJ({identifier: near the IEntitlementStore offset
$ujKw = 'uJ({identifier:'
$ujIdx = 0
$ujCount = 0
while (($ujIdx = $c.IndexOf($ujKw, $ujIdx)) -ge 0) {
    $ujCount++
    $ctx = Get-Context -Content $c -Offset $ujIdx -ContextSize 200
    Append "[$ujCount] offset=$ujIdx : $ctx"
    $ujIdx += $ujKw.Length
}
Append ""
Append "Total uJ({identifier: occurrences: $ujCount"
Append ""

# ============================================================
# 6. Subscription/Plan/Pro/Free keywords
# ============================================================
Append "============================================================"
Append "  6. Subscription/Plan/Pro/Free Keywords"
Append "============================================================"
Append ""

foreach ($kw in @('subscription', 'isPro', 'isFree', 'planType', 'userPlan', 'plan_type', 'tier', 'FREE_ACTIVITY', 'PREMIUM_USAGE', 'STANDARD_MODE', 'MODEL_PREMIUM', 'quota', 'QuotaExhausted', 'UsageLimit')) {
    Append "--- Keyword: '$kw' ---"
    $kwIdx = 0
    $kwCount = 0
    while (($kwIdx = $c.IndexOf($kw, $kwIdx, [System.StringComparison]::OrdinalIgnoreCase)) -ge 0) {
        $kwCount++
        $ctx = Get-Context -Content $c -Offset $kwIdx -ContextSize 100
        Append "  [$kwCount] offset=$kwIdx : $ctx"
        $kwIdx += $kw.Length
        if ($kwCount -ge 30) {
            Append "  ... (truncated at 30 hits)"
            break
        }
    }
    Append "  Total '$kw' occurrences: $kwCount"
    Append ""
}

# ============================================================
# 7. efc function (commercial activity config) at ~8701488
# ============================================================
Append "============================================================"
Append "  7. efc Function (Commercial Activity Config) at ~8701488"
Append "============================================================"
Append ""

$efcKw = 'efc'
# Search for efc function definition
$efcIdx = 0
$efcCount = 0
while (($efcIdx = $c.IndexOf($efcKw, $efcIdx)) -ge 0) {
    $efcCount++
    # Only show first 20 occurrences with context
    if ($efcCount -le 20) {
        $ctx = Get-Context -Content $c -Offset $efcIdx -ContextSize 100
        Append "[$efcCount] offset=$efcIdx : $ctx"
    }
    $efcIdx += $efcKw.Length
    if ($efcCount -ge 100) {
        Append "... (truncated at 100 hits, total may be more)"
        break
    }
}
Append "Total 'efc' occurrences: $efcCount (showing first 20)"
Append ""

# Also check the specific offset from discoveries.md
Append "--- Context at offset 8701488 (efc function) ---"
$efcCtx = Get-Context -Content $c -Offset 8701488 -ContextSize 500
Append $efcCtx
Append ""

# ============================================================
# 8. FREE_ACTIVITY_QUOTA_EXHAUSTED and related error codes
# ============================================================
Append "============================================================"
Append "  8. Quota/Limit Error Codes"
Append "============================================================"
Append ""

foreach ($errKw in @('FREE_ACTIVITY_QUOTA_EXHAUSTED', 'MODEL_PREMIUM_EXHAUSTED', 'PREMIUM_USAGE_LIMIT', 'STANDARD_MODE_USAGE_LIMIT', 'INTERNAL_USAGE_LIMIT', 'ENTERPRISE_QUOTA')) {
    $errIdx = $c.IndexOf($errKw)
    if ($errIdx -ge 0) {
        Append "$errKw at offset: $errIdx"
        Append "  Context: $(Get-Context -Content $c -Offset $errIdx -ContextSize 200)"
        Append ""
    } else {
        Append "$errKw NOT FOUND"
        Append ""
    }
}

# ============================================================
# 9. Nu class (EntitlementStore implementation) deep dive
# ============================================================
Append "============================================================"
Append "  9. Nu Class (EntitlementStore Implementation) Deep Dive"
Append "============================================================"
Append ""

# From discoveries.md: Nc = IEntitlementStore token, Nu = implementation
# The registration is uJ({identifier:Nc}) at ~7260182
# Let's find the Nu class definition

# Search for class Nu or Nu= patterns
$nuPatterns = @('class Nu{', 'class Nu ', 'Nu=class', 'Nu=({', 'new Nu(')
foreach ($pat in $nuPatterns) {
    $nuIdx = $c.IndexOf($pat)
    while ($nuIdx -ge 0) {
        Append "Pattern '$pat' at offset: $nuIdx"
        Append "  Context: $(Get-Context -Content $c -Offset $nuIdx -ContextSize 300)"
        Append ""
        $nuIdx = $c.IndexOf($pat, $nuIdx + $pat.Length)
    }
}

# ============================================================
# 10. T5/T3 class (Entitlement-related from discoveries #46)
# ============================================================
Append "============================================================"
Append "  10. T5/T3 (Entitlement-Related at offset ~7256181)"
Append "============================================================"
Append ""

# From discoveries.md: #46 at 7256181, T5 token, T3 implementation, "Entitlement 相关"
$t5Ctx = Get-Context -Content $c -Offset 7256181 -ContextSize 2000
Append "Context at offset 7256181 (T5 Entitlement-related):"
Append $t5Ctx
Append ""

# ============================================================
# 11. resolve(Nc) calls - who uses IEntitlementStore
# ============================================================
Append "============================================================"
Append "  11. resolve(Nc) and IEntitlementStore Usage"
Append "============================================================"
Append ""

# Search for patterns that resolve the entitlement store
$resolvePatterns = @('resolve(Nc)', 'resolve(T5)', '.Nc)', '.T5)')
foreach ($pat in $resolvePatterns) {
    $rIdx = 0
    $rCount = 0
    while (($rIdx = $c.IndexOf($pat, $rIdx)) -ge 0) {
        $rCount++
        if ($rCount -le 15) {
            $ctx = Get-Context -Content $c -Offset $rIdx -ContextSize 150
            Append "Pattern '$pat' [$rCount] offset=$rIdx : $ctx"
        }
        $rIdx += $pat.Length
    }
    Append "Total '$pat' occurrences: $rCount"
    Append ""
}

# ============================================================
# 12. Commercial permission check patterns
# ============================================================
Append "============================================================"
Append "  12. Commercial Permission Check Patterns"
Append "============================================================"
Append ""

$permPatterns = @('checkPermission', 'hasPermission', 'isAllowed', 'canUse', 'isEntitled', 'checkEntitlement', 'getEntitlement', 'entitlementCheck', 'commercialCheck', 'permissionService', 'PermissionService')
foreach ($pat in $permPatterns) {
    $pIdx = 0
    $pCount = 0
    while (($pIdx = $c.IndexOf($pat, $pIdx, [System.StringComparison]::OrdinalIgnoreCase)) -ge 0) {
        $pCount++
        if ($pCount -le 10) {
            $ctx = Get-Context -Content $c -Offset $pIdx -ContextSize 150
            Append "Pattern '$pat' [$pCount] offset=$pIdx : $ctx"
        }
        $pIdx += $pat.Length
    }
    Append "Total '$pat' occurrences: $pCount"
    Append ""
}

# ============================================================
# 13. "pro" and "free" near entitlement/subscription context
# ============================================================
Append "============================================================"
Append "  13. Pro/Free Tier Keywords in Subscription Context"
Append "============================================================"
Append ""

$tierPatterns = @('"pro"', '"free"', "'pro'", "'free'", 'isProUser', 'isFreeUser', 'proUser', 'freeUser', 'ProPlan', 'FreePlan', 'pro_plan', 'free_plan', 'planType', 'user_type', 'userType')
foreach ($pat in $tierPatterns) {
    $tIdx = 0
    $tCount = 0
    while (($tIdx = $c.IndexOf($pat, $tIdx, [System.StringComparison]::OrdinalIgnoreCase)) -ge 0) {
        $tCount++
        if ($tCount -le 10) {
            $ctx = Get-Context -Content $c -Offset $tIdx -ContextSize 150
            Append "Pattern '$pat' [$tCount] offset=$tIdx : $ctx"
        }
        $tIdx += $pat.Length
    }
    if ($tCount -gt 0) {
        Append "Total '$pat' occurrences: $tCount"
        Append ""
    }
}

# ============================================================
# 14. activityConfig and commercial activity patterns
# ============================================================
Append "============================================================"
Append "  14. Activity Config & Commercial Activity Patterns"
Append "============================================================"
Append ""

$actPatterns = @('activityConfig', 'commercialActivity', 'chatConfirmPopUp', 'hub,errorInfo', 'FREE_ACTIVITY')
foreach ($pat in $actPatterns) {
    $aIdx = 0
    $aCount = 0
    while (($aIdx = $c.IndexOf($pat, $aIdx, [System.StringComparison]::OrdinalIgnoreCase)) -ge 0) {
        $aCount++
        if ($aCount -le 10) {
            $ctx = Get-Context -Content $c -Offset $aIdx -ContextSize 200
            Append "Pattern '$pat' [$aCount] offset=$aIdx : $ctx"
        }
        $aIdx += $pat.Length
    }
    Append "Total '$pat' occurrences: $aCount"
    Append ""
}

# ============================================================
# Write results
# ============================================================
Append "============================================================"
Append "  END OF EXPLORATION"
Append "============================================================"

$resultText = $sb.ToString()
[IO.File]::WriteAllText($OutFile, $resultText, [System.Text.Encoding]::UTF8)
Write-Host "Results written to: $OutFile"
Write-Host "Result size: $($resultText.Length) chars"
