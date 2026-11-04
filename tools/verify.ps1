param()
$ErrorActionPreference = 'Stop'
$cityRepo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
& (Join-Path $PSScriptRoot 'project.ps1') Test
& (Join-Path $PSScriptRoot 'project.ps1') Export
$cityPin = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
$cityEditor = Join-Path $cityRepo ('.tools/godot/' + $cityPin.version + '/Godot_v' + $cityPin.version + '-stable_win64_console.exe')
$cityPack = Join-Path $cityRepo 'builds/windows/citybuilder.pck'
$cityDriver = Join-Path $cityRepo 'game/tests/packed_integration.gd'
$cityOutput = @(& $cityEditor --headless --main-pack $cityPack --script $cityDriver 2>&1)
$cityExit = $LASTEXITCODE
$cityOutput | Tee-Object -FilePath (Join-Path $cityRepo 'builds/validation/packed-integration.log')
if ($cityExit -ne 0 -or ($cityOutput -match 'SCRIPT ERROR:|^ERROR:|^FAIL:') -or -not ($cityOutput -match '"suite":"packed-integration"')) { throw 'Packed integration checks failed or did not finish.' }
$cityExportConsole = Join-Path $cityRepo 'builds/windows/citybuilder.console.exe'
$cityOutput = @(& $cityExportConsole --headless --quit-after 6 2>&1)
$cityExit = $LASTEXITCODE
$cityOutput | Tee-Object -FilePath (Join-Path $cityRepo 'builds/validation/export-startup.log')
if ($cityExit -ne 0 -or ($cityOutput -match 'SCRIPT ERROR:|^ERROR:')) { throw 'Export startup check failed.' }
Write-Output 'Automated checks passed. These do not replace manual Windows UI and graphics testing.'
