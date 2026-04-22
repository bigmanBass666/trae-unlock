const fs = require('fs');
const path = 'd:/Test/trae-unlock/patches/definitions.json';
const raw = fs.readFileSync(path, 'utf8');
const data = JSON.parse(raw);

const patch = data.patches.find(p => p.id === 'auto-continue-thinking');
if (patch) {
    patch.find_original = 'if(V&&J){let e=M.localize("continue",{},"Continue");var _acT=Date.now();if(!window.__taeAC||_acT-window.__taeAC>5000){window.__taeAC=_acT;if(!window.__traeSvc){window.__traeSvc={D:D,b:b,M:M,sid:h,mid:o};console.log("[v8-L1] captured services for L2 poller")}else{window.__traeSvc.sid=h;window.__traeSvc.mid=o;console.log("[v8-L1] updated service refs")}}return sX().createElement(Cr.Alert,{onDoubleClick:e_,type:"warning",message:ef,actionText:e,onActionClick:ec})}';
    patch.replace_with = "if(typeof D!=='undefined'&&D&&typeof b!=='undefined'&&b){if(!window.__traeSvc){window.__traeSvc={D:D,b:b,M:M};console.log('[v9-L1] early service capture at render')}else{window.__traeSvc.D=D;window.__traeSvc.b=b;window.__traeSvc.M=M}}if(V&&J){let e=M.localize('continue',{},'Continue');var _acT=Date.now();if(!window.__taeAC||_acT-window.__taeAC>5000){window.__taeAC=_acT;if(window.__traeSvc){window.__traeSvc.sid=h;window.__traeSvc.mid=o;console.log('[v9-L1] error detected, session refs updated')}}return sX().createElement(Cr.Alert,{onDoubleClick:e_,type:'warning',message:ef,actionText:e,onActionClick:ec})}";
    patch.name = '自动续接思考上限 (v9 - 早捕获+L2独立)';
    patch.description = 'v9 核心修复: 将服务捕获从 if(V&&J) 内部移到外部。v8缺陷: L2依赖L1先执行才能设置window.__traeSvc，但后台L1冻结导致__traeSvc永远为空。v9方案: L1在每次渲染时无条件下早捕获服务引用(D/b/M)，L2轮询器独立可用。解决了切换窗口后auto-continue失效的根本问题。';
    patch.check_fingerprint = '[v9-L1] early service capture';
    
    fs.writeFileSync(path, JSON.stringify(data, null, 4), 'utf8');
    
    // Verify
    const verify = JSON.parse(fs.readFileSync(path, 'utf8'));
    const p2 = verify.patches.find(p => p.id === 'auto-continue-thinking');
    console.log('OK: v9 patch applied');
    console.log('  name:', p2.name);
    console.log('  fingerprint:', p2.check_fingerprint);
    console.log('  find_original starts with:', p2.find_original.substring(0, 30));
    console.log('  replace_with starts with:', p2.replace_with.substring(0, 50));
} else {
    console.error('ERROR: auto-continue-thinking patch not found!');
}
