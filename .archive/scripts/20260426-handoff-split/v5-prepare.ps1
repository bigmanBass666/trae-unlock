$ErrorActionPreference = "Stop"
$clean = 'd:\Test\trae-unlock\backups\clean-20260425-025343.ext'
$target = 'D:\apps\Trae CN\resources\app\node_modules\@byted-icube\ai-modules-chat\dist\index.js'

Write-Host "[v5-prep] Step 1: Restoring from clean backup..." -ForegroundColor Cyan
[System.IO.File]::Copy($clean, $target, $true)
$sz = [System.IO.File]::ReadAllText($target).Length
Write-Host "[v5-prep] Restored OK, size=$sz bytes" -ForegroundColor Green

Write-Host "[v5-prep] Step 2: Running apply-patches.ps1..." -ForegroundColor Cyan
& "$PSScriptRoot\apply-patches.ps1"
