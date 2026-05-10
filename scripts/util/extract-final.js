/**
 * extract-final.js — 提取剩余的精确代码块
 */
const fs = require('fs');
const path = require('path');
const BEAUTIFIED_PATH = path.join(__dirname, '..', '..', 'unpacked', 'index.beautified.js');
const content = fs.readFileSync(BEAUTIFIED_PATH, 'utf8');

function getContext(pos, before = 300, after = 300) {
    return content.substring(Math.max(0, pos - before), Math.min(content.length, pos + after));
}

// ============ data-source-auto-confirm 完整提取 ============
console.log('=== data-source-auto-confirm ===');
const dsPos = content.indexOf("r.name !== MD.ViewFiles");
if (dsPos >= 0) {
    // 从 r.name !== MD.ViewFiles 开始，找到整个逻辑表达式的结束
    // 这个表达式是: r.name !== MD.ViewFiles || "object" != typeof y || Array.isArray(y) || (y.files = ...)
    // 需要找到 || (y.files = ...) 的结束
    // 策略：从 r.name !== MD.ViewFiles 开始，找到下一个 ; 或 ,（不在括号内的）
    let pos = dsPos;
    let parenDepth = 0;
    let bracketDepth = 0;
    let endPos = dsPos;
    
    for (let i = dsPos; i < content.length && i < dsPos + 3000; i++) {
        const ch = content[i];
        if (ch === '(') parenDepth++;
        if (ch === ')') parenDepth--;
        if (ch === '[') bracketDepth++;
        if (ch === ']') bracketDepth--;
        
        // 找到顶层逗号或分号
        if (parenDepth === 0 && bracketDepth === 0) {
            if (ch === ',' || ch === ';') {
                // 检查是否在 y.files.map 的闭包内
                const before = content.substring(dsPos, i);
                // 计算未闭合的括号
                let pd = 0;
                for (const c of before) {
                    if (c === '(') pd++;
                    if (c === ')') pd--;
                }
                if (pd === 0) {
                    endPos = i;
                    break;
                }
            }
        }
    }
    
    const find_original = content.substring(dsPos, endPos);
    console.log('find_original:');
    console.log(find_original);
    console.log('Length:', find_original.length);
}

// ============ sync-force-confirm 搜索 ============
console.log('\n=== sync-force-confirm ===');
// 搜索 useMemo 中包含 Confirmed 和 Unconfirmed 的
let idx = 0;
while (true) {
    idx = content.indexOf("useMemo(", idx);
    if (idx === -1) break;
    const ctx = content.substring(idx, idx + 600);
    if ((ctx.includes("Confirmed") || ctx.includes("Canceled")) && ctx.includes("Unconfirmed")) {
        console.log(`\nuseMemo with confirm status @${idx}:`);
        console.log(ctx.substring(0, 500));
    }
    idx += 8;
}

// ============ auto-confirm-commands 完整提取 ============
console.log('\n=== auto-confirm-commands full extraction ===');
const acPos = content.indexOf('e?.confirm_info?.confirm_status === "unconfirmed")');
if (acPos >= 0) {
    // 向前找到 if 开始
    const ifStart = content.lastIndexOf("if (", acPos);
    // 从 if 开始，找到整个 if-else 块
    // 先找 if 块结束
    let pos = ifStart;
    let braceDepth = 0;
    let ifEnd = ifStart;
    let started = false;
    for (let i = ifStart; i < content.length && i < ifStart + 5000; i++) {
        if (content[i] === '{') { braceDepth++; started = true; }
        if (content[i] === '}') { braceDepth--; }
        if (started && braceDepth === 0) { ifEnd = i + 1; break; }
    }
    
    // 检查 if 后面是否有 else
    const afterIf = content.substring(ifEnd, ifEnd + 50).trim();
    console.log('After if block:', JSON.stringify(afterIf.substring(0, 40)));
    
    if (afterIf.startsWith("else")) {
        // 找 else 块结束
        const elseStart = content.indexOf("else", ifEnd);
        braceDepth = 0; started = false;
        let elseEnd = elseStart;
        for (let i = elseStart; i < content.length && i < elseStart + 3000; i++) {
            if (content[i] === '{') { braceDepth++; started = true; }
            if (content[i] === '}') { braceDepth--; }
            if (started && braceDepth === 0) { elseEnd = i + 1; break; }
        }
        // 但 else 后面可能不是 { 而是 单行语句
        if (!started) {
            // else 后面是单行语句，找到 ;
            elseEnd = content.indexOf(";", elseStart) + 1;
        }
        const find_original = content.substring(ifStart, elseEnd);
        console.log('find_original (with else):');
        console.log(find_original);
        console.log('Length:', find_original.length);
    } else {
        const find_original = content.substring(ifStart, ifEnd);
        console.log('find_original (no else):');
        console.log(find_original);
        console.log('Length:', find_original.length);
    }
}

// ============ 搜索 auto-confirm-commands 的黑名单 ============
console.log('\n=== Blacklist check in auto-confirm-commands ===');
const acBlacklist = content.indexOf("response_to_user", acPos - 1000);
if (acBlacklist >= 0 && acBlacklist < acPos + 2000) {
    console.log('response_to_user found near auto-confirm');
    console.log(getContext(acBlacklist, 100, 100));
} else {
    console.log('response_to_user NOT FOUND near auto-confirm');
}

// ============ 搜索 MD 枚举中的 AskUserQuestion ============
console.log('\n=== MD.AskUserQuestion search ===');
// 在 DG.parse 附近搜索 AskUserQuestion
const dgParsePos = content.indexOf("r.name !== MD.ViewFiles");
if (dgParsePos >= 0) {
    // 搜索更大范围
    const bigContext = content.substring(dgParsePos - 10000, dgParsePos + 10000);
    const askUserInDG = bigContext.indexOf("AskUserQuestion");
    if (askUserInDG >= 0) {
        console.log('AskUserQuestion found in DG.parse context:');
        console.log(bigContext.substring(askUserInDG - 50, askUserInDG + 100));
    } else {
        console.log('AskUserQuestion NOT FOUND in DG.parse context (20k range)');
    }
    // 搜索 confirm_info 在 DG.parse 中
    const confirmInfoInDG = bigContext.indexOf("confirm_info");
    if (confirmInfoInDG >= 0) {
        console.log('confirm_info found in DG.parse context:');
        console.log(bigContext.substring(confirmInfoInDG - 50, confirmInfoInDG + 100));
    } else {
        console.log('confirm_info NOT FOUND in DG.parse context');
    }
}

// ============ 搜索 data-source-auto-confirm 的注入点 ============
console.log('\n=== data-source-auto-confirm injection point ===');
// 在 ViewFiles 处理后搜索可能的注入点
if (dsPos >= 0) {
    // 找到 y.files.map 的结束
    const mapStart = content.indexOf("y.files.map(e =>", dsPos);
    if (mapStart >= 0) {
        // 找到 map 回调结束
        let parenDepth = 0;
        let mapEnd = mapStart;
        let started = false;
        for (let i = mapStart; i < content.length && i < mapStart + 2000; i++) {
            if (content[i] === '(') { parenDepth++; started = true; }
            if (content[i] === ')') { parenDepth--; }
            if (started && parenDepth === 0) { mapEnd = i + 1; break; }
        }
        console.log('y.files.map ends @', mapEnd);
        console.log('After map:', content.substring(mapEnd, mapEnd + 200));
    }
}

console.log('\n=== DONE ===');
