$ErrorActionPreference = "Stop"
$path = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$c = [IO.File]::ReadAllText($path)

$target = 'teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)'
$idx = $c.IndexOf($target)

if ($idx -ge 0) {
    Write-Host "[v5-locate] FOUND at offset: $idx" -ForegroundColor Green
    $ctx = $c.Substring($idx, [Math]::Min(120, $c.Length - $idx))
    Write-Host "[v5-locate] Context: $ctx" -ForegroundColor Cyan

    $braceIdx = $c.IndexOf('{', $idx)
    Write-Host "[v5-locate] Opening brace at: $braceIdx (inject after this)" -ForegroundColor Yellow
} else {
    Write-Host "[v5-locate] NOT FOUND!" -ForegroundColor Red
}
