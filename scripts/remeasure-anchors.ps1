$path = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$c = [IO.File]::ReadAllText($path)
Write-Host "File size: $($c.Length) chars"

$anchors = @(
    @{name="Symbol.for(aiAgent.ILogService)"; search='Symbol.for("aiAgent.ILogService")'; doc="~6473533"},
    @{name="Symbol(ISessionStore)"; search='Symbol("ISessionStore")'; doc="~7087490"},
    @{name="Symbol(IPlanItemStreamParser)"; search='Symbol("IPlanItemStreamParser")'; doc="~7503299"},
    @{name="resumeChat"; search="resumeChat"; doc="~7540953"},
    @{name="sendChatMessage"; search="sendChatMessage"; doc="~7524962"},
    @{name="provideUserResponse"; search="provideUserResponse"; doc="~7509668"},
    @{name="getRunCommandCardBranch"; search="getRunCommandCardBranch"; doc="~8069620"},
    @{name="computeSelectedModelAndMode"; search="computeSelectedModelAndMode"; doc="~7215828"},
    @{name="ICommercialPermissionService"; search="ICommercialPermissionService"; doc="~7267682"},
    @{name="kg.TASK_TURN_EXCEEDED_ERROR"; search="TASK_TURN_EXCEEDED_ERROR"; doc="~54415"},
    @{name="Symbol.for(IErrorStreamParser)"; search='Symbol.for("IErrorStreamParser")'; doc="~7300000"},
    @{name="Symbol(IEntitlementStore)"; search='Symbol("IEntitlementStore")'; doc="~7259427"},
    @{name="eventHandlerFactory"; search="eventHandlerFactory"; doc="~7300000"},
    @{name="uJ({identifier:"; search='uJ({identifier:'; doc="various"},
    @{name="uX("; search='uX('; doc="various"},
    @{name="icube.shellExec"; search='icube.shellExec'; doc="~6146361"}
)

Write-Host "`n=== Anchor Re-measurement Report ==="
Write-Host ("{0,-45} {1,10} {2,10} {3,10}" -f "Anchor", "Actual", "Doc", "Drift")
Write-Host ("-" * 80)

foreach ($a in $anchors) {
    $idx = $c.IndexOf($a.search)
    $actual = if ($idx -ge 0) { $idx } else { "NOT_FOUND" }
    $drift = ""
    if ($idx -ge 0 -and $a.doc -match '~?(\d+)') {
        $docVal = [int]$Matches[1]
        $drift = ($idx - $docVal).ToString("+#;-#;0")
    }
    Write-Host ("{0,-45} {1,10} {2,10} {3,10}" -f $a.name, $actual, $a.doc, $drift)
}

Write-Host "`n=== DI Statistics ==="
$ujCount = ([regex]::Matches($c, 'uJ\(\{identifier:')).Count
$uxCount = ([regex]::Matches($c, 'uX\(')).Count
$symbolForCount = ([regex]::Matches($c, 'Symbol\.for\(')).Count
$symbolCount = ([regex]::Matches($c, 'Symbol\(')).Count
Write-Host "uJ registrations: $ujCount"
Write-Host "uX injections: $uxCount"
Write-Host "Symbol.for count: $symbolForCount"
Write-Host "Symbol() count: $symbolCount"

Write-Host "`n=== Error Code Enum ==="
$kgIdx = $c.IndexOf("TASK_TURN_EXCEEDED_ERROR")
if ($kgIdx -ge 0) {
    $ctx = $c.Substring([Math]::Max(0, $kgIdx - 200), 400)
    Write-Host "kg enum context (first occurrence):"
    Write-Host $ctx
}

Write-Host "`n=== Search Template Validation ==="
$templates = @(
    @{id="DI-01"; search='uX('; expect="816 hits"},
    @{id="DI-02"; search='uJ({identifier:'; expect="186 hits"},
    @{id="DI-03"; search='Symbol.for("'; expect="54 hits"},
    @{id="SSE-02-old"; search='Symbol.for("IPlanItemStreamParser")'; expect="EMPTY"},
    @{id="SSE-02-new"; search='Symbol("IPlanItemStreamParser")'; expect="found"},
    @{id="EVT-05"; search='icube.shellExec'; expect="found"},
    @{id="COM-01"; search='ICommercialPermissionService'; expect="found"},
    @{id="GEN-07"; search='ToolCallName'; expect="found"},
    @{id="ERR-01"; search='4000002'; expect="found"},
    @{id="RCT-08"; search='getRunCommandCardBranch'; expect="found"}
)

foreach ($t in $templates) {
    $idx = $c.IndexOf($t.search)
    $status = if ($idx -ge 0) { "OK (@$idx)" } else { "EMPTY" }
    Write-Host "$($t.id): $status (expected: $($t.expect))"
}
