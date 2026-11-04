param()
$ErrorActionPreference = 'Stop'
$cityRepo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
& (Join-Path $PSScriptRoot 'project.ps1') Test
& (Join-Path $PSScriptRoot 'project.ps1') Export
$cityPin = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
$cityEditor = Join-Path $cityRepo ('.tools/godot/' + $cityPin.version + '/Godot_v' + $cityPin.version + '-stable_win64_console.exe')
$cityPack = Join-Path $cityRepo 'builds/windows/citybuilder.pck'
$cityDriver = Join-Path $cityRepo 'game/tests/packed_integration.gd'
# Native stderr is captured as text with 'Continue' (Windows PowerShell 5.1 would otherwise abort mid-log).
$ErrorActionPreference = 'Continue'
$cityOutput = @(& $cityEditor --headless --main-pack $cityPack --script $cityDriver 2>&1 | ForEach-Object { "$_" })
$cityExit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
Set-Content -LiteralPath (Join-Path $cityRepo 'builds/validation/packed-integration.log') -Value $cityOutput -Encoding utf8
$cityOutput
if ($cityExit -ne 0 -or ($cityOutput -match 'SCRIPT ERROR:|^ERROR:|^FAIL:') -or -not ($cityOutput -match '"suite":"packed-integration"')) { throw 'Packed integration checks failed or did not finish.' }
$cityExportConsole = Join-Path $cityRepo 'builds/windows/citybuilder.console.exe'
$ErrorActionPreference = 'Continue'
$cityOutput = @(& $cityExportConsole --headless --quit-after 6 2>&1 | ForEach-Object { "$_" })
$cityExit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
Set-Content -LiteralPath (Join-Path $cityRepo 'builds/validation/export-startup.log') -Value $cityOutput -Encoding utf8
$cityOutput
if ($cityExit -ne 0 -or ($cityOutput -match 'SCRIPT ERROR:|^ERROR:')) { throw 'Export startup check failed.' }
Write-Output 'Automated checks passed. These do not replace manual Windows UI and graphics testing.'
