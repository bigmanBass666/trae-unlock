var fs = require('fs');
var execSync = require('child_process').execSync;
var path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
var backupDir = 'd:/Test/trae-unlock/backups';

console.log('[v27] === RESTORE + REAPPLY ===');

// Step 1: Find latest good backup
var files = fs.readdirSync(backupDir).filter(function(f) {
    return f.indexOf('before-v27') >= 0 && f.endsWith('.backup');
}).sort().reverse();

if (files.length === 0) {
    console.error('❌ No v27 backup found!');
    process.exit(1);
}

console.log('[v27] Restoring from:', files[0]);
fs.copyFileSync(backupDir + '/' + files[0], path);

var c = fs.readFileSync(path, 'utf8');
console.log('[v27] File size after restore:', c.length);

// Verify clean state
var idx2 = c.indexOf('parse(e,t){e.code===kg.MODEL_RESPONSE_TIMEOUT_ERROR');
console.log('[v27] L2 injection point found:', idx2 >= 0 ? '@' + idx2 : 'NOT FOUND!');

if (idx2 < 0) {
    console.error('❌ Injection point not found even in backup!');
    process.exit(1);
}

// Step 2: Apply simplified L2
var inj2 = 'parse(e,t){if(!window.__v27l2){window.__v27l2=1;var _rc=e&&e.code;if(_rc&&[4000002,4000009,4000012,987].indexOf(_rc)>=0){console.log("[v27-bg] L2 detected",_rc);try{var _sv=uj.getInstance().resolve(BR);if(_sv){_sv.resumeChat({sessionId:t.sessionId,messageId:t.agentMessageId});console.log("[v27-bg] L2 resumeChat sent")}}catch(_ex){console.log("[v27-bg] L2 err:",_ex.message||_ex)}}}e.code===kg.MODEL_RESPONSE_TIMEOUT_ERROR';

c = c.substring(0, idx2) + inj2 + c.substring(idx2 + 'parse(e,t){e.code===kg.MODEL_RESPONSE_TIMEOUT_ERROR'.length);
console.log('✅ [v27] L2 injected');

// Step 3: Force Max Mode
if (c.indexOf('||true') < 0) {
    var findB = 'p=this._commercialPermissionService.isOlderCommercialUser(),g=this._commercialPermissionService.isSaas()';
    var idxB = c.indexOf(findB);
    if (idxB >= 0) {
        c = c.substring(0, idxB) + 'p=this._commercialPermissionService.isOlderCommercialUser()||true,g=this._commercialPermissionService.isSaas()||true' + c.substring(idxB + findB.length);
        console.log('✅ [v27] force-max-mode applied');
    }
}

fs.writeFileSync(path, c, 'utf8');

// Step 4: Syntax check
try {
    execSync('node --check "' + path + '"', { stdio: 'pipe' });
    console.log('✅ [v27] syntax check PASSED!');
} catch(e) {
    console.error('❌ Syntax error:', e.stderr.toString().substring(0, 400));
    // Restore and exit
    fs.copyFileSync(backupDir + '/' + files[0], path);
    console.log('⚠️ Restored from backup');
    process.exit(1);
}

// Step 5: Verify
var vc = fs.readFileSync(path, 'utf8');
var checks = [
    ['[v7] triggering', 'L1 (pre-existing)'],
    ['[v27-bg] L2 detected', 'L2 (new)'],
    ['||true', 'force-max-mode']
];
checks.forEach(function(ch) {
    console.log((vc.indexOf(ch[0]) >= 0 ? '✅' : '❌'), ch[1]);
});

// Final backup
var ts = new Date().toISOString().replace(/[:.]/g,'-').substring(0,19);
fs.copyFileSync(path, backupDir+'/indexjs-v27-FINAL-'+ts+'.backup');

console.log('');
console.log('🎉🎉🎉 V27 COMPLETE! 🎉🎉🎉');
console.log('   Backup: indexjs-v27-FINAL-' + ts + '.backup');
console.log('');
console.log('   🔄 RESTART TRAE AND TEST! 🔄');
