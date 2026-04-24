const fs = require('fs');
const path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
const cleanBackup = 'd:/Test/trae-unlock/backups/index.js.20260423-083502.backup';
if (fs.existsSync(cleanBackup)) fs.writeFileSync(path, fs.readFileSync(cleanBackup, 'utf-8'), 'utf-8');
else { console.error('No backup'); process.exit(1); }
let c = fs.readFileSync(path, 'utf-8');

var f = 'teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)';
// v17 FINAL: detect error → extract sid+aid from t (session obj) → IMMEDIATELY resumeChat in BACKGROUND!
// Key: build params object STEP BY STEP to avoid {} syntax conflict with surrounding code
var v = ';if(i&&i.code&&[4000002,4000009,4000012,987].indexOf(i.code)>=0){var _n=Date.now();if(!window.__traeAC17||_n-window.__traeAC17>5000){window.__traeAC17=_n;try{var _m=t?t.messages:null,_ml=_m?_m.length:0;if(_ml>0){var _lm=_m[_ml-1],_sid=t?.sessionId,_aid=_lm?.agentMessageId;if(_sid&&_aid){console.log("[v17-bg] RESUMING",i.code,_sid,_aid);var _p={};_p.messageId=_aid;_p.sessionId=_sid;uj.getInstance().resolve(BR).resumeChat(_p);console.log("[v17-bg] OK")}}}catch(_e){console.log("[v17-bg] err",_e)}}}';
c = c.replace(f, f.replace('{', '{' + v));

fs.writeFileSync(path, c, 'utf-8');
console.log(c.includes('[v17-bg]') ? 'INJECTED' : 'FAIL');
try { require('child_process').execSync('node --check "' + path.replace(/\//g,'\\') + '"', {stdio:'pipe'}); console.log('SYNTAX OK'); }
catch(e) { console.error('SYNTAX FAIL:', e.stderr?.toString()); process.exit(1); }
