$c = [IO.File]::ReadAllText("D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js")

Write-Output "========== Check: where is our watcher relative to FR()? =========="
$bgIdx = $c.IndexOf("[v15-bg]")
if ($bgIdx -ge 0) {
    Write-Output "[v15-bg] first occurrence at offset: ${bgIdx}"
    
    # Search backwards for "async function FR" or "function FR"
    $searchStart = [Math]::Max(0, $bgIdx - 3000)
    $region = $c.Substring($searchStart, $bgIdx - $searchStart)
    
    # Count brace balance from searchStart to bgIdx to determine nesting depth
    $pos = $searchStart
    $depth = 0
    while ($pos -lt $bgIdx) {
        $ch = $c.Substring($pos, 1)
        if ($ch -eq "{") { $depth++ }
        elseif ($ch -eq "}") { $depth-- }
        $pos++
    }
    Write-Output "Brace depth at [v15-bg] position: ${depth} (depth>0 = inside function(s))"
    
    # Also check for FR( or async function nearby
    $frIdx = $region.LastIndexOf("FR(")
    if ($frIdx -ge 0) {
        Write-Output "Last FR( in region at relative offset: ${frIdx} (absolute: $($searchStart + $frIdx))"
    }
    $asyncIdx = $region.LastIndexOf("async function")
    if ($asyncIdx -ge 0) {
        Write-Output "Last 'async function' in region at relative offset: ${asyncIdx}"
        # Show context around it
        $ctxStart = [Math]::Max(0, $asyncIdx - 20)
        Write-Output "Context:", $region.Substring($ctxStart, 80)
    }
}

Write-Output ""
Write-Output "========== Check: original n.subscribe (sub#8) location vs our watcher =========="
$subIdx = $c.IndexOf("n.subscribe((e,t)=>{((e.currentSession")
if ($subIdx -ge 0) {
    Write-Output "Original sub#8 at offset: ${subIdx}"
    # Our watcher should be before this
    $watcherIdx = $c.IndexOf("uj.getInstance().resolve(xC).subscribe(function(e)")
    if ($watcherIdx -ge 0) {
        Write-Output "Our watcher subscribe at offset: ${watcherIdx}"
        Write-Output "Distance: $($subIdx - $watcherIdx) chars between them"
        
        # Show the code between watcher and original sub#8
        $between = $c.Substring($watcherIdx, $subIdx - $watcherIdx)
        Write-Output "Code between (first 200 chars):"
        Write-Output $between.Substring(0, [Math]::Min(200, $between.Length))
    }
}
