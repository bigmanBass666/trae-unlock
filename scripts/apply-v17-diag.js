const fs = require('fs');
const path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
const cleanBackup = 'd:/Test/trae-unlock/backups/index.js.20260423-083502.backup';
if (fs.existsSync(cleanBackup)) fs.writeFileSync(path, fs.readFileSync(cleanBackup, 'utf-8'), 'utf-8');
else { console.error('No backup'); process.exit(1); }
let c = fs.readFileSync(path, 'utf-8');

// v17 DIAGNOSTIC ONLY - no resumeCall, just log all available info
var f = 'teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)';
var v = ';if(i&&i.code){var _keys=t?Object.keys(t):"null";console.log("[v17-bg]",JSON.stringify({code:i.code,sid:t?.sessionId,aid:t?.agentMessageId,type:typeof t,keys:_keys}))}';
c = c.replace(f, f.replace('{', '{' + v));

fs.writeFileSync(path, c, 'utf-8');
console.log(c.includes('[v17-bg]') ? 'INJECTED' : 'FAIL');
try { require('child_process').execSync('node --check "' + path.replace(/\//g,'\\') + '"', {stdio:'pipe'}); console.log('SYNTAX OK'); }
catch(e) { console.error('SYNTAX FAIL:', e.stderr?.toString()); process.exit(1); }
