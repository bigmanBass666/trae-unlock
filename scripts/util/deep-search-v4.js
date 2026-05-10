/**
 * deep-search-v4.js — 最终确认关键变量名
 */
const fs = require('fs');
const path = require('path');
const BEAUTIFIED_PATH = path.join(__dirname, '..', '..', 'unpacked', 'index.beautified.js');
const content = fs.readFileSync(BEAUTIFIED_PATH, 'utf8');

function getContext(pos, before = 300, after = 300) {
    return content.substring(Math.max(0, pos - before), Math.min(content.length, pos + after));
}
function getLineInfo(pos) {
    return (content.substring(0, pos).match(/\n/g) || []).length + 1;
}

// 1. 搜索 Ib 变量的完整定义
console.log('--- 1. Ib variable definition ---');
let ibIdx = 0;
let ibCount = 0;
while (ibCount < 5) {
    ibIdx = content.indexOf("let Ib =", ibIdx);
    if (ibIdx === -1) break;
    console.log(`let Ib = @${ibIdx} (line ${getLineInfo(ibIdx)}):`);
    console.log(content.substring(ibIdx, ibIdx + 200));
    ibIdx += 8;
    ibCount++;
}
// 也搜索 var Ib =
ibIdx = 0;
while (ibCount < 10) {
    ibIdx = content.indexOf("Ib =", ibIdx);
    if (ibIdx === -1) break;
    const ctx = content.substring(ibIdx, ibIdx + 100);
    if (ctx.match(/^(Ib\s*=\s*[a-zA-Z])/)) {
        console.log(`Ib = @${ibIdx} (line ${getLineInfo(ibIdx)}):`);
        console.log(ctx);
    }
    ibIdx += 4;
    ibCount++;
}

// 2. 搜索 Ib.LLM_STOP_DUP_TOOL_CALL
console.log('\n--- 2. Ib.LLM_STOP_DUP_TOOL_CALL ---');
const ibDupTool = content.indexOf("Ib.LLM_STOP_DUP_TOOL_CALL");
console.log(`Ib.LLM_STOP_DUP_TOOL_CALL: ${ibDupTool >= 0 ? `FOUND @${ibDupTool}` : 'NOT FOUND'}`);

// 3. 搜索 LLM_STOP_DUP_TOOL_CALL 的所有引用
console.log('\n--- 3. All LLM_STOP_DUP_TOOL_CALL references ---');
let dupIdx = 0;
let dupCount = 0;
while (dupCount < 10) {
    dupIdx = content.indexOf("LLM_STOP_DUP_TOOL_CALL", dupIdx);
    if (dupIdx === -1) break;
    console.log(`  @${dupIdx}: ${getContext(dupIdx, 30, 50).replace(/\n/g, ' ').substring(0, 100)}`);
    dupIdx += 22;
    dupCount++;
}

// 4. 搜索 LLM_STOP_CONTENT_LOOP 的所有引用
console.log('\n--- 4. All LLM_STOP_CONTENT_LOOP references ---');
let loopIdx = 0;
let loopCount = 0;
while (loopCount < 10) {
    loopIdx = content.indexOf("LLM_STOP_CONTENT_LOOP", loopIdx);
    if (loopIdx === -1) break;
    console.log(`  @${loopIdx}: ${getContext(loopIdx, 30, 50).replace(/\n/g, ' ').substring(0, 100)}`);
    loopIdx += 21;
    loopCount++;
}

// 5. 搜索 efx 数组附近的所有变量声明
console.log('\n--- 5. Variables near efx ---');
const efxPos = content.indexOf("efx = [Ib.SERVER_CRASH");
if (efxPos >= 0) {
    const bigContext = content.substring(efxPos - 2000, efxPos + 2000);
    // 搜索所有变量赋值
    const varMatches = [...bigContext.matchAll(/(\w+)\s*=\s*\[?[^\n;]{0,100}/g)];
    for (const m of varMatches) {
        if (m[1].length <= 3 && m[0].includes('Ib')) {
            console.log(`  ${m[0].substring(0, 100)}`);
        }
    }
}

// 6. 搜索完整的 if(W&&$) 上下文，包括变量声明
console.log('\n--- 6. Full context around if(W&&$) ---');
const wDollarPos = content.indexOf("if (W && $) {");
if (wDollarPos >= 0) {
    // 向前搜索到函数开始
    const bigContext = content.substring(wDollarPos - 8000, wDollarPos + 1000);
    // 找到所有关键变量声明
    const keyVars = ['W', '$', 'J', 'q', 'n', 'et', 'eg', 'ed', 'ey', 'D', 'b', 'o', 'h', 'y'];
    for (const v of keyVars) {
        const regex = new RegExp(`\\b${v}\\s*=\\s*[^,;\\n]{5,80}`, 'g');
        const matches = [...bigContext.matchAll(regex)];
        if (matches.length > 0) {
            console.log(`  ${v} = ${matches[0][0].substring(v.length + 3).substring(0, 80)}`);
        }
    }
}

// 7. 搜索 ec 回调 — 在 L1 组件中
console.log('\n--- 7. ec callback in L1 component ---');
// 搜索 D.resumeChat 调用
const dResumePos = content.indexOf("D.resumeChat({");
if (dResumePos >= 0) {
    console.log(`D.resumeChat @${dResumePos} (line ${getLineInfo(dResumePos)}):`);
    console.log(getContext(dResumePos, 500, 500));
}

// 8. 搜索 ed 回调定义 (onActionClick for continue)
console.log('\n--- 8. ed callback definition ---');
const edPos = content.indexOf("ed = (0, Tl.A)(() => {");
if (edPos >= 0) {
    console.log(`ed = @${edPos} (line ${getLineInfo(edPos)}):`);
    console.log(getContext(edPos, 100, 500));
} else {
    // 在 if(W&&$) 附近搜索
    if (wDollarPos >= 0) {
        const before = content.substring(wDollarPos - 5000, wDollarPos);
        const edMatch = before.match(/ed\s*=\s*\(0,\s*\w+\.\w+\)\s*\([^)]*\)\s*=>\s*\{[^}]+\}/);
        if (edMatch) {
            console.log('ed definition:', edMatch[0].substring(0, 200));
        }
        // 搜索 ed = 模式
        const edMatches = [...before.matchAll(/\bed\s*=\s*[^\n]{5,150}/g)];
        for (const m of edMatches) {
            console.log(`  ed: ${m[0].substring(0, 150)}`);
        }
    }
}

// 9. 搜索 MD.AskUserQuestion 和 MD.ExitPlanMode 在 DG.parse 中的使用
console.log('\n--- 9. MD.AskUserQuestion in DG.parse ---');
// 在 data-source-auto-confirm 位置附近搜索
const dsPos = content.indexOf("r.name !== MD.ViewFiles");
if (dsPos >= 0) {
    const bigContext = content.substring(dsPos - 5000, dsPos + 5000);
    // 搜索 AskUserQuestion
    const askUserPos = bigContext.indexOf("AskUserQuestion");
    if (askUserPos >= 0) {
        console.log(`AskUserQuestion near DG.parse @offset ${askUserPos}:`);
        console.log(bigContext.substring(askUserPos - 50, askUserPos + 100));
    } else {
        console.log('AskUserQuestion NOT FOUND near DG.parse');
    }
    // 搜索 ExitPlanMode
    const exitPlanPos = bigContext.indexOf("ExitPlanMode");
    if (exitPlanPos >= 0) {
        console.log(`ExitPlanMode near DG.parse @offset ${exitPlanPos}:`);
        console.log(bigContext.substring(exitPlanPos - 50, exitPlanPos + 100));
    } else {
        console.log('ExitPlanMode NOT FOUND near DG.parse');
    }
    // 搜索 confirm_status 在 DG.parse 中
    const confirmPos = bigContext.indexOf("confirm_status");
    if (confirmPos >= 0) {
        console.log(`confirm_status near DG.parse @offset ${confirmPos}:`);
        console.log(bigContext.substring(confirmPos - 50, confirmPos + 100));
    } else {
        console.log('confirm_status NOT FOUND near DG.parse');
    }
    // 搜索 auto_confirm 在 DG.parse 中
    const autoConfirmPos = bigContext.indexOf("auto_confirm");
    if (autoConfirmPos >= 0) {
        console.log(`auto_confirm near DG.parse @offset ${autoConfirmPos}:`);
        console.log(bigContext.substring(autoConfirmPos - 50, autoConfirmPos + 100));
    } else {
        console.log('auto_confirm NOT FOUND near DG.parse');
    }
}

// 10. 搜索 auto-confirm-commands 中的黑名单
console.log('\n--- 10. Blacklist in auto-confirm-commands ---');
const acPos = content.indexOf("[PlanItemStreamParser] auto-confirming knowledges background toolcall");
if (acPos >= 0) {
    const bigContext = content.substring(acPos, acPos + 2000);
    console.log(bigContext.substring(0, 1500));
}

// 11. 搜索 service-layer-runcommand-confirm 中的完整 else 分支
console.log('\n--- 11. service-layer-runcommand-confirm else branch ---');
const slPos = content.indexOf("t?.sessionId === h || e?.confirm_info?.auto_confirm || this.storeService.setBadgesBySessionId");
if (slPos >= 0) {
    // 向前搜索 else
    const before = content.substring(slPos - 1000, slPos);
    const elseMatch = before.lastIndexOf("} else");
    if (elseMatch >= 0) {
        const elsePos = slPos - 1000 + elseMatch;
        console.log(`else branch @${elsePos}:`);
        console.log(content.substring(elsePos, slPos + 500));
    }
}

// 12. 搜索 force-max-mode 的 beautified 格式
console.log('\n--- 12. force-max-mode beautified format ---');
const fmPos = content.indexOf("p = this._commercialPermissionService.isOlderCommercialUser()");
if (fmPos >= 0) {
    // 提取精确的两行
    const ctx = content.substring(fmPos - 50, fmPos + 200);
    console.log(ctx);
}

// 13. 搜索 bypass-runcommandcard-redlist 的完整 switch 块
console.log('\n--- 13. bypass-runcommandcard-redlist full switch block ---');
const switchPos = content.indexOf("switch (t) {\n                        case Mp.AutoRunMode.WHITELIST:");
if (switchPos >= 0) {
    // 找到 switch 结束
    let braceDepth = 0;
    let switchEnd = switchPos;
    let started = false;
    for (let i = switchPos; i < content.length && i < switchPos + 5000; i++) {
        if (content[i] === '{') { braceDepth++; started = true; }
        if (content[i] === '}') { braceDepth--; }
        if (started && braceDepth === 0) { switchEnd = i + 1; break; }
    }
    const switchBlock = content.substring(switchPos, switchEnd);
    console.log(switchBlock);
}

// 14. 搜索 auto-continue-thinking 的完整 if(W&&$) 块
console.log('\n--- 14. auto-continue-thinking full if(W&&$) block ---');
if (wDollarPos >= 0) {
    // 找到 if 块结束
    let braceDepth = 0;
    let blockEnd = wDollarPos;
    let started = false;
    for (let i = wDollarPos; i < content.length && i < wDollarPos + 3000; i++) {
        if (content[i] === '{') { braceDepth++; started = true; }
        if (content[i] === '}') { braceDepth--; }
        if (started && braceDepth === 0) { blockEnd = i + 1; break; }
    }
    const ifBlock = content.substring(wDollarPos, blockEnd);
    console.log(ifBlock);
}

console.log('\n=== DONE ===');
