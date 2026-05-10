const fs = require('fs');
const c = fs.readFileSync('d:/Test/trae-unlock/unpacked/index.beautified.js', 'utf8');

// confirm-info-hijack 的 anchor
const anchor = 'console.log("verifyCommand", a),\n                            n.confirm_info = a';

console.log('=== Anchor 验证 ===');
console.log(`Anchor length: ${anchor.length}`);
console.log(`Contains anchor: ${c.includes(anchor)}`);

if (!c.includes(anchor)) {
  // 尝试不带 \n 的版本
  const anchorNoNL = 'console.log("verifyCommand", a), n.confirm_info = a';
  console.log(`Contains (no \\n): ${c.includes(anchorNoNL)}`);
  
  // 搜索 console.log("verifyCommand" 附近
  const logIdx = c.indexOf('console.log("verifyCommand"');
  if (logIdx >= 0) {
    console.log(`\nFound console.log("verifyCommand" at index ${logIdx}`);
    console.log(`Context (100 chars):`);
    console.log(c.substring(logIdx, logIdx + 120));
    
    // 检查实际换行符
    const afterLog = c.substring(logIdx, logIdx + 80);
    console.log(`\nActual chars after log:`);
    for (let i = 0; i < Math.min(afterLog.length, 60); i++) {
      const ch = afterLog[i] === '\n' ? '\\n' : afterLog[i];
      process.stdout.write(ch);
    }
    console.log('');
  }
} else {
  const idx = c.indexOf(anchor);
  const before = c.substring(0, idx);
  const lineNum = (before.match(/\n/g) || []).length + 1;
  console.log(`\n✅ ANCHOR FOUND at Line ${lineNum}, index ${idx}`);
}
