# DXHR-HD-Enhancement

An installation helper and research workspace for improving the visuals of the Steam edition of **Deus Ex: Human Revolution - Director's Cut** while keeping the Simplified Chinese localization working.

## Scope

The current package is a community AI-upscaled texture pack. It replaces only a subset of low-resolution textures; it is not a full model remaster. Because the archive contains packed `.000` resources without a scene manifest, a particular location such as the police station may show little or no visible change.

The project intentionally does not modify the game's `BIGFILE.*` archives or replace the working ModHook DLL. The Chinese localization remains in `mods\zh-cn.000`, while the texture package is installed as `mods\ai_upscale.000` through `ai_upscale.005`.

## Installation

1. Install the Steam Director's Cut normally.
2. The repository includes `ChinesePatch\DEHRCNv1.1.exe`, the original [Simplified Chinese patch](https://steamcommunity.com/groups/tianmiao/discussions/0/1471967615878483558/). The main installer can launch it for you with `-InstallChinesePatch`.
3. Download this repository as a ZIP and open PowerShell in its folder.
4. Run this command, replacing the path with the friend's Steam library path:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Install-DXHRHD.ps1 -GameDirectory "D:\SteamLibrary\steamapps\common\Deus Ex Human Revolution Director's Cut" -InstallChinesePatch -DownloadPackage
```

The script downloads the 2.01 GB texture archive from ModDB, verifies its size and MD5, creates one backup, installs the HD texture files, and preserves the Chinese patch and `DFEngine.dll`. Add `-LaunchGame` to start the game after installation.

If the archive was downloaded manually, place `DXHR_AI_Upscale_v1.2.7z` beside the script and omit `-DownloadPackage`. If the Chinese patch was already installed, omit `-InstallChinesePatch`.

## Manual installation

The helper also works with a local package:

```powershell
powershell -ExecutionPolicy Bypass -File .\Install-DXHRHD.ps1 -GameDirectory "D:\SteamLibrary\steamapps\common\Deus Ex Human Revolution Director's Cut"
```

The script validates the game executable and package, backs up the current `mods` directory once, extracts the package, and merges only its `mods` contents. Windows `tar.exe` is supported; 7-Zip is optional.

## Source package

- Filename: `DXHR_AI_Upscale_v1.2.7z`
- Expected size: `2162779864` bytes
- Expected MD5: `7136ec5db744b7d44a4ceaa23c6378df`
- The archive is intentionally ignored by Git and must be obtained from the original distribution page.

## Current limitations

- This is texture enhancement, not a higher-polygon model overhaul.
- The AI pack is partial, so improvements vary by scene.
- The game itself must be launched to verify visual changes; the installer performs structural and checksum validation only.
