// v14: Hybrid - teaEventChatFail flag + visibilitychange instant resume
const fs = require('fs');
const path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
const cleanBackup = 'd:/Test/trae-unlock/backups/index.js.20260423-083502.backup';
const backupPath = 'd:/Test/trae-unlock/backups/indexjs-v14.backup';

// Restore from clean base (has v7 L1 but no v11/v12/v13)
if (fs.existsSync(cleanBackup)) {
    fs.writeFileSync(path, fs.readFileSync(cleanBackup, 'utf-8'), 'utf-8');
    console.log('Restored from clean backup (v7 only)');
} else {
    console.error('Clean backup not found!');
    process.exit(1);
}

let c = fs.readFileSync(path, 'utf-8');
console.log('Size:', c.length);

// === PART 1: Hook teaEventChatFail to set error flag ===
const findOrig = 'teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)';
const idx = c.indexOf(findOrig);
if (idx < 0) { console.error('Pattern not found!'); process.exit(1); }
console.log('Hook point at:', idx);

// Set flag on ANY call with matching code. No cooldown. No polling. Just flag.
const inject1 = `;try{if(i&&i.code&&[4000002,4000009,4000012,987].indexOf(i.code)>=0){window.__traeBGError={code:i.code,time:Date.now()};console.log("[v14-bg] FLAG SET",i.code)}}catch(_e){}`;

const repl1 = findOrig.replace('{', '{' + inject1);
c = c.replace(findOrig, repl1);

// === PART 2: Add visibilitychange listener at end of file ===
const vcCode = `;
if(!window.__traeVC14){
window.__traeVC14=1;
document.addEventListener("visibilitychange",function(){
    if(document.visibilityState==="visible"&&window.__traeBGError){
        var _err=window.__traeBGError,_now=Date.now();
        if(_now-_err.time<30000){
            window.__traeBGError=null;
            console.log("[v14-bg] VISIBLE, resuming",_err.code);
            try{
                var _s=uj.getInstance().resolve(xC).getState(),_cs=_s.currentSession,_m=_cs?.messages;
                if(_m&&_m.length){
                    var _last=_m[_m.length-1],_ec=_last?.exception?.code;
                    if([4000002,4000009,4000012,987].indexOf(_ec)>=0&&_last?.agentMessageId&&_cs?.sessionId){
                        uj.getInstance().resolve(BR).resumeChat({messageId:_last.agentMessageId,sessionId:_cs.sessionId});
                        console.log("[v14-bg] OK")
                    }
                }
            }catch(_e){console.log("[v14-bg] err:",_e)}
        }
    }
})
}`;
c = c.trimEnd() + vcCode;

if (!c.includes('[v14-bg]')) { console.error('Fingerprint missing!'); process.exit(1); }

fs.writeFileSync(path, c, 'utf-8');
fs.writeFileSync(backupPath, c);
console.log('Applied! Size:', c.length);

const { execSync } = require('child_process');
try {
    execSync('node --check "' + path.replace(/\//g, '\\') + '"', { stdio: 'pipe' });
    console.log('SYNTAX OK');
} catch (e) {
    console.error('SYNTAX FAIL:', e.stderr?.toString());
    process.exit(1);
}
console.log('DONE');
