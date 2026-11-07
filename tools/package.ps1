param()
$ErrorActionPreference = 'Stop'
$cityRepo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$cityExport = Join-Path $cityRepo 'builds/windows'
$cityBuild = Get-Content -LiteralPath (Join-Path $cityExport 'BUILD.json') -Raw | ConvertFrom-Json
$cityExpected = @('ASSETS.md','citybuilder.console.exe','citybuilder.exe','citybuilder.pck','GODOT_COPYRIGHT.txt','GODOT_LICENSE.txt','PLAYTEST.txt','README.txt')
if (@(Compare-Object $cityExpected @($cityBuild.files.file)).Count -ne 0) { throw 'Unexpected files in build manifest. Review before packaging.' }
$cityPaths = @()
foreach ($cityFile in $cityBuild.files) {
    $cityPath = Join-Path $cityExport $cityFile.file
    if ((Get-FileHash -LiteralPath $cityPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $cityFile.sha256) { throw "Build hash mismatch: $($cityFile.file)" }
    $cityPaths += $cityPath
}
$cityPaths += Join-Path $cityExport 'BUILD.json'
$cityArchive = Join-Path $cityRepo ('builds/citybuilder-' + $cityBuild.game_version + '-windows-x64.zip')
Compress-Archive -LiteralPath $cityPaths -DestinationPath $cityArchive -CompressionLevel Optimal -Force
$cityDigest = (Get-FileHash -LiteralPath $cityArchive -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath ($cityArchive + '.sha256') -Value ($cityDigest + '  ' + [IO.Path]::GetFileName($cityArchive)) -Encoding ascii
Write-Output "Packaged existing build: $cityArchive"
Write-Output "SHA256: $cityDigest"
