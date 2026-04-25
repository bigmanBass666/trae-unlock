$ErrorActionPreference = "Stop"
$path = "D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js"
$c = [IO.File]::ReadAllText($path)

$searchStr = 'teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)'
$idx = $c.IndexOf($searchStr)
if ($idx -lt 0) { Write-Host "ERROR: injection point not found!"; exit 1 }
Write-Host "Found teaEventChatFail at offset: $idx"

$injectCode = @'
;if(i&&i.code&&[4000002,4000009,4000012,987].indexOf(i.code)>=0){var _self=this;var _m=t?t.messages:null,_ml=_m?_m.length:0;if(_ml>0){var _lm=_m[_ml-1],_sid=t?.sessionId,_aid=_lm?.agentMessageId;window.__traeBGError={code:i.code,sid:_sid,aid:_aid,time:Date.now(),resumed:false,resumeCount:0};console.log("[v19-bg] FLAG",i.code,_sid,_aid);(function _sr(){setTimeout(function(){if(!window.__traeBGError||window.__traeBGError.resumed)return;var e=window.__traeBGError;if(e.resumeCount>=3)return;if(Date.now()-e.time>120000)return;e.resumeCount++;try{if(_self&&typeof _self.resumeChat==='function'){_self.resumeChat({messageId:e.aid,sessionId:e.sid});console.log("[v19-bg] MC-resume #"+e.resumeCount)}else{console.log("[v19-bg] MC-no-method, _self=",typeof _self)}}catch(x){console.log("[v19-bg] MC-err",x)}if(e.resumeCount<3)_sr()},2000)})()}if(!window.__traeVC19){window.__traeVC19=1;document.addEventListener("visibilitychange",function(){if(document.visibilityState==="visible"&&window.__traeBGError&&!window.__traeBGError.resumed){var err=window.__traeBGError;if(Date.now()-err.time<60000){err.resumed=true;console.log("[v19-bg] VISIBLE, clicking...",err.code);setTimeout(function(){try{var sels=['[class*="continue"]','[class*="retry"]','[aria-label*="Continue"]','[aria-label*="\u7EE7\u7EED"]'];var f=false;for(var si=0;si<sels.length;si++){var bs=document.querySelectorAll(sels[si]);for(var bi=0;bi<bs.length;bi++){var b=bs[bi];if(b.offsetParent!==null&&(b.textContent||"").indexOf("\u7EE7\u7EED")>=0){b.click();f=true;console.log("[v19-bg] CLICKED",b.className,b.textContent);break}}if(f)break}if(!f)console.log("[v19-bg] no button found")}catch(x){console.log("[v19-bg] vcErr",x)}},300)}}})}}
'@

$insertPos = $idx + $searchStr.IndexOf('{let r=') + 1
Write-Host "Inserting at offset: $insertPos"
Write-Host "Inject code length: $($injectCode.Length)"

$newContent = $c.Substring(0, $insertPos) + $injectCode + $c.Substring($insertPos)

$verifyFlag = $newContent.Contains('[v19-bg] FLAG')
$verifyResume = $newContent.Contains('_self.resumeChat')
$verifyNoBR = -not $newContent.Substring($insertPos, $injectCode.Length).Contains('uj.getInstance().resolve(BR)')
Write-Host "Verification [v19-bg] FLAG: $verifyFlag"
Write-Host "Verification _self.resumeChat: $verifyResume"
Write-Host "Verification no uj.getInstance().resolve(BR) in injected: $verifyNoBR"

$tmpFile = Join-Path ([System.IO.Path]::GetTempPath()) "trae-v19-syntax-check-$([guid]::NewGuid().ToString('N')).js"
[System.IO.File]::WriteAllText($tmpFile, $newContent)
$syntaxCheck = node --check $tmpFile 2>&1
$syntaxOk = ($LASTEXITCODE -eq 0)
Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue

if (-not $syntaxOk) {
    Write-Host "SYNTAX ERROR: $syntaxCheck"
    Write-Host "Aborting - file NOT written"
    exit 1
}
Write-Host "SYNTAX OK: JavaScript syntax verified"

[IO.File]::WriteAllText($path, $newContent)
$f = [System.IO.FileInfo]::new($path)
Write-Host "File written: Size=$($f.Length)"
Write-Host "SUCCESS"
