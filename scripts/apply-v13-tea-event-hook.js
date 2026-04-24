// v13: Hook teaEventChatFail + queueMicrotask polling
// Strategy: teaEventChatFail fires immediately after error (67 lines in log!)
//   → detect error code from 3rd param (i.code)
//   → queueMicrotask loop to wait for Store update
//   → resumeChat as soon as exception appears in Store

const fs = require('fs');
const path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
const backupPath = 'd:/Test/trae-unlock/backups/index.js.pre-v12.backup';

// Restore from pre-v12 backup (clean base)
if (fs.existsSync(backupPath)) {
    fs.writeFileSync(path, fs.readFileSync(backupPath, 'utf-8'), 'utf-8');
    console.log('Restored from pre-v12 backup (clean base)');
} else {
    console.error('Backup not found!');
    process.exit(1);
}

let c = fs.readFileSync(path, 'utf-8');
console.log('File size:', c.length);

// Target: teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t);
const findOrig = 'teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)';
const idx = c.indexOf(findOrig);
if (idx < 0) {
    console.error('Pattern not found! Searching for partial...');
    const pi = c.indexOf('teaEventChatFail(e,t,i)');
    if (pi >= 0) {
        console.log('Partial at:', pi, c.substring(pi, pi + 80));
    }
    process.exit(1);
}
console.log('Found at offset:', idx);

// v13 inject: after {, check i.code, start qMT polling if match
const inject = `;if(i&&i.code&&[4000002,4000009,4000012,987].indexOf(i.code)>=0){var _t13=Date.now();if(!window.__traeAC13||_t13-window.__traeAC13>5000){window.__traeAC13=_t13;console.log("[v13-bg] teaEventChatFail",i.code);var _poll13=function(){queueMicrotask(function(){try{var _s=uj.getInstance().resolve(xC).getState(),_cs=_s.currentSession,_m=_cs?.messages;if(_m&&_m.length){var _last=_m[_m.length-1],_ec=_last?.exception?.code;if(_ec===i.code||[4000002,4000009,4000012,987].indexOf(_ec)>=0){if(_last?.agentMessageId&&_cs?.sessionId){uj.getInstance().resolve(BR).resumeChat({messageId:_last.agentMessageId,sessionId:_cs.sessionId});console.log("[v13-bg] OK");return}}var _dt=Date.now();if(_dt-_t13<3000){_poll13()}else{console.log("[v13-bg] timeout")}}}catch(_e){console.log("[v13-bg] err:",_e)}})};_poll13()}}`;

const repl = findOrig.replace('{', '{' + inject);
c = c.replace(findOrig, repl);

if (!c.includes('[v13-bg]')) { console.error('Fingerprint missing!'); process.exit(1); }

fs.writeFileSync(path, c, 'utf-8');
console.log('Applied! Size:', c.length);

const { execSync } = require('child_process');
try {
    execSync('node --check "' + path.replace(/\//g, '\\') + '"', { stdio: 'pipe' });
    console.log('SYNTAX OK');
} catch (e) {
    console.error('SYNTAX FAIL:', e.stderr?.toString());
    process.exit(1);
}

fs.writeFileSync(backupPath, c);
console.log('DONE');
