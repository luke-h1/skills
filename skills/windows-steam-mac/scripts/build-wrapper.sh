#!/bin/sh
# Builds a Sikarugir wrapper that runs the Windows Steam client on Apple Silicon,
# with a visible UI (D3DMetal) and a working microphone.
set -eu

TEMPLATE="${TEMPLATE:-Template-1.0.27}"
# Sikarugir engines 10.0_7 and later fail mic capture with -10879 (Sikarugir issue #275).
ENGINE="${ENGINE:-WS12WineSikarugir10.0_6}"
NAME="${NAME:-Steam}"
BUNDLE_ID="${BUNDLE_ID:-com.sikarugir.wrapper.steam}"

SUPPORT="$HOME/Library/Application Support/Sikarugir"
APPS="$HOME/Applications/Sikarugir"
APP="$APPS/$NAME.app"
SS="$APP/Contents/SharedSupport"
PB=/usr/libexec/PlistBuddy
BASE=https://github.com/Sikarugir-App

[ "$(uname -m)" = arm64 ] || { echo "This script is for Apple Silicon." >&2; exit 1; }
[ -e "$APP" ] && { echo "$APP exists. Remove it or set NAME=." >&2; exit 1; }
/usr/bin/pgrep -q oahd || /usr/sbin/softwareupdate --install-rosetta --agree-to-license
command -v winetricks >/dev/null || brew install winetricks
command -v ffmpeg >/dev/null || brew install ffmpeg

mkdir -p "$SUPPORT/Engines" "$SUPPORT/Template" "$APPS"
[ -f "$SUPPORT/Template/$TEMPLATE.tar.xz" ] || curl -fL -o "$SUPPORT/Template/$TEMPLATE.tar.xz" "$BASE/Template/releases/download/v1.0/$TEMPLATE.tar.xz"
[ -f "$SUPPORT/Engines/$ENGINE.tar.xz" ] || curl -fL -o "$SUPPORT/Engines/$ENGINE.tar.xz" "$BASE/Engines/releases/download/v1.0/$ENGINE.tar.xz"

T=$(mktemp -d)
tar -xJf "$SUPPORT/Template/$TEMPLATE.tar.xz" -C "$T"
tar -xJf "$SUPPORT/Engines/$ENGINE.tar.xz" -C "$T"
mv "$T/$TEMPLATE.app" "$APP"
rm -rf "$SS/wine"
mv "$T/wswine.bundle" "$SS/wine"
rm -rf "$T"
# The launcher looks for winetricks only in the engine bin folder.
cp -L "$(command -v winetricks)" "$SS/wine/bin/winetricks"
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

"$APP/Contents/MacOS/wineskinlauncher" WSS-wineprefixcreate
"$APP/Contents/MacOS/wineskinlauncher" WSS-winetricks steam
[ -f "$SS/prefix/drive_c/Program Files (x86)/Steam/steam.exe" ] || { echo "Steam install failed. Read $SS/Logs/Winetricks.log" >&2; exit 1; }

PL="$APP/Contents/Info.plist"
$PB -c 'Set :"Program Name and Path" "/Program Files (x86)/Steam/steam.exe"' "$PL"
# The Steam UI is black with software CEF flags or DXMT. D3DMetal draws it.
$PB -c 'Set :"Program Flags" ""' -c 'Set :D3DMETAL 1' "$PL"
$PB -c "Set :CFBundleIdentifier $BUNDLE_ID" -c "Set :CFBundleName $NAME (Windows)" "$PL"
# codesign rejects a symlink as the main executable. "launcher" is a symlink to "Sikarugir".
$PB -c 'Set :CFBundleExecutable Sikarugir' "$PL"
# macOS does not show a privacy prompt for a background-only app.
$PB -c 'Delete :NSBGOnly' "$PL" 2>/dev/null || true

# Wine sends only preflight TCC checks, so macOS never shows the mic prompt.
# One real AVFoundation capture from the wrapper context triggers the prompt.
cat >> "$APP/Contents/Resources/Scripts/StartupScript" <<'EOF'
micStatus=$(/usr/bin/osascript -l JavaScript -e 'ObjC.import("AVFoundation"); $.NSClassFromString("AVCaptureDevice").authorizationStatusForMediaType("soun")' 2>/dev/null)
if [ "$micStatus" = "0" ]; then
	/opt/homebrew/bin/ffmpeg -nostdin -hide_banner -loglevel error -f avfoundation -i ":default" -t 1 -f null - >/dev/null 2>&1
fi
EOF

codesign --force --deep --sign - --identifier "$BUNDLE_ID" "$APP"
tccutil reset Microphone "$BUNDLE_ID" >/dev/null 2>&1 || true
open "$APP"
echo "Built $APP. Allow the microphone prompt, then log in to Steam."
