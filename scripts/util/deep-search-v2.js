/**
 * deep-search-v2.js — 精确提取每个补丁的 find_original 代码块
 */

const fs = require('fs');
const path = require('path');

const BEAUTIFIED_PATH = path.join(__dirname, '..', '..', 'unpacked', 'index.beautified.js');
const content = fs.readFileSync(BEAUTIFIED_PATH, 'utf8');

function getContext(pos, before = 500, after = 500) {
    return content.substring(Math.max(0, pos - before), Math.min(content.length, pos + after));
}

function getLineInfo(pos) {
    const beforeText = content.substring(0, pos);
    const lineNum = (beforeText.match(/\n/g) || []).length + 1;
    return lineNum;
}

function findBraceBlock(startPos, maxLen = 5000) {
    let braceDepth = 0;
    let started = false;
    let endPos = startPos;
    for (let i = startPos; i < content.length && i < startPos + maxLen; i++) {
        if (content[i] === '{') { braceDepth++; started = true; }
        if (content[i] === '}') { braceDepth--; }
        if (started && braceDepth === 0) { endPos = i + 1; break; }
    }
    return content.substring(startPos, endPos);
}

console.log('=== PRECISE CODE BLOCK EXTRACTION ===\n');

// ============ 1. efh-resume-list ============
console.log('--- 1. efh-resume-list ---');
const efxPos = content.indexOf("efx = [Ib.SERVER_CRASH");
// 提取完整数组（到 ] 结尾）
let efxEnd = efxPos;
let depth = 0;
for (let i = efxPos; i < content.length && i < efxPos + 2000; i++) {
    if (content[i] === '[') depth++;
    if (content[i] === ']') depth--;
    if (depth === 0 && content[i] === ']') { efxEnd = i + 1; break; }
}
const efxBlock = content.substring(efxPos, efxEnd);
console.log('efx full block:');
console.log(efxBlock);
console.log('');

// 检查 Ib 枚举中有哪些错误码
console.log('Checking Ib enum members...');
const ibEnumStart = content.indexOf('Ib.SERVER_CRASH');
if (ibEnumStart >= 0) {
    // 向前搜索 Ib 定义
    const beforeChunk = content.substring(Math.max(0, ibEnumStart - 5000), ibEnumStart);
    const enumDefMatch = beforeChunk.match(/let\s+Ib\s*=/);
    if (enumDefMatch) {
        const enumStart = ibEnumStart - 5000 + beforeChunk.lastIndexOf('let Ib');
        const enumBlock = content.substring(enumStart, enumStart + 3000);
        // 提取所有 Ib.XXX 成员
        const members = [...enumBlock.matchAll(/Ib\.(\w+)/g)].map(m => m[1]);
        const uniqueMembers = [...new Set(members)];
        console.log('Ib members:', uniqueMembers.join(', '));
        // 检查关键成员
        for (const key of ['LLM_STOP_DUP_TOOL_CALL', 'LLM_STOP_CONTENT_LOOP', 'DEFAULT', 'TASK_TURN_EXCEEDED_ERROR', 'MODEL_OUTPUT_TOO_LONG']) {
            console.log(`  Ib.${key}: ${uniqueMembers.includes(key) ? 'EXISTS' : 'NOT FOUND'}`);
        }
    }
}

// 也搜索 Ib 枚举定义
const ibDefinePos = content.indexOf('let Ib =');
if (ibDefinePos >= 0) {
    console.log(`\nIb enum definition @${ibDefinePos} (line ${getLineInfo(ibDefinePos)}):`);
    console.log(content.substring(ibDefinePos, ibDefinePos + 500));
}

// ============ 2. guard-clause-bypass ============
console.log('\n--- 2. guard-clause-bypass ---');
const guardPos = content.indexOf("if (!n || !J || et) return null");
console.log(`Guard clause @${guardPos} (line ${getLineInfo(guardPos)}):`);
console.log(getContext(guardPos, 300, 300));

// ============ 3. bypass-loop-detection ============
console.log('\n--- 3. bypass-loop-detection ---');
// $ = !![Ib.MODEL_OUTPUT_TOO_LONG, Ib.TASK_TURN_EXCEEDED_ERROR].includes(y)
const dollarPos = content.indexOf("$ = !![Ib.MODEL_OUTPUT_TOO_LONG");
if (dollarPos >= 0) {
    console.log(`$ assignment @${dollarPos} (line ${getLineInfo(dollarPos)}):`);
    console.log(getContext(dollarPos, 200, 200));
}

// 搜索完整的变量声明块
const turnExceededPos = content.indexOf("Ib.TASK_TURN_EXCEEDED_ERROR");
if (turnExceededPos >= 0) {
    console.log(`\nTASK_TURN_EXCEEDED_ERROR context @${turnExceededPos}:`);
    console.log(getContext(turnExceededPos, 500, 500));
}

// ============ 4. auto-continue-l2-parse ============
console.log('\n--- 4. auto-continue-l2-parse ---');
const parsePos = content.indexOf("parse(e, t) {\n                    e.code === Ib.MODEL_RESPONSE_TIMEOUT_ERROR");
if (parsePos >= 0) {
    console.log(`parse method @${parsePos} (line ${getLineInfo(parsePos)}):`);
    // 提取完整方法
    const parseBlock = findBraceBlock(parsePos + "parse(e, t) {".length - 1, 3000);
    console.log("parse(e, t) {" + parseBlock.substring(1));
}

// 搜索 class Fa extends LH
const faClassPos = content.indexOf("class Fa extends LH");
if (faClassPos >= 0) {
    console.log(`\nclass Fa @${faClassPos} (line ${getLineInfo(faClassPos)}):`);
    console.log(content.substring(faClassPos, faClassPos + 200));
}

// 搜索 DI Token — bb.Suspend
const bbSuspendPos = content.indexOf("bb.Suspend");
if (bbSuspendPos >= 0) {
    console.log(`\nbb.Suspend @${bbSuspendPos}:`);
    console.log(getContext(bbSuspendPos, 100, 100));
}

// 搜索 IErrorStreamParser
const iErrorPos = content.indexOf("IErrorStreamParser");
if (iErrorPos >= 0) {
    console.log(`\nIErrorStreamParser @${iErrorPos}:`);
    console.log(getContext(iErrorPos, 100, 200));
}

// ============ 5. force-max-mode ============
console.log('\n--- 5. force-max-mode ---');
const commercialPos = content.indexOf("p = this._commercialPermissionService.isOlderCommercialUser()");
if (commercialPos >= 0) {
    console.log(`isOlderCommercialUser @${commercialPos} (line ${getLineInfo(commercialPos)}):`);
    console.log(getContext(commercialPos, 200, 200));
}

// ============ 6. auto-confirm-commands ============
console.log('\n--- 6. auto-confirm-commands ---');
const autoConfirmPos = content.indexOf("[PlanItemStreamParser] auto-confirming knowledges background toolcall");
if (autoConfirmPos >= 0) {
    console.log(`auto-confirming @${autoConfirmPos} (line ${getLineInfo(autoConfirmPos)}):`);
    console.log(getContext(autoConfirmPos, 500, 500));
}

// ============ 7. bypass-runcommandcard-redlist ============
console.log('\n--- 7. bypass-runcommandcard-redlist ---');
// 找到 switch(t) { case Mp.AutoRunMode.WHITELIST: 结构
const switchTPos = content.indexOf("switch (t) {\n                        case Mp.AutoRunMode.WHITELIST:");
if (switchTPos >= 0) {
    console.log(`switch(t) @${switchTPos} (line ${getLineInfo(switchTPos)}):`);
    console.log(getContext(switchTPos, 100, 1500));
} else {
    // 尝试其他格式
    const altSwitchPos = content.indexOf("case Mp.AutoRunMode.WHITELIST:");
    if (altSwitchPos >= 0) {
        console.log(`case Mp.AutoRunMode.WHITELIST @${altSwitchPos} (line ${getLineInfo(altSwitchPos)}):`);
        console.log(getContext(altSwitchPos, 300, 1500));
    }
}

// ============ 8. service-layer-runcommand-confirm ============
console.log('\n--- 8. service-layer-runcommand-confirm ---');
const badgesPos2 = content.indexOf("t?.sessionId === h || e?.confirm_info?.auto_confirm || this.storeService.setBadgesBySessionId");
if (badgesPos2 >= 0) {
    console.log(`setBadgesBySessionId context @${badgesPos2} (line ${getLineInfo(badgesPos2)}):`);
    console.log(getContext(badgesPos2, 500, 500));
}

// ============ 9. data-source-auto-confirm ============
console.log('\n--- 9. data-source-auto-confirm ---');
const viewFilesPos = content.indexOf("r.name !== MD.ViewFiles");
if (viewFilesPos >= 0) {
    console.log(`MD.ViewFiles @${viewFilesPos} (line ${getLineInfo(viewFilesPos)}):`);
    console.log(getContext(viewFilesPos, 200, 500));
}

// ============ 10. auto-continue-thinking (L1) ============
console.log('\n--- 10. auto-continue-thinking (L1) ---');
// if (W && $) { let e = x.localize("continue", {}, "Continue")
const wDollarPos = content.indexOf("if (W && $) {");
if (wDollarPos >= 0) {
    console.log(`if (W && $) @${wDollarPos} (line ${getLineInfo(wDollarPos)}):`);
    console.log(getContext(wDollarPos, 300, 500));
}

// ============ 11. auto-continue-v11-store-subscribe ============
console.log('\n--- 11. auto-continue-v11-store-subscribe ---');
// 搜索 subscribe 模式
const subPositions = [];
let subIdx = 0;
while (subPositions.length < 10) {
    subIdx = content.indexOf(".subscribe(", subIdx);
    if (subIdx === -1) break;
    subPositions.push(subIdx);
    subIdx += 11;
}
console.log(`Found ${subPositions.length} .subscribe() calls`);
// 找到在 $J store 附近的 subscribe
for (const pos of subPositions) {
    const ctx = getContext(pos, 200, 300);
    if (ctx.includes("$J") || ctx.includes("currentSessionId") || ctx.includes("sessionId")) {
        console.log(`\n.subscribe @${pos} (line ${getLineInfo(pos)}):`);
        console.log(ctx);
    }
}

// ============ 12. force-auto-confirm ============
console.log('\n--- 12. force-auto-confirm ---');
const confirmPos = content.indexOf("!e && ea === Mz.Unconfirmed && eo && eS.confirm(!0)");
if (confirmPos >= 0) {
    console.log(`force-auto-confirm @${confirmPos} (line ${getLineInfo(confirmPos)}):`);
    console.log(getContext(confirmPos, 300, 300));
}

// ============ 13. sync-force-confirm ============
console.log('\n--- 13. sync-force-confirm ---');
// 搜索 useMemo 中包含 Mz.Unconfirmed 的
const useMemoPositions = [];
let useMemIdx = 0;
while (useMemoPositions.length < 20) {
    useMemIdx = content.indexOf("useMemo(", useMemIdx);
    if (useMemIdx === -1) break;
    const ctx = content.substring(useMemIdx, useMemIdx + 500);
    if (ctx.includes("Mz.Unconfirmed") || ctx.includes("Mz.Confirmed")) {
        console.log(`\nuseMemo with Mz @${useMemIdx} (line ${getLineInfo(useMemIdx)}):`);
        console.log(ctx.substring(0, 400));
    }
    useMemIdx += 8;
}

// ============ 14. 搜索 ec() 回调 — 续接按钮点击 ============
console.log('\n--- 14. ec() callback (v7 debug) ---');
// 搜索 resumeChat 调用
const resumeChatPositions = [];
let rcIdx = 0;
while (resumeChatPositions.length < 10) {
    rcIdx = content.indexOf("resumeChat(", rcIdx);
    if (rcIdx === -1) break;
    resumeChatPositions.push(rcIdx);
    rcIdx += 10;
}
console.log(`Found ${resumeChatPositions.length} resumeChat() calls`);
for (const pos of resumeChatPositions) {
    console.log(`  @${pos} (line ${getLineInfo(pos)}): ${getContext(pos, 100, 100).replace(/\n/g, ' ').substring(0, 150)}`);
}

// ============ 15. 搜索 sendChatMessage 调用 ============
console.log('\n--- 15. sendChatMessage calls ---');
const scmPositions = [];
let scmIdx = 0;
while (scmPositions.length < 10) {
    scmIdx = content.indexOf("sendChatMessage(", scmIdx);
    if (scmIdx === -1) break;
    scmPositions.push(scmIdx);
    scmIdx += 15;
}
console.log(`Found ${scmPositions.length} sendChatMessage() calls`);
for (const pos of scmPositions) {
    console.log(`  @${pos} (line ${getLineInfo(pos)}): ${getContext(pos, 50, 100).replace(/\n/g, ' ').substring(0, 150)}`);
}

// ============ 16. 搜索 uj.getInstance().resolve ============
console.log('\n--- 16. uj.getInstance().resolve calls ---');
const ujPositions = [];
let ujIdx = 0;
while (ujPositions.length < 10) {
    ujIdx = content.indexOf("uj.getInstance()", ujIdx);
    if (ujIdx === -1) break;
    ujPositions.push(ujIdx);
    ujIdx += 16;
}
console.log(`Found ${ujPositions.length} uj.getInstance() calls`);
for (const pos of ujPositions) {
    console.log(`  @${pos} (line ${getLineInfo(pos)}): ${getContext(pos, 20, 100).replace(/\n/g, ' ').substring(0, 150)}`);
}

// ============ 17. 搜索 BR (SessionServiceV2 DI Token) ============
console.log('\n--- 17. BR DI Token ---');
// 搜索 SessionServiceV2 或 ISessionService
const sessionServicePos = content.indexOf("ISessionServiceV2");
if (sessionServicePos >= 0) {
    console.log(`ISessionServiceV2 @${sessionServicePos}:`);
    console.log(getContext(sessionServicePos, 100, 200));
}
const sessionServiceV2Pos = content.indexOf("SessionServiceV2");
if (sessionServiceV2Pos >= 0) {
    console.log(`SessionServiceV2 @${sessionServiceV2Pos}:`);
    console.log(getContext(sessionServiceV2Pos, 100, 200));
}

// ============ 18. 搜索 ec() 续接回调定义 ============
console.log('\n--- 18. ec() / retryChatByUserMessageId ---');
const retryPos = content.indexOf("retryChatByUserMessageId");
if (retryPos >= 0) {
    console.log(`retryChatByUserMessageId @${retryPos} (line ${getLineInfo(retryPos)}):`);
    console.log(getContext(retryPos, 300, 300));
}

// ============ 19. 完整的 auto-continue L1 上下文 ============
console.log('\n--- 19. Full auto-continue L1 context ---');
// if (W && $) 是关键入口
if (wDollarPos >= 0) {
    // 向前搜索更多上下文
    const bigContext = content.substring(wDollarPos - 1000, wDollarPos + 1500);
    console.log(bigContext);
}

// ============ 20. 完整的 guard-clause + auto-continue 上下文 ============
console.log('\n--- 20. Full guard-clause + auto-continue context ---');
if (guardPos >= 0) {
    const bigContext = content.substring(guardPos - 500, guardPos + 2000);
    console.log(bigContext);
}

console.log('\n=== DONE ===');
