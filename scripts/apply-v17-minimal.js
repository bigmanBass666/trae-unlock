const fs = require('fs');
const path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
const cleanBackup = 'd:/Test/trae-unlock/backups/index.js.20260423-083502.backup';

if (fs.existsSync(cleanBackup)) fs.writeFileSync(path, fs.readFileSync(cleanBackup, 'utf-8'), 'utf-8');
else { console.error('No backup'); process.exit(1); }
let c = fs.readFileSync(path, 'utf-8');

// Step 1: inject minimal logging (PROVEN TO WORK)
var f = 'teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)';
var v1 = ';if(i&&i.code&&[4000002,4000009,4000012,987].indexOf(i.code)>=0){console.log("[v17-bg]",i.code,"sid:",t&&t.sessionId,"aid:",t&&t.agentMessageId)}';
c = c.replace(f, f.replace('{', '{' + v1));

// Step 2: ADD resumeChat by replacing the [v17-bg] log line
// Find: console.log("[v17-bg]",i.code,"sid:",t&&t.sessionId,"aid:",t&&t.agentMessageId)
// Replace with: console.log(...) + ;try{resume logic}
var logLine = 'console.log("[v17-bg]",i.code,"sid:",t&&t.sessionId,"aid:",t&&t.agentMessageId)';
var resumeLogic = [
    logLine,
    ';try{if(t&&t.sessionId&&t.agentMessageId){uj.getInstance().resolve(BR).resumeChat({messageId:t.agentMessageId,sessionId:t.sessionId});console.log("[v17-bg] OK")}}catch(e){console.log("[v17-bg] err",e)}}'
].join('');
c = c.replace(logLine, resumeLogic);

fs.writeFileSync(path, c, 'utf-8');
console.log(c.includes('[v17-bg]') ? 'INJECTED' : 'FAIL');
try { require('child_process').execSync('node --check "' + path.replace(/\//g,'\\') + '"', {stdio:'pipe'}); console.log('SYNTAX OK'); }
catch(e) { console.error('SYNTAX FAIL:', e.stderr?.toString()); process.exit(1); }
