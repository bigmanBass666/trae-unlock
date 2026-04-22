$file = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$content = Get-Content $file -Raw

# 搜索5个失效补丁的原始模式
$patterns = @(
    @{name="data-source-auto-confirm ORIGINAL"; pattern='i\.name!==CS\.ViewFiles.*e\.start_line=e\.start_line_one_indexed'},
    @{name="auto-confirm-commands ORIGINAL"; pattern='e\?\.confirm_info\?\.confirm_status===.unconfirmed.?.if.s.'},
    @{name="bypass-runcommandcard-redlist ORIGINAL"; pattern='case Cr\.AutoRunMode\.WHITELIST:switch\(i\)'},
    @{name="auto-continue-thinking ORIGINAL"; pattern='if\(V&&J\)\{let e=M\.localize'},
    @{name="bypass-loop-detection ORIGINAL"; pattern='J=\!\!\[kg\.MODEL_OUTPUT_TOO_LONG,kg\.TASK_TURN_EXCEEDED_ERROR\]'}
)

foreach ($p in $patterns) {
    $matches = [regex]::Matches($content, $p.pattern)
    $count = $matches.Count
    if ($count -gt 0) {
        Write-Host "✅ FOUND: $($p.name) ($count matches)"
        # Get position of first match
        $pos = $matches[0].Index
        Write-Host "   Position: $pos"
    } else {
        Write-Host "❌ NOT FOUND: $($p.name)"
    }
}