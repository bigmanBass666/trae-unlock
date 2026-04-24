const fs = require('fs');
const path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';

console.log('[v19] === Hybrid Background Auto-Resume Patch ===');

let content = fs.readFileSync(path, 'utf8');
const originalLength = content.length;
console.log(`[v19] Original file size: ${originalLength}`);

// ============================================
// PART1: teaEventChatFail flag enhancement
// Replace existing v16 __traeBGError with enhanced version (includes sid/aid)
// ============================================
const part1Old = 'window.__traeBGError={code:i.code,time:Date.now()}';
const part1Idx = content.indexOf(part1Old);

if (part1Idx === -1) {
    console.error('[v19] PART1 ERROR: Cannot find:', part1Old);
    process.exit(1);
}

const part1New = `(function(){var _m=t?t.messages:null,_ml=_m?_m.length:0;if(_ml>0){var _lm=_m[_ml-1],_sid=t?.sessionId,_aid=_lm?.agentMessageId;window.__traeBGError={code:i.code,sid:_sid,aid:_aid,time:Date.now(),resumed:false,resumeCount:0};console.log("[v19-bg] FLAG",i.code,_sid,_aid)}else{window.__traeBGError={code:i.code,sid:null,aid:null,time:Date.now(),resumed:false,resumeCount:0};console.log("[v19-bg] FLAG",i.code,"no-messages")}})()`;
content = content.substring(0, part1Idx) + part1New + content.substring(part1Idx + part1Old.length);
console.log(`[v19] PART1 replaced at offset ${part1Idx} (enhanced __traeBGError)`);

// ============================================
// PART2 & PART3: Module-level injection
// Anchor: ',l})()});' — inject BEFORE this pattern
// Original tail: ...FW}})(),l})()});
// After inject:   ...FW}})(),[CODE],l})()});
// ============================================
const anchorPattern = ',l})()});';
const anchorIdx = content.indexOf(anchorPattern, content.length - 100);

if (anchorIdx === -1) {
    console.error('[v19] PART2/3 ERROR: Cannot find anchor:', anchorPattern);
    process.exit(1);
}

console.log(`[v19] Module-level anchor at offset ${anchorIdx}`);

const part2 = `void(!window.__traeMC19&&(window.__traeMC19=1,(function(){function scheduleRetry(){setTimeout(function(){if(!window.__traeBGError)return;var err=window.__traeBGError;if(err.resumed||err.resumeCount>=3)return;var now=Date.now();if(now-err.time>120000)return;try{var svc=uj.getInstance().resolve(BR);if(svc&&svc.resumeChat){svc.resumeChat({messageId:err.aid,sessionId:err.sid});err.resumeCount++;console.log("[v19-bg] MC-resume #"+err.resumeCount)}}catch(e){console.log("[v19-bg] MC-err",e)}scheduleRetry()},2000)}if(window.__traeBGError)scheduleRetry()})()))`;

const part3 = `void(!window.__traeVC19&&(window.__traeVC19=1,document.addEventListener("visibilitychange",function(){if(document.visibilityState==="visible"&&window.__traeBGError&&!window.__traeBGError.resumed){var err=window.__traeBGError;var now=Date.now();if(now-err.time<60000){err.resumed=true;console.log("[v19-bg] VISIBLE, clicking button...",err.code);setTimeout(function(){try{var selectors=['[class*="continue"]','[class*="retry"]','[aria-label*="Continue"]','[aria-label*="继续"]'];var found=false;for(var si=0;si<selectors.length;si++){var btns=document.querySelectorAll(selectors[si]);for(var bi=0;bi<btns.length;bi++){var b=btns[bi];if(b.offsetParent!==null&&(b.textContent||"").indexOf("继续")>=0){b.click();found=true;console.log("[v19-bg] CLICKED",b.className,b.textContent);break}}if(found)break}if(!found)console.log("[v19-bg] no button found")}catch(e){console.log("[v19-bg] vcErr",e)}},300)}}})))`;

content = content.substring(0, anchorIdx) + ',' + part2 + ',' + part3 + content.substring(anchorIdx);
console.log(`[v19] PART2+PART3 injected at offset ${anchorIdx} (before ',l})()});')`);

// Write back
fs.writeFileSync(path, content, 'utf8');
console.log(`[v19] File written. New size: ${content.length} (+${content.length - originalLength} bytes)`);

// Verify fingerprint
const fpCount = (content.match(/\[v19-bg\]/g) || []).length;
console.log(`[v19] Fingerprint [v19-bg] found ${fpCount} time(s)`);

console.log('[v19] === Injection Complete ===');
