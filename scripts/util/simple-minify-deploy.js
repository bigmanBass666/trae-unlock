const fs = require('fs');

const patched = fs.readFileSync('d:/Test/trae-unlock/unpacked/index.beautified.js', 'utf8');
const targetPath = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.mjs';

// 备份
const ts = new Date().toISOString().replace(/[:.]/g, '').slice(0, 14);
if (fs.existsSync(targetPath)) {
  fs.copyFileSync(targetPath, 'd:/Test/trae-unlock/backups/index.mjs.pre-v4-' + ts + '.mjs');
}

// 直接复制（不压缩）
fs.writeFileSync(targetPath, patched);

console.log(`✅ Deployed (uncompressed): ${targetPath}`);
console.log(`   Size: ${(patched.length / 1024 / 1024).toFixed(1)} MB`);
console.log(`   Has Mz.Confirmed: ${patched.includes('Mz.Confirmed')}`);
console.log(`   Has n.confirm_info: ${patched.includes('n.confirm_info = a')}`);
console.log(`   Has verifyCommand: ${patched.includes('verifyCommand')}`);
