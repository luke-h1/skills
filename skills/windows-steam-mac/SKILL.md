---
name: windows-steam-mac
description: Run the Windows Steam client and Windows-only Steam games on an Apple Silicon Mac with Sikarugir (Wine), with a visible Steam UI and a working microphone. Use when the user wants a free CrossOver alternative for Steam, wants to play a Windows-only game such as SCP Secret Laboratory on a Mac, or reports a black Steam window, a steamwebhelper crash loop, a CrossOver bottle error in Heroic, or a microphone that does not work in Wine (NotReadableError, mic not in the macOS privacy list).
---

# Windows Steam on Apple Silicon

This skill builds a Sikarugir wrapper that runs the Windows Steam client.
The wrapper shows the Steam UI and gives microphone input to games.

## Procedure

1. Make sure that Homebrew is on the Mac.
2. Install Sikarugir Creator. This step is optional, because the script does not use it.
   ```sh
   brew trust Sikarugir-App/sikarugir
   brew install --cask Sikarugir-App/sikarugir/sikarugir
   ```
3. Run the build script:
   ```sh
   sh scripts/build-wrapper.sh
   ```
4. When macOS asks for microphone access for "Steam (Windows)", click Allow.
5. Log in to Steam. Install the game in this Steam.
6. Start the wrapper with `open ~/Applications/Sikarugir/Steam.app`.

The script uses these environment variables: `NAME`, `BUNDLE_ID`, `ENGINE`, `TEMPLATE`.
The first start of Steam downloads an update. This takes approximately 4 minutes.
The first start of a game can run a .NET installer. This installer is slow in Wine.

## Hard rules

- Use engine `WS12WineSikarugir10.0_6` for the microphone. Engines 10.0_7 and later cannot open audio input. Refer to Sikarugir issue #275.
- Set `D3DMETAL` to 1 and keep `Program Flags` empty. The `-cef-disable-gpu` flags and DXMT give a black Steam window.
- Do not use Wine-Crossover 23.7 for Steam. Its Wine 8 base makes `steamwebhelper` crash in a loop.
- Do not sign the wrapper again after the user allows the microphone. A new ad-hoc signature can cancel the permission.
- Do not run `.app` bundles as commands. Use `open`.
- Do not use `nohup` or other system binaries to start Wine. macOS removes `DYLD_*` variables from system binaries, and Wine cannot find its libraries.

## Diagnosis

| Symptom | Cause | Fix |
|---|---|---|
| Heroic: `The CrossOver bottle "" does not exist` | Heroic found a CrossOver trial and selected it | Set the Heroic Wine version to a downloaded build, or use this wrapper |
| `steamwebhelper` restarts many times each second | Wine version is too old | Use a Wine 10 or 11 engine |
| Steam window is black | CEF draws through DXVK, DXMT, or software output | Set `D3DMETAL` to 1 and remove the CEF flags |
| Steam log shows `NotReadableError` | macOS denies the mic, or the engine bug | Do the two checks below |
| Wrapper is not in the macOS Microphone list | The bundle seal is broken, because the prefix is in the bundle | No fix is necessary. The permission still applies |

## Microphone checks

1. Read the macOS decisions for the wrapper:
   ```sh
   log show --last 10m --predicate 'process == "tccd" AND eventMessage CONTAINS "kTCCServiceMicrophone"'
   ```
   `AUTHREQ_ATTRIBUTION` gives the responsible app. `AUTHREQ_RESULT` with `authValue=2` means allowed, and `authValue=1` means not decided.
2. If all the requests have `preflight=yes` and `authValue=1`, the prompt did not occur. Reset the permission and start the wrapper again:
   ```sh
   tccutil reset Microphone com.sikarugir.wrapper.steam
   open ~/Applications/Sikarugir/Steam.app
   ```
3. If macOS allows the mic and Steam still shows `NotReadableError`, read the Wine log. Set `WINEDEBUG` to `+coreaudio,+mmdevapi` and `Debug Mode` to 1 in `Contents/Info.plist`. Then read `Contents/SharedSupport/Logs/LastRunWine.log`.
4. If the log shows `Couldn't enable I/O on input element: ffffd581`, the engine has the bug. Replace `Contents/SharedSupport/wine` with the `wswine.bundle` folder from `WS12WineSikarugir10.0_6.tar.xz`. Copy `winetricks` into the new `wine/bin` folder.

## Wrapper layout

- `Contents/Info.plist` keeps the wrapper settings: `Program Name and Path`, `Program Flags`, `D3DMETAL`, `WINEDEBUG`, `Debug Mode`.
- `Contents/SharedSupport/wine` is the engine. `Contents/SharedSupport/prefix` is the Wine prefix.
- `Contents/Resources/Scripts/StartupScript` runs before Wine. macOS gives its child processes the identity of the wrapper.
- `Contents/MacOS/wineskinlauncher` accepts commands: `WSS-wineprefixcreate`, `WSS-winetricks <verb>`, `WSS-winecfg`, `WSS-wineserverkill`.

## Removal

To remove this setup, use the `windows-steam-mac-uninstall` skill.

## Limits

- Games with kernel anti-cheat do not start in Wine.
- Online servers can refuse a Wine client.
- If the wrapper cannot give a mic to a game, use a Windows 11 ARM virtual machine in VMware Fusion.
