$targetFile = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$outFile = "D:\Test\trae-unlock\scripts\explore-supplemental-results.txt"
if (Test-Path $outFile) { Remove-Item $outFile }
function Log($msg) { Add-Content -Path $outFile -Value $msg -Encoding UTF8 }

$content = [System.IO.File]::ReadAllText($targetFile)

# 1. Find class ID (SessionRelationStore)
$idx = $content.IndexOf("class ID")
Log "class ID at: $idx"
if ($idx -ge 0) {
    $s = [Math]::Max(0, $idx - 200)
    $e = [Math]::Min($content.Length, $idx + 3000)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 2. Find NE token (IModelService DI identifier)
$ne = $content.IndexOf("identifier:NE")
Log "identifier:NE at: $ne"
if ($ne -ge 0) {
    $s = [Math]::Max(0, $ne - 300)
    $e = [Math]::Min($content.Length, $ne + 300)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 3. Find kv = Symbol.for("IModelService")
$kv = $content.IndexOf("let kv=Symbol")
Log "let kv=Symbol at: $kv"
if ($kv -ge 0) {
    $s = [Math]::Max(0, $kv - 100)
    $e = [Math]::Min($content.Length, $kv + 300)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 4. Find the ID class DI registration (uJ with identifier for SessionRelationStore)
$idUj = $content.IndexOf("class ID")
if ($idUj -ge 0) {
    $searchEnd = [Math]::Min($content.Length, $idUj + 50000)
    $chunk = $content.Substring($idUj, $searchEnd - $idUj)
    $ujIdx = $chunk.IndexOf("uJ({identifier:")
    if ($ujIdx -ge 0) {
        Log "ID class uJ registration at offset: $($idUj + $ujIdx)"
        $s = [Math]::Max(0, $ujIdx - 100)
        $e = [Math]::Min($chunk.Length, $ujIdx + 300)
        Log $chunk.Substring($s, $e - $s)
    }
}
Log ""

# 5. DocsetServiceImpl class (Gd)
$gd = $content.IndexOf("class Gd")
Log "class Gd at: $gd"
if ($gd -ge 0) {
    $s = [Math]::Max(0, $gd - 200)
    $e = [Math]::Min($content.Length, $gd + 5000)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 6. DocsetServiceImpl DI registration
$dsUj = $content.IndexOf("uJ({identifier:WK")
Log "uJ({identifier:WK at: $dsUj"
if ($dsUj -ge 0) {
    $s = [Math]::Max(0, $dsUj - 200)
    $e = [Math]::Min($content.Length, $dsUj + 400)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 7. WK token definition
$wk = $content.IndexOf("IDocsetService")
if ($wk -ge 0) {
    $s = [Math]::Max(0, $wk - 200)
    $e = [Math]::Min($content.Length, $wk + 400)
    Log "IDocsetService context at $wk"
    Log $content.Substring($s, $e - $s)
}
Log ""

# 8. KnowledgesTaskService (FC)
$fc = $content.IndexOf("class FC") 
Log "class FC at: $fc"
if ($fc -ge 0) {
    $s = [Math]::Max(0, $fc - 200)
    $e = [Math]::Min($content.Length, $fc + 3000)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 9. Knowledges commands registration
$kc = $content.IndexOf("icube.knowledges")
Log "icube.knowledges at: $kc"
if ($kc -ge 0) {
    $s = [Math]::Max(0, $kc - 200)
    $e = [Math]::Min($content.Length, $kc + 2000)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 10. DocsetCkgIndexStatus enum
$dcs = $content.IndexOf("DocsetCkgIndexStatus")
Log "DocsetCkgIndexStatus at: $dcs"
if ($dcs -ge 0) {
    $s = [Math]::Max(0, $dcs - 200)
    $e = [Math]::Min($content.Length, $dcs + 800)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 11. DocsetCKGStatus enum
$dcgs = $content.IndexOf("DocsetCKGStatus")
Log "DocsetCKGStatus at: $dcgs"
if ($dcgs -ge 0) {
    $s = [Math]::Max(0, $dcgs - 200)
    $e = [Math]::Min($content.Length, $dcgs + 800)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 12. Model fee levels (kH enum)
$kh = $content.IndexOf("AdvancedModel")
Log "AdvancedModel at: $kh"
if ($kh -ge 0) {
    $s = [Math]::Max(0, $kh - 200)
    $e = [Math]::Min($content.Length, $kh + 500)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 13. Model config source (kY enum)
$ky = $content.IndexOf("kY.Trae")
Log "kY.Trae at: $ky"
if ($ky -ge 0) {
    $s = [Math]::Max(0, $ky - 200)
    $e = [Math]::Min($content.Length, $ky + 500)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 14. force_close_auto config
$fca = $content.IndexOf("force_close_auto")
Log "force_close_auto at: $fca"
if ($fca -ge 0) {
    $s = [Math]::Max(0, $fca - 200)
    $e = [Math]::Min($content.Length, $fca + 400)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 15. max_mode property
$mm = $content.IndexOf("max_mode")
Log "max_mode at: $mm (first occurrence)"
if ($mm -ge 0) {
    $s = [Math]::Max(0, $mm - 200)
    $e = [Math]::Min($content.Length, $mm + 400)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 16. is_dollar_max property
$idm = $content.IndexOf("is_dollar_max")
Log "is_dollar_max at: $idm"
if ($idm -ge 0) {
    $s = [Math]::Max(0, $idm - 200)
    $e = [Math]::Min($content.Length, $idm + 400)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 17. fee_model_level property
$fml = $content.IndexOf("fee_model_level")
Log "fee_model_level at: $fml"
if ($fml -ge 0) {
    $s = [Math]::Max(0, $fml - 200)
    $e = [Math]::Min($content.Length, $fml + 400)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 18. DocsetService injection in sendToAgent
$sta = $content.IndexOf("IDocsetService")
$staCount = 0
while ($sta -ge 0 -and $staCount -lt 5) {
    $s = [Math]::Max(0, $sta - 200)
    $e = [Math]::Min($content.Length, $sta + 400)
    Log "IDocsetService occurrence at $sta"
    Log $content.Substring($s, $e - $s)
    Log ""
    $sta = $content.IndexOf("IDocsetService", $sta + 1)
    $staCount++
}
Log ""

# 19. Knowledges background task types
$fe = $content.IndexOf("class FE") 
Log "class FE at: $fe"
if ($fe -ge 0) {
    $s = [Math]::Max(0, $fe - 100)
    $e = [Math]::Min($content.Length, $fe + 1000)
    Log $content.Substring($s, $e - $s)
}
Log ""

# 20. ent_knowledge_base gating
$ekb = $content.IndexOf("ent_knowledge_base")
Log "ent_knowledge_base at: $ekb"
if ($ekb -ge 0) {
    $s = [Math]::Max(0, $ekb - 200)
    $e = [Math]::Min($content.Length, $ekb + 400)
    Log $content.Substring($s, $e - $s)
}
Log ""

Write-Host "Supplemental results written to $outFile"
