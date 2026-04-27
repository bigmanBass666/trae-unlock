$script:AST_TOOLS_ROOT = Split-Path -Parent $PSScriptRoot
$script:BABEL_ROOT = Join-Path $script:AST_TOOLS_ROOT "tools\node_modules"
$script:TMP_DIR = Join-Path $env:TEMP "ast-search-tmp"

function New-TempJSFile {
    param([string]$Content)
    if (-not (Test-Path $script:TMP_DIR)) { New-Item -ItemType Directory -Path $script:TMP_DIR -Force | Out-Null }
    $tmpFile = Join-Path $script:TMP_DIR ("ast-{0}.js" -f [Guid]::NewGuid().ToString("N").Substring(0,12))
    [IO.File]::WriteAllText($tmpFile, $Content, [System.Text.Encoding]::UTF8)
    return $tmpFile
}

function Invoke-ASTNode {
    param([string]$JsCode, [switch]$NoCleanup)
    $tmp = New-TempJSFile $JsCode
    try {
        $nodeArgs = @("--max-old-space-size=4096", $tmp)
        $result = & node $nodeArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            $errText = ($result | Where-Object { $_ -is [string] }) -join "`n"
            Write-Warning "Node.js error (exit $LASTEXITCODE): $errText"
            return $null
        }
        return ($result | Where-Object { $_ -is [string] }) -join "`n"
    } finally {
        if (-not $NoCleanup) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
    }
}

function Search-AST {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string]$NodeType,
        [string]$NamePattern = ".*",
        [int]$MaxResults = 50
    )
    $absPath = (Resolve-Path $FilePath -ErrorAction Stop).Path
    $escapedPattern = $NamePattern -replace "'", "\'"
    $jsTemplate = @"
const parser = require('$($script:BABEL_ROOT -replace '\\','/')/@babel/parser/lib/index.js');
const traverse = require('$($script:BABEL_ROOT -replace '\\','/')/@babel/traverse/lib/index.js').default;
const fs = require('fs');
const src = fs.readFileSync('$($absPath -replace '\\','/')', 'utf8');
let ast;
try {
  ast = parser.parse(src, {
    sourceType: 'module',
    plugins: ['decorators', 'decoratorAutoAccessors', 'classProperties', 'classPrivateProperties', 'classPrivateMethods', 'jsx'],
    errorRecovery: true,
    tokens: false
  });
} catch(e) {
  process.stderr.write('PARSE_ERROR: ' + e.message + '\n');
  process.exit(1);
}
const lines = src.split('\n');
const results = [];
const nameRe = new RegExp('$escapedPattern');
let count = 0;
const MAX = $MaxResults;
traverse(ast, {
  $NodeType(path) {
    const n = path.node;
    let name = '';
    if (n.id && n.id.name) name = n.id.name;
    else if (n.key && n.key.name) name = n.key.name;
    else if (n.callee && n.callee.name) name = n.callee.name;
    else if (n.type === 'ClassDeclaration' || n.type === 'ClassExpression') name = n.id ? n.id.name : '(anonymous)';
    if (!nameRe.test(name)) return;
    count++;
    if (count > MAX) return path.stop();
    const loc = n.loc ? n.loc.start : null;
    const startLine = loc ? loc.line : 0;
    const endLine = n.loc ? n.loc.end.line : 0;
    const ctxStart = Math.max(0, startLine - 2);
    const ctxEnd = Math.min(lines.length, endLine + 1);
    const context = lines.slice(ctxStart, ctxEnd).join('\n');
    results.push({
      type: n.type,
      name: name,
      start_line: startLine,
      end_line: endLine,
      start_col: loc ? loc.column : 0,
      context_preview: context.substring(0, 500)
    });
  }
});
process.stdout.write(JSON.stringify(results, null, 0));
"@
    $output = Invoke-ASTNode $jsTemplate
    if (-not $output) { return @() }
    try {
        $data = $output | ConvertFrom-Json
        return @(if ($data -is [array]) { $data } else { ,@($data) })
    } catch {
        Write-Warning "Failed to parse AST output: $_"
        return @()
    }
}

function Search-ASTFast {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string]$NodeType,
        [string]$NamePattern = ".*",
        [int]$MaxResults = 200
    )
    $absPath = (Resolve-Path $FilePath -ErrorAction Stop).Path
    $escapedPattern = $NamePattern -replace "'", "\'"
    $jsTemplate = @"
const parser = require('$($script:BABEL_ROOT -replace '\\','/')/@babel/parser/lib/index.js');
const traverse = require('$($script:BABEL_ROOT -replace '\\','/')/@babel/traverse/lib/index.js').default;
const fs = require('fs');
const src = fs.readFileSync('$($absPath -replace '\\','/')', 'utf8');
let ast;
try {
  ast = parser.parse(src, {
    sourceType: 'module',
    plugins: ['decorators', 'decoratorAutoAccessors', 'classProperties', 'classPrivateProperties', 'classPrivateMethods', 'jsx'],
    errorRecovery: true,
    tokens: false
  });
} catch(e) {
  process.stderr.write('PARSE_ERROR: ' + e.message + '\n');
  process.exit(1);
}
const results = [];
const nameRe = new RegExp('$escapedPattern');
let count = 0;
const MAX = $MaxResults;
traverse(ast, {
  $NodeType(path) {
    const n = path.node;
    let name = '';
    if (n.id && n.id.name) name = n.id.name;
    else if (n.key && n.key.name) name = n.key.name;
    else if (n.callee && n.callee.name) name = n.callee.name;
    else if (n.type === 'ClassDeclaration' || n.type === 'ClassExpression') name = n.id ? n.id.name : '(anonymous)';
    if (!nameRe.test(name)) return;
    count++;
    if (count > MAX) return path.stop();
    const loc = n.loc ? n.loc.start : null;
    results.push({ type: n.type, name: name, line: loc ? loc.line : 0, col: loc ? loc.column : 0 });
  }
});
process.stdout.write(JSON.stringify(results));
"@
    $output = Invoke-ASTNode $jsTemplate
    if (-not $output) { return @() }
    try {
        $data = $output | ConvertFrom-Json
        return @(if ($data -is [array]) { $data } else { ,@($data) })
    } catch {
        Write-Warning "Failed to parse AST output: $_"
        return @()
    }
}

function Extract-AllFunctions {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string]$OutputFile = "functions-index.json"
    )
    $absPath = (Resolve-Path $FilePath -ErrorAction Stop).Path
    $outAbs = if ([System.IO.Path]::IsPathRooted($OutputFile)) { $OutputFile } else { Join-Path (Get-Location) $OutputFile }
    $jsTemplate = @"
const parser = require('$($script:BABEL_ROOT -replace '\\','/')/@babel/parser/lib/index.js');
const traverse = require('$($script:BABEL_ROOT -replace '\\','/')/@babel/traverse/lib/index.js').default;
const fs = require('fs');
const src = fs.readFileSync('$($absPath -replace '\\','/')', 'utf8');
let ast;
try {
  ast = parser.parse(src, {
    sourceType: 'module',
    plugins: ['decorators', 'decoratorAutoAccessors', 'classProperties', 'classPrivateProperties', 'classPrivateMethods', 'jsx'],
    errorRecovery: true,
    tokens: false
  });
} catch(e) {
  process.stderr.write('PARSE_ERROR: ' + e.message + '\n');
  process.exit(1);
}
const functions = [];
traverse(ast, {
  FunctionDeclaration(path) {
    const n = path.node;
    const params = n.params.map(p => p.type === 'Identifier' ? p.name : p.type === 'RestElement' && p.argument ? '...' + p.argument.name : p.type);
    functions.push({
      name: n.id ? n.id.name : '(anonymous)',
      type: 'FunctionDeclaration',
      params: params,
      async: n.async || false,
      generator: n.generator || false,
      start: n.loc ? n.loc.start.line : 0,
      end: n.loc ? n.loc.end.line : 0
    });
  },
  'FunctionExpression|ArrowFunctionExpression'(path) {
    const n = path.node;
    let name = '';
    const parent = path.parent;
    if (parent) {
      if (parent.type === 'VariableDeclarator' && parent.id) name = parent.id.name;
      else if (parent.type === 'AssignmentExpression' && parent.left && parent.left.type === 'Identifier') name = parent.left.name;
      else if (parent.type === 'MethodDefinition' && parent.key) name = parent.key.name;
      else if (parent.type === 'Property' && parent.key) name = parent.key.name;
      else if ((parent.type === 'ExportDefaultDeclaration' || parent.type === 'ExportNamedDeclaration') && parent.declaration === n) name = '(exported)';
    }
    if (!name) name = '(anonymous)';
    const params = n.params.map(p => p.type === 'Identifier' ? p.name : p.type === 'RestElement' && p.argument ? '...' + p.argument.name : p.type);
    functions.push({
      name: name,
      type: n.type,
      params: params,
      async: n.async || false,
      generator: n.generator || false,
      start: n.loc ? n.loc.start.line : 0,
      end: n.loc ? n.loc.end.line : 0
    });
  }
});
functions.sort((a,b)=>a.start-b.start);
fs.writeFileSync('$($outAbs -replace '\\','/')', JSON.stringify(functions, null, 2));
process.stdout.write(JSON.stringify({total: functions.length, output: '$($outAbs -replace '\\','/')'}));
"@
    $output = Invoke-ASTNode $jsTemplate
    if ($output) {
        try {
            $info = $output | ConvertFrom-Json
            Write-Host "Extracted $($info.total) functions -> $($info.output)" -ForegroundColor Green
        } catch {
            Write-Host "Raw output: $output" -ForegroundColor Yellow
        }
    }
}

function Extract-AllClasses {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string]$OutputFile = "classes-index.json"
    )
    $absPath = (Resolve-Path $FilePath -ErrorAction Stop).Path
    $outAbs = if ([System.IO.Path]::IsPathRooted($OutputFile)) { $OutputFile } else { Join-Path (Get-Location) $OutputFile }
    $jsTemplate = @"
const parser = require('$($script:BABEL_ROOT -replace '\\','/')/@babel/parser/lib/index.js');
const traverse = require('$($script:BABEL_ROOT -replace '\\','/')/@babel/traverse/lib/index.js').default;
const fs = require('fs');
const src = fs.readFileSync('$($absPath -replace '\\','/')', 'utf8');
let ast;
try {
  ast = parser.parse(src, {
    sourceType: 'module',
    plugins: ['decorators', 'decoratorAutoAccessors', 'classProperties', 'classPrivateProperties', 'classPrivateMethods', 'jsx'],
    errorRecovery: true,
    tokens: false
  });
} catch(e) {
  process.stderr.write('PARSE_ERROR: ' + e.message + '\n');
  process.exit(1);
}
const classes = [];
traverse(ast, {
  ClassDeclaration(path) {
    const n = path.node;
    const extendsClause = n.superClass
      ? (n.superClass.type === 'Identifier' ? n.superClass.name : n.superClass.type)
      : null;
    const methods = [];
    n.body.body.forEach(m => {
      if (m.type === 'MethodDefinition') {
        methods.push({
          kind: m.kind,
          key: m.key.name || m.key.value || '(computed)',
          static: m.static || false,
          computed: m.computed || false
        });
      }
    });
    const decorators = (n.decorators || []).map(d =>
      d.expression.type === 'Identifier' ? d.expression.name :
      d.expression.type === 'CallExpression' && d.expression.callee ? d.expression.callee.name + '(...)' : d.expression.type
    );
    classes.push({
      name: n.id ? n.id.name : '(anonymous)',
      extends: extendsClause,
      decorators: decorators,
      methods: methods,
      start: n.loc ? n.loc.start.line : 0,
      end: n.loc ? n.loc.end.line : 0
    });
  },
  ClassExpression(path) {
    const n = path.node;
    let className = '(anonymous)';
    const parent = path.parent;
    if (parent && parent.type === 'VariableDeclarator' && parent.id) className = parent.id.name;
    else if (parent && parent.type === 'AssignmentExpression' && parent.left && parent.left.type === 'Identifier') className = parent.left.name;
    const extendsClause = n.superClass
      ? (n.superClass.type === 'Identifier' ? n.superClass.name : n.superClass.type)
      : null;
    const methods = [];
    n.body.body.forEach(m => {
      if (m.type === 'MethodDefinition') {
        methods.push({
          kind: m.kind,
          key: m.key.name || m.key.value || '(computed)',
          static: m.static || false
        });
      }
    });
    classes.push({
      name: className,
      type: 'ClassExpression',
      extends: extendsClause,
      methods: methods,
      start: n.loc ? n.loc.start.line : 0,
      end: n.loc ? n.loc.end.line : 0
    });
  }
});
classes.sort((a,b)=>a.start-b.start);
fs.writeFileSync('$($outAbs -replace '\\','/')', JSON.stringify(classes, null, 2));
process.stdout.write(JSON.stringify({total: classes.length, output: '$($outAbs -replace '\\','/')'}));
"@
    $output = Invoke-ASTNode $jsTemplate
    if ($output) {
        try {
            $info = $output | ConvertFrom-Json
            Write-Host "Extracted $($info.total) classes -> $($info.output)" -ForegroundColor Green
        } catch {
            Write-Host "Raw output: $output" -ForegroundColor Yellow
        }
    }
}
