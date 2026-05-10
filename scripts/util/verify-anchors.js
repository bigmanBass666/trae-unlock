/**
 * verify-anchors.js — 验证所有补丁的 anchor 能否在 beautified.js 中找到
 */
const fs = require('fs');
const path = require('path');
const BEAUTIFIED_PATH = path.join(__dirname, '..', '..', 'unpacked', 'index.beautified.js');
const DEFS_PATH = path.join(__dirname, '..', '..', 'patches', 'definitions.json');

const content = fs.readFileSync(BEAUTIFIED_PATH, 'utf8');
const defs = JSON.parse(fs.readFileSync(DEFS_PATH, 'utf8'));

console.log('=== ANCHOR VERIFICATION ===\n');

let passCount = 0;
let failCount = 0;
let skipCount = 0;

for (const patch of defs.patches) {
    if (!patch.enabled) {
        console.log(`[SKIP] ${patch.id}: disabled`);
        skipCount++;
        continue;
    }
    
    if (patch.anchor.startsWith('DISABLED') || patch.find_original === 'NOOP_ALREADY_APPLIED') {
        console.log(`[SKIP] ${patch.id}: no-op/disabled`);
        skipCount++;
        continue;
    }
    
    // 验证 anchor
    const anchorIdx = content.indexOf(patch.anchor);
    if (anchorIdx === -1) {
        console.log(`[FAIL] ${patch.id}: anchor NOT FOUND`);
        console.log(`  anchor: "${patch.anchor.substring(0, 80)}..."`);
        failCount++;
        continue;
    }
    
    // 验证 find_original
    const findIdx = content.indexOf(patch.find_original);
    if (findIdx === -1) {
        console.log(`[FAIL] ${patch.id}: anchor found @${anchorIdx}, but find_original NOT FOUND`);
        console.log(`  find_original (first 100): "${patch.find_original.substring(0, 100)}..."`);
        // 尝试找到部分匹配
        const partialLen = Math.min(50, patch.find_original.length);
        const partialIdx = content.indexOf(patch.find_original.substring(0, partialLen));
        if (partialIdx >= 0) {
            console.log(`  Partial match (first ${partialLen} chars) found @${partialIdx}`);
            console.log(`  Actual text at that position: "${content.substring(partialIdx, partialIdx + 100)}..."`);
        }
        failCount++;
        continue;
    }
    
    // 验证 find_original 在 anchor 附近
    const distance = Math.abs(findIdx - anchorIdx);
    const nearby = distance < 5000;
    
    console.log(`[PASS] ${patch.id}: anchor @${anchorIdx}, find_original @${findIdx} (distance: ${distance}${nearby ? '' : ' *** FAR AWAY ***'})`);
    passCount++;
    
    // 验证 replace_with 中的关键变量名
    const replaceWith = patch.replace_with;
    const oldVars = ['kg.', 'efg', 'Cr.', 'P7.', 'M.localize', 'bQ.', 'zU ', 'DV ', 'b3.Suspend', 'BR)', 'CS.', 'Ck.', 'xc.', 'sX()', 'uj.getInstance', 'Ir.Z', 'k1)', 'xC)', 'FP(', 'if(V&&J)', 'if(V && J)'];
    for (const oldVar of oldVars) {
        if (replaceWith.includes(oldVar)) {
            console.log(`  [WARN] Old variable name "${oldVar}" still in replace_with!`);
        }
    }
}

console.log(`\n=== SUMMARY ===`);
console.log(`PASS: ${passCount}`);
console.log(`FAIL: ${failCount}`);
console.log(`SKIP: ${skipCount}`);
console.log(`TOTAL: ${defs.patches.length}`);

if (failCount > 0) {
    console.log('\n!!! SOME ANCHORS OR FIND_ORIGINALS NOT FOUND - NEEDS FIXING !!!');
    process.exit(1);
} else {
    console.log('\nAll enabled patches verified successfully!');
}
