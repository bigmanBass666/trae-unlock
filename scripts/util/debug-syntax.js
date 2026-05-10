const fs = require('fs');

const patched = fs.readFileSync('d:/Test/trae-unlock/unpacked/index.beautified.js', 'utf8');

// 检查 confirm-info-hijack 注入点周围的代码是否有语法问题
const target = 'a.confirm_status = Mz.Confirmed';
const idx = patched.indexOf(target);
if (idx >= 0) {
  // 获取注入点前后各 500 字符
  const start = Math.max(0, idx - 500);
  const end = Math.min(patched.length, idx + target.length + 500);
  const context = patched.substring(start, end);
  
  console.log('=== 注入点周围代码 ===\n');
  console.log(context);
  
  // 检查括号匹配
  let depth = 0;
  for (let i = start; i < end; i++) {
    if (patched[i] === '(') depth++;
    if (patched[i] === ')') depth--;
    if (depth < 0) {
      console.log(`\n⚠️ 括号不匹配! 在 index ${i} (相对 ${i - start})`);
      break;
    }
  }
  console.log(`\n括号深度最终: ${depth}`);
}

// 尝试用 acorn 解析（更详细的错误信息）
console.log('\n=== 尝试解析注入函数 ===\n');
// 找到 async verifyCommand(e) 的开始
const funcStart = patched.indexOf('async verifyCommand(e)');
if (funcStart >= 0) {
  // 找函数结束（下一个同级方法或类结束）
  let funcEnd = funcStart;
  let braceCount = 0;
  let foundFirstBrace = false;
  for (let i = funcStart; i < patched.length; i++) {
    if (patched[i] === '{') { braceCount++; foundFirstBrace = true; }
    if (patched[i] === '}') { braceCount--; }
    if (foundFirstBrace && braceCount === 0) { funcEnd = i + 1; break; }
    if (i > funcStart + 5000) { funcEnd = i; break; } // safety limit
  }
  
  const funcBody = patched.substring(funcStart, funcEnd);
  console.log(`函数长度: ${funcBody.length} chars`);
  
  // 写出函数体供检查
  fs.writeFileSync('d:/Test/trae-unlock/scripts/util/verifyCommand-func.js', funcBody);
  console.log('已保存到 scripts/util/verifyCommand-func.js');
}
