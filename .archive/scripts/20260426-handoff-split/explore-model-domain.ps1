$ErrorActionPreference = "Continue"
$targetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$outFile = "D:\Test\trae-unlock\scripts\explore-model-domain-results.txt"

if (Test-Path $outFile) { Remove-Item $outFile }
function Log($msg) { Add-Content -Path $outFile -Value $msg -Encoding UTF8 }

Log "=== Model Domain Exploration ==="
Log "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Log ""

$content = [System.IO.File]::ReadAllText($targetFile)
$totalLen = $content.Length
Log "File size: $totalLen chars"
Log ""

# ============================================================
# Phase 1: Core anchor - computeSelectedModelAndMode
# ============================================================
Log "========== Phase 1: Core Anchor =========="
Log ""

$anchor = "computeSelectedModelAndMode"
$idx = $content.IndexOf($anchor)
Log "Anchor: $anchor"
Log "  IndexOf result: $idx"

if ($idx -ge 0) {
    $start = [Math]::Max(0, $idx - 2500)
    $end = [Math]::Min($totalLen, $idx + 2500)
    $ctx = $content.Substring($start, $end - $start)
    Log "  Context range: $start .. $end (5000 chars)"
    Log "--- CONTEXT START ---"
    Log $ctx
    Log "--- CONTEXT END ---"
}
Log ""

# ============================================================
# Phase 2: Related classes - NR (IModelService), k2 (IModelStore)
# ============================================================
Log "========== Phase 2: Core Classes =========="
Log ""

# NR class (IModelService)
$nrIdx = $content.IndexOf("class NR")
Log "class NR (IModelService): $nrIdx"
if ($nrIdx -ge 0) {
    $s = [Math]::Max(0, $nrIdx - 500)
    $e = [Math]::Min($totalLen, $nrIdx + 4500)
    Log $content.Substring($s, $e - $s)
}
Log ""

# k2 class (IModelStore)
$k2Idx = $content.IndexOf("class k2")
Log "class k2 (IModelStore): $k2Idx"
if ($k2Idx -ge 0) {
    $s = [Math]::Max(0, $k2Idx - 500)
    $e = [Math]::Min($totalLen, $k2Idx + 4500)
    Log $content.Substring($s, $e - $s)
}
Log ""

# ============================================================
# Phase 3: kG enum (Manual/Auto/Max) and bJ enum
# ============================================================
Log "========== Phase 3: Enums =========="
Log ""

# kG enum
$searches = @("kG={", "kG =", "var kG", "let kG", "const kG")
foreach ($s in $searches) {
    $i = $content.IndexOf($s)
    if ($i -ge 0) {
        Log "kG enum found via '$s' @ $i"
        $cs = [Math]::Max(0, $i - 200)
        $ce = [Math]::Min($totalLen, $i + 800)
        Log $content.Substring($cs, $ce - $cs)
        break
    }
}
Log ""

# bJ enum
$searches = @("bJ={", "bJ =", "var bJ", "let bJ", "const bJ")
foreach ($s in $searches) {
    $i = $content.IndexOf($s)
    if ($i -ge 0) {
        Log "bJ enum found via '$s' @ $i"
        $cs = [Math]::Max(0, $i - 200)
        $ce = [Math]::Min($totalLen, $i + 800)
        Log $content.Substring($cs, $ce - $cs)
        break
    }
}
Log ""

# ============================================================
# Phase 4: DI registrations (uJ with model-related tokens)
# ============================================================
Log "========== Phase 4: DI Registrations =========="
Log ""

$modelTokens = @(
    "IModelService",
    "IModelStore",
    "ModelService",
    "ModelStore"
)

foreach ($token in $modelTokens) {
    # Search for uJ registrations
    $pattern = "uJ($token"
    $idx2 = 0
    $count = 0
    while (($idx2 = $content.IndexOf($pattern, $idx2)) -ge 0 -and $count -lt 5) {
        Log "uJ registration for '$token' @ $idx2"
        $cs = [Math]::Max(0, $idx2 - 200)
        $ce = [Math]::Min($totalLen, $idx2 + 500)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
        $idx2 += $pattern.Length
        $count++
    }
    if ($count -eq 0) {
        Log "No uJ registration found for '$token'"
        
        # Try Symbol registrations
        $symPattern = "Symbol(`"$token`")"
        $symIdx = $content.IndexOf($symPattern)
        if ($symIdx -ge 0) {
            Log "  Symbol found: $symPattern @ $symIdx"
            $cs = [Math]::Max(0, $symIdx - 200)
            $ce = [Math]::Min($totalLen, $symIdx + 500)
            Log $content.Substring($cs, $ce - $cs)
        }
        
        $symForPattern = "Symbol.for(`"$token`")"
        $symForIdx = $content.IndexOf($symForPattern)
        if ($symForIdx -ge 0) {
            Log "  Symbol.for found: $symForPattern @ $symForIdx"
            $cs = [Math]::Max(0, $symForIdx - 200)
            $ce = [Math]::Min($totalLen, $symForIdx + 500)
            Log $content.Substring($cs, $ce - $cs)
        }
        Log ""
    }
}
Log ""

# ============================================================
# Phase 5: DI injections (uX with model-related tokens)
# ============================================================
Log "========== Phase 5: DI Injections =========="
Log ""

foreach ($token in $modelTokens) {
    $pattern = "uX($token"
    $idx2 = 0
    $count = 0
    while (($idx2 = $content.IndexOf($pattern, $idx2)) -ge 0 -and $count -lt 5) {
        Log "uX injection for '$token' @ $idx2"
        $cs = [Math]::Max(0, $idx2 - 200)
        $ce = [Math]::Min($totalLen, $idx2 + 500)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
        $idx2 += $pattern.Length
        $count++
    }
    if ($count -eq 0) {
        Log "No uX injection found for '$token'"
        Log ""
    }
}
Log ""

# ============================================================
# Phase 6: Method calls and API endpoints
# ============================================================
Log "========== Phase 6: Method Calls & API =========="
Log ""

$methodSearches = @(
    "computeSelectedModelAndMode",
    "selectedModel",
    "modelMode",
    "maxMode",
    "autoMode",
    "manualMode",
    "getModelList",
    "switchModel",
    "model_list",
    "/model",
    "ai-model",
    "chatModel",
    "chat_model"
)

foreach ($ms in $methodSearches) {
    $idx2 = 0
    $count = 0
    $positions = @()
    while (($idx2 = $content.IndexOf($ms, $idx2)) -ge 0 -and $count -lt 3) {
        $positions += $idx2
        $idx2 += $ms.Length
        $count++
    }
    $totalHits = 0
    $tIdx = 0
    while (($tIdx = $content.IndexOf($ms, $tIdx)) -ge 0) {
        $totalHits++
        $tIdx += $ms.Length
    }
    Log "'$ms': $totalHits total hits, first 3 positions: $($positions -join ', ')"
    
    foreach ($pos in $positions) {
        $cs = [Math]::Max(0, $pos - 150)
        $ce = [Math]::Min($totalLen, $pos + 300)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
    }
}
Log ""

# ============================================================
# Phase 7: Model-related API endpoints
# ============================================================
Log "========== Phase 7: API Endpoints =========="
Log ""

$apiSearches = @(
    "byteintlapi.com",
    "ai-api",
    "bytegate",
    "/api/chat",
    "/api/model",
    "model_config",
    "modelConfig",
    "model_config_id"
)

foreach ($api in $apiSearches) {
    $idx2 = 0
    $count = 0
    while (($idx2 = $content.IndexOf($api, $idx2)) -ge 0 -and $count -lt 3) {
        Log "'$api' @ $idx2"
        $cs = [Math]::Max(0, $idx2 - 200)
        $ce = [Math]::Min($totalLen, $idx2 + 400)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
        $idx2 += $api.Length
        $count++
    }
}
Log ""

# ============================================================
# Phase 8: NR class full method extraction
# ============================================================
Log "========== Phase 8: NR Class Full Methods =========="
Log ""

if ($nrIdx -ge 0) {
    $nrEnd = [Math]::Min($totalLen, $nrIdx + 15000)
    $nrContent = $content.Substring($nrIdx, $nrEnd - $nrIdx)
    Log "NR class content (15000 chars from @ $nrIdx):"
    Log $nrContent
}
Log ""

# ============================================================
# Phase 9: k2 class full method extraction
# ============================================================
Log "========== Phase 9: k2 Class Full Methods =========="
Log ""

if ($k2Idx -ge 0) {
    $k2End = [Math]::Min($totalLen, $k2Idx + 15000)
    $k2Content = $content.Substring($k2Idx, $k2End - $k2Idx)
    Log "k2 class content (15000 chars from @ $k2Idx):"
    Log $k2Content
}
Log ""

# ============================================================
# Phase 10: Model mode switching logic
# ============================================================
Log "========== Phase 10: Mode Switching Logic =========="
Log ""

$modeSearches = @(
    "kG.Max",
    "kG.Auto",
    "kG.Manual",
    "forceMax",
    "force_max",
    "upgradeMode",
    "downgradeMode",
    "switchMode",
    "modeSwitch"
)

foreach ($ms in $modeSearches) {
    $idx2 = 0
    $count = 0
    while (($idx2 = $content.IndexOf($ms, $idx2)) -ge 0 -and $count -lt 5) {
        Log "'$ms' @ $idx2"
        $cs = [Math]::Max(0, $idx2 - 200)
        $ce = [Math]::Min($totalLen, $idx2 + 400)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
        $idx2 += $ms.Length
        $count++
    }
    if ($count -eq 0) {
        Log "'$ms': NOT FOUND"
        Log ""
    }
}
Log ""

# ============================================================
# Phase 11: Model selection UI components
# ============================================================
Log "========== Phase 11: Model Selection UI =========="
Log ""

$uiSearches = @(
    "ModelSelector",
    "ModelSwitcher",
    "ModelPicker",
    "model-selector",
    "model-switcher",
    "model-picker",
    "selectedModelId",
    "currentModelId",
    "activeModel"
)

foreach ($us in $uiSearches) {
    $idx2 = 0
    $count = 0
    while (($idx2 = $content.IndexOf($us, $idx2)) -ge 0 -and $count -lt 3) {
        Log "'$us' @ $idx2"
        $cs = [Math]::Max(0, $idx2 - 150)
        $ce = [Math]::Min($totalLen, $idx2 + 300)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
        $idx2 += $us.Length
        $count++
    }
    if ($count -eq 0) {
        Log "'$us': NOT FOUND"
        Log ""
    }
}
Log ""

# ============================================================
# Phase 12: Premium model restrictions
# ============================================================
Log "========== Phase 12: Premium Model Restrictions =========="
Log ""

$premiumSearches = @(
    "PREMIUM_MODE_USAGE_LIMIT",
    "STANDARD_MODE_USAGE_LIMIT",
    "MODEL_NOT_EXISTED",
    "MODEL_OUTPUT_TOO_LONG",
    "CLAUDE_MODEL_FORBIDDEN",
    "modelForbidden",
    "model_forbidden",
    "premiumModel",
    "premium_model"
)

foreach ($ps in $premiumSearches) {
    $idx2 = 0
    $count = 0
    while (($idx2 = $content.IndexOf($ps, $idx2)) -ge 0 -and $count -lt 3) {
        Log "'$ps' @ $idx2"
        $cs = [Math]::Max(0, $idx2 - 200)
        $ce = [Math]::Min($totalLen, $idx2 + 400)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
        $idx2 += $ps.Length
        $count++
    }
    if ($count -eq 0) {
        Log "'$ps': NOT FOUND"
        Log ""
    }
}
Log ""

Log "=== Model Domain Exploration Complete ==="
Write-Host "Results written to $outFile"
