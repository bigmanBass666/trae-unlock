const fs = require('fs');
const path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
const cleanBackup = 'd:/Test/trae-unlock/backups/index.js.20260423-083502.backup';
if (fs.existsSync(cleanBackup)) fs.writeFileSync(path, fs.readFileSync(cleanBackup, 'utf-8'), 'utf-8');
else { console.error('No backup'); process.exit(1); }
let c = fs.readFileSync(path, 'utf-8');

var f = 'teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)';
// v17 FINAL v2: resumeChat + 2s fallback to sendChatMessage (same pattern as v7!)
// Use Di=_aiAgentChatService for both resumeChat and sendChatMessage
var v = ';if(i&&i.code&&[4000002,4000009,4000012,987].indexOf(i.code)>=0){var _n=Date.now();if(!window.__traeAC17||_n-window.__traeAC17>5000){window.__traeAC17=_n;try{var _m=t?t.messages:null,_ml=_m?_m.length:0;if(_ml>0){var _lm=_m[_ml-1],_sid=t?.sessionId,_aid=_lm?.agentMessageId;if(_sid){console.log("[v17-bg] RESUMING",i.code,_sid,_aid);var _svc=uj.getInstance().resolve(BR),_chat=uj.getInstance().resolve(Di);if(_aid){try{_svc.resumeChat({messageId:_aid,sessionId:_sid});console.log("[v17-bg] OK-resume")}catch(_ex){console.log("[v17-bg] resumeErr",_ex)}}setTimeout(function(){try{var _s2=uj.getInstance().resolve(xC).getState(),_cs2=_s2.currentSession,_ml2=_cs2?.messages?.length||0;if(_ml2<=_ml){console.log("[v17-bg] fallback-sendChat");_chat.sendChatMessage({message:"Continue",sessionId:_sid});console.log("[v17-bg] OK-send")}}catch(_e3){console.log("[v17-bg] fallbackErr",_e3)}},3000)}else{console.log("[v17-bg] noAid")}}}catch(_e){console.log("[v17-bg] err",_e)}}}';
c = c.replace(f, f.replace('{', '{' + v));

fs.writeFileSync(path, c, 'utf-8');
console.log(c.includes('[v17-bg]') ? 'INJECTED' : 'FAIL');
try { require('child_process').execSync('node --check "' + path.replace(/\//g,'\\') + '"', {stdio:'pipe'}); console.log('SYNTAX OK'); }
catch(e) { console.error('SYNTAX FAIL:', e.stderr?.toString()); process.exit(1); }
