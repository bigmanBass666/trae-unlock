var fs = require('fs');
var path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
var backupDir = 'd:/Test/trae-unlock/backups';

console.log('=== Force Max Mode Apply Script ===\n');

// Read current file (should already have v22 applied)
var c = fs.readFileSync(path, 'utf8');
console.log('Current file size:', c.length);

// The injection point: where isOlderCommercialUser and isSaas are called before computeSelectedModelAndMode
var find = 'p=this._commercialPermissionService.isOlderCommercialUser(),g=this._commercialPermissionService.isSaas()';
var idx = c.indexOf(find);

if (idx < 0) {
    // Try alternative forms
    var alts = [
        'isOlderCommercialUser(),g=this._commercialPermissionService.isSaas()',
        '.isOlderCommercialUser(),',
        'isSaas()'
    ];
    for (var i = 0; i < alts.length; i++) {
        var ai = c.indexOf(alts[i]);
        if (ai >= 0) {
            console.log('Found alternative:', alts[i], '@' + ai);
            console.log('Context:', c.substring(Math.max(0, ai - 50), ai + 100));
        }
    }
    console.error('ERROR: Injection point not found!');
    process.exit(1);
}

console.log('✅ Found injection point @' + idx);
console.log('   Context:', c.substring(idx, idx + 120));

// Replace: force both to true by appending ||true
var replace = 'p=this._commercialPermissionService.isOlderCommercialUser()||true,g=this._commercialPermissionService.isSaas()||true//force-max-mode';
c = c.substring(0, idx) + replace + c.substring(idx + find.length);

console.log('✅ Patched. New size:', c.length);

// Write
fs.writeFileSync(path, c);
console.log('✅ File written');

// Syntax check
try {
    require('child_process').execSync('node --check "' + path + '"', { stdio: 'pipe' });
    console.log('\n✅ SYNTAX OK');
} catch(e) {
    console.error('\n❌ SYNTAX ERROR:');
    console.error(e.stderr.toString().substring(0, 500));
    process.exit(1);
}

// Verify fingerprint
var fpIdx = c.indexOf('force-max-mode');
console.log('\n✅ Fingerprint "force-max-mode" found @' + fpIdx);
console.log('✅ Also contains "||true" for permission bypass');

// Backup this version
var ts = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19);
var backupPath = backupDir + '/indexjs-force-max-' + ts + '.backup';
fs.copyFileSync(path, backupPath);
console.log('✅ Backup created:', backupPath);

console.log('\n=== FORCE MAX MODE APPLIED SUCCESSFULLY ===');
console.log('Restart Trae IDE to take effect.');
