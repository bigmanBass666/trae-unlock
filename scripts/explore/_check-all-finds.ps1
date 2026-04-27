$targetFile = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'
$c = [System.IO.File]::ReadAllText($targetFile)

# Check auto-continue-l2-parse find_original
$find_l2 = 'class zU extends DV{parse(e,t){e.code===kg.MODEL_RESPONSE_TIMEOUT_ERROR&&t.osStatus&&t.osStatus.get(b3.Suspend)&&(e.code=kg.OS_SUSPEND_TIMEOUT);let i=this._aiChatRequestErrorService.getErrorInfoWithError(e),r={status:"warn"===i.level?bQ.Warning:bQ.Error,exception:{code:e.code,message:i.message,data:e.data,model_call_chain:e.data?.model_call_chain}};return this.chatStreamFrontResponseReporter.updateFrontResponsePayloadWhenError(e,r,t),r}'
$idx_l2 = $c.IndexOf($find_l2)
Write-Host ("auto-continue-l2-parse find_original: " + $(if($idx_l2 -ge 0){"FOUND at "+$idx_l2}else{"NOT FOUND"}))

# Check auto-continue-v11-store-subscribe find_original
$find_v11 = 'd!==t.currentSessionId)&&a()})}async function FP(e){let t=uj.getInstance(),i=t.resolve(k1),{currentAgent:r}=t.resolve(xC).getState()'
$idx_v11 = $c.IndexOf($find_v11)
Write-Host ("auto-continue-v11-store-subscribe find_original: " + $(if($idx_v11 -ge 0){"FOUND at "+$idx_v11}else{"NOT FOUND"}))

# Extract the CLEAN code for auto-continue-thinking
$anchor = 'if(V&&J){let e=M.localize("continue",{},"Continue")'
$idx = $c.IndexOf($anchor)
$cleanCode = $c.Substring($idx, $c.IndexOf('}', $c.IndexOf('ed})}', $idx) + 1) - $idx + 1)
Write-Host ""
Write-Host "=== CLEAN code for auto-continue-thinking ==="
Write-Host $cleanCode
Write-Host ""
Write-Host ("Length: " + $cleanCode.Length + " chars")
