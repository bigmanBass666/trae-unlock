// v12 mutation-site injection v3 - MINIMAL REPLACEMENT
// Only replace the h.exception= assignment, don't touch braces/return
const fs = require('fs');
const path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
const backupPath = 'd:/Test/trae-unlock/backups/index.js.pre-v12.backup';

if (fs.existsSync(backupPath)) {
    fs.writeFileSync(path, fs.readFileSync(backupPath, 'utf-8'), 'utf-8');
}

let c = fs.readFileSync(path, 'utf-8');
console.log('Size:', c.length);

// ONLY replace the assignment line, keep }}return h} intact
const findOrig = 'h.exception={code:t,message:i.message,data:e.error.data}';
const idx = c.indexOf(findOrig);
if (idx < 0) { console.error('NOT FOUND'); process.exit(1); }
console.log('Found at:', idx);

// Append our detection code after the assignment, before the closing }
const extra = `;if(t===4000002||t===4000009||t===4000012||t===987){var _n=Date.now();if(!window.__traeAC12||_n-window.__traeAC12>5000){window.__traeAC12=_n;console.log("[v12-bg]",t);queueMicrotask(function(){try{var _s=uj.getInstance().resolve(xC).getState(),_cs=_s.currentSession,_m=_cs?.messages;if(_m&&_m.length){var _last=_m[_m.length-1];if(_last?.agentMessageId&&_cs?.sessionId){uj.getInstance().resolve(BR).resumeChat({messageId:_last.agentMessageId,sessionId:_cs.sessionId});console.log("[v12-bg] OK")}}}catch(_e){console.log("[v12-bg] err:",_e)}})}}`;

const repl = findOrig + extra;
c = c.replace(findOrig, repl);

if (!c.includes('[v12-bg]')) { console.error('NO FINGERPRINT'); process.exit(1); }

fs.writeFileSync(path, c, 'utf-8');
console.log('Applied! Size:', c.length);

const { execSync } = require('child_process');
try {
    execSync('node --check "' + path.replace(/\//g, '\\') + '"', { stdio: 'pipe' });
    console.log('SYNTAX OK');
} catch (e) {
    console.error('SYNTAX FAIL:', e.stderr?.toString());
    const di = c.indexOf('[v12-bg]');
    if (di >= 0) console.error('DEBUG:', c.substring(Math.max(0, di - 60), di + 80));
    process.exit(1);
}

fs.writeFileSync(backupPath, c);
console.log('DONE');
