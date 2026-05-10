const fs = require('fs');
const { execSync } = require('child_process');

const patched = fs.readFileSync('d:/Test/trae-unlock/unpacked/index.beautified.js', 'utf8');

// 用 node 内置的简单压缩（不依赖 terser）来验证语法
console.log('=== 语法验证 ===\n');
try {
  new Function(patched);
  console.log('✅ JavaScript 语法有效 (new Function)');
} catch(e) {
  console.log(`❌ 语法错误: ${e.message}`);
}

// 尝试用 esbuild 或 swc 压缩
console.log('\n=== 尝试替代压缩方案 ===\n');

// 方案1: 直接用 uglify-js（如果安装了）
try {
  const uglify = require('uglify-js');
  const result = uglify.minify(patched, { compress: false, mangle: false });
  if (result.error) {
    console.log(`❌ uglify-js 错误: ${result.error.message}`);
    if (result.error.line) {
      const lines = patched.split('\n');
      console.log(`   Line ${result.error.line}: ${lines[result.error.line - 1]?.trim()}`);
    }
  } else {
    fs.writeFileSync('d:/Test/trae-unlock/unpacked/index.test.mjs', result.code);
    console.log(`✅ uglify-js 成功! ${(patched.length/1024/1024).toFixed(1)}MB → ${(result.code.length/1024/1024).toFixed(1)}MB`);
  }
} catch(e) {
  console.log(`⚠️ uglify-js 不可用: ${e.message}`);
}

// 方案2: 简单的空白移除 + 写入
if (!fs.existsSync('d:/Test/tae-unlock/unpacked/index.test.mjs')) {
  // 移除注释和多余空行，但保留可读性
  let minified = patched
    .replace(/\/\/[^\n]*/g, '')           // 单行注释
    .replace(/\/\*[\s\S]*?\*\//g, '')     // 多行注释  
    .replace(/\n{3,}/g, '\n\n')            // 多余空行
    .replace(/[ \t]+$/gm, '');             // 行尾空格
  
  fs.writeFileSync('d:/Test/trae-unlock/unpacked/index.test.mjs', minified);
  console.log(`⚠️ 使用简单压缩: ${(patched.length/1024/1024).toFixed(1)}MB → ${(minified.length/1024/1024).toFixed(1)}MB`);
}
