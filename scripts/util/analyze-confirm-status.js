const fs = require('fs');
const c = fs.readFileSync('d:/Test/trae-unlock/unpacked/index.beautified.js', 'utf8');

// 关键发现：confirm_status 从未被直接赋值为 "confirmed"
// 那它是怎么被设置的？搜索 confirm_info 的创建和修改

console.log('=== 1. confirm_info 对象创建/赋值模式 ===\n');
const infoPatterns = [
  'confirm_info: {',
  'confirm_info:{',
  'confirm_info =',
  '.confirm_info =',
  '.confirm_info=',
  '{confirm_info',
];
infoPatterns.forEach(pat => {
  let idx = 0;
  const found = [];
  while ((idx = c.indexOf(pat, idx)) !== -1) {
    const before = c.substring(0, idx);
    const lineNum = (before.match(/\n/g) || []).length + 1;
    const ctx = c.substring(Math.max(0, idx - 30), idx + pat.length + 120);
    found.push({ line: lineNum, ctx });
    idx += pat.length;
    if (found.length >= 10) break; // limit output
  }
  console.log(`"${pat}": ${found.length >= 10 ? '10+' : found.length} occurrences`);
  found.forEach(f => {
    console.log(`  Line ${f.line}: ${f.ctx.replace(/\n/g, ' ').substring(0, 150)}`);
  });
  console.log('');
});

console.log('=== 2. NEED_CONFIRM / "unconfirmed" 赋值（源头） ===\n');
const sourcePatterns = [
  'NEED_CONFIRM',
  '"unconfirmed"',
  'NEED_CONFIRM:',
  'NEED_CONFIRM=',
  ': "unconfirmed"',
  ':"unconfirmed"',
  '.Unconfirmed',
];
sourcePatterns.forEach(pat => {
  let idx = 0;
  const found = [];
  while ((idx = c.indexOf(pat, idx)) !== -1) {
    const before = c.substring(0, idx);
    const lineNum = (before.match(/\n/g) || []).length + 1;
    // Only show context around first few
    if (found.length < 8) {
      const ctx = c.substring(Math.max(0, idx - 50), idx + pat.length + 80);
      found.push({ line: lineNum, ctx });
    }
    idx += pat.length;
  }
  if (found.length > 0) {
    console.log(`"${pat}": ${found.length} total`);
    found.forEach(f => {
      console.log(`  Line ${f.line}: ${f.ctx.replace(/\n/g, ' ')}`);
    });
    console.log('');
  }
});

console.log('=== 3. 关键行 186303 周围的完整上下文（useMemo 决策点） ===\n');
const useMemoIdx = c.indexOf('f === Mz.Unconfirmed && !g');
if (useMemoIdx >= 0) {
  const before = c.substring(0, useMemoIdx);
  const lineNum = (before.match(/\n/g) || []).length + 1;
  // 获取前后 500 字符
  const start = Math.max(0, useMemoIdx - 500);
  const end = Math.min(c.length, useMemoIdx + 500);
  console.log(`Line ~${lineNum}:\n`);
  console.log(c.substring(start, end));
}

console.log('\n=== 4. 关键行 146994 周围（service-layer 注入点） ===\n');
const serviceIdx = c.indexOf('e?.confirm_info?.confirm_status === "unconfirmed"');
if (serviceIdx >= 0) {
  const before = c.substring(0, serviceIdx);
  const lineNum = (before.match(/\n/g) || []).length + 1;
  const start = Math.max(0, serviceIdx - 400);
  const end = Math.min(c.length, serviceIdx + 400);
  console.log(`Line ~${lineNum}:\n`);
  console.log(c.substring(start, end));
}

console.log('\n=== 5. 关键行 177422（过滤器检查点）===\n');
const filterIdx = c.indexOf('"unconfirmed"].includes(t.confirm_info?.confirm_status');
if (filterIdx >= 0) {
  const before = c.substring(0, filterIdx);
  const lineNum = (before.match(/\n/g) || []).length + 1;
  const start = Math.max(0, filterIdx - 300);
  const end = Math.min(c.length, filterIdx + 300);
  console.log(`Line ~${lineNum}:\n`);
  console.log(c.substring(start, end));
}
