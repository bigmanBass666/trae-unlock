/**
 * deep-search-v3.js — 确认剩余变量名映射
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

// ============ 1. DI Container 名称 ============
console.log('--- 1. DI Container (uj replacement) ---');
// 搜索 ServiceLocator 或 getInstance 模式
for (const pattern of ['uC.getInstance()', 'uM.getInstance()', 'ServiceLocator']) {
    const pos = content.indexOf(pattern);
    if (pos >= 0) {
        console.log(`${pattern} @${pos} (line ${getLineInfo(pos)}):`);
        console.log(getContext(pos, 100, 200));
    } else {
        console.log(`${pattern}: NOT FOUND`);
    }
}

// ============ 2. ISessionServiceV2 DI Token ============
console.log('\n--- 2. ISessionServiceV2 DI Token ---');
const uoPos = content.indexOf('let Uo = Symbol("ISessionServiceV2")');
if (uoPos >= 0) {
    console.log(`Uo @${uoPos}:`);
    console.log(getContext(uoPos, 100, 200));
}

// ============ 3. 完整的变量声明块 (guard clause 附近) ============
console.log('\n--- 3. Variable declarations near guard clause ---');
const guardPos = content.indexOf("if (!n || !J || et) return null");
if (guardPos >= 0) {
    // 向前搜索变量声明
    const bigContext = content.substring(guardPos - 3000, guardPos + 100);
    // 找到 let 或 const 声明块
    const letMatch = bigContext.match(/let \{[^}]+\}\s*=\s*\([^)]+\)\([^)]*\)[^]*$/);
    if (letMatch) {
        console.log('Variable declarations:');
        console.log(letMatch[0].substring(0, 2000));
    }
}

// ============ 4. ed 回调 (onActionClick) ============
console.log('\n--- 4. ed callback (onActionClick for continue) ---');
// 在 if (W && $) 附近搜索 ed 定义
const wDollarPos = content.indexOf("if (W && $) {");
if (wDollarPos >= 0) {
    const before = content.substring(wDollarPos - 2000, wDollarPos);
    // 搜索 ed = 
    const edMatch = before.match(/ed\s*=\s*[^,]+/g);
    if (edMatch) {
        console.log('ed definitions:', edMatch);
    }
    // 搜索 eu = 
    const euMatch = before.match(/eu\s*=\s*[^,]+/g);
    if (euMatch) {
        console.log('eu definitions:', euMatch);
    }
    // 搜索 ey = 
    const eyMatch = before.match(/ey\s*=\s*[^,]+/g);
    if (eyMatch) {
        console.log('ey definitions:', eyMatch);
    }
}

// ============ 5. D (SessionService) 变量 ============
console.log('\n--- 5. D variable (SessionService) ---');
// 在 if (W && $) 附近搜索 D.resumeChat
if (wDollarPos >= 0) {
    const after = content.substring(wDollarPos, wDollarPos + 5000);
    const resumeMatch = after.match(/(\w+)\.resumeChat/);
    if (resumeMatch) {
        console.log(`resumeChat called on: ${resumeMatch[1]}`);
    }
    const scmMatch = after.match(/(\w+)\.sendChatMessage/);
    if (scmMatch) {
        console.log(`sendChatMessage called on: ${scmMatch[1]}`);
    }
}

// ============ 6. 完整的 ec() 回调 ============
console.log('\n--- 6. ec() retry callback ---');
// 搜索包含 resumeChat 和 retryChatByUserMessageId 的回调
const retryCallbackSearch = content.indexOf("retryChatByUserMessageId");
if (retryCallbackSearch >= 0) {
    // 在 L1 组件附近搜索
    const nearGuard = content.substring(guardPos - 5000, guardPos + 5000);
    const retryInScope = nearGuard.indexOf("retryChatByUserMessageId");
    if (retryInScope >= 0) {
        console.log(`retryChatByUserMessageId found near guard @offset ${retryInScope}`);
        console.log(nearGuard.substring(retryInScope - 200, retryInScope + 200));
    }
}

// ============ 7. 搜索 ec 定义 ============
console.log('\n--- 7. ec definition ---');
// 搜索 ec = (0, 模式
const ecPattern = content.indexOf("ec = (0,");
if (ecPattern >= 0) {
    console.log(`ec = (0, @${ecPattern}:`);
    console.log(getContext(ecPattern, 100, 500));
}
// 也搜索 ec= 模式
let ecIdx = 0;
let ecCount = 0;
while (ecCount < 5) {
    ecIdx = content.indexOf("ec=", ecIdx);
    if (ecIdx === -1) break;
    const ctx = getContext(ecIdx, 50, 100);
    if (ctx.includes("resumeChat") || ctx.includes("retryChat") || ctx.includes("sendChatMessage")) {
        console.log(`ec= @${ecIdx} (line ${getLineInfo(ecIdx)}):`);
        console.log(ctx);
    }
    ecIdx += 3;
    ecCount++;
}

// ============ 8. 完整的 auto-continue L1 上下文 (更大范围) ============
console.log('\n--- 8. Full L1 auto-continue context (5000 chars) ---');
if (wDollarPos >= 0) {
    // 搜索 D 变量定义
    const bigContext = content.substring(wDollarPos - 5000, wDollarPos + 2000);
    // 搜索 D = 模式
    const dMatch = bigContext.match(/D\s*=\s*[^,;\n]+/g);
    if (dMatch) {
        console.log('D definitions near W&&$:', dMatch.slice(0, 5));
    }
    // 搜索 b = (currentSession)
    const bMatch = bigContext.match(/b\s*=\s*[^,;\n]+/g);
    if (bMatch) {
        console.log('b definitions near W&&$:', bMatch.slice(0, 5));
    }
}

// ============ 9. 搜索 Qs 函数 (v11 store-subscribe) ============
console.log('\n--- 9. Qs function (v11 replacement for FP) ---');
const qsPos = content.indexOf("async function Qs(e)");
if (qsPos >= 0) {
    console.log(`async function Qs(e) @${qsPos} (line ${getLineInfo(qsPos)}):`);
    console.log(getContext(qsPos, 100, 500));
}

// ============ 10. 搜索 subscribe 附近的完整代码 ============
console.log('\n--- 10. subscribe context near Qs ---');
const subNearQs = content.indexOf("n.subscribe((e, t) => {");
if (subNearQs >= 0) {
    console.log(`subscribe @${subNearQs} (line ${getLineInfo(subNearQs)}):`);
    console.log(getContext(subNearQs, 500, 500));
}

// ============ 11. 搜索 MD 枚举 (ViewFiles etc.) ============
console.log('\n--- 11. MD enum (ToolCallName) ---');
const mdViewFiles = content.indexOf("MD.ViewFiles");
if (mdViewFiles >= 0) {
    // 向前搜索 MD 定义
    const before = content.substring(Math.max(0, mdViewFiles - 3000), mdViewFiles);
    const mdDefMatch = before.match(/MD\s*=\s*[^;]+/);
    if (mdDefMatch) {
        console.log('MD definition:', mdDefMatch[0].substring(0, 200));
    }
}
// 搜索 MD.AskUserQuestion
const mdAskUser = content.indexOf("MD.AskUserQuestion");
if (mdAskUser >= 0) {
    console.log(`MD.AskUserQuestion @${mdAskUser}:`);
    console.log(getContext(mdAskUser, 100, 100));
} else {
    console.log('MD.AskUserQuestion: NOT FOUND');
    // 搜索替代
    const altAskUser = content.indexOf("AskUserQuestion");
    console.log('AskUserQuestion positions:');
    let idx = 0;
    let count = 0;
    while (count < 5) {
        idx = content.indexOf("AskUserQuestion", idx);
        if (idx === -1) break;
        console.log(`  @${idx}: ${getContext(idx, 30, 50).replace(/\n/g, ' ').substring(0, 100)}`);
        idx += 15;
        count++;
    }
}

// ============ 12. 搜索 MD.ExitPlanMode ============
console.log('\n--- 12. MD.ExitPlanMode ---');
const mdExit = content.indexOf("MD.ExitPlanMode");
if (mdExit >= 0) {
    console.log(`MD.ExitPlanMode @${mdExit}:`);
    console.log(getContext(mdExit, 100, 100));
} else {
    console.log('MD.ExitPlanMode: NOT FOUND');
}

// ============ 13. 搜索 data-source-auto-confirm 精确上下文 ============
console.log('\n--- 13. data-source-auto-confirm precise context ---');
const dsPos = content.indexOf("r.name !== MD.ViewFiles");
if (dsPos >= 0) {
    console.log(`r.name !== MD.ViewFiles @${dsPos} (line ${getLineInfo(dsPos)}):`);
    console.log(getContext(dsPos, 300, 600));
}

// ============ 14. 搜索 auto-confirm-commands 精确上下文 ============
console.log('\n--- 14. auto-confirm-commands precise context ---');
const acPos = content.indexOf("e?.confirm_info?.confirm_status === \"unconfirmed\")");
if (acPos >= 0) {
    console.log(`confirm_status === "unconfirmed" @${acPos} (line ${getLineInfo(acPos)}):`);
    console.log(getContext(acPos, 500, 800));
}

// ============ 15. 搜索 service-layer-runcommand-confirm 精确上下文 ============
console.log('\n--- 15. service-layer-runcommand-confirm precise context ---');
const slPos = content.indexOf("t?.sessionId === h || e?.confirm_info?.auto_confirm || this.storeService.setBadgesBySessionId");
if (slPos >= 0) {
    console.log(`setBadgesBySessionId line @${slPos} (line ${getLineInfo(slPos)}):`);
    console.log(getContext(slPos, 500, 500));
}

// ============ 16. 搜索 force-max-mode 精确上下文 ============
console.log('\n--- 16. force-max-mode precise context ---');
const fmPos = content.indexOf("p = this._commercialPermissionService.isOlderCommercialUser()");
if (fmPos >= 0) {
    console.log(`isOlderCommercialUser @${fmPos}:`);
    console.log(getContext(fmPos, 200, 200));
}

// ============ 17. 搜索 eE(xA.Confirmed) 上下文 ============
console.log('\n--- 17. eE(xA.Confirmed) context ---');
const eEPos = content.indexOf("eE(xA.Confirmed)");
if (eEPos >= 0) {
    console.log(`eE(xA.Confirmed) @${eEPos}:`);
    console.log(getContext(eEPos, 300, 300));
}

// ============ 18. 搜索 useMemo with Mz (sync-force-confirm) ============
console.log('\n--- 18. useMemo with Mz.Unconfirmed ---');
let useMemoIdx = 0;
let useMemoCount = 0;
while (useMemoCount < 50) {
    useMemoIdx = content.indexOf("useMemo(", useMemoIdx);
    if (useMemoIdx === -1) break;
    const ctx = content.substring(useMemoIdx, useMemoIdx + 500);
    if (ctx.includes("Mz.Unconfirmed") || ctx.includes("Mz.Confirmed")) {
        console.log(`\nuseMemo with Mz @${useMemoIdx} (line ${getLineInfo(useMemoIdx)}):`);
        console.log(ctx.substring(0, 400));
    }
    useMemoIdx += 8;
    useMemoCount++;
}

// ============ 19. 搜索 Ib 枚举完整定义 ============
console.log('\n--- 19. Ib enum full definition ---');
// 搜索包含 LLM_STOP 的
for (const key of ['LLM_STOP_DUP_TOOL_CALL', 'LLM_STOP_CONTENT_LOOP', 'TASK_TURN_EXCEEDED', 'MODEL_OUTPUT_TOO_LONG', 'DEFAULT']) {
    const pos = content.indexOf(key);
    if (pos >= 0) {
        console.log(`${key} @${pos}: ${getContext(pos, 50, 50).replace(/\n/g, ' ')}`);
    } else {
        console.log(`${key}: NOT FOUND`);
    }
}

// ============ 20. 搜索 ec 回调完整定义 ============
console.log('\n--- 20. Full ec callback search ---');
// 在 guard clause 附近搜索包含 resumeChat 的回调
if (guardPos >= 0) {
    const bigContext = content.substring(guardPos - 8000, guardPos + 8000);
    // 搜索所有包含 resumeChat 的行
    const lines = bigContext.split('\n');
    for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes('resumeChat') || lines[i].includes('retryChatByUserMessageId')) {
            console.log(`  Line ${i}: ${lines[i].trim().substring(0, 150)}`);
        }
    }
}

console.log('\n=== DONE ===');
