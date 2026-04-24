const fs = require('fs');
const path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
const cleanBackup = 'd:/Test/trae-unlock/backups/index.js.20260423-083502.backup';
if (fs.existsSync(cleanBackup)) fs.writeFileSync(path, fs.readFileSync(cleanBackup, 'utf-8'), 'utf-8');
else { console.error('No backup'); process.exit(1); }
let c = fs.readFileSync(path, 'utf-8');

var f = 'teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)';
// Log: code, sessionId, messages.length, lastMsg.agentMessageId, lastMsg.exception
var v = ';if(i&&i.code){var _m=t?t.messages:null,_ml=_m?_m.length:0,_lm=_ml>0?_m[_ml-1]:null;console.log("[v17-bg]",JSON.stringify({code:i.code,sid:t?.sessionId,msgLen:_ml,lastAid:_lm?_lm.agentMessageId:null,lastExc:_lm?_lm.exception:null}))}';
c = c.replace(f, f.replace('{', '{' + v));

fs.writeFileSync(path, c, 'utf-8');
console.log(c.includes('[v17-bg]') ? 'INJECTED' : 'FAIL');
try { require('child_process').execSync('node --check "' + path.replace(/\//g,'\\') + '"', {stdio:'pipe'}); console.log('SYNTAX OK'); }
catch(e) { console.error('SYNTAX FAIL:', e.stderr?.toString()); process.exit(1); }
