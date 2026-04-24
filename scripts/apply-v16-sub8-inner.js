// v16: Safest possible injection - insert inside sub#8 callback body
// Use a MID-CALLBACK anchor instead of tail to avoid brace issues
const fs = require('fs');
const path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
const cleanBackup = 'd:/Test/trae-unlock/backups/index.js.20260423-083502.backup';

if (fs.existsSync(cleanBackup)) {
    fs.writeFileSync(path, fs.readFileSync(cleanBackup, 'utf-8'), 'utf-8');
} else { console.error('No backup'); process.exit(1); }

let c = fs.readFileSync(path, 'utf-8');

// PART 1: teaEventChatFail flag (PROVEN)
const findTea = 'teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)';
c = c.replace(findTea, findTea.replace('{', '{' + `;try{if(i&&i.code&&[4000002,4000009,4000012,987].indexOf(i.code)>=0){window.__traeBGError={code:i.code,time:Date.now()};console.log("[v16-bg] FLAG",i.code)}}catch(_e){}`));
console.log('PART1 OK');

// PART 2: Inject INSIDE sub#8 callback using MID-point anchor
// The callback body contains: ((condition)&&a())
// We'll replace "&&a()" with "&&a();OUR_CHECK"
// This is a simple expression-statement replacement, no brace changes needed!
const midAnchor = 'currentSessionId!==t.currentSessionId)&&a()';
const mIdx = c.indexOf(midAnchor);
if (mIdx < 0) { console.error('mid-anchor not found!'); process.exit(1); }
console.log('PART2 at:', mIdx);

// Simple: just append after the a() call, before the closing )
const check = `;
try{
var _f=window.__traeBGError;
if(_f){
var _m=e.currentSession?.messages;
if(_m&&_m.length){
var _l=_m[_m.length-1];
if([4000002,4000009,4000012,987].indexOf(_l?.exception?.code)>=0&&_l?.agentMessageId&&e.currentSession?.sessionId){
window.__traeBGError=null;
uj.getInstance().resolve(BR).resumeChat({messageId:_l.agentMessageId,sessionId:e.currentSession.sessionId});
console.log("[v16-bg] OK",_f.code)
}
}}
}catch(__e){}`;

c = c.replace(midAnchor, 'currentSessionId!==t.currentSessionId)&&a()' + check);

if (!c.includes('[v16-bg]')) { console.error('Fingerprint missing!'); process.exit(1); }

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

fs.writeFileSync('d:/Test/trae-unlock/backups/indexjs-v16.backup', c);
console.log('DONE');
