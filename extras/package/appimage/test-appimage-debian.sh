#!/bin/sh
# Runs inside a clean Debian or Ubuntu container: installs Xvfb, the test
# tools and the desktop libraries the AppImage takes from the host, then runs
# the test as an unprivileged user.
#
#   test-appimage-debian.sh NAME [APPIMAGE [VIDEO]]
#
# Expects test-appimage.sh next to this script, the AppImage in /work and the
# video in /media unless given, and writes /out/NAME.png and /out/NAME.log.
set -e
name=$1
app=${2:-/work/VLC_Redesign-1.0.0-$(uname -m).AppImage}
video=${3:-/media/The_Wand_S01E01.mp4}
tools=$(dirname "$(readlink -f "$0")")

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
pkgs=
for p in xvfb xdotool imagemagick procps util-linux \
	libgl1 libegl1 libopengl0 libgbm1 libgl1-mesa-dri libdrm2 \
	libx11-6 libx11-xcb1 libxcb1 libxcb-dri3-0 libice6 libsm6 \
	libwayland-client0 libglib2.0-0 \
	libfontconfig1 libfreetype6 libharfbuzz0b libfribidi0 fonts-dejavu-core \
	libasound2 libpipewire-0.3-0 libjack-jackd2-0 \
	libusb-1.0-0 libgmp10 libgpg-error0 libcom-err2 zlib1g libstdc++6
do
	# Ubuntu 24.04 and Debian 13 renamed some libraries for 64-bit time_t.
	if apt-cache show "${p}t64" > /dev/null 2>&1; then p=${p}t64; fi
	pkgs="$pkgs $p"
done
apt-get install -y -qq --no-install-recommends $pkgs > /dev/null
ldd --version | head -n 1
useradd -m tester
chown tester /out
runuser -u tester -- "$tools/test-appimage.sh" "$app" "$video" "/out/$name" 10
