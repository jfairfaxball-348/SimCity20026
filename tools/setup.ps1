param()
$ErrorActionPreference = 'Stop'
$cityRepo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$cityPin = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
$cityDownloads = Join-Path $cityRepo '.tools/downloads'
$cityTools = Join-Path $cityRepo ('.tools/godot/' + $cityPin.version)
New-Item -ItemType Directory -Force -Path $cityDownloads,$cityTools | Out-Null
foreach ($cityKind in @('editor','templates')) {
    $cityName = $cityPin.$cityKind
    $cityExpected = $cityPin.($cityKind + '_sha512')
    $cityArchive = Join-Path $cityDownloads $cityName
    if (-not (Test-Path -LiteralPath $cityArchive)) {
        & curl.exe --fail --location --silent --show-error --retry 2 --output $cityArchive ($cityPin.release_url + '/' + $cityName)
        if ($LASTEXITCODE -ne 0) { throw "Download failed for $cityName. Remove only the incomplete archive before retrying." }
    }
    if ((Get-FileHash -LiteralPath $cityArchive -Algorithm SHA512).Hash.ToLowerInvariant() -ne $cityExpected) {
        throw "Checksum mismatch for $cityName. The archive was not executed/extracted."
    }
    if ($cityKind -eq 'editor') {
        Expand-Archive -LiteralPath $cityArchive -DestinationPath $cityTools -Force
    } else {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $cityTemplates = Join-Path $cityTools 'templates'
        New-Item -ItemType Directory -Force -Path $cityTemplates | Out-Null
        $cityZip = [System.IO.Compression.ZipFile]::OpenRead($cityArchive)
        try {
            foreach ($cityEntry in $cityZip.Entries) {
                if ($cityEntry.Name -in @('windows_debug_x86_64.exe','windows_release_x86_64.exe','windows_debug_x86_64_console.exe','windows_release_x86_64_console.exe','version.txt')) {
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($cityEntry, (Join-Path $cityTemplates $cityEntry.Name), $true)
                }
            }
        } finally { $cityZip.Dispose() }
        if ((Get-Content -LiteralPath (Join-Path $cityTemplates 'version.txt') -Raw).Trim() -ne ($cityPin.version + '.stable')) {
            throw 'Unexpected template version'
        }
    }
}
$cityExe = Join-Path $cityTools ('Godot_v' + $cityPin.version + '-stable_win64_console.exe')
$cityActualVersion = (& $cityExe --version | Out-String).Trim()
if ($cityActualVersion -ne $cityPin.version_output) { throw 'Unexpected editor version' }
Write-Output "Verified and installed locally: $cityActualVersion"
