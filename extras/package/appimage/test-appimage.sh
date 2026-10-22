#!/bin/sh
# Plays VIDEO with the AppImage on a virtual 1920x1080 screen and saves the
# screen after SECONDS as OUT.png, with VLC's log as OUT.log. Fails unless
# VLC is still running then, with the Qt interface up and the video on a
# display.
#
#   test-appimage.sh APPIMAGE VIDEO OUT [SECONDS]
set -eu
app=$1 video=$2 out=$3 seconds=${4:-10}

# The extracted AppImage and VLC's settings stay in a scratch directory, so
# every run starts like a first launch.
tmp=$(mktemp -d /tmp/appimage-test.XXXXXX)
export HOME=$tmp/home TMPDIR=$tmp DISPLAY=:99
mkdir "$HOME"

Xvfb :99 -screen 0 1920x1080x24 -nolisten tcp > /dev/null 2>&1 &
xvfb=$!
vlc=
trap 'kill $vlc $xvfb 2> /dev/null || true; wait; rm -rf "$tmp"' EXIT

i=0
until xdotool getdisplaygeometry > /dev/null 2>&1; do
	i=$((i + 1))
	[ "$i" -lt 100 ] || { echo "Xvfb did not start" >&2; exit 1; }
	sleep 0.1
done

# Without --no-qt-privacy-ask the first-run wizard covers the player.
"$app" --appimage-extract-and-run -vv --aout=adummy --no-qt-privacy-ask \
	"$video" > "$out.log" 2>&1 &
vlc=$!

# There is no window manager to place the window, so it is made to fill the
# screen once it shows up.
win=$(timeout 60 xdotool search --sync --onlyvisible --class vlc 2> /dev/null | head -n 1) || true
if [ -n "$win" ]; then
	xdotool windowmove "$win" 0 0 windowsize "$win" 1920 1080
fi
sleep "$seconds"

# The player hides its controls until the pointer moves.
xdotool mousemove 900 600 sleep 0.3 mousemove 960 540 sleep 1
import -window root "$out.png"

status=0
if ! kill -0 "$vlc" 2> /dev/null; then
	echo "VLC exited early" >&2
	status=1
fi
for line in 'using interface module "qt"' 'using vout window module "qt"' 'using vout display module'; do
	if ! grep -q "$line" "$out.log"; then
		echo "missing from the log: $line" >&2
		status=1
	fi
done
[ "$status" = 0 ] || tail -n 40 "$out.log" >&2
grep -E 'using (interface|vout window|vout display|video decoder) module' "$out.log" || true
exit "$status"
