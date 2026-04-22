const fs = require('fs');
const src = 'backups/clean-20260422-140841.ext';
const dst = 'D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js';
fs.copyFileSync(src, dst);
const c = fs.readFileSync(dst, 'utf8');
console.log('Restored. Size:', (dst.length/1024/1024).toFixed(2), 'MB');
console.log('Has [v9-L1]:', c.includes('[v9-L1]'));
console.log('Has [v8-L2]:', c.includes('[v8-L2]'));
console.log('Has [v7-auto]:', c.includes('[v7-auto]'));
