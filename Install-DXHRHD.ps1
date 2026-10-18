[CmdletBinding()]
param(
    [string]$GameDirectory = '',
    [string]$PackagePath = '',
    [switch]$DownloadPackage,
    [switch]$AllowWithoutChinesePatch,
    [switch]$LaunchGame
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$expectedLength = 2162779864
$expectedMd5 = '7136ec5db744b7d44a4ceaa23c6378df'
$packageUrl = 'https://www.moddb.com/downloads/start/245859'
$archiveTool = Get-Command 7z.exe -ErrorAction SilentlyContinue
$tarTool = Get-Command tar.exe -ErrorAction SilentlyContinue
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($GameDirectory)) {
    $GameDirectory = Read-Host 'Enter the Deus Ex Human Revolution Director''s Cut folder path'
}
if ([string]::IsNullOrWhiteSpace($PackagePath)) {
    $PackagePath = Join-Path $scriptDirectory 'DXHR_AI_Upscale_v1.2.7z'
}

if (-not (Test-Path -LiteralPath $GameDirectory -PathType Container)) {
    throw "Game directory was not found: $GameDirectory"
}
if (-not (Test-Path -LiteralPath $PackagePath -PathType Leaf) -and $DownloadPackage) {
    Write-Output 'Downloading the texture package from ModDB...'
    Invoke-WebRequest -Uri $packageUrl -OutFile $PackagePath -MaximumRedirection 10
}
if (-not (Test-Path -LiteralPath $PackagePath -PathType Leaf)) {
    throw "Texture package was not found: $PackagePath. Download it from $packageUrl or rerun with -DownloadPackage."
}
if (-not $archiveTool -and -not $tarTool) {
    throw 'Neither 7z.exe nor tar.exe was found.'
}

$package = Get-Item -LiteralPath $PackagePath
if ($package.Length -ne $expectedLength) {
    throw "Unexpected package size: $($package.Length)"
}
$hashCommand = Get-Command Get-FileHash -ErrorAction SilentlyContinue
if ($hashCommand) {
    $hash = (Get-FileHash -LiteralPath $PackagePath -Algorithm MD5).Hash.ToLowerInvariant()
} else {
    $hash = ((certutil.exe -hashfile $PackagePath MD5 | Select-Object -Skip 1 | Select-Object -First 1) -replace '\s', '').ToLowerInvariant()
}
if ($hash -ne $expectedMd5) {
    throw "Unexpected package MD5: $hash"
}

$modsDirectory = Join-Path $GameDirectory 'mods'
$gameExecutable = Join-Path $GameDirectory 'DXHRDC.exe'
$chinesePackage = Join-Path $modsDirectory 'zh-cn.000'
$backupDirectory = Join-Path $GameDirectory 'Backup\DXHR-HD-Enhancement'
$stagingDirectory = Join-Path $env:TEMP 'DXHR-HD-Enhancement-Staging'

New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
if (-not (Test-Path -LiteralPath $gameExecutable -PathType Leaf)) {
    throw "DXHRDC.exe was not found in: $GameDirectory"
}
if (-not (Test-Path -LiteralPath $chinesePackage -PathType Leaf) -and -not $AllowWithoutChinesePatch) {
    throw "Chinese patch was not detected at $chinesePackage. Install the Chinese patch first, or rerun with -AllowWithoutChinesePatch."
}
if ((Test-Path -LiteralPath $modsDirectory) -and -not (Test-Path -LiteralPath (Join-Path $backupDirectory 'mods-before-hd'))) {
    Copy-Item -LiteralPath $modsDirectory -Destination (Join-Path $backupDirectory 'mods-before-hd') -Recurse -Force
}
if (Test-Path -LiteralPath $stagingDirectory) {
    Remove-Item -LiteralPath $stagingDirectory -Recurse -Force
}
New-Item -ItemType Directory -Path $stagingDirectory -Force | Out-Null

if ($archiveTool) {
    & $archiveTool.Source x $PackagePath "-o$stagingDirectory" -y | Out-Host
} else {
    & $tarTool.Source -xf $PackagePath -C $stagingDirectory | Out-Host
}
if ($LASTEXITCODE -ne 0) {
    throw "Archive extraction failed with exit code $LASTEXITCODE"
}

$stagedMods = Get-ChildItem -LiteralPath $stagingDirectory -Directory -Recurse | Where-Object Name -eq 'mods' | Select-Object -First 1
if (-not $stagedMods) {
    throw 'The package did not contain a mods directory.'
}
New-Item -ItemType Directory -Path $modsDirectory -Force | Out-Null
Get-ChildItem -LiteralPath $stagedMods.FullName -Force | Where-Object Name -ne 'zh-cn.000' | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $modsDirectory -Recurse -Force
}

$preservedDll = Join-Path $GameDirectory 'DFEngine.dll'
if (Test-Path -LiteralPath $preservedDll -PathType Leaf) {
    $version = (Get-Item -LiteralPath $preservedDll).VersionInfo.FileVersion
    if ($version -ne '1.1.0.0') {
        Write-Warning "DFEngine.dll is $version; expected 1.1.0.0. No DLL was changed."
    }
}
Remove-Item -LiteralPath $stagingDirectory -Recurse -Force
Write-Output 'HD textures installed. Existing Chinese files and DFEngine.dll were preserved.'
if ($LaunchGame) {
    Start-Process -FilePath $gameExecutable -WorkingDirectory $GameDirectory
}
