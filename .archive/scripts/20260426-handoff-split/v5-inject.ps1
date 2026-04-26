$ErrorActionPreference = "Stop"
$path = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'

Write-Host "[v5-inject] Reading target file..." -ForegroundColor Cyan
$c = [IO.File]::ReadAllText($path)
$origLen = $c.Length
Write-Host "[v5-inject] Original size: $origLen bytes" -ForegroundColor Gray

$target = 'teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)'
$idx = $c.IndexOf($target)

if ($idx -lt 0) {
    Write-Host "[v5-inject] ERROR: teaEventChatFail not found!" -ForegroundColor Red
    exit 1
}

$braceIdx = $c.IndexOf('{', $idx)
if ($braceIdx -lt 0) {
    Write-Host "[v5-inject] ERROR: opening brace not found!" -ForegroundColor Red
    exit 1
}

$injectPos = $braceIdx + 1
Write-Host "[v5-inject] Injection point: offset $injectPos (after { at $braceIdx)" -ForegroundColor Yellow

$v5Code = @'
;if(i&&i.code&&[4000002,4000009,4000012,987].indexOf(i.code)>=0){var _ts=function(){return new Date().toISOString().substr(11,12)};var _m=t?t.messages:null,_ml=_m?_m.length:0;if(_ml>0){var _lm=_m[_ml-1],_sid=t?.sessionId,_aid=_lm?.agentMessageId;window.__traeBGError={code:i.code,sid:_sid,aid:_aid,time:Date.now(),resumed:false,resumeCount:0};console.log("[v19-bg]"+_ts()+" FLAG",i.code,_sid,_aid);(function _sr(){setTimeout(function(){if(!window.__traeBGError||window.__traeBGError.resumed)return;var e=window.__traeBGError;if(e.resumeCount>=1)return;if(Date.now()-e.time>120000)return;e.resumeCount++;try{var _cs=uj.getInstance().resolve(Di);if(_cs&&typeof _cs.resumeChat==='function'){_cs.resumeChat({messageId:e.aid,sessionId:e.sid});console.log("[v19-bg]"+_ts()+" MC-resume #"+e.resumeCount)}else{console.log("[v19-bg]"+_ts()+" MC-no-svc, Di=",typeof Di," resolved=",typeof _cs)}}catch(x){var _msg=(x.message||x.toString()||'');if(_msg.indexOf('session_id')>=0||_msg.indexOf('Validate')>=0){console.log("[v19-bg]"+_ts()+" MC-validate-ignore",_msg)}else{console.log("[v19-bg]"+_ts()+" MC-err",_msg)}}if(e.resumeCount<1)_sr()},2000)})()}if(!window.__traeVC19&&typeof document!=='undefined'&&typeof document.addEventListener==='function'){window.__traeVC19=1;document.addEventListener("visibilitychange",function(){if(document.visibilityState==="visible"&&window.__traeBGError&&!window.__traeBGError.resumed){var err=window.__traeBGError;if(Date.now()-err.time<60000){err.resumed=true;console.log("[v19-bg]"+_ts()+" VISIBLE, clicking...",err.code);setTimeout(function(){try{var sels=['[class*="continue"]','[class*="retry"]','[aria-label*="Continue"]','[aria-label*="继续"]'];var f=false;for(var si=0;si<sels.length;si++){var bs=document.querySelectorAll(sels[si]);for(var bi=0;bi<bs.length;bi++){var b=bs[bi];if(b.offsetParent!==null&&(b.textContent||"").indexOf("继续")>=0){b.click();f=true;console.log("[v19-bg]"+_ts()+" CLICKED",b.className,b.textContent);break}}if(f)break}if(!f)console.log("[v19-bg]"+_ts()+" no button found");try{if(typeof window!=='undefined'&&window.dispatchEvent){window.dispatchEvent(new Event('focus'));window.dispatchEvent(new Event('resize'))}}catch(re){console.log("[v19-bg]"+_ts()+" refresh-err",re)}}catch(x){console.log("[v19-bg]"+_ts()+" vcErr",x)}},300)}}})}else if(!window.__traeVC19){console.log("[v19-bg]"+_ts()+" VC-skip: no document.addEventListener");window.__traeVC19=2}}
'@

$newC = $c.Substring(0, $injectPos) + $v5Code + $c.Substring($injectPos)

Write-Host "[v5-inject] Writing injected file..." -ForegroundColor Cyan
[IO.File]::WriteAllText($path, $newC)
$newLen = [IO.File]::ReadAllText($path).Length

Write-Host "[v5-inject] New size: $newLen bytes (added $($newLen - $origLen))" -ForegroundColor Green
Write-Host "[v5-inject] INJECTION COMPLETE" -ForegroundColor Green
