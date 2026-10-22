#!/bin/bash
# Builds the AppImage of VLC with the Qt interface for the machine it runs on,
# x86_64 or aarch64, in an Ubuntu 22.04 container, so that it runs wherever
# glibc is 2.35 or newer (Ubuntu 22.04, Debian 12 and everything after them).
#
#   build-appimage-compat.sh [SOURCE | --prepare]
#
# The x86_64 image is built on the Unraid host, the aarch64 one by the
# appimage-arm64 workflow on GitHub's arm64 runners. SOURCE, if given,
# updates the source first:
#   FILE.bundle  a git bundle, e.g. "git bundle create x.bundle 429df92..main";
#                its first branch is checked out
#   REV          a commit the clone already has
# Without SOURCE the current checkout is built again. Only changed files are
# rebuilt, and the packages, Qt and the libraries built from source are
# reused from the previous run. --prepare stops once those are in place, so
# CI can cache them before the long VLC build.
#
# Environment:
#   CPUS, MEMORY  container limits (default 4 and 4g)
#   JOBS          parallel compile jobs (default CPUS)
#   VERSION       AppImage version (default 1.0.0)
#   DATA          where everything is kept (see below)
#
# Everything is kept in $DATA, which the container sees as /build:
#   vlc/       the source clone; build/ and AppDir/ sit next to it
#   deps/      libraries 22.04 has in a version too old for VLC 4
#   qt/        Qt: the official binaries on x86_64, which need glibc 2.28;
#              on aarch64 they need 2.38, so Qt is built from source there
#   kit/       linuxdeploy, its Qt plugin, appimagetool and the runtime
#   out/       the AppImage
#
# Ubuntu 22.04 has every other library VLC needs in a new enough version.
# They are bundled, so the AppImage only takes glibc, the graphics stack,
# fonts, audio servers and the other libraries of linuxdeploy's exclude list
# from the host. All of these keep their ABI, and the host's are at least as
# new as 22.04's. The compiler is 22.04's own GCC 11 and the newest C++
# runtime it asks for is the GCC 12 libstdc++ that 22.04 and Debian 12 ship,
# so none is bundled.
set -euo pipefail

CONTAINER=vlc-appimage-build
DATA=${DATA:-/mnt/user/appdata/vlc-appimage-build}
CPUS=${CPUS:-4}
MEMORY=${MEMORY:-4g}
JOBS=${JOBS:-$CPUS}
VERSION=${VERSION:-1.0.0}

QT_VERSION=6.8.3
MAX_GLIBC=2.35
MAX_GLIBCXX=3.4.30

# The container runs natively, so the host's architecture is the image's.
arch=$(uname -m)
case $arch in
	x86_64) qt_arch=gcc_64 ;;
	aarch64) qt_arch=gcc_arm64 ;;
	*) echo "no AppImage build for $arch" >&2; exit 1 ;;
esac

step() { printf '\n== %s\n' "$*"; }

# On the host: start the container, run this script in it, stop it again.
host_main() {
	local arg=${1:-}

	# A bundle outside $DATA is copied in, so the container can read it.
	if [ -f "$arg" ]; then
		arg=$(realpath "$arg")
		case $arg in
			"$DATA"/*) ;;
			*) mkdir -p "$DATA/incoming"; cp "$arg" "$DATA/incoming/"; arg=$DATA/incoming/$(basename "$arg") ;;
		esac
		arg=/build/${arg#"$DATA"/}
	fi

	mkdir -p "$DATA"
	if ! docker inspect "$CONTAINER" > /dev/null 2>&1; then
		docker run -d --init --name "$CONTAINER" \
			--cpus "$CPUS" --memory "$MEMORY" --memory-swap "$MEMORY" \
			-v "$DATA:/build" -w /build \
			ubuntu:22.04 sleep infinity > /dev/null
	else
		docker update --cpus "$CPUS" --memory "$MEMORY" --memory-swap "$MEMORY" "$CONTAINER" > /dev/null
		docker start "$CONTAINER" > /dev/null
	fi
	trap 'docker stop "$CONTAINER" > /dev/null' EXIT

	docker cp "$0" "$CONTAINER:/usr/local/bin/build-appimage-compat.sh"
	docker exec -e JOBS="$JOBS" -e VERSION="$VERSION" "$CONTAINER" \
		/usr/local/bin/build-appimage-compat.sh --inside "$arg"
}

# Everything below runs in the container.
B=/build
src=$B/vlc
build=$B/build
appdir=$B/AppDir
deps=$B/deps
kit=$B/kit
venv=$B/venv
qtdir=$B/qt/$QT_VERSION/$qt_arch
image=$B/out/VLC_Redesign-$VERSION-$arch.AppImage

export CCACHE_DIR=$B/ccache
export PATH=$venv/bin:$qtdir/bin:$deps/bin:$PATH
export PKG_CONFIG_PATH=$deps/lib/pkgconfig:$deps/share/pkgconfig:$qtdir/lib/pkgconfig

# Packages that "apt-get build-dep vlc" does not pull in on 22.04, or that
# VLC 4 uses beyond VLC 3.
extra_packages=(
	git curl ca-certificates file ccache python3-venv ninja-build cmake
	spirv-tools libegl-dev libgl-dev libgles-dev libvulkan-dev libgbm-dev
	libdrm-dev libwayland-dev libxkbcommon-x11-dev libxcb-composite0-dev
	libxcb-cursor-dev libxcb-damage0-dev libxcb-icccm4-dev libxcb-image0-dev
	libxcb-keysyms1-dev libxcb-randr0-dev libxcb-render-util0-dev
	libxcb-shape0-dev libxcb-sync-dev libxcb-util-dev libxcb-xfixes0-dev
	libxcb-xinerama0-dev libxcb-xkb-dev libxcursor-dev libxi-dev
	libxinerama-dev libxpm-dev libxrandr-dev libxres-dev libxss-dev
	libxtst-dev libsqlite3-dev libxxhash-dev libzstd-dev liblz4-dev
	libjpeg-dev libpng-dev libtag1-dev libunibreak-dev libutf8proc-dev
	liblua5.4-dev lua5.4 libjack-jackd2-dev libsrt-gnutls-dev libsecret-1-dev
	libnotify-dev libgtk-3-dev librsvg2-dev libsystemd-dev libseccomp-dev
	libplacebo-dev libdav1d-dev libass-dev libebur128-dev libopenmpt-dev
	libgme-dev libsidplay2-dev libsoxr-dev libchromaprint-dev
	libaribb24-dev libspatialaudio-dev libmysofa-dev libfluidsynth-dev
	libsmbclient-dev libnfs-dev libssh2-1-dev libmtp-dev
	libvncserver-dev libprotobuf-dev protobuf-compiler libsdl2-dev
	libavcodec-dev libavformat-dev libavutil-dev libswscale-dev
	libswresample-dev libpostproc-dev libva-dev libvdpau-dev
	libvpx-dev libaom-dev libx264-dev libx265-dev
	libmatroska-dev libebml-dev
)

# What building Qt needs on top of that, for the features of the official
# binaries the AppImage uses.
qt_build_packages=(
	libfontconfig1-dev libfreetype-dev libx11-xcb-dev libxkbcommon-dev
	libxcb-glx0-dev libxcb-xinput-dev libxrender-dev libxext-dev libsm-dev
	libice-dev libdbus-1-dev libglib2.0-dev libssl-dev libicu-dev libpcre2-dev
)

install_packages() {
	local stamp=/var/lib/vlc-appimage-packages sum
	local packages=("${extra_packages[@]}")
	if [ "$arch" = aarch64 ]; then
		packages+=("${qt_build_packages[@]}")
	fi
	# A change to the list or to this function installs again.
	sum=$({ declare -f install_packages; printf '%s\n' "${packages[@]}"; } | sha256sum)
	[ "$(cat "$stamp" 2>/dev/null)" = "$sum" ] && return

	export DEBIAN_FRONTEND=noninteractive
	sed -i 's/^# deb-src/deb-src/' /etc/apt/sources.list
	apt-get update -qq
	apt-get build-dep -y -qq --no-install-recommends vlc > /dev/null
	apt-get install -y -qq --no-install-recommends "${packages[@]}" > /dev/null
	# The build-dep pulls in libupnp 1.8.4, whose headers would mix with
	# those of the newer one in $deps.
	apt-get remove -y -qq libupnp-dev > /dev/null
	echo "$sum" > "$stamp"
}

# 22.04's meson is older than the 1.10 VLC asks for.
install_tools() {
	[ -x "$venv/bin/meson" ] && return
	local tools=(meson==1.12.1)
	if [ "$arch" = x86_64 ]; then
		tools+=(aqtinstall==3.3.0)
	fi
	python3 -m venv "$venv"
	"$venv/bin/pip" install -q "${tools[@]}"
}

# 22.04's own Qt 6.2 is too old for the interface. Qt Wayland, Svg and
# Declarative are part of the default download.
install_qt() {
	if [ "$arch" = aarch64 ]; then
		build_qt
		# The same qt.conf aqt writes. Without it Qt takes its prefix from the
		# QtCore that qmake loads, which during deployment is the bundled copy.
		printf '[Paths]\nPrefix=..\n' > "$qtdir/bin/qt.conf"
		return
	fi
	[ -x "$qtdir/bin/qmake" ] && return
	aqt install-qt -O "$B/qt" linux desktop "$QT_VERSION" linux_gcc_64 -m qtshadertools
}

# Qt's own arm64 binaries are built on Ubuntu 24.04 and need glibc 2.38, so
# on arm64 the modules of the default download are built here instead, with
# 22.04's compiler and libraries. qttools is only there for lrelease, which
# Qt's translations are built with.
build_qt() {
	[ -f "$qtdir/.complete" ] && return
	qt_module qtbase 56001b905601bb9023d399f3ba780d7fa940f3e4861e496a7c490331f49e0b80 \
		-DFEATURE_xcb=ON -DFEATURE_opengl_desktop=ON -DFEATURE_openssl_runtime=ON \
		-DFEATURE_dbus=ON -DFEATURE_icu=ON -DFEATURE_zstd=ON
	qt_module qtshadertools f6ec88bf42deba84d8f6b5d0914636ceed4749ccb51d1945b2f79b322b7ecf47
	qt_module qtsvg 35eb516460f00f264eb504baa253432384351cf23fb9980a5857190e8deef438
	qt_module qtdeclarative 1f03a2b8f5588b4face7da87926e9b2c1372b3a32157c52df07a75067a9db1af
	qt_module qtwayland 20fe385887d21190165a3180c17dcfc8b9a0e1da4ec76865b6334bdc709994b0
	qt_module qttools 02a4e219248b94f1333df843d25763f35251c1074cdc4fb5bda67d340f8c8b3a \
		-DFEATURE_assistant=OFF -DFEATURE_designer=OFF -DFEATURE_qdoc=OFF \
		-DFEATURE_clang=OFF -DFEATURE_pixeltool=OFF -DFEATURE_distancefieldgenerator=OFF
	qt_module qttranslations c3c61d79c3d8fe316a20b3617c64673ce5b5519b2e45535f49bee313152fa531

	# A module that finds fewer libraries than it wants still builds, just
	# without the plugins the AppImage needs.
	local f
	for f in plugins/platforms/libqxcb.so plugins/platforms/libqwayland-egl.so \
		plugins/xcbglintegrations/libqxcb-glx-integration.so \
		plugins/xcbglintegrations/libqxcb-egl-integration.so \
		plugins/wayland-graphics-integration-client/libqt-plugin-wayland-egl.so \
		plugins/platformthemes/libqxdgdesktopportal.so \
		plugins/tls/libqopensslbackend.so translations/qtbase_de.qm; do
		[ -e "$qtdir/$f" ] || { echo "Qt was built without $f" >&2; exit 1; }
	done
	touch "$qtdir/.complete"
	rm -rf "$B/src/qt" "$B/src/tarballs/"*-everywhere-src-"$QT_VERSION".tar.xz
}

# qt_module NAME SHA256 [OPTIONS] builds one Qt module and installs it into
# $qtdir. The modules after qtbase are configured with its qt-cmake.
qt_module() {
	local name=$1 sum=$2; shift 2
	local dir=$B/src/qt/$name cmake=("$qtdir/bin/qt-cmake")
	[ -f "$dir/.installed" ] && return
	fetch "qt/$name" "https://download.qt.io/archive/qt/${QT_VERSION%.*}/$QT_VERSION/submodules/$name-everywhere-src-$QT_VERSION.tar.xz" "$sum"
	[ "$name" = qtbase ] && cmake=(cmake)
	echo "building $name"
	rm -rf "$dir/build"
	if ! { "${cmake[@]}" -S "$dir" -B "$dir/build" -G Ninja \
			-DCMAKE_INSTALL_PREFIX="$qtdir" -DCMAKE_BUILD_TYPE=Release \
			-DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF "$@" &&
		cmake --build "$dir/build" --parallel "$JOBS" &&
		cmake --install "$dir/build" --strip; } > "$dir/build.log" 2>&1; then
		tail -n 30 "$dir/build.log" >&2
		exit 1
	fi
	touch "$dir/.installed"
}

# fetch NAME URL SHA256 unpacks the tarball into $B/src/NAME once.
fetch() {
	local name=$1 url=$2 sum=$3 tarball=$B/src/tarballs/${2##*/}
	[ -d "$B/src/$name" ] && return
	mkdir -p "$B/src/tarballs"
	[ -s "$tarball" ] || curl -fsSL -o "$tarball" "$url"
	echo "$sum  $tarball" | sha256sum -c --quiet
	mkdir -p "$B/src/$name"
	tar -xf "$tarball" -C "$B/src/$name" --strip-components=1
}

# meson_dep NAME [OPTIONS] builds and installs a meson project into $deps.
meson_dep() {
	local name=$1; shift
	local dir=$B/src/$name
	[ -f "$dir/.installed" ] && return
	echo "building $name"
	rm -rf "$dir/build"
	if ! { meson setup "$dir/build" "$dir" --prefix="$deps" --libdir=lib --buildtype=release "$@" &&
		ninja -C "$dir/build" -j"$JOBS" install; } > "$dir/build.log" 2>&1; then
		tail -n 30 "$dir/build.log" >&2
		exit 1
	fi
	touch "$dir/.installed"
}

build_deps() {
	local fdo=https://gitlab.freedesktop.org

	# VLC needs wayland-scanner 1.23 and wayland-protocols 1.33. Only the
	# scanner is built; the code it generates still runs on 22.04's
	# libwayland-client.
	fetch wayland $fdo/wayland/wayland/-/releases/1.23.1/downloads/wayland-1.23.1.tar.xz \
		864fb2a8399e2d0ec39d56e9d9b753c093775beadc6022ce81f441929a81e5ed
	meson_dep wayland -Dlibraries=false -Dscanner=true -Dtests=false \
		-Ddocumentation=false -Ddtd_validation=false

	fetch wayland-protocols $fdo/wayland/wayland-protocols/-/releases/1.45/downloads/wayland-protocols-1.45.tar.xz \
		4d2b2a9e3e099d017dc8107bf1c334d27bb87d9e4aff19a0c8d856d17cd41ef0
	meson_dep wayland-protocols -Dtests=false

	# VLC's PipeWire output wants 0.3.64, 22.04 has 0.3.48. The client library
	# is built only to compile against: the AppImage takes libpipewire from
	# the host like the other audio libraries. 22.04's default sound server is
	# PulseAudio, which VLC then uses.
	fetch pipewire $fdo/pipewire/pipewire/-/archive/0.3.65/pipewire-0.3.65.tar.bz2 \
		c78c95cdff2774418f0a9468e94a1b2800761d322f13104df6501e1a0dc92558
	# The modules do not build without the audioconvert plugin.
	meson_dep pipewire --auto-features=disabled -Dsession-managers=[] \
		-Dexamples=disabled -Dtests=disabled \
		-Dspa-plugins=enabled -Daudioconvert=enabled

	# Not packaged for 22.04. The version VLC's contribs pin.
	fetch medialibrary https://code.videolan.org/videolan/medialibrary/-/archive/0.13.2/medialibrary-0.13.2.tar.bz2 \
		acda95dae8f357cf1ea6c71ac3979235555dae5fef5d33d218d14d1e5d729682
	meson_dep medialibrary -Dlibvlc=disabled -Dtests=disabled

	# UPnP discovery wants 1.8.5, 22.04 has 1.8.4.
	fetch libupnp https://github.com/pupnp/pupnp/releases/download/release-1.14.20/libupnp-1.14.20.tar.bz2 \
		ee4b4f85aa00ce38b782cf480fa569a90c7ccb23b0a9a076073a2d0bd6227335
	autotools_dep libupnp --disable-samples --disable-static

	# The scripts are compiled with the first luac on PATH, and it has to
	# match the Lua 5.4 VLC links; 22.04's default luac is 5.2.
	mkdir -p "$deps/bin"
	ln -sf /usr/bin/luac5.4 "$deps/bin/luac"
}

# autotools_dep NAME [OPTIONS] is meson_dep for a configure script.
autotools_dep() {
	local name=$1; shift
	local dir=$B/src/$name
	[ -f "$dir/.installed" ] && return
	echo "building $name"
	if ! (cd "$dir" && ./configure --prefix="$deps" --libdir="$deps/lib" "$@" &&
		make -j"$JOBS" && make install) > "$dir/build.log" 2>&1; then
		tail -n 30 "$dir/build.log" >&2
		exit 1
	fi
	touch "$dir/.installed"
}

fetch_kit() {
	local gh=https://github.com
	local -A urls=(
		[linuxdeploy-$arch.AppImage]=$gh/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-$arch.AppImage
		[linuxdeploy-plugin-qt-$arch.AppImage]=$gh/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-$arch.AppImage
		[appimagetool-$arch.AppImage]=$gh/AppImage/appimagetool/releases/download/continuous/appimagetool-$arch.AppImage
		[runtime-$arch]=$gh/AppImage/type2-runtime/releases/download/continuous/runtime-$arch
	)
	mkdir -p "$kit/bin"
	for f in "${!urls[@]}"; do
		[ -s "$kit/$f" ] && continue
		echo "downloading $f"
		curl -fsSL -o "$kit/$f.part" "${urls[$f]}"
		chmod +x "$kit/$f.part"
		mv "$kit/$f.part" "$kit/$f"
	done

	# Unpacked once, so the tools need no FUSE in the container. linuxdeploy
	# finds its plugins on PATH.
	for tool in linuxdeploy linuxdeploy-plugin-qt appimagetool; do
		[ -x "$kit/$tool/AppRun" ] && continue
		rm -rf "$kit/squashfs-root" "$kit/$tool"
		(cd "$kit" && "./$tool-$arch.AppImage" --appimage-extract > /dev/null)
		mv "$kit/squashfs-root" "$kit/$tool"
		ln -sf "../$tool/AppRun" "$kit/bin/$tool"
	done
}

update_source() {
	local arg=$1
	if [ ! -d "$src/.git" ]; then
		git clone -q https://code.videolan.org/videolan/vlc.git "$src"
	fi
	git config --global --add safe.directory "$src"
	[ -n "$arg" ] || return 0

	local rev=$arg
	if [[ $arg == *.bundle ]]; then
		local ref
		ref=$(git -C "$src" bundle list-heads "$arg" | awk 'NR == 1 { print $2 }')
		[ -n "$ref" ] || { echo "no branch in $arg" >&2; exit 1; }
		git -C "$src" fetch -q "$arg" "$ref"
		rev=FETCH_HEAD
	fi
	# A forced checkout only rewrites the files that differ, so the rebuild
	# stays incremental.
	git -C "$src" checkout -q -f --detach "$rev"
	git -C "$src" clean -fdq
}

# The features a complete player needs are enabled explicitly, so a missing
# library stops the build instead of quietly dropping a module. An existing
# build dir is reconfigured, which picks up packages added since. The UPnP
# server includes <upnp/...>, while libupnp's .pc only names include/upnp.
configure() {
	local reconfigure=()
	[ -f "$build/build.ninja" ] && reconfigure=(--reconfigure)
	meson setup "${reconfigure[@]}" "$build" "$src" \
		--prefix=/usr \
		--libdir=lib \
		--buildtype=release \
		-Db_ndebug=true \
		-Dqt=enabled \
		-Dmedialibrary=enabled \
		-Davcodec=enabled -Davformat=enabled -Dswscale=enabled \
		-Ddav1d=enabled -Dlibplacebo=enabled -Dgles2=disabled \
		-Dfreetype=enabled -Dfontconfig=enabled -Dfribidi=enabled -Dharfbuzz=enabled \
		-Dlibass=enabled -Dgnutls=enabled -Dtaglib=enabled \
		-Dxcb=enabled -Dx11=enabled -Dwayland=enabled \
		-Dpulse=enabled -Dpipewire=enabled -Dalsa=enabled \
		-Dpkg_config_path="$PKG_CONFIG_PATH" \
		-Dc_args="-I$deps/include" -Dcpp_args="-I$deps/include"
}

# VLC's meson files install neither a desktop entry nor icons.
write_desktop_entry() {
	local apps=$appdir/usr/share/applications
	local mimetypes
	mimetypes=$(sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' "$src/share/vlc.desktop.mimetypes" | tr '\n' ';')
	mkdir -p "$apps"
	sed -e '/^Name\[/d' -e '/^TryExec=/d' \
		-e 's/^Name=.*/Name=VLC/' \
		-e 's|^Exec=.*|Exec=vlc --started-from-file %U|' \
		-e "s|@MIMETYPES@|$mimetypes|" \
		"$src/share/vlc.desktop.in" > "$apps/vlc.desktop"

	for size in 16x16 32x32 48x48 128x128 256x256; do
		install -Dm644 "$src/share/icons/$size/vlc.png" \
			"$appdir/usr/share/icons/hicolor/$size/apps/vlc.png"
	done
}

# VLC finds its plugins, data and helpers relative to libvlccore (see
# src/linux/dirs.c), so the launcher only keeps the host's Qt and VLC search
# paths from leaking into the bundle.
write_apprun() {
	# linuxdeploy leaves AppRun as a symlink to usr/bin/vlc.
	rm -f "$appdir/AppRun"
	cat > "$appdir/AppRun" <<-'EOF'
	#!/bin/sh
	HERE=$(dirname "$(readlink -f "$0")")
	unset VLC_PLUGIN_PATH VLC_DATA_PATH VLC_LIB_PATH VLC_LIBEXEC_PATH QML2_IMPORT_PATH
	export QT_PLUGIN_PATH="$HERE/usr/plugins"
	export QML_IMPORT_PATH="$HERE/usr/qml"
	exec "$HERE/usr/bin/vlc" "$@"
	EOF
	chmod +x "$appdir/AppRun"
}

bundle_libraries() {
	# The Qt plugin leaves out EGL on Wayland, without which Qt Quick has no
	# OpenGL there.
	local egl=$appdir/usr/plugins/wayland-graphics-integration-client
	mkdir -p "$appdir/usr/plugins"
	cp -a "$qtdir/plugins/wayland-graphics-integration-client" "$egl"

	# --deploy-deps-only does not descend into subdirectories, and without it
	# linuxdeploy gives the VLC plugins an RPATH of plain $ORIGIN.
	local dirs=()
	while IFS= read -r dir; do
		dirs+=(--deploy-deps-only "$dir")
	done < <(find "$appdir/usr/lib/vlc" "$appdir/usr/libexec/vlc" "$egl" -name '*.so' -printf '%h\n' | sort -u)
	dirs+=(--deploy-deps-only "$appdir/usr/libexec/vlc")

	# The Qt plugin scans the QML sources for imports; the files themselves
	# are compiled into the Qt interface plugin.
	PATH=$kit/bin:$PATH \
	QMAKE=$qtdir/bin/qmake \
	QML_SOURCES_PATHS=$src/modules/gui/qt \
	EXTRA_PLATFORM_PLUGINS=libqwayland-egl.so\;libqwayland-generic.so \
	EXTRA_QT_MODULES=svg \
	LD_LIBRARY_PATH=$appdir/usr/lib:$appdir/usr/lib/vlc:$deps/lib:$qtdir/lib \
	"$kit/bin/linuxdeploy" \
		--appdir "$appdir" \
		--executable "$appdir/usr/bin/vlc" \
		"${dirs[@]}" \
		--desktop-file "$appdir/usr/share/applications/vlc.desktop" \
		--icon-file "$appdir/usr/share/icons/hicolor/256x256/apps/vlc.png" \
		--plugin qt

	# vlc-qt-check starts a QApplication from libexec, away from usr/bin/qt.conf.
	sed 's|^Prefix = .*|Prefix = ../../|' "$appdir/usr/bin/qt.conf" > "$appdir/usr/libexec/vlc/qt.conf"

	# linuxdeploy links the smallest icon as the AppImage icon.
	ln -sf usr/share/icons/hicolor/256x256/apps/vlc.png "$appdir/vlc.png"
}

# Lists the libraries the AppImage expects from the host, fails if Qt, VLC
# or FFmpeg libraries would still be loaded from the build system, and fails
# if any file needs a newer glibc than MAX_GLIBC or a newer libstdc++ than
# MAX_GLIBCXX.
check_bundle() {
	local elfs needed bundled outside versions glibc glibcxx
	elfs=$(find "$appdir" -type f \( -name '*.so*' -o -perm -u+x \) -exec sh -c \
		'file -b "$1" | grep -q "^ELF" && echo "$1"' sh {} \;)
	needed=$(xargs -d '\n' readelf -d <<< "$elfs" 2>/dev/null \
		| sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p' | LC_ALL=C sort -u)
	bundled=$(find "$appdir" -name '*.so*' -printf '%f\n' | LC_ALL=C sort -u)
	echo "libraries taken from the host:" $(LC_ALL=C comm -23 <(echo "$needed") <(echo "$bundled"))

	outside=$(xargs -d '\n' -n 1 ldd <<< "$elfs" 2>/dev/null \
		| awk -v appdir="$appdir" '$2 == "=>" && index($3, appdir) != 1 { print $1 }' \
		| { grep -E '^lib(Qt6|vlc|medialibrary|av|sw|icu)' || true; } | sort -u)
	if [ -n "$outside" ]; then
		echo "bundled but resolved outside the AppDir:" $outside >&2
		exit 1
	fi

	versions=$(xargs -d '\n' objdump -T <<< "$elfs" 2>/dev/null \
		| grep -oE 'GLIBC(XX)?_[0-9][0-9.]*' | sort -u)
	glibc=$(sed -n 's/^GLIBC_//p' <<< "$versions" | sort -V | tail -n 1)
	glibcxx=$(sed -n 's/^GLIBCXX_//p' <<< "$versions" | sort -V | tail -n 1)
	echo "newest glibc symbol version used: $glibc"
	echo "newest libstdc++ symbol version used: $glibcxx"
	if [ "$(printf '%s\n' "$glibc" "$MAX_GLIBC" | sort -V | tail -n 1)" != "$MAX_GLIBC" ]; then
		echo "the bundle needs glibc $glibc, more than $MAX_GLIBC" >&2
		exit 1
	fi
	if [ "$(printf '%s\n' "$glibcxx" "$MAX_GLIBCXX" | sort -V | tail -n 1)" != "$MAX_GLIBCXX" ]; then
		echo "the bundle needs libstdc++ $glibcxx, more than $MAX_GLIBCXX" >&2
		exit 1
	fi
}

inside_main() {
	step "packages"
	install_packages
	install_tools
	install_qt
	build_deps
	fetch_kit
	[ "${1:-}" = --prepare ] && return

	step "source"
	update_source "${1:-}"
	local commit
	commit=$(git -C "$src" rev-parse --short=10 HEAD)
	echo "building $commit"

	step "build"
	configure
	ninja -C "$build" -j"$JOBS"

	step "install"
	rm -rf "$appdir"
	meson install -C "$build" --destdir "$appdir" --strip --quiet
	rm -rf "$appdir/usr/include" "$appdir/usr/lib/pkgconfig"
	find "$appdir" -name '*.a' -delete
	write_desktop_entry

	step "bundle"
	bundle_libraries
	write_apprun
	check_bundle

	# The cache records each plugin's size and time, so it is written after
	# linuxdeploy has rewritten their RPATHs.
	"$appdir/usr/libexec/vlc/vlc-cache-gen" "$appdir/usr/lib/vlc/plugins"

	step "image"
	mkdir -p "${image%/*}"
	rm -f "$image"
	ARCH=$arch VERSION=$VERSION \
		"$kit/bin/appimagetool" --no-appstream \
		--runtime-file "$kit/runtime-$arch" \
		"$appdir" "$image"
	echo "$commit" > "$image.commit"
	sha256sum "$image" | tee "$image.sha256"
	ls -l "$image"
}

if [ "${1:-}" = --inside ]; then
	shift
	inside_main "$@"
else
	host_main "$@"
fi
