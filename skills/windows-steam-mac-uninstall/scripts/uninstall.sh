#!/bin/sh
# Removes the setup that windows-steam-mac/scripts/build-wrapper.sh made.
# Usage: uninstall.sh [--downloads] [--creator] [--heroic] [--yes]
set -eu

NAME="${NAME:-Steam}"
BUNDLE_ID="${BUNDLE_ID:-com.sikarugir.wrapper.steam}"
APPS="$HOME/Applications/Sikarugir"
APP="$APPS/$NAME.app"
SUPPORT="$HOME/Library/Application Support/Sikarugir"
HEROIC="$HOME/Library/Application Support/heroic"

downloads=0 creator=0 heroic=0 yes=0
for a in "$@"; do
	case "$a" in
		--downloads) downloads=1 ;;
		--creator) creator=1 ;;
		--heroic) heroic=1 ;;
		--all) downloads=1 creator=1 heroic=1 ;;
		--yes) yes=1 ;;
		*) echo "Unknown option: $a" >&2; exit 2 ;;
	esac
done

targets=""
add() { [ -e "$1" ] || [ -L "$1" ] && targets="$targets
$1"; return 0; }

add "$APP"
add "$HOME/.cache/winetricks/steam"
if [ "$downloads" = 1 ]; then
	add "$SUPPORT"
	add "$HOME/.cache/winetricks/corefonts"
fi
if [ "$heroic" = 1 ]; then
	add "$HOME/Games/Heroic/Prefixes/Steam"
	add "$HOME/Games/Heroic/SteamSetup.exe"
	for w in "$HEROIC/tools/wine/"Wine-*; do add "$w"; done
fi

echo "This will remove:"
[ -n "$targets" ] && printf '%s\n' "$targets" | sed '/^$/d; s/^/  /' || echo "  (no files)"
echo "  microphone permission for $BUNDLE_ID"
[ "$creator" = 1 ] && echo "  Homebrew cask: sikarugir"
echo
echo "WARNING: The wrapper contains the Steam install, the games, and local game saves."
if [ "$yes" != 1 ]; then
	printf 'Type "remove" to continue: '
	read -r answer
	[ "$answer" = remove ] || { echo "Stopped. Nothing was removed."; exit 1; }
fi

osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
[ -x "$APP/Contents/SharedSupport/wine/bin/wineserver" ] && "$APP/Contents/SharedSupport/wine/bin/wineserver" -k 2>/dev/null || true
sleep 2

printf '%s\n' "$targets" | sed '/^$/d' | while IFS= read -r p; do
	rm -rf "$p"
	echo "removed $p"
done
rmdir "$APPS" 2>/dev/null || true

tccutil reset Microphone "$BUNDLE_ID" >/dev/null 2>&1 || true
echo "reset microphone permission for $BUNDLE_ID"

if [ "$creator" = 1 ]; then
	brew uninstall --cask sikarugir || true
fi
echo "Done."
