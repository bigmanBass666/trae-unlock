const fs = require('fs');
const c = fs.readFileSync('d:/Test/trae-unlock/unpacked/index.beautified.js', 'utf8');

// 搜索当前（已打 v3.0 补丁的）beautified.js 中 verifyCommand 的代码
// confirm-info-hijack 的原始 anchor 在已补丁代码中可能不匹配

console.log('=== 搜索 verifyCommand 区域的当前代码状态 ===\n');

// 搜索 verifyCommand 函数
const verifyCmdIdx = c.indexOf('async verifyCommand(e)');
if (verifyCmdIdx >= 0) {
  const before = c.substring(0, verifyCmdIdx);
  const lineNum = (before.match(/\n/g) || []).length + 1;
  console.log(`verifyCommand at Line ${lineNum}`);
  
  // 获取整个函数（到下一个方法定义之前）
  const funcStart = verifyCmdIdx;
  // 找函数结束（下一个 async 方法或同级方法）
  let funcEnd = c.indexOf('\n                ', verifyCmdIdx + 100);
  if (funcEnd < 0) funcEnd = verifyCmdIdx + 3000;
  
  const funcBody = c.substring(funcStart, Math.min(c.length, funcEnd));
  console.log(`\n函数体 (${funcBody.length} chars):`);
  console.log('---');
  console.log(funcBody.replace(/\n/g, '\n'));
  console.log('---');
}

// 搜索 n.confirm_info = a 的所有出现
console.log('\n=== "n.confirm_info = a" 所有出现 ===\n');
let idx = 0;
while ((idx = c.indexOf('n.confirm_info = a', idx)) !== -1) {
  const before = c.substring(0, idx);
  const ln = (before.match(/\n/g) || []).length + 1;
  const ctx = c.substring(Math.max(0, idx - 100), idx + 100);
  console.log(`Line ${ln}:`);
  console.log(`  ${ctx.replace(/\n/g, ' ')}`);
  console.log('');
  idx += 15;
}

// 搜索 confirm_info 相关的所有赋值
console.log('=== 所有 .confirm_info = 出现 ===\n');
idx = 0;
while ((idx = c.indexOf('.confirm_info =', idx)) !== -1) {
  const before = c.substring(0, idx);
  const ln = (before.match(/\n/g) || []).length + 1;
  const ctx = c.substring(Math.max(0, idx - 60), idx + 80);
  console.log(`Line ${ln}: ...${ctx.replace(/\n/g, ' ').trim()}...`);
  idx += 14;
}
