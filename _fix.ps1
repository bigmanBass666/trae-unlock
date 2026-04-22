$json = Get-Content 'patches\definitions.json' -Raw

# 1. Replace auto-continue-thinking find_original (line 37)
$oldAct = '"find_original":  "if(V\u0026\u0026J){let e=M.localize(\"continue\",{},\"Continue\");queueMicrotask(()=>{try{if(o\u0026\u0026h)try{D.resumeChat({messageId:o,sessionId:h})}catch(_){D.sendChatMessage({message:e,sessionId:b.getCurrentSession()?.sessionId})}else{D.sendChatMessage({message:e,sessionId:b.getCurrentSession()?.sessionId})}}catch(_){D.sendChatMessage({message:e,sessionId:b.getCurrentSession()?.sessionId})}});return sX().createElement(Cr.Alert,{onDoubleClick:e_,type:\"warning\",message:ef,actionText:e,onActionClick:ec})}"'

$newAct = '"find_original":  "if(V\u0026\u0026J){let e=M.localize(\"continue\",{},\"Continue\");console.log(\"[v7-auto] if(V\u0026\u0026J) ENTERED, o=\"+o+\" h=\"+h);queueMicrotask(()=>{console.log(\"[v7-auto] queueMicrotask FIRED, o=\"+o+\" h=\"+h);try{if(o\u0026\u0026h){console.log(\"[v7-auto] o\u0026\u0026h=true, calling resumeChat...\");try{D.resumeChat({messageId:o,sessionId:h});console.log(\"[v7-auto] resumeChat RETURNED (may be async)\")}catch(err){console.log(\"[v7-auto] resumeChat THREW:\",err);D.sendChatMessage({message:e,sessionId:b.getCurrentSession()?.sessionId})}}else{console.log(\"[v7-auto] o||h=empty, fallback sendChatMessage\");D.sendChatMessage({message:e,sessionId:b.getCurrentSession()?.sessionId})}}catch(err){console.log(\"[v7-auto] OUTER catch:\",err);D.sendChatMessage({message:e,sessionId:b.getCurrentSession()?.sessionId})}});return sX().createElement(Cr.Alert,{onDoubleClick:e_,type:\"warning\",message:ef,actionText:e,onActionClick:ec})}"'

if ($json.Contains($oldAct)) {
    $json = $json.Replace($oldAct, $newAct)
    Write-Host "[OK] auto-continue-thinking find_original updated"
} else {
    Write-Host "[FAIL] auto-continue-thinking find_original NOT FOUND in file"
    # Show what's actually there
    $idx = $json.IndexOf('"find_original":  "if(V')
    if ($idx -ge 0) {
        Write-Host "Actual content at idx $idx :"
        Write-Host $json.Substring($idx, [Math]::Min(200, $json.Length - $idx))
    }
}

# 2. Replace ec-debug-log find_original (line 147)
$oldEc = '"find_original":  "ec=(0,Ir.Z)(()=>{if(!a||!h)return;let e=[...efg];try{if(\"v3\"===p\u0026\u0026e.includes(_)){C.info(`[errorMessageWithAction] resumeChat with v3 process support, agentProcess: ${p}, code: ${_}, userMessageId: ${a}, sessionId: ${h}`),D.resumeChat({messageId:o,sessionId:h});let e=b.getCurrentSession();A.teaEventChatRetry(g,e,{isResume:!0})}else b.retryChatByUserMessageId(a)}catch(e){S.event({name:A_.ICubeAIAgentRetryError,errorCode:e?.code||A_.ICubeAIAgentRetryError,errorMsg:e?.message,errorStack:e?.stack,status:void 0,costTime:0})}})"'

$newEc = '"find_original":  "ec=(0,Ir.Z)(()=>{console.log(\"[v7-manual] ec() CALLED, a=\"+a+\" h=\"+h+\" p=\"+p+\" _=\"+_+\" efg.includes(_)=\"+(Array.isArray(efg)\u0026\u0026efg.includes(_)));if(!a||!h){console.log(\"[v7-manual] BLOCKED: !a||!h, a=\"+a+\" h=\"+h);return}let e=[...efg];console.log(\"[v7-manual] passed !a||!h guard, p=\"+p+\" efg.includes(_)=\"+(e!==undefined\u0026\u0026e.includes(_)));try{if(\"v3\"===p\u0026\u0026e.includes(_)){console.log(\"[v7-manual] v3 MATCH! calling resumeChat o=\"+o+\" h=\"+h);D.resumeChat({messageId:o,sessionId:h});let e2=b.getCurrentSession();A.teaEventChatRetry(g,e2,{isResume:!0})}else{console.log(\"[v7-manual] NO v3 match or _ not in efg, p=\"+p+\" _=\"+_);b.retryChatByUserMessageId(a)}}catch(err){console.log(\"[v7-manual] ec() THROW:\",err);S.event({name:A_.ICubeAIAgentRetryError,componentName:\"ICubeAIChat\",extra:{error:err?.message||String(err),chatRetryType:0,errorCode:_,isV3Mode:\"v3\"===p,errorMessage:ef}})})}"'

if ($json.Contains($oldEc)) {
    $json = $json.Replace($oldEc, $newEc)
    Write-Host "[OK] ec-debug-log find_original updated"
} else {
    Write-Host "[FAIL] ec-debug-log find_original NOT FOUND in file"
    $idx2 = $json.IndexOf('"find_original":  "ec=(')
    if ($idx2 -ge 0) {
        Write-Host "Actual content at idx $idx2 :"
        Write-Host $json.Substring($idx2, [Math]::Min(200, $json.Length - $idx2))
    }
}

# Write back
Set-Content 'patches\definitions.json' $json -NoNewline
Write-Host "`nFile written."
