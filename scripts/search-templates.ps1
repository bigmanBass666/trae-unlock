param()

$DefaultPath = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'

function Get-Context {
    param(
        [string]$Content,
        [int]$Offset,
        [int]$ContextSize = 150
    )
    $start = [Math]::Max(0, $Offset - $ContextSize)
    $end = [Math]::Min($Content.Length, $Offset + $ContextSize)
    $prefix = if ($start -gt 0) { '...' } else { '' }
    $suffix = if ($end -lt $Content.Length) { '...' } else { '' }
    $snippet = $Content.Substring($start, $end - $start) -replace '\r?\n', ' '
    "${prefix}${snippet}${suffix}"
}

function Search-DIToken {
    param(
        [string]$Path = $DefaultPath,
        [int]$Context = 150
    )
    if (-not (Test-Path $Path)) { Write-Warning "File not found: $Path"; return @() }
    $c = [IO.File]::ReadAllText($Path)
    $keywords = @('uX(')
    $results = @()
    foreach ($kw in $keywords) {
        $idx = 0
        while (($idx = $c.IndexOf($kw, $idx)) -ge 0) {
            $results += [PSCustomObject]@{ Offset = $idx; Context = (Get-Context -Content $c -Offset $idx -ContextSize $Context); Keyword = $kw }
            $idx += $kw.Length
        }
    }
    $results
}

function Search-ServiceProperty {
    param(
        [string]$Path = $DefaultPath,
        [int]$Context = 150
    )
    if (-not (Test-Path $Path)) { Write-Warning "File not found: $Path"; return @() }
    $c = [IO.File]::ReadAllText($Path)
    $keywords = @('this._')
    $results = @()
    foreach ($kw in $keywords) {
        $idx = 0
        while (($idx = $c.IndexOf($kw, $idx)) -ge 0) {
            $results += [PSCustomObject]@{ Offset = $idx; Context = (Get-Context -Content $c -Offset $idx -ContextSize $Context); Keyword = $kw }
            $idx += $kw.Length
        }
    }
    $results
}

function Search-Subscribe {
    param(
        [string]$Path = $DefaultPath,
        [int]$Context = 150
    )
    if (-not (Test-Path $Path)) { Write-Warning "File not found: $Path"; return @() }
    $c = [IO.File]::ReadAllText($Path)
    $keywords = @('.subscribe(')
    $results = @()
    foreach ($kw in $keywords) {
        $idx = 0
        while (($idx = $c.IndexOf($kw, $idx)) -ge 0) {
            $results += [PSCustomObject]@{ Offset = $idx; Context = (Get-Context -Content $c -Offset $idx -ContextSize $Context); Keyword = $kw }
            $idx += $kw.Length
        }
    }
    $results
}

function Search-EventHandler {
    param(
        [string]$Path = $DefaultPath,
        [int]$Context = 150
    )
    if (-not (Test-Path $Path)) { Write-Warning "File not found: $Path"; return @() }
    $c = [IO.File]::ReadAllText($Path)
    $keywords = @('eventHandlerFactory.handle(')
    $results = @()
    foreach ($kw in $keywords) {
        $idx = 0
        while (($idx = $c.IndexOf($kw, $idx)) -ge 0) {
            $results += [PSCustomObject]@{ Offset = $idx; Context = (Get-Context -Content $c -Offset $idx -ContextSize $Context); Keyword = $kw }
            $idx += $kw.Length
        }
    }
    $results
}

function Search-StoreAction {
    param(
        [string]$Path = $DefaultPath,
        [int]$Context = 150
    )
    if (-not (Test-Path $Path)) { Write-Warning "File not found: $Path"; return @() }
    $c = [IO.File]::ReadAllText($Path)
    $keywords = @('storeService.', 'setCurrentSession')
    $results = @()
    foreach ($kw in $keywords) {
        $idx = 0
        while (($idx = $c.IndexOf($kw, $idx)) -ge 0) {
            $results += [PSCustomObject]@{ Offset = $idx; Context = (Get-Context -Content $c -Offset $idx -ContextSize $Context); Keyword = $kw }
            $idx += $kw.Length
        }
    }
    $results
}

function Search-ReactHook {
    param(
        [string]$Path = $DefaultPath,
        [int]$Context = 150
    )
    if (-not (Test-Path $Path)) { Write-Warning "File not found: $Path"; return @() }
    $c = [IO.File]::ReadAllText($Path)
    $keywords = @('useCallback(', 'useMemo(', 'useEffect(')
    $results = @()
    foreach ($kw in $keywords) {
        $idx = 0
        while (($idx = $c.IndexOf($kw, $idx)) -ge 0) {
            $results += [PSCustomObject]@{ Offset = $idx; Context = (Get-Context -Content $c -Offset $idx -ContextSize $Context); Keyword = $kw }
            $idx += $kw.Length
        }
    }
    $results
}

function Search-ErrorEnum {
    param(
        [string]$Path = $DefaultPath,
        [int]$Context = 150
    )
    if (-not (Test-Path $Path)) { Write-Warning "File not found: $Path"; return @() }
    $c = [IO.File]::ReadAllText($Path)
    $keywords = @('kg.')
    $results = @()
    foreach ($kw in $keywords) {
        $idx = 0
        while (($idx = $c.IndexOf($kw, $idx)) -ge 0) {
            $results += [PSCustomObject]@{ Offset = $idx; Context = (Get-Context -Content $c -Offset $idx -ContextSize $Context); Keyword = $kw }
            $idx += $kw.Length
        }
    }
    $results
}

function Search-TeaEvent {
    param(
        [string]$Path = $DefaultPath,
        [int]$Context = 150
    )
    if (-not (Test-Path $Path)) { Write-Warning "File not found: $Path"; return @() }
    $c = [IO.File]::ReadAllText($Path)
    $keywords = @('teaEvent', 'tea.')
    $results = @()
    foreach ($kw in $keywords) {
        $idx = 0
        while (($idx = $c.IndexOf($kw, $idx)) -ge 0) {
            $results += [PSCustomObject]@{ Offset = $idx; Context = (Get-Context -Content $c -Offset $idx -ContextSize $Context); Keyword = $kw }
            $idx += $kw.Length
        }
    }
    $results
}

function Search-IPC {
    param(
        [string]$Path = $DefaultPath,
        [int]$Context = 150
    )
    if (-not (Test-Path $Path)) { Write-Warning "File not found: $Path"; return @() }
    $c = [IO.File]::ReadAllText($Path)
    $keywords = @('postMessage', 'onmessage', 'ipcRenderer')
    $results = @()
    foreach ($kw in $keywords) {
        $idx = 0
        while (($idx = $c.IndexOf($kw, $idx)) -ge 0) {
            $results += [PSCustomObject]@{ Offset = $idx; Context = (Get-Context -Content $c -Offset $idx -ContextSize $Context); Keyword = $kw }
            $idx += $kw.Length
        }
    }
    $results
}

function Search-SettingKey {
    param(
        [string]$Path = $DefaultPath,
        [int]$Context = 150
    )
    if (-not (Test-Path $Path)) { Write-Warning "File not found: $Path"; return @() }
    $c = [IO.File]::ReadAllText($Path)
    $keywords = @('AI.toolcall.', 'chat.tools.')
    $results = @()
    foreach ($kw in $keywords) {
        $idx = 0
        while (($idx = $c.IndexOf($kw, $idx)) -ge 0) {
            $results += [PSCustomObject]@{ Offset = $idx; Context = (Get-Context -Content $c -Offset $idx -ContextSize $Context); Keyword = $kw }
            $idx += $kw.Length
        }
    }
    $results
}

function Search-Generic {
    param(
        [Parameter(Mandatory)]
        [string]$Keyword,
        [string]$Path = $DefaultPath,
        [int]$Context = 150
    )
    if (-not (Test-Path $Path)) { Write-Warning "File not found: $Path"; return @() }
    $c = [IO.File]::ReadAllText($Path)
    $results = @()
    $idx = 0
    while (($idx = $c.IndexOf($Keyword, $idx)) -ge 0) {
        $results += [PSCustomObject]@{ Offset = $idx; Context = (Get-Context -Content $c -Offset $idx -ContextSize $Context); Keyword = $Keyword }
        $idx += $Keyword.Length
    }
    $results
}

function Search-All {
    param(
        [string]$Path = $DefaultPath,
        [int]$Context = 80
    )
    if (-not (Test-Path $Path)) { Write-Warning "File not found: $Path"; return }
    $searches = @{
        'DIToken'        = { Search-DIToken -Path $Path -Context $Context }
        'ServiceProperty' = { Search-ServiceProperty -Path $Path -Context $Context }
        'Subscribe'      = { Search-Subscribe -Path $Path -Context $Context }
        'EventHandler'   = { Search-EventHandler -Path $Path -Context $Context }
        'StoreAction'    = { Search-StoreAction -Path $Path -Context $Context }
        'ReactHook'      = { Search-ReactHook -Path $Path -Context $Context }
        'ErrorEnum'      = { Search-ErrorEnum -Path $Path -Context $Context }
        'TeaEvent'       = { Search-TeaEvent -Path $Path -Context $Context }
        'IPC'            = { Search-IPC -Path $Path -Context $Context }
        'SettingKey'     = { Search-SettingKey -Path $Path -Context $Context }
    }
    $summary = @()
    foreach ($name in $searches.Keys | Sort-Object) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $results = & $searches[$name]
        $sw.Stop()
        $count = if ($results) { $results.Count } else { 0 }
        $summary += [PSCustomObject]@{
            SearchName = $name
            HitCount   = $count
            ElapsedMs  = $sw.ElapsedMilliseconds
        }
        Write-Host ("[{0}] {1} hits ({2}ms)" -f $name, $count, $sw.ElapsedMilliseconds)
    }
    Write-Host ''
    Write-Host '=== Search-All Summary ==='
    $summary | Format-Table -AutoSize
    $summary
}

if($MyInvocation.MyCommand.CommandType -eq 'ExternalScript'){}
