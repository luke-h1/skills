---
name: windows-steam-mac-uninstall
description: Remove the Windows Steam on Mac setup that the windows-steam-mac skill made - the Sikarugir Steam wrapper, its games and saves, the microphone permission, and optionally the Sikarugir downloads, Sikarugir Creator, and the Heroic Steam leftovers. Use when the user wants to uninstall, remove, clean up, or start again with Windows Steam, Sikarugir, or the Steam wrapper on their Mac.
---

# Uninstall Windows Steam on Mac

This skill removes the setup from the `windows-steam-mac` skill.

## Procedure

1. Tell the user that the wrapper contains Steam, all the installed games, and local game saves. Steam Cloud keeps only the cloud saves.
2. Ask the user which optional parts to remove. Refer to the options table.
3. Run the script without `--yes`. The script shows the list of items and asks for the word "remove".
   ```sh
   sh scripts/uninstall.sh [options]
   ```
4. Use `--yes` only if the user approved the list in this conversation.

## Options

| Option | Removes |
|---|---|
| (none) | The wrapper `~/Applications/Sikarugir/Steam.app`, the winetricks Steam cache, and the microphone permission |
| `--downloads` | The Sikarugir engines and templates in `~/Library/Application Support/Sikarugir`, and the winetricks font cache |
| `--creator` | The `sikarugir` Homebrew cask (Sikarugir Creator) |
| `--heroic` | The Heroic Steam prefix, `SteamSetup.exe`, and the Wine builds in the Heroic tools folder |
| `--all` | All of the items above |

The script uses the `NAME` and `BUNDLE_ID` environment variables, with the same values as the build script.

## Hard rules

- Do not remove `winetricks`, `ffmpeg`, or Rosetta 2. Other software can use them.
- Do not remove the Heroic app or the other Heroic games. After `--heroic`, tell the user to remove the Steam tile in Heroic.
- Do not remove other wrappers in `~/Applications/Sikarugir`. The script removes that folder only when it is empty.
- If the user has a CrossOver trial in `~/Downloads`, tell the user about it. Do not remove it.

## Check

1. Make sure that `~/Applications/Sikarugir/Steam.app` does not exist.
2. Make sure that no Wine process runs: `pgrep -lf 'steam.exe|wineserver'`.
