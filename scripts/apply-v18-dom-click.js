// v18: teaEventChatFail flag + visibilitychange DOM click (INSIDE IIFE, proven location)
const fs = require('fs');
const path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
const cleanBackup = 'd:/Test/trae-unlock/backups/index.js.20260423-083502.backup';
if (fs.existsSync(cleanBackup)) fs.writeFileSync(path, fs.readFileSync(cleanBackup, 'utf-8'), 'utf-8');
else { console.error('No backup'); process.exit(1); }
let c = fs.readFileSync(path, 'utf-8');

// PART 1: teaEventChatFail flag (same as v17 diagnostic - PROVEN to work in bg)
var f = 'teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)';
var v1 = ';if(i&&i.code&&[4000002,4000009,4000012,987].indexOf(i.code)>=0){var _m=t?t.messages:null,_ml=_m?_m.length:0;if(_ml>0){var _lm=_m[_ml-1],_sid=t?.sessionId,_aid=_lm?.agentMessageId;window.__traeBGError={code:i.code,sid:_sid,aid:_aid,time:Date.now()};console.log("[v18-bg] FLAG",i.code,_sid,_aid)}}}';
c = c.replace(f, f.replace('{', '{' + v1));

// PART 2: visibilitychange DOM click INSIDE sub#8 callback area (PROVEN EXECUTION LOCATION)
// Use the pre-subscribe anchor that worked in v15/v16
var preSubAnchor = 'a(),n.subscribe((e,t)';
var pIdx = c.indexOf(preSubAnchor);
if (pIdx < 0) { console.error('pre-sub anchor not found!'); process.exit(1); }
console.log('PART2 at:', pIdx);

// Inject VC listener + DOM finder before existing subscribe #8
// The listener: on visible → check flag → find continue button → click
var vcCode = `;
if(!window.__traeVC18){
window.__traeVC18=1;
document.addEventListener("visibilitychange",function(){
    if(document.visibilityState==="visible"&&window.__traeBGError){
        var err=window.__traeBGError;
        var now=Date.now();
        if(now-err.time<60000){
            window.__traeBGError=null;
            console.log("[v18-bg] VISIBLE, looking for button...",err.code);
            setTimeout(function(){
                try{
                    var btns=document.querySelectorAll('[class*="continue"],[class*="retry"],[aria-label*="Continue"],[aria-label*="继续"]');
                    var found=false;
                    for(var bi=0;bi<btns.length;bi++){
                        var b=btns[bi];
                        if(b.offsetParent!==null){
                            b.click();
                            found=true;
                            console.log("[v18-bg] CLICKED button",b.className,b.textContent);
                            break;
                        }
                    }
                    if(!found){
                        var all=document.querySelectorAll('button,[role="button"],[class*="btn"]');
                        for(var ai=0;ai<all.length;ai++){
                            var a=all[ai];
                            var txt=(a.textContent||"").toLowerCase();
                            var cls=(a.className||"").toLowerCase();
                            if((txt.indexOf("continue")>=0||txt.indexOf("继续")>=0||cls.indexOf("continue")>=0)&&a.offsetParent!==null){
                                a.click();
                                found=true;
                                console.log("[v18-bg] CLICKED text-match",a.textContent);
                                break;
                            }
                        }
                    }
                    if(!found)console.log("[v18-bg] no button found");
                }catch(e){console.log("[v18-bg] vcErr",e)}
            },500);
        }
    }
})
}`;

c = c.replace(preSubAnchor, vcCode + 'a(),n.subscribe((e,t)');

if (!c.includes('[v18-bg]')) { console.error('Fingerprint missing!'); process.exit(1); }

fs.writeFileSync(path, c, 'utf-8');
console.log('Applied! Size:', c.length);
try { require('child_process').execSync('node --check "' + path.replace(/\//g,'\\') + '"', {stdio:'pipe'}); console.log('SYNTAX OK'); }
catch(e) { console.error('SYNTAX FAIL:', e.stderr?.toString()); process.exit(1); }
fs.writeFileSync('d:/Test/trae-unlock/backups/indexjs-v18.backup', c);
console.log('DONE');
