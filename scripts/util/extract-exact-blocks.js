/**
 * extract-exact-blocks.js — 从 beautified.js 提取每个补丁的精确 find_original
 */
const fs = require('fs');
const path = require('path');

const BEAUTIFIED_PATH = path.join(__dirname, '..', '..', 'unpacked', 'index.beautified.js');
const content = fs.readFileSync(BEAUTIFIED_PATH, 'utf8');

const results = {};

// ============ 1. efh-resume-list ============
console.log('=== 1. efh-resume-list ===');
const efxStart = content.indexOf("efx = [Ib.SERVER_CRASH");
if (efxStart >= 0) {
    // 找到数组结束的 ]
    let depth = 0, end = efxStart;
    for (let i = efxStart; i < content.length && i < efxStart + 2000; i++) {
        if (content[i] === '[') depth++;
        if (content[i] === ']') depth--;
        if (depth === 0 && content[i] === ']') { end = i + 1; break; }
    }
    const find_original = content.substring(efxStart, end);
    console.log('find_original:');
    console.log(find_original);
    console.log('Length:', find_original.length);
    results['efh-resume-list'] = { find_original, position: efxStart };
}

// ============ 2. guard-clause-bypass ============
console.log('\n=== 2. guard-clause-bypass ===');
const guardPos = content.indexOf("if (!n || !J || et) return null");
if (guardPos >= 0) {
    const find_original = "if (!n || !J || et) return null;";
    // 检查后面是否有分号
    const actualText = content.substring(guardPos, guardPos + find_original.length);
    console.log('find_original:', JSON.stringify(actualText));
    results['guard-clause-bypass'] = { find_original: actualText, position: guardPos };
}

// ============ 3. bypass-loop-detection ============
console.log('\n=== 3. bypass-loop-detection ===');
const dollarPos = content.indexOf("$ = !![Ib.MODEL_OUTPUT_TOO_LONG, Ib.TASK_TURN_EXCEEDED_ERROR].includes(y)");
if (dollarPos >= 0) {
    const find_original = "$ = !![Ib.MODEL_OUTPUT_TOO_LONG, Ib.TASK_TURN_EXCEEDED_ERROR].includes(y)";
    const actualText = content.substring(dollarPos, dollarPos + find_original.length);
    console.log('find_original:', JSON.stringify(actualText));
    results['bypass-loop-detection'] = { find_original: actualText, position: dollarPos };
}

// ============ 4. auto-continue-l2-parse ============
console.log('\n=== 4. auto-continue-l2-parse ===');
const parseStart = content.indexOf("parse(e, t) {\n                    e.code === Ib.MODEL_RESPONSE_TIMEOUT_ERROR");
if (parseStart >= 0) {
    // 找到方法结束
    let braceDepth = 0, end = parseStart, started = false;
    for (let i = parseStart; i < content.length && i < parseStart + 3000; i++) {
        if (content[i] === '{') { braceDepth++; started = true; }
        if (content[i] === '}') { braceDepth--; }
        if (started && braceDepth === 0) { end = i + 1; break; }
    }
    const find_original = content.substring(parseStart, end);
    console.log('find_original:');
    console.log(find_original);
    console.log('Length:', find_original.length);
    results['auto-continue-l2-parse'] = { find_original, position: parseStart };
}

// ============ 5. force-max-mode ============
console.log('\n=== 5. force-max-mode ===');
const fmStart = content.indexOf("p = this._commercialPermissionService.isOlderCommercialUser()");
if (fmStart >= 0) {
    // 提取两行
    const afterFirst = content.substring(fmStart, fmStart + 300);
    const secondLineStart = afterFirst.indexOf("f = this._commercialPermissionService.isSaas()");
    if (secondLineStart >= 0) {
        const secondLineEnd = afterFirst.indexOf(",", secondLineStart) + 1;
        const find_original = afterFirst.substring(0, secondLineEnd);
        console.log('find_original:');
        console.log(find_original);
        results['force-max-mode'] = { find_original, position: fmStart };
    }
}

// ============ 6. auto-confirm-commands ============
console.log('\n=== 6. auto-confirm-commands ===');
// 这个补丁标记为 ALREADY_APPLIED，但需要更新 anchor
const acStart = content.indexOf("[PlanItemStreamParser] auto-confirming knowledges background toolcall");
if (acStart >= 0) {
    console.log('anchor found @', acStart);
    // 提取完整的 if(f) 块
    // 从 confirm_status === "unconfirmed" 开始
    const unconfirmedPos = content.indexOf('e?.confirm_info?.confirm_status === "unconfirmed")', acStart - 500);
    if (unconfirmedPos >= 0) {
        // 向前找到 if 开始
        const ifStart = content.lastIndexOf("if (", unconfirmedPos);
        // 找到整个 if-else 块结束
        let pos = ifStart;
        let braceDepth = 0, started = false;
        for (let i = pos; i < content.length && i < pos + 5000; i++) {
            if (content[i] === '{') { braceDepth++; started = true; }
            if (content[i] === '}') { braceDepth--; }
            if (started && braceDepth === 0) {
                // 检查后面是否有 else
                const afterElse = content.substring(i + 1, i + 20).trim();
                if (afterElse.startsWith("else")) {
                    // 继续找 else 块结束
                    const elseStart = content.indexOf("else", i + 1);
                    pos = elseStart;
                    continue;
                }
                pos = i + 1;
                break;
            }
        }
        const find_original = content.substring(ifStart, pos);
        console.log('find_original (first 500 chars):');
        console.log(find_original.substring(0, 500));
        console.log('Length:', find_original.length);
    }
}

// ============ 7. bypass-runcommandcard-redlist ============
console.log('\n=== 7. bypass-runcommandcard-redlist ===');
const switchStart = content.indexOf("switch (t) {\n                        case Mp.AutoRunMode.WHITELIST:");
if (switchStart >= 0) {
    // 找到 switch 结束
    let braceDepth = 0, end = switchStart, started = false;
    for (let i = switchStart; i < content.length && i < switchStart + 5000; i++) {
        if (content[i] === '{') { braceDepth++; started = true; }
        if (content[i] === '}') { braceDepth--; }
        if (started && braceDepth === 0) { end = i + 1; break; }
    }
    const find_original = content.substring(switchStart, end);
    console.log('find_original:');
    console.log(find_original);
    results['bypass-runcommandcard-redlist'] = { find_original, position: switchStart };
}

// ============ 8. service-layer-runcommand-confirm ============
console.log('\n=== 8. service-layer-runcommand-confirm ===');
const slLine = content.indexOf("t?.sessionId === h || e?.confirm_info?.auto_confirm || this.storeService.setBadgesBySessionId(t.sessionId, e?.confirm_info?.confirm_status)");
if (slLine >= 0) {
    const find_original = content.substring(slLine, slLine + "t?.sessionId === h || e?.confirm_info?.auto_confirm || this.storeService.setBadgesBySessionId(t.sessionId, e?.confirm_info?.confirm_status)".length);
    console.log('find_original:', JSON.stringify(find_original));
    results['service-layer-runcommand-confirm'] = { find_original, position: slLine };
}

// ============ 9. data-source-auto-confirm ============
console.log('\n=== 9. data-source-auto-confirm ===');
const dsStart = content.indexOf("r.name !== MD.ViewFiles || \"object\" != typeof y || Array.isArray(y) || (y.files = y.files && Array.isArray(y.files) ? y.files.map(e => (e.start_line_one_indexed");
if (dsStart >= 0) {
    // 找到这个长表达式的结束
    // 需要找到 .map 的结束括号
    let parenDepth = 0, end = dsStart, started = false;
    for (let i = dsStart; i < content.length && i < dsStart + 2000; i++) {
        if (content[i] === '(') { parenDepth++; started = true; }
        if (content[i] === ')') { parenDepth--; }
        if (started && parenDepth === 0) { end = i + 1; break; }
    }
    const find_original = content.substring(dsStart, end);
    console.log('find_original:');
    console.log(find_original);
    console.log('Length:', find_original.length);
    results['data-source-auto-confirm'] = { find_original, position: dsStart };
}

// ============ 10. auto-continue-thinking (L1) ============
console.log('\n=== 10. auto-continue-thinking (L1) ===');
const wDollarStart = content.indexOf("if (W && $) {\n                        let e = x.localize(\"continue\", {}, \"Continue\");\n                        return cx.default.createElement(Mp.Alert, {");
if (wDollarStart >= 0) {
    // 找到 if 块结束
    let braceDepth = 0, end = wDollarStart, started = false;
    for (let i = wDollarStart; i < content.length && i < wDollarStart + 3000; i++) {
        if (content[i] === '{') { braceDepth++; started = true; }
        if (content[i] === '}') { braceDepth--; }
        if (started && braceDepth === 0) { end = i + 1; break; }
    }
    const find_original = content.substring(wDollarStart, end);
    console.log('find_original:');
    console.log(find_original);
    results['auto-continue-thinking'] = { find_original, position: wDollarStart };
}

// ============ 11. auto-continue-v11-store-subscribe ============
console.log('\n=== 11. auto-continue-v11-store-subscribe ===');
// 搜索 subscribe 调用结束位置 + async function Qs
const subEnd = content.indexOf("n.subscribe((e, t) => {\n                    ((e.currentSession?.messages?.length ?? 0) !== (t.currentSession?.messages?.length ?? 0) || e.currentSessionId !== t.currentSessionId) && o()\n                })\n            }\n            async function Qs(e)");
if (subEnd >= 0) {
    const endOfSubscribe = subEnd + "n.subscribe((e, t) => {\n                    ((e.currentSession?.messages?.length ?? 0) !== (t.currentSession?.messages?.length ?? 0) || e.currentSessionId !== t.currentSessionId) && o()\n                })\n            }\n            async function Qs(e)".length;
    const find_original = content.substring(subEnd, endOfSubscribe);
    console.log('find_original:');
    console.log(find_original);
    results['auto-continue-v11-store-subscribe'] = { find_original, position: subEnd };
} else {
    console.log('NOT FOUND - trying alternative search');
    // 搜索 })\n            }\n            async function Qs(e)
    const altPos = content.indexOf("})\n            }\n            async function Qs(e)");
    if (altPos >= 0) {
        console.log('Alternative found @', altPos);
        console.log(getContext(altPos, 200, 100));
    }
}

// ============ 12. force-auto-confirm ============
console.log('\n=== 12. force-auto-confirm ===');
const facPos = content.indexOf("!e && ea === Mz.Unconfirmed && eo && eS.confirm(!0)");
if (facPos >= 0) {
    const find_original = content.substring(facPos, facPos + "!e && ea === Mz.Unconfirmed && eo && eS.confirm(!0)".length);
    console.log('find_original:', JSON.stringify(find_original));
    results['force-auto-confirm'] = { find_original, position: facPos };
}

// ============ 13. sync-force-confirm ============
console.log('\n=== 13. sync-force-confirm ===');
// 搜索 useMemo 中包含 Mz 的
let smuIdx = 0;
while (true) {
    smuIdx = content.indexOf("useMemo(", smuIdx);
    if (smuIdx === -1) break;
    const ctx = content.substring(smuIdx, smuIdx + 500);
    if (ctx.includes("Mz.Unconfirmed") && ctx.includes("Mz.Confirmed")) {
        console.log(`useMemo with Mz @${smuIdx}:`);
        console.log(ctx.substring(0, 400));
        break;
    }
    smuIdx += 8;
}

// ============ 14. ec-debug-log (v7) ============
console.log('\n=== 14. ec-debug-log (v7) ===');
const ecDefPos = content.indexOf("ec = (0, Tl.A)(() => {\n                            if (!o || !h) return;\n                            let e = [...efx];");
if (ecDefPos >= 0) {
    // 找到 ec 回调结束
    let braceDepth = 0, end = ecDefPos, started = false;
    for (let i = ecDefPos; i < content.length && i < ecDefPos + 5000; i++) {
        if (content[i] === '{') { braceDepth++; started = true; }
        if (content[i] === '}') { braceDepth--; }
        if (started && braceDepth === 0) { end = i + 1; break; }
    }
    const find_original = content.substring(ecDefPos, end);
    console.log('find_original (first 500):');
    console.log(find_original.substring(0, 500));
    console.log('Length:', find_original.length);
    results['ec-debug-log'] = { find_original, position: ecDefPos };
}

// 保存结果
const outputPath = path.join(__dirname, '..', '..', 'unpacked', 'exact-blocks.json');
fs.writeFileSync(outputPath, JSON.stringify(results, null, 2), 'utf8');
console.log(`\nResults saved to ${outputPath}`);

function getContext(pos, before = 300, after = 300) {
    return content.substring(Math.max(0, pos - before), Math.min(content.length, pos + after));
}
