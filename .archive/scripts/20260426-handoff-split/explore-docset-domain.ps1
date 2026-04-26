$ErrorActionPreference = "Continue"
$targetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$outFile = "D:\Test\trae-unlock\scripts\explore-docset-domain-results.txt"

if (Test-Path $outFile) { Remove-Item $outFile }
function Log($msg) { Add-Content -Path $outFile -Value $msg -Encoding UTF8 }

Log "=== Docset Domain Exploration ==="
Log "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Log ""

$content = [System.IO.File]::ReadAllText($targetFile)
$totalLen = $content.Length
Log "File size: $totalLen chars"
Log ""

# ============================================================
# Phase 1: Core DI Tokens - 5 ai.* tokens
# ============================================================
Log "========== Phase 1: Core DI Tokens =========="
Log ""

$diTokens = @(
    "ai.IDocsetService",
    "ai.IDocsetStore",
    "ai.IDocsetCkgLocalApiService",
    "ai.IDocsetOnlineApiService",
    "ai.IWebCrawlerFacade"
)

foreach ($token in $diTokens) {
    $idx = $content.IndexOf($token)
    Log "Token: $token"
    Log "  First occurrence: $idx"
    
    if ($idx -ge 0) {
        $start = [Math]::Max(0, $idx - 500)
        $end = [Math]::Min($totalLen, $idx + 2000)
        Log "  Context (2500 chars):"
        Log $content.Substring($start, $end - $start)
    }
    Log ""
    
    # Find all occurrences
    $allIdx = 0
    $positions = @()
    while (($allIdx = $content.IndexOf($token, $allIdx)) -ge 0) {
        $positions += $allIdx
        $allIdx += $token.Length
    }
    Log "  All positions ($($positions.Count) hits): $($positions -join ', ')"
    Log ""
}
Log ""

# ============================================================
# Phase 2: DI registrations (uJ with docset tokens)
# ============================================================
Log "========== Phase 2: DI Registrations (uJ) =========="
Log ""

$docsetSearchTerms = @(
    "IDocsetService",
    "IDocsetStore",
    "IDocsetCkgLocalApiService",
    "IDocsetOnlineApiService",
    "IWebCrawlerFacade",
    "DocsetService",
    "DocsetStore",
    "DocsetCkgLocalApiService",
    "DocsetOnlineApiService",
    "WebCrawlerFacade"
)

foreach ($term in $docsetSearchTerms) {
    # uJ registration
    $pattern = "uJ($term"
    $idx2 = 0
    $count = 0
    while (($idx2 = $content.IndexOf($pattern, $idx2)) -ge 0 -and $count -lt 3) {
        Log "uJ registration for '$term' @ $idx2"
        $cs = [Math]::Max(0, $idx2 - 300)
        $ce = [Math]::Min($totalLen, $idx2 + 800)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
        $idx2 += $pattern.Length
        $count++
    }
    if ($count -eq 0) {
        Log "No uJ registration found for '$term'"
        Log ""
    }
}
Log ""

# ============================================================
# Phase 3: DI injections (uX with docset tokens)
# ============================================================
Log "========== Phase 3: DI Injections (uX) =========="
Log ""

foreach ($term in $docsetSearchTerms) {
    $pattern = "uX($term"
    $idx2 = 0
    $count = 0
    while (($idx2 = $content.IndexOf($pattern, $idx2)) -ge 0 -and $count -lt 5) {
        Log "uX injection for '$term' @ $idx2"
        $cs = [Math]::Max(0, $idx2 - 300)
        $ce = [Math]::Min($totalLen, $idx2 + 800)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
        $idx2 += $pattern.Length
        $count++
    }
    if ($count -eq 0) {
        Log "No uX injection found for '$term'"
        Log ""
    }
}
Log ""

# ============================================================
# Phase 4: Knowledges services
# ============================================================
Log "========== Phase 4: Knowledges Services =========="
Log ""

$knowledgesSearches = @(
    "Knowledges",
    "knowledges",
    "IKnowledgeService",
    "KnowledgeService",
    "knowledge_service",
    "knowledges.",
    "ai.Knowledge",
    "ai.IKnowledge"
)

foreach ($ks in $knowledgesSearches) {
    $idx2 = 0
    $count = 0
    $positions = @()
    while (($idx2 = $content.IndexOf($ks, $idx2)) -ge 0 -and $count -lt 5) {
        $positions += $idx2
        $idx2 += $ks.Length
        $count++
    }
    $totalHits = 0
    $tIdx = 0
    while (($tIdx = $content.IndexOf($ks, $tIdx)) -ge 0) {
        $totalHits++
        $tIdx += $ks.Length
    }
    Log "'$ks': $totalHits total hits, first 5: $($positions -join ', ')"
    
    foreach ($pos in $positions) {
        $cs = [Math]::Max(0, $pos - 200)
        $ce = [Math]::Min($totalLen, $pos + 500)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
    }
}
Log ""

# ============================================================
# Phase 5: Docset-related classes
# ============================================================
Log "========== Phase 5: Docset Classes =========="
Log ""

$classSearches = @(
    "DocsetService",
    "DocsetStore",
    "CkgLocalApiService",
    "CkgLocalApi",
    "OnlineApiService",
    "WebCrawler",
    "DocsetManager",
    "DocsetRepository"
)

foreach ($cs2 in $classSearches) {
    $idx2 = 0
    $count = 0
    while (($idx2 = $content.IndexOf($cs2, $idx2)) -ge 0 -and $count -lt 3) {
        Log "'$cs2' @ $idx2"
        $cs = [Math]::Max(0, $idx2 - 200)
        $ce = [Math]::Min($totalLen, $idx2 + 500)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
        $idx2 += $cs2.Length
        $count++
    }
    if ($count -eq 0) {
        Log "'$cs2': NOT FOUND"
        Log ""
    }
}
Log ""

# ============================================================
# Phase 6: Docset API endpoints
# ============================================================
Log "========== Phase 6: Docset API Endpoints =========="
Log ""

$apiSearches = @(
    "/docset",
    "/docsets",
    "/ckg",
    "/web-crawler",
    "/webcrawler",
    "/knowledge",
    "/knowledges",
    "docset_api",
    "docsetApi",
    "ckg_api",
    "ckgApi",
    "crawler_api",
    "crawlerApi"
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
    if ($count -eq 0) {
        Log "'$api': NOT FOUND"
        Log ""
    }
}
Log ""

# ============================================================
# Phase 7: Docset data flow - createDocset, deleteDocset, etc.
# ============================================================
Log "========== Phase 7: Docset Data Flow Methods =========="
Log ""

$flowSearches = @(
    "createDocset",
    "deleteDocset",
    "updateDocset",
    "getDocset",
    "listDocset",
    "addDocset",
    "removeDocset",
    "syncDocset",
    "indexDocset",
    "crawlDocset",
    "parseDocset",
    "docsetList",
    "docsetDetail",
    "docsetInfo",
    "docsetStatus",
    "docset_id",
    "docsetId",
    "spaceId",
    "space_id"
)

foreach ($fs in $flowSearches) {
    $idx2 = 0
    $count = 0
    while (($idx2 = $content.IndexOf($fs, $idx2)) -ge 0 -and $count -lt 3) {
        Log "'$fs' @ $idx2"
        $cs = [Math]::Max(0, $idx2 - 150)
        $ce = [Math]::Min($totalLen, $idx2 + 300)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
        $idx2 += $fs.Length
        $count++
    }
    if ($count -eq 0) {
        Log "'$fs': NOT FOUND"
        Log ""
    }
}
Log ""

# ============================================================
# Phase 8: WebCrawler specific
# ============================================================
Log "========== Phase 8: WebCrawler Specific =========="
Log ""

$crawlerSearches = @(
    "WebCrawler",
    "webCrawler",
    "web_crawler",
    "crawlUrl",
    "crawl_url",
    "fetchUrl",
    "fetch_url",
    "scrapeUrl",
    "scrape_url",
    "parseHtml",
    "parse_html",
    "extractContent",
    "extract_content"
)

foreach ($crs in $crawlerSearches) {
    $idx2 = 0
    $count = 0
    while (($idx2 = $content.IndexOf($crs, $idx2)) -ge 0 -and $count -lt 3) {
        Log "'$crs' @ $idx2"
        $cs = [Math]::Max(0, $idx2 - 150)
        $ce = [Math]::Min($totalLen, $idx2 + 300)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
        $idx2 += $crs.Length
        $count++
    }
    if ($count -eq 0) {
        Log "'$crs': NOT FOUND"
        Log ""
    }
}
Log ""

# ============================================================
# Phase 9: CKG (Code Knowledge Graph) specific
# ============================================================
Log "========== Phase 9: CKG Specific =========="
Log ""

$ckgSearches = @(
    "CkgLocal",
    "ckgLocal",
    "ckg_local",
    "CkgOnline",
    "ckgOnline",
    "ckg_online",
    "CodeKnowledgeGraph",
    "codeKnowledgeGraph",
    "code_knowledge_graph",
    "ckgIndex",
    "ckg_index",
    "ckgQuery",
    "ckg_query",
    "ckgSearch",
    "ckg_search"
)

foreach ($ckg in $ckgSearches) {
    $idx2 = 0
    $count = 0
    while (($idx2 = $content.IndexOf($ckg, $idx2)) -ge 0 -and $count -lt 3) {
        Log "'$ckg' @ $idx2"
        $cs = [Math]::Max(0, $idx2 - 150)
        $ce = [Math]::Min($totalLen, $idx2 + 300)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
        $idx2 += $ckg.Length
        $count++
    }
    if ($count -eq 0) {
        Log "'$ckg': NOT FOUND"
        Log ""
    }
}
Log ""

# ============================================================
# Phase 10: Docset Store state structure
# ============================================================
Log "========== Phase 10: Docset Store State =========="
Log ""

$storeSearches = @(
    "docsetStore",
    "docset_store",
    "useDocsetStore",
    "DocsetStoreState",
    "docsetStoreState",
    "IDocsetStore",
    "docsetList:",
    "docsets:",
    "currentDocset",
    "selectedDocset"
)

foreach ($ss in $storeSearches) {
    $idx2 = 0
    $count = 0
    while (($idx2 = $content.IndexOf($ss, $idx2)) -ge 0 -and $count -lt 3) {
        Log "'$ss' @ $idx2"
        $cs = [Math]::Max(0, $idx2 - 200)
        $ce = [Math]::Min($totalLen, $idx2 + 400)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
        $idx2 += $ss.Length
        $count++
    }
    if ($count -eq 0) {
        Log "'$ss': NOT FOUND"
        Log ""
    }
}
Log ""

# ============================================================
# Phase 11: Knowledges commands (from handoff: knowledges.* commands)
# ============================================================
Log "========== Phase 11: Knowledges Commands =========="
Log ""

$cmdSearches = @(
    "knowledges.add",
    "knowledges.remove",
    "knowledges.list",
    "knowledges.search",
    "knowledges.update",
    "knowledges.create",
    "knowledges.delete",
    "knowledges.sync",
    "knowledges.index",
    "knowledges.crawl"
)

foreach ($cmd in $cmdSearches) {
    $idx2 = 0
    $count = 0
    while (($idx2 = $content.IndexOf($cmd, $idx2)) -ge 0 -and $count -lt 3) {
        Log "'$cmd' @ $idx2"
        $cs = [Math]::Max(0, $idx2 - 200)
        $ce = [Math]::Min($totalLen, $idx2 + 400)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
        $idx2 += $cmd.Length
        $count++
    }
    if ($count -eq 0) {
        Log "'$cmd': NOT FOUND"
        Log ""
    }
}
Log ""

# ============================================================
# Phase 12: Docset <-> Chat integration
# ============================================================
Log "========== Phase 12: Docset-Chat Integration =========="
Log ""

$intSearches = @(
    "docsetContext",
    "docset_context",
    "knowledgeContext",
    "knowledge_context",
    "withDocset",
    "with_docset",
    "chatWithDocset",
    "chat_with_docset",
    "docsetInChat",
    "docset_in_chat",
    "knowledgeBase",
    "knowledge_base",
    "knowledgeBaseId",
    "knowledge_base_id"
)

foreach ($is2 in $intSearches) {
    $idx2 = 0
    $count = 0
    while (($idx2 = $content.IndexOf($is2, $idx2)) -ge 0 -and $count -lt 3) {
        Log "'$is2' @ $idx2"
        $cs = [Math]::Max(0, $idx2 - 200)
        $ce = [Math]::Min($totalLen, $idx2 + 400)
        Log $content.Substring($cs, $ce - $cs)
        Log ""
        $idx2 += $is2.Length
        $count++
    }
    if ($count -eq 0) {
        Log "'$is2': NOT FOUND"
        Log ""
    }
}
Log ""

Log "=== Docset Domain Exploration Complete ==="
Write-Host "Results written to $outFile"
