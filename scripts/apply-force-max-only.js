var fs = require('fs');
var execSync = require('child_process').execSync;
var path = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
var backupDir = 'd:/Test/trae-unlock/backups';

console.log('=== Force-Max-Mode Only (Safe) ===\n');

// 1. Restore clean backup
var files = fs.readdirSync(backupDir).filter(function(f) {
    return f.endsWith('.backup') && f.indexOf('20260425-184248') >= 0;
});
if (!files.length) { console.error('No backup!'); process.exit(1); }
fs.copyFileSync(backupDir + '/' + files[0], path);
console.log('Restored:', files[0]);

// 2. Verify clean file syntax
try { execSync('node --check "' + path + '"', { stdio: 'pipe' }); console.log('✅ Clean syntax OK'); }
catch(e) { console.error('❌ Clean file has syntax error!'); process.exit(1); }

// 3. Apply force-max-mode only
var c = fs.readFileSync(path, 'utf8');
var find = 'p=this._commercialPermissionService.isOlderCommercialUser(),g=this._commercialPermissionService.isSaas()';
var idx = c.indexOf(find);
if (idx < 0) { console.error('❌ Injection point not found!'); process.exit(1); }
console.log('Found @' + idx);

c = c.substring(0, idx) + 'p=this._commercialPermissionService.isOlderCommercialUser()||true,g=this._commercialPermissionService.isSaas()||true' + c.substring(idx + find.length);
fs.writeFileSync(path, c);

// 4. Syntax check
try { execSync('node --check "' + path + '"', { stdio: 'pipe' }); console.log('✅✅ SYNTAX OK! Force Max Mode applied.'); }
catch(e) { console.error('❌ Syntax error after patch:'); console.error(e.stderr.toString().substring(0, 300)); process.exit(1); }

// 5. Verify
console.log('\n||true count:', (c.match(/\|\|true/g) || []).length);

// 6. Backup
var ts = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19);
fs.copyFileSync(path, backupDir + '/indexjs-force-max-' + ts + '.backup');
console.log('Backup: indexjs-force-max-' + ts + '.backup\n🎉 DONE - Restart Trae!');
