param([ValidateSet('Import','Test','Run','Export')][string]$Action = 'Test')
$ErrorActionPreference = 'Stop'
$cityRepo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$cityPin = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
$cityExe = Join-Path $cityRepo ('.tools/godot/' + $cityPin.version + '/Godot_v' + $cityPin.version + '-stable_win64_console.exe')
if (-not (Test-Path -LiteralPath $cityExe)) { throw 'Run tools/setup.ps1 first.' }
if ((& $cityExe --version | Out-String).Trim() -ne $cityPin.version_output) { throw 'Editor version does not match toolchain pin.' }
$cityGame = Join-Path $cityRepo 'game'
$cityValidation = Join-Path $cityRepo 'builds/validation'
New-Item -ItemType Directory -Force -Path $cityValidation | Out-Null
function Invoke-CityCheck([string[]]$CityArguments, [string]$LogName) {
    # Local 'Continue': Windows PowerShell 5.1 otherwise aborts on the first stderr line.
    $ErrorActionPreference = 'Continue'
    $cityOutput = @(& $cityExe @CityArguments 2>&1 | ForEach-Object { "$_" })
    $cityExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    # Explicit UTF-8 logs: Windows PowerShell 5.1 Tee-Object would write UTF-16.
    Set-Content -LiteralPath (Join-Path $cityValidation $LogName) -Value $cityOutput -Encoding utf8
    $cityOutput
    if ($cityExit -ne 0 -or ($cityOutput -match 'SCRIPT ERROR:|^ERROR:')) { throw "Godot check failed: $LogName (exit $cityExit)" }
}
if ($Action -eq 'Run') {
    & $cityExe --path $cityGame
    exit $LASTEXITCODE
}
Invoke-CityCheck @('--headless','--path',$cityGame,'--import') 'import.log'
if ($Action -eq 'Test') {
    $cityPriorTestDir = $env:CITY_TEST_DIR
    try {
        $env:CITY_TEST_DIR = Join-Path $cityValidation 'headless'
        Invoke-CityCheck @('--headless','--path',$cityGame,'--script','res://tests/run_tests.gd') 'tests.log'
    } finally { $env:CITY_TEST_DIR = $cityPriorTestDir }
}
if ($Action -eq 'Export') {
    $cityExport = Join-Path $cityRepo 'builds/windows'
    New-Item -ItemType Directory -Force -Path $cityExport | Out-Null
    Invoke-CityCheck @('--headless','--path',$cityGame,'--export-release','Windows Desktop',(Join-Path $cityExport 'citybuilder.exe')) 'export.log'
    Copy-Item -LiteralPath (Join-Path $cityRepo 'licenses/GODOT_LICENSE.txt'),(Join-Path $cityRepo 'licenses/GODOT_COPYRIGHT.txt'),(Join-Path $cityRepo 'licenses/ASSETS.md') -Destination $cityExport
    Copy-Item -LiteralPath (Join-Path $cityRepo 'docs/BUILD_README.txt') -Destination (Join-Path $cityExport 'README.txt')
    $cityDistributionFiles = @('ASSETS.md','citybuilder.console.exe','citybuilder.exe','citybuilder.pck','GODOT_COPYRIGHT.txt','GODOT_LICENSE.txt','README.txt')
    $cityRecords = @($cityDistributionFiles | ForEach-Object { Get-Item -LiteralPath (Join-Path $cityExport $_) } | ForEach-Object {
        [ordered]@{ file = $_.Name; bytes = $_.Length; sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
    })
    # Read version identifiers from source so the manifest cannot drift from the build.
    $cityVersion = [regex]::Match((Get-Content -LiteralPath (Join-Path $cityGame 'project.godot') -Raw), 'config/version="([^"]+)"').Groups[1].Value
    $citySchema = [int][regex]::Match((Get-Content -LiteralPath (Join-Path $cityGame 'scripts/sim/city_state.gd') -Raw), 'const SCHEMA: int = (\d+)').Groups[1].Value
    if (-not $cityVersion -or $citySchema -lt 1) { throw 'Could not read game version or save schema from source.' }
    $cityManifest = [ordered]@{ game_version = $cityVersion; engine = $cityPin.version_output; schema = $citySchema; files = $cityRecords } | ConvertTo-Json -Depth 4
    # BOM-free UTF-8 under both Windows PowerShell 5.1 and PowerShell 7.
    [IO.File]::WriteAllText((Join-Path $cityExport 'BUILD.json'), $cityManifest, (New-Object Text.UTF8Encoding $false))
    Write-Output "Exported to $cityExport"
}
