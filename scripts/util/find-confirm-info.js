const fs = require('fs');
const c = fs.readFileSync('d:/Test/trae-unlock/unpacked/index.beautified.js', 'utf8');

// 精确搜索 confirm_info = a 的位置
const patterns = [
  '.confirm_info = a',
  'confirm_info=a',
  'confirm_info = a',
  'n.confirm_info',
];
patterns.forEach(pat => {
  let idx = 0;
  while ((idx = c.indexOf(pat, idx)) !== -1) {
    const before = c.substring(0, idx);
    const lineNum = (before.match(/\n/g) || []).length + 1;
    const ctx = c.substring(Math.max(0, idx - 200), idx + pat.length + 200);
    console.log(`=== "${pat}" at line ${lineNum} (index ${idx}) ===`);
    console.log(ctx.replace(/\n/g, '\n  '));
    console.log('');
    idx += pat.length;
  }
});
