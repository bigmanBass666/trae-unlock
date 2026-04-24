// v15: Simpler approach - inject BEFORE subscribe #8 line
// Instead of replacing the end of subscribe callback, add our code
// as a separate statement RIGHT BEFORE the n.subscribe(...) call.
// This way we don't touch subscribe's internal structure at all.
const fs = require('fs');
const path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
const cleanBackup = 'd:/Test/trae-unlock/backups/index.js.20260423-083502.backup';

if (fs.existsSync(cleanBackup)) {
    fs.writeFileSync(path, fs.readFileSync(cleanBackup, 'utf-8'), 'utf-8');
} else { console.error('No backup'); process.exit(1); }

let c = fs.readFileSync(path, 'utf-8');

// PART 1: teaEventChatFail flag
const findTea = 'teaEventChatFail(e,t,i){let r=this.getAssistantMessageReportParamsByTurnId(e,t)';
const injectFlag = `;try{if(i&&i.code&&[4000002,4000009,4000012,987].indexOf(i.code)>=0){window.__traeBGError={code:i.code,time:Date.now()};console.log("[v15-bg] FLAG",i.code)}}catch(_e){}`;
c = c.replace(findTea, findTea.replace('{', '{' + injectFlag));
console.log('PART1 OK');

// PART 2: Hook store setState - intercept when messages are updated with exception
// Find: setCurrentSession or any place where Store gets new data with exception
// Better approach: wrap uj.getInstance().resolve(xC).setState to detect exception writes

// Actually, simplest approach: hook the EXISTING subscribe #8 by wrapping it
// Find: n.subscribe((e,t)=>{...original...})
// Replace: n.subscribe((e,t)=>{...original... ;OUR_CHECK...})

// Use a shorter unique anchor right BEFORE n.subscribe(
const preSubAnchor = 'a(),n.subscribe((e,t)';
const pIdx = c.indexOf(preSubAnchor);
if (pIdx < 0) {
    console.error('pre-subscribe anchor not found!');
    // Try alternative
    const alt = c.indexOf('n.subscribe((e,t)');
    console.log('alt n.subscribe at:', alt);
    process.exit(1);
}
console.log('PART2 anchor at:', pIdx);

// Inject our store-watcher subscription RIGHT BEFORE the existing subscribe #8
// This new subscription will fire on EVERY state change and check for our flag + exception
const watcherCode = `
uj.getInstance().resolve(xC).subscribe(function(e){
  try{
    var _f=window.__traeBGError;
    if(_f&&_f.code){
      var _now=Date.now();
      if(_now-_f.time<30000){
        var _m=e.currentSession?.messages;
        if(_m&&_m.length){
          var _l=_m[_m.length-1];
          if([4000002,4000009,4000012,987].indexOf(_l?.exception?.code)>=0&&_l?.agentMessageId&&e.currentSession?.sessionId){
            window.__traeBGError=null;
            uj.getInstance().resolve(BR).resumeChat({messageId:_l.agentMessageId,sessionId:e.currentSession.sessionId});
            console.log("[v15-bg] OK",_f.code)
          }
        }
      }
    }
  }catch(_e){}
});
`;

// Insert watcher BEFORE the existing subscribe #8
c = c.replace(preSubAnchor, watcherCode + 'a(),n.subscribe((e,t)');

if (!c.includes('[v15-bg]')) { console.error('Fingerprint missing!'); process.exit(1); }

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
fs.writeFileSync('d:/Test/trae-unlock/backups/indexjs-v15.backup', c);
console.log('DONE');
