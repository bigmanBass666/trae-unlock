const fs = require('fs');
const c = fs.readFileSync('d:/Test/trae-unlock/unpacked/index.beautified.js', 'utf8');

console.log('=== Phase 1: confirm_info 源头注入点完整分析 ===\n');

// 1. 精确定位 + 完整函数上下文
const target = 'n.confirm_info = a';
const idx = c.indexOf(target);
if (idx < 0) {
  console.log('ERROR: Target not found!');
  process.exit(1);
}

// 获取行号
const before = c.substring(0, idx);
const lineNum = (before.match(/\n/g) || []).length + 1;
console.log(`1. 注入点位置: Line ${lineNum}, Index ${idx}`);

// 获取前后 60 行的完整上下文（函数级别）
const lines = c.split('\n');
const startLine = Math.max(0, lineNum - 80);
const endLine = Math.min(lines.length, lineNum + 20);
console.log(`\n2. 函数上下文 (Lines ${startLine+1} to ${endLine}):\n`);
console.log('---');
for (let i = startLine; i < endLine; i++) {
  const marker = (i === lineNum - 1) ? ' >>> INJECTION POINT <<<' : '';
  console.log(`${String(i+1).padStart(6)}: ${lines[i]}${marker}`);
}
console.log('---');

// 3. 验证 Mz 在作用域内可达 — 搜索包含此函数的更大范围中 Mz 的定义/引用
console.log('\n3. Mz (UserConfirmStatusEnum) 可达性检查:');
// 找到包含注入点的函数边界
let funcStart = idx;
let braceDepth = 0;
let inFunc = false;
for (let i = idx; i >= 0; i--) {
  if (c[i] === '}') braceDepth++;
  if (c[i] === '{') {
    braceDepth--;
    if (braceDepth < 0) { funcStart = i; break; }
  }
}
// 从函数开始到注入点搜索 Mz
const funcContext = c.substring(funcStart, idx);
const mzInFunc = (funcContext.match(/Mz/g) || []).length;
console.log(`   Mz 出现在同一函数中的次数: ${mzInFunc}`);

// 更广范围搜索 Mz.Confirmed 定义
const mzConfirmedIdx = c.indexOf('Mz.Confirmed');
if (mzConfirmedIdx >= 0) {
  const mzBefore = c.substring(0, mzConfirmedIdx);
  const mzLine = (mzBefore.match(/\n/g) || []).length + 1;
  const distance = Math.abs(mzLine - lineNum);
  console.log(`   Mz.Confirmed 定义位置: Line ${mzLine} (距注入点 ${distance} 行)`);
}

// 4. 验证 a 对象结构 — 看 a 是从哪里来的
console.log('\n4. "a" 变量来源追踪:');
// 向上搜索最近的 "a" 赋值或参数定义
const searchBack = c.substring(Math.max(0, idx - 2000), idx);
const aPatterns = [
  /[,(\s]a\s*[\)=]/g,
  /function\s*\([^)]*a[^)]*\)/g,
];
// 搜索 verifyCommand 函数签名
const verifyCmdIdx = c.lastIndexOf('verifyCommand', idx);
if (verifyCmdIdx >= 0) {
  const vcBefore = c.substring(0, verifyCmdIdx);
  const vcLine = (vcBefore.match(/\n/g) || []).length + 1;
  console.log(`   verifyCommand 引用位置: Line ${vcLine}`);
}
// 搜索函数参数列表中的 a
const paramSearch = c.substring(Math.max(0, idx - 500), idx);
const paramMatch = paramSearch.match(/\(([^)]{0,200})\)\s*\{/g);
if (paramMatch) {
  // 找最后一个匹配（最接近注入点的）
  for (let i = paramMatch.length - 1; i >= 0; i--) {
    if (paramMatch[i].includes('a') || paramMatch[i].includes('a,')) {
      console.log(`   最近函数签名含 "a": ${paramMatch[i].trim()}`);
      break;
    }
  }
}

// 5. 验证 setCurrentSession 是否覆盖修改
console.log('\n5. setCurrentSession 覆盖风险检查:');
const setCurrIdx = c.indexOf('setCurrentSession', idx);
if (setCurrIdx > 0 && setCurrIdx < idx + 500) {
  const setCurrDist = setCurrIdx - idx;
  console.log(`   setCurrentSession 在注入点后 ${setCurrDist} 字符处`);
  // 检查它是否重新构建了 confirm_info
  const afterSetCurr = c.substring(setCurrIdx, setCurrIdx + 300);
  if (afterSetCurr.includes('confirm_info')) {
    console.log('   ⚠️  WARNING: setCurrentSession 后有 confirm_info 相关代码，可能覆盖！');
    console.log(`   代码片段: ${afterSetCurr.substring(0, 200).replace(/\n/g, ' ')}`);
  } else {
    console.log('   ✅ 安全: setCurrentSession 后未直接操作 confirm_info');
  }
} else {
  console.log('   ✅ setCurrentSession 不在附近，无覆盖风险');
}

// 6. 提取精确的 find_original 和 replace_with 候选
console.log('\n6. 补丁候选值提取:');
// find_original: 注入点所在行的原始文本（含周围）
const injectionLine = lines[lineNum - 1];
console.log(`   注入行原文: ${injectionLine.trim()}`);

// 扩大到包含逗号表达式链
let foStart = idx;
let foEnd = idx + target.length;
// 向前找到语句开始
for (let i = idx - 1; i >= Math.max(0, idx - 300); i--) {
  if (c[i] === '\n' || (c[i] === '(' && i > 0 && c[i-1] === 'return')) {
    foStart = i + (c[i] === '\n' ? 1 : 0);
    break;
  }
}
// 向后找到语句结束
for (let i = idx + target.length; i < Math.min(c.length, idx + 500); i++) {
  if (c[i] === ')' || (c[i] === ',' && c.substring(i, i+20).includes('this.'))) {
    foEnd = i;
    break;
  }
}
const findOriginalCandidate = c.substring(foStart, foEnd).replace(/\n/g, '');
console.log(`   find_original 候选 (${findOriginalCandidate.length} chars):`);
console.log(`   [${findOriginalCandidate.substring(0, 150)}...]`);

// replace_with: 在 n.confirm_info = a 后追加
const replaceWithCandidate = findOriginalCandidate.replace(
  'n.confirm_info = a)',
  'n.confirm_info = a, a && (a.confirm_status = Mz.Confirmed)'
);
console.log(`\n   replace_with 候选 (${replaceWithCandidate.length} chars):`);
console.log(`   [${replaceWithCandidate.substring(0, 180)}...]`);

console.log('\n=== 分析完成 ===');
