/**
 * deep-search.js — 综合搜索 beautified.js 中所有补丁的代码位置
 * 
 * 用法: node scripts/util/deep-search.js
 * 
 * 输出: 每个补丁的搜索结果，包含精确位置和上下文
 */

const fs = require('fs');
const path = require('path');

const BEAUTIFIED_PATH = path.join(__dirname, '..', '..', 'unpacked', 'index.beautified.js');
const OUTPUT_PATH = path.join(__dirname, '..', '..', 'unpacked', 'deep-search-results.json');

console.log('[deep-search] Loading beautified.js...');
const content = fs.readFileSync(BEAUTIFIED_PATH, 'utf8');
console.log(`[deep-search] File size: ${content.length} chars`);

// ============ 工具函数 ============

function searchAll(pattern, maxResults = 5) {
    const results = [];
    let idx = 0;
    while (results.length < maxResults) {
        idx = content.indexOf(pattern, idx);
        if (idx === -1) break;
        results.push(idx);
        idx += pattern.length;
    }
    return results;
}

function searchRegex(regex, maxResults = 5) {
    const results = [];
    let match;
    const re = new RegExp(regex.source, regex.flags);
    while (results.length < maxResults && (match = re.exec(content)) !== null) {
        results.push({ index: match.index, match: match[0], groups: match.groups });
    }
    return results;
}

function getContext(pos, before = 300, after = 300) {
    const start = Math.max(0, pos - before);
    const end = Math.min(content.length, pos + after);
    return content.substring(start, end);
}

function getLineInfo(pos) {
    // 计算行号
    const beforeText = content.substring(0, pos);
    const lineNum = (beforeText.match(/\n/g) || []).length + 1;
    const lastNewline = beforeText.lastIndexOf('\n');
    const colNum = pos - lastNewline;
    return { line: lineNum, col: colNum };
}

function extractBeautifiedBlock(pos, maxLen = 800) {
    // 从位置开始，提取到下一个合理断点（如空行或缩进回退）
    let end = Math.min(content.length, pos + maxLen);
    // 尝试在合理位置截断
    const chunk = content.substring(pos, end);
    return chunk;
}

// ============ 补丁搜索定义 ============

const patchSearches = {
    "efh-resume-list": {
        description: "可恢复错误列表扩展",
        searches: [
            { type: "string", pattern: "efx = [Ib.SERVER_CRASH", desc: "efx 数组定义" },
            { type: "string", pattern: "Ib.SERVER_CRASH", desc: "Ib 错误码枚举" },
            { type: "string", pattern: "Ib.TASK_TURN_EXCEEDED_ERROR", desc: "思考上限错误码" },
            { type: "string", pattern: "Ib.LLM_STOP_DUP_TOOL_CALL", desc: "重复工具调用错误码" },
            { type: "string", pattern: "Ib.LLM_STOP_CONTENT_LOOP", desc: "内容循环错误码" },
            { type: "string", pattern: "Ib.DEFAULT", desc: "DEFAULT 错误码" },
        ]
    },
    "guard-clause-bypass": {
        description: "Guard Clause 循环检测放行",
        searches: [
            { type: "string", pattern: 'localize("continue"', desc: "localize continue 调用" },
            { type: "regex", pattern: /if\s*\(\s*!\s*\w+\s*\|\|\s*!\s*\w+\s*\|\|\s*\w+\s*\)\s*return\s+null/, desc: "guard clause if(!x||!y||z)return null" },
            { type: "regex", pattern: /if\s*\(\s*\w+\s*&&\s*\w+\s*\)\s*\{/, desc: "if(V&&J) 等价结构" },
            { type: "string", pattern: "Alert", desc: "Alert 组件使用" },
            { type: "string", pattern: "onActionClick", desc: "onActionClick 回调" },
        ]
    },
    "bypass-loop-detection": {
        description: "绕过循环检测警告",
        searches: [
            { type: "regex", pattern: /\w+\s*=\s*!!\s*\[/, desc: "J=!![ 模式" },
            { type: "string", pattern: "Ib.MODEL_OUTPUT_TOO_LONG", desc: "MODEL_OUTPUT_TOO_LONG 错误码" },
            { type: "string", pattern: "Ib.TASK_TURN_EXCEEDED_ERROR", desc: "TASK_TURN_EXCEEDED_ERROR" },
            { type: "regex", pattern: /\w+\s*=\s*!!\s*\[\s*\w+\.\w+/, desc: "=!![X.Y 模式" },
            { type: "string", pattern: ".includes(_)", desc: ".includes(_) 过滤" },
        ]
    },
    "auto-continue-l2-parse": {
        description: "L2层自动续接 ErrorStreamParser.parse",
        searches: [
            { type: "string", pattern: "_aiChatRequestErrorService", desc: "ErrorStreamParser 依赖" },
            { type: "string", pattern: "getErrorInfoWithError", desc: "getErrorInfoWithError 方法" },
            { type: "string", pattern: "Ib.MODEL_RESPONSE_TIMEOUT_ERROR", desc: "MODEL_RESPONSE_TIMEOUT_ERROR" },
            { type: "string", pattern: "OS_SUSPEND_TIMEOUT", desc: "OS_SUSPEND_TIMEOUT" },
            { type: "string", pattern: "chatStreamFrontResponseReporter", desc: "chatStreamFrontResponseReporter" },
            { type: "regex", pattern: /parse\s*\(\s*\w+\s*,\s*\w+\s*\)\s*\{/, desc: "parse(e,t) 方法定义" },
        ]
    },
    "force-max-mode": {
        description: "强制 Max 模式",
        searches: [
            { type: "string", pattern: "isOlderCommercialUser", desc: "isOlderCommercialUser 方法" },
            { type: "string", pattern: "isSaas", desc: "isSaas 方法" },
            { type: "string", pattern: "_commercialPermissionService", desc: "商业权限服务" },
            { type: "string", pattern: "computeSelectedModelAndMode", desc: "模型选择计算" },
        ]
    },
    "auto-confirm-commands": {
        description: "命令自动确认",
        searches: [
            { type: "string", pattern: "[PlanItemStreamParser] auto-confirming", desc: "自动确认日志" },
            { type: "string", pattern: "confirm_status", desc: "confirm_status 字段" },
            { type: "string", pattern: "provideUserResponse", desc: "provideUserResponse 方法" },
            { type: "string", pattern: "tool_confirm", desc: "tool_confirm 类型" },
        ]
    },
    "bypass-runcommandcard-redlist": {
        description: "绕过 RunCommandCard 全模式弹窗",
        searches: [
            { type: "string", pattern: "Mp.AutoRunMode", desc: "AutoRunMode 枚举引用" },
            { type: "string", pattern: "Mp.BlockLevel", desc: "BlockLevel 枚举引用" },
            { type: "string", pattern: "zS.Default", desc: "Default 返回值" },
            { type: "string", pattern: "getRunCommandCardBranch", desc: "getRunCommandCardBranch 方法" },
            { type: "regex", pattern: /switch\s*\(\s*\w+\s*\)\s*\{\s*case\s+\w+\.\w+\.\w+:/, desc: "switch(t) case X.Y.Z:" },
        ]
    },
    "service-layer-runcommand-confirm": {
        description: "服务层自动确认+状态同步",
        searches: [
            { type: "string", pattern: "setBadgesBySessionId", desc: "setBadgesBySessionId 方法" },
            { type: "string", pattern: "auto_confirm", desc: "auto_confirm 字段" },
            { type: "string", pattern: "confirm_info", desc: "confirm_info 字段" },
        ]
    },
    "data-source-auto-confirm": {
        description: "数据源强制auto_confirm",
        searches: [
            { type: "string", pattern: "ViewFiles", desc: "ViewFiles 工具名" },
            { type: "string", pattern: "start_line_one_indexed", desc: "start_line_one_indexed 字段" },
            { type: "string", pattern: "AskUserQuestion", desc: "AskUserQuestion 工具名" },
            { type: "string", pattern: "ExitPlanMode", desc: "ExitPlanMode 工具名" },
        ]
    },
    "auto-continue-thinking": {
        description: "自动续接思考上限 (L1层)",
        searches: [
            { type: "string", pattern: 'localize("continue"', desc: "localize continue" },
            { type: "string", pattern: "onDoubleClick", desc: "onDoubleClick 事件" },
            { type: "string", pattern: "onActionClick", desc: "onActionClick 事件" },
        ]
    },
    "auto-continue-v11-store-subscribe": {
        description: "v11 store.subscribe 监听",
        searches: [
            { type: "string", pattern: "async function FP(e)", desc: "FP 函数定义" },
            { type: "string", pattern: "async function FQ(e)", desc: "FQ 函数定义" },
            { type: "string", pattern: "async function FR(e)", desc: "FR 函数定义" },
            { type: "regex", pattern: /async\s+function\s+F\w\(e\)\s*\{/, desc: "F* 函数族" },
            { type: "string", pattern: "resolve(k1)", desc: "resolve(k1) 调用" },
        ]
    },
    "force-auto-confirm": {
        description: "强制自动确认 (根因修复)",
        searches: [
            { type: "string", pattern: "Unconfirmed", desc: "Unconfirmed 状态" },
            { type: "string", pattern: "Confirmed", desc: "Confirmed 状态" },
            { type: "regex", pattern: /\w+\.confirm\s*\(\s*!\s*0\s*\)/, desc: "ew.confirm(!0) 模式" },
        ]
    },
    "sync-force-confirm": {
        description: "同步强制确认",
        searches: [
            { type: "regex", pattern: /useMemo\s*\(\s*\(\s*\)\s*=>/, desc: "useMemo(() =>" },
            { type: "string", pattern: "Unconfirmed", desc: "Unconfirmed 状态" },
            { type: "string", pattern: "Confirmed", desc: "Confirmed 状态" },
        ]
    }
};

// ============ 执行搜索 ============

const results = {};

for (const [patchId, config] of Object.entries(patchSearches)) {
    console.log(`\n${'='.repeat(60)}`);
    console.log(`[${patchId}] ${config.description}`);
    console.log('='.repeat(60));
    
    results[patchId] = { description: config.description, findings: [] };
    
    for (const search of config.searches) {
        let found;
        if (search.type === "string") {
            found = searchAll(search.pattern, 3);
        } else if (search.type === "regex") {
            try {
                found = searchRegex(search.pattern, 3);
            } catch (e) {
                found = [{ error: e.message }];
            }
        }
        
        const finding = {
            search: search.desc,
            pattern: search.type === "string" ? search.pattern : search.pattern.source,
            type: search.type,
            count: Array.isArray(found) ? found.length : 0,
            locations: []
        };
        
        if (Array.isArray(found) && found.length > 0) {
            for (const item of found) {
                if (typeof item === 'number') {
                    const lineInfo = getLineInfo(item);
                    const ctx = getContext(item, 200, 200);
                    finding.locations.push({
                        position: item,
                        line: lineInfo.line,
                        context: ctx
                    });
                    console.log(`  [${search.desc}] FOUND @${item} (line ${lineInfo.line})`);
                    console.log(`    Context: ...${ctx.substring(0, 100)}...`);
                } else if (item.index !== undefined) {
                    const lineInfo = getLineInfo(item.index);
                    finding.locations.push({
                        position: item.index,
                        line: lineInfo.line,
                        match: item.match.substring(0, 100),
                        context: getContext(item.index, 150, 150)
                    });
                    console.log(`  [${search.desc}] REGEX MATCH @${item.index} (line ${lineInfo.line}): "${item.match.substring(0, 80)}"`);
                }
            }
        } else {
            console.log(`  [${search.desc}] NOT FOUND`);
        }
        
        results[patchId].findings.push(finding);
    }
}

// ============ 深度搜索：关键代码块提取 ============

console.log(`\n${'#'.repeat(60)}`);
console.log('## DEEP EXTRACTION: 关键代码块精确提取');
console.log('#'.repeat(60));

// 1. efx 数组完整内容
const efxPos = content.indexOf("efx = [Ib.SERVER_CRASH");
if (efxPos >= 0) {
    // 找到数组结束位置
    let bracketDepth = 0;
    let endPos = efxPos;
    let started = false;
    for (let i = efxPos; i < content.length && i < efxPos + 2000; i++) {
        if (content[i] === '[') { bracketDepth++; started = true; }
        if (content[i] === ']') { bracketDepth--; }
        if (started && bracketDepth === 0) { endPos = i + 1; break; }
    }
    const efxBlock = content.substring(efxPos, endPos);
    console.log('\n[efx ARRAY] Full content:');
    console.log(efxBlock);
    results["efh-resume-list"].efxFullBlock = efxBlock;
    results["efh-resume-list"].efxPosition = efxPos;
}

// 2. ErrorStreamParser 类定义
const errorServicePos = content.indexOf("_aiChatRequestErrorService");
if (errorServicePos >= 0) {
    // 向前搜索 class 定义
    const beforeChunk = content.substring(Math.max(0, errorServicePos - 5000), errorServicePos);
    const classMatch = beforeChunk.match(/class\s+(\w+)\s+extends\s+(\w+)\s*\{[^]*$/);
    if (classMatch) {
        const classStart = errorServicePos - 5000 + beforeChunk.lastIndexOf("class " + classMatch[1]);
        console.log(`\n[ErrorStreamParser] Class: ${classMatch[1]} extends ${classMatch[2]}`);
        console.log(`  Position: ${classStart}`);
        // 提取 parse 方法
        const parseSearch = content.substring(classStart, classStart + 5000);
        const parseMatch = parseSearch.match(/parse\s*\(\s*(\w+)\s*,\s*(\w+)\s*\)\s*\{/);
        if (parseMatch) {
            const parseStart = classStart + parseSearch.indexOf(parseMatch[0]);
            // 找到方法结束
            let braceDepth = 0;
            let methodEnd = parseStart;
            let methodStarted = false;
            for (let i = parseStart + parseMatch[0].length - 1; i < content.length && i < parseStart + 3000; i++) {
                if (content[i] === '{') { braceDepth++; methodStarted = true; }
                if (content[i] === '}') { braceDepth--; }
                if (methodStarted && braceDepth === 0) { methodEnd = i + 1; break; }
            }
            const parseBlock = content.substring(parseStart, methodEnd);
            console.log(`  parse method @${parseStart}:`);
            console.log(parseBlock.substring(0, 800));
            results["auto-continue-l2-parse"].parseMethod = parseBlock;
            results["auto-continue-l2-parse"].parsePosition = parseStart;
            results["auto-continue-l2-parse"].className = classMatch[1];
            results["auto-continue-l2-parse"].parentClass = classMatch[2];
        }
    }
}

// 3. localize("continue") 上下文 — 找到 auto-continue L1 逻辑
const localizeContinuePositions = searchAll('localize("continue"', 5);
for (const pos of localizeContinuePositions) {
    const ctx = getContext(pos, 500, 500);
    console.log(`\n[localize("continue")] @${pos}:`);
    console.log(ctx);
}

// 4. guard clause 搜索 — 在 localize("continue") 附近搜索
for (const pos of localizeContinuePositions) {
    const nearby = content.substring(Math.max(0, pos - 2000), pos + 2000);
    // 搜索 if(!x||!y||z)return null 模式
    const guardMatch = nearby.match(/if\s*\(\s*!\s*(\w+)\s*\|\|\s*!\s*(\w+)\s*\|\|\s*(\w+)\s*\)\s*return\s+null/);
    if (guardMatch) {
        const guardPos = pos - 2000 + nearby.indexOf(guardMatch[0]);
        console.log(`\n[GUARD CLAUSE] @${guardPos}: ${guardMatch[0]}`);
        console.log(`  Variables: !${guardMatch[1]} || !${guardMatch[2]} || ${guardMatch[3]}`);
        const guardCtx = getContext(guardPos, 300, 300);
        console.log(`  Context: ...${guardCtx}...`);
        results["guard-clause-bypass"].guardClause = guardMatch[0];
        results["guard-clause-bypass"].guardPosition = guardPos;
        results["guard-clause-bypass"].guardVars = { n: guardMatch[1], q: guardMatch[2], et: guardMatch[3] };
    }
    
    // 搜索 if(V&&J) 等价结构
    const vjMatch = nearby.match(/if\s*\(\s*(\w+)\s*&&\s*(\w+)\s*\)\s*\{/);
    if (vjMatch) {
        const vjPos = pos - 2000 + nearby.indexOf(vjMatch[0]);
        console.log(`\n[if(V&&J)] @${vjPos}: ${vjMatch[0]}`);
        console.log(`  Variables: ${vjMatch[1]} && ${vjMatch[2]}`);
        results["guard-clause-bypass"].vjClause = vjMatch[0];
        results["guard-clause-bypass"].vjPosition = vjPos;
        results["guard-clause-bypass"].vjVars = { V: vjMatch[1], J: vjMatch[2] };
    }
}

// 5. J=!![ 模式搜索 — 循环检测
const includesUnderscore = searchAll('.includes(_)', 5);
for (const pos of includesUnderscore) {
    const ctx = getContext(pos, 300, 100);
    console.log(`\n[.includes(_)] @${pos}:`);
    console.log(ctx);
    // 检查前面是否有 =!![ 模式
    const before = content.substring(Math.max(0, pos - 200), pos);
    const assignMatch = before.match(/(\w+)\s*=\s*!!\s*\[/);
    if (assignMatch) {
        console.log(`  Found assignment: ${assignMatch[0]}`);
        results["bypass-loop-detection"].assignment = assignMatch[0];
        results["bypass-loop-detection"].assignVar = assignMatch[1];
        // 提取完整数组
        const arrayStart = pos - 200 + before.indexOf(assignMatch[0]);
        let bracketDepth = 0;
        let arrayEnd = arrayStart;
        let arrayStarted = false;
        for (let i = arrayStart + assignMatch[0].indexOf('['); i < content.length && i < arrayStart + 1000; i++) {
            if (content[i] === '[') { bracketDepth++; arrayStarted = true; }
            if (content[i] === ']') { bracketDepth--; }
            if (arrayStarted && bracketDepth === 0) { arrayEnd = i + 1; break; }
        }
        const fullAssign = content.substring(arrayStart, arrayEnd + 20);
        console.log(`  Full assignment: ${fullAssign}`);
        results["bypass-loop-detection"].fullAssignment = fullAssign;
        results["bypass-loop-detection"].assignmentPosition = arrayStart;
    }
}

// 6. RunCommandCard / AutoRunMode / BlockLevel 上下文
const autoRunModePos = searchAll("Mp.AutoRunMode", 5);
for (const pos of autoRunModePos) {
    const ctx = getContext(pos, 300, 500);
    console.log(`\n[Mp.AutoRunMode] @${pos}:`);
    console.log(ctx);
}

// 7. isOlderCommercialUser 上下文
const commercialPos = searchAll("isOlderCommercialUser", 3);
for (const pos of commercialPos) {
    const ctx = getContext(pos, 300, 300);
    console.log(`\n[isOlderCommercialUser] @${pos}:`);
    console.log(ctx);
}

// 8. PlanItemStreamParser auto-confirming
const autoConfirmPos = searchAll("[PlanItemStreamParser] auto-confirming", 3);
for (const pos of autoConfirmPos) {
    const ctx = getContext(pos, 500, 500);
    console.log(`\n[auto-confirming] @${pos}:`);
    console.log(ctx);
}

// 9. setBadgesBySessionId 上下文
const badgesPos = searchAll("setBadgesBySessionId", 3);
for (const pos of badgesPos) {
    const ctx = getContext(pos, 300, 300);
    console.log(`\n[setBadgesBySessionId] @${pos}:`);
    console.log(ctx);
}

// 10. ViewFiles / start_line_one_indexed 上下文
const viewFilesPos = searchAll("ViewFiles", 3);
for (const pos of viewFilesPos) {
    const ctx = getContext(pos, 200, 300);
    if (ctx.includes("start_line_one_indexed")) {
        console.log(`\n[ViewFiles+start_line] @${pos}:`);
        console.log(ctx);
    }
}

// 11. store.subscribe 模式搜索
const storeSubscribePositions = searchRegex(/\.subscribe\s*\(\s*function\s*\(/, 5);
for (const item of storeSubscribePositions) {
    const ctx = getContext(item.index, 200, 300);
    console.log(`\n[store.subscribe] @${item.index}:`);
    console.log(ctx);
}

// 12. Unconfirmed/Confirmed 状态搜索
const unconfirmedPositions = searchAll("Unconfirmed", 5);
console.log(`\n[Unconfirmed] Found ${unconfirmedPositions.length} occurrences`);
for (const pos of unconfirmedPositions) {
    const ctx = getContext(pos, 200, 200);
    console.log(`  @${pos}: ...${ctx.substring(0, 150)}...`);
}

// 13. FP/FQ/FR 函数搜索
for (const fn of ['FP', 'FQ', 'FR', 'FS', 'FT']) {
    const fnPos = searchAll(`async function ${fn}(e)`, 2);
    if (fnPos.length > 0) {
        for (const pos of fnPos) {
            const ctx = getContext(pos, 100, 400);
            console.log(`\n[async function ${fn}(e)] @${pos}:`);
            console.log(ctx);
        }
    }
}

// 14. 搜索 confirm_info 和 auto_confirm 在同一上下文中
const confirmInfoPos = searchAll("confirm_info", 5);
console.log(`\n[confirm_info] Found ${confirmInfoPos.length} occurrences`);
for (const pos of confirmInfoPos) {
    const ctx = getContext(pos, 300, 300);
    console.log(`  @${pos}: ...${ctx.substring(0, 200)}...`);
}

// 15. 搜索 DI Token — Suspend
const suspendPos = searchAll("Suspend", 5);
console.log(`\n[Suspend] Found ${suspendPos.length} occurrences`);
for (const pos of suspendPos.slice(0, 3)) {
    const ctx = getContext(pos, 100, 100);
    console.log(`  @${pos}: ...${ctx}...`);
}

// ============ 保存结果 ============

fs.writeFileSync(OUTPUT_PATH, JSON.stringify(results, null, 2), 'utf8');
console.log(`\n[deep-search] Results saved to ${OUTPUT_PATH}`);
console.log('[deep-search] Done!');
