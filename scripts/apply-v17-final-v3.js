const fs = require('fs');
const path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
const cleanBackup = 'd:/Test/trae-unlock/backups/index.js.20260423-083502.backup';
if (fs.existsSync(cleanBackup)) fs.writeFileSync(path, fs.readFileSync(cleanBackup, 'utf-8'), 'utf-8');
else { console.error('No backup'); process.exit(1); }
let c = fs.readFileSync(path, 'utf-8');

var f = 'teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)';
// v17 FINAL v3: resumeChat + qMT polling fallback (NOT setTimeout!)
// qMT proven to work in background (v13 test showed it runs even when Store empty)
// Poll every microtask cycle (~100-200 iterations = ~1-3 seconds), then fallback to sendChatMessage
var v = ';if(i&&i.code&&[4000002,4000009,4000012,987].indexOf(i.code)>=0){var _n=Date.now();if(!window.__traeAC17||_n-window.__traeAC17>5000){window.__traeAC17=_n;try{var _m=t?t.messages:null,_ml=_m?_m.length:0;if(_ml>0){var _lm=_m[_ml-1],_sid=t?.sessionId,_aid=_lm?.agentMessageId;if(_sid){console.log("[v17-bg]",i.code,_sid,_aid);var _svc=uj.getInstance().resolve(BR),_chat=uj.getInstance().resolve(Di);try{if(_aid)_svc.resumeChat({messageId:_aid,sessionId:_sid});else _svc.resumeChat({sessionId:_sid});console.log("[v17-bg] OK-resume")}catch(_ex){console.log("[v17-bg] rErr",_ex)}var _startMsgLen=_ml,_pollCount=0,_pollMax=150;(function _poll17(){_pollCount++;if(_pollCount>_pollMax){console.log("[v17-bg] poll-timeout,fallback");try{_chat.sendChatMessage({message:"Continue",sessionId:_sid});console.log("[v17-bg] OK-send")}catch(_e5){console.log("[v17-bg] sErr",_e5)}}else{queueMicrotask(function(){try{var _s=uj.getInstance().resolve(xC).getState(),_cs=_s.currentSession,_cml=_cs?.messages?.length||0;if(_cml>_startMsgLen){console.log("[v17-bg] OK-resumed",_cml-_startMsgLen,"new msgs")}else{_poll17()}}catch(_e4){console.log("[v17-bg] pErr",_e4)}})}})()}}}catch(_e){console.log("[v17-bg] err",_e)}}}';
c = c.replace(f, f.replace('{', '{' + v));

fs.writeFileSync(path, c, 'utf-8');
console.log(c.includes('[v17-bg]') ? 'INJECTED' : 'FAIL');
try { require('child_process').execSync('node --check "' + path.replace(/\//g,'\\') + '"', {stdio:'pipe'}); console.log('SYNTAX OK'); }
catch(e) { console.error('SYNTAX FAIL:', e.stderr?.toString()); process.exit(1); }
