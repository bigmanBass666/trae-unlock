// v17: compact single-line injection
const fs = require('fs');
const path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
const cleanBackup = 'd:/Test/trae-unlock/backups/index.js.20260423-083502.backup';
if (fs.existsSync(cleanBackup)) fs.writeFileSync(path, fs.readFileSync(cleanBackup, 'utf-8'), 'utf-8');
else { console.error('No backup'); process.exit(1); }
let c = fs.readFileSync(path, 'utf-8');
const findTea = 'teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)';
const inj = ';try{if(i&&i.code&&[4000002,4000009,4000012,987].indexOf(i.code)>=0){var _n=Date.now();if(!window.__traeAC17||_n-window.__traeAC17>5000){window.__traeAC17=_n;console.log("[v17-bg]",i.code,t?.sessionId,t?.agentMessageId);try{var _s=uj.getInstance().resolve(BR);if(t?.sessionId&&t?.agentMessageId){_s.resumeChat({messageId:t.agentMessageId,sessionId:t.sessionId});console.log("[v17-bg] OK")}else if(t?.sessionId){_s.resumeChat({sessionId:t.sessionId});console.log("[v17-bg] OK-noMsgId")}else console.log("[v17-bg] noCtx",t&&Object.keys(t))}catch(x){console.log("[v17-bg] err2",x)}}}}catch(e){console.log("[v17-bg] err1",e)}}';
c = c.replace(findTea, findTea.replace('{', '{' + inj));
if (!c.includes('[v17-bg]')) { console.error('MISSING'); process.exit(1); }
fs.writeFileSync(path, c, 'utf-8');
console.log('Applied!', c.length);
try { require('child_process').execSync('node --check "' + path.replace(/\//g,'\\') + '"', {stdio: 'pipe'}); console.log('OK'); }
catch(e) { console.error('FAIL:', e.stderr?.toString()); process.exit(1); }
fs.writeFileSync('d:/Test/trae-unlock/backups/indexjs-v17.backup', c);
console.log('DONE');
