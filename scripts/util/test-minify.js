const fs = require('fs');

const patched = fs.readFileSync('d:/Test/trae-unlock/unpacked/index.beautified.js', 'utf8');

console.log('=== 验证已补丁代码 ===\n');
if (patched.includes('a.confirm_status = Mz.Confirmed')) {
  console.log('✅ confirm-info-hijack 注入成功');
  const idx = patched.indexOf('a.confirm_status = Mz.Confirmed');
  const before = patched.substring(0, idx);
  const lineNum = (before.match(/\n/g) || []).length + 1;
  console.log(`   位置: Line ${lineNum}`);
  console.log(`   上下文: ...${patched.substring(idx - 80, idx + 60)}...`);
} else {
  console.log('❌ confirm-info-hijack 未找到！');
}

console.log('\n=== Terser 压缩测试 ===\n');
try {
  const terser = require('terser');
  terser.minify(patched, {
    compress: { dead_code: true, unused: true, conditionals: true },
    mangle: false,
    output: { comments: false }
  }).then(result => {
    if (result.error) {
      console.log(`❌ Terser 错误:`);
      console.log(`   Message: ${result.error.message}`);
      console.log(`   Line: ${result.error.line}, Col: ${result.error.col}`);
      if (result.error.line) {
        const lines = patched.split('\n');
        console.log(`   行内容: ${lines[result.error.line - 1]}`);
      }
    } else {
      console.log('✅ Terser 压缩成功!');
      console.log(`   原始: ${(patched.length / 1024 / 1024).toFixed(1)} MB → 压缩: ${(result.code.length / 1024 / 1024).toFixed(1)} MB`);
      fs.writeFileSync('d:/Test/trae-unlock/unpacked/index.test.mjs', result.code);
      console.log('   测试文件已保存');
    }
  }).catch(e => {
    console.log(`❌ Terser 执行错误: ${e.message}`);
  });
} catch(e) {
  console.log(`❌ 加载错误: ${e.message}`);
}
