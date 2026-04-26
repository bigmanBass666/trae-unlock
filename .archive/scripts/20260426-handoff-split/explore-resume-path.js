var fs = require('fs');
var c = fs.readFileSync('D:/apps/Trae CN/resources/app/node_modules/@byted-icube/ai-modules-chat/dist/index.js', 'utf8');
var out = '';

// Targeted searches
var targets = [
    'resumeChat',
    '.chat(',
    'sendChatMessage',
    'GZt',
    'Validate data',
    'missing field',
    '.invoke(',
    'ipcRenderer',
    'ipc.call'
];

for (var i = 0; i < targets.length; i++) {
    var t = targets[i];
    var pos = c.indexOf(t);
    if (pos >= 0) {
        out += '=== FOUND: "' + t + '" at pos:' + pos + ' ===\n';
        var s = Math.max(0, pos - 80);
        var l = Math.min(200, c.length - pos + 80);
        out += c.substring(s, l) + '\n\n';
        
        // Count total occurrences
        var count = 0;
        var searchFrom = 0;
        while ((searchFrom = c.indexOf(t, searchFrom)) >= 0) {
            count++;
            searchFrom++;
        }
        out += 'Total occurrences: ' + count + '\n\n';
    } else {
        out += '=== NOT FOUND: "' + t + '" ===\n\n';
    }
}

// Search for Di class area - find teaEventChatFail and look at surrounding class methods
var teaIdx = c.indexOf('teaEventChatFail(e,t,i)');
if (teaIdx >= 0) {
    out += '=== Area around teaEventChatFail ===\n';
    out += 'teaEventChatFail pos: ' + teaIdx + '\n';
    
    // Look for class definition patterns nearby (within 10000 chars before)
    var area = c.substring(Math.max(0, teaIdx - 10000), teaIdx + 200);
    
    // Find all method definitions in this area
    var methods = area.match(/\w+\s*\([^)]*\)\s*[{=]/g);
    if (methods) {
        out += 'Method-like patterns in area:\n';
        for (var m = 0; m < Math.min(methods.length, 30); m++) {
            out += '  ' + methods[m] + '\n';
        }
    }
    
    // Find "this." references that look like method calls
    var thisMethods = area.match(/this\.\w+\s*\(/g);
    if (thisMethods) {
        var unique = {};
        out += '\n"this.xxx(" calls in area:\n';
        for (var n = 0; n < thisMethods.length; n++) {
            var name = thisMethods[n].replace(/\(.*/, '');
            if (!unique[name]) {
                unique[name] = true;
                out += '  ' + name + '\n';
            }
        }
    }
    
    out += '\n';
}

fs.writeFileSync('d:/Test/trae-unlock/scripts/explore-output3.txt', out);
console.log('Done! Length:', out.length);
