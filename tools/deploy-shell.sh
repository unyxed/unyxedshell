#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/env.sh"

D="$UNYX/dist/unyxedshell"
SHIMS="${SHIMS:-$UNYX/quickshell/shims}"
[ -d "$SHIMS" ] || SHIMS="$UNYX/quickshell-shims/shims"

QS_BUILD="${QS_BUILD:-$UNYX/build/qs}"
DEPS="${DEPS_DIR:-$UNYX/build/deps}"
FONTTOOLS="${FONTTOOLS:-uv run -q --with fonttools fonttools}"
"$UNYX/tools/fetch-deps.sh" >/dev/null

rm -rf "$D"
"$UNYX/tools/deploy.sh" "$D" "$QS_BUILD/qs.exe" "$QS_BUILD/qsw.exe" >/dev/null

native_path() {
	if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s\n' "$1"; fi
}

pin_unused_axes() {
	local src="$1" axes="$2" key cache
	key=$(sha256sum "$src" | cut -c1-16)
	cache="$UNYX/build/fonts/$key-$(basename "$src")"
	if [ ! -f "$cache" ]; then
		mkdir -p "$UNYX/build/fonts"
		# shellcheck disable=SC2086
		if ! $FONTTOOLS varLib.instancer "$(native_path "$src")" $axes -o "$(native_path "$cache.tmp")" >/dev/null 2>&1; then
			echo "warning: could not pin the axes of $(basename "$src"), shipping it as is" >&2
			rm -f "$cache.tmp"
			cp -f "$src" "$D/fonts/"
			return
		fi
		mv "$cache.tmp" "$cache"
	fi
	cp -f "$cache" "$D/fonts/$(basename "$src")"
}

rm -rf "$D/fonts"
mkdir -p "$D/fonts"
for f in "$DEPS"/fonts/*; do
	case "$f" in
	*GoogleSansFlex* | *MaterialSymbolsRounded*) pin_unused_axes "$f" "GRAD=0" ;;
	*) cp -f "$f" "$D/fonts/" ;;
	esac
done

rm -rf "$D/icons"
mkdir -p "$D/icons"
cp -f "$UNYX"/ii/defaults/windows/icons/*.svg "$D/icons/"
cp -f "$UNYX"/ii/assets/icons/*.svg "$D/icons/"
for f in "$UNYX"/tools/icons/adwaita/*; do
	case "$f" in
	*.svg) cp -f "$f" "$D/icons/" ;;
	*) cp -f "$f" "$D/icons/adwaita-$(basename "$f")" ;;
	esac
done

rm -rf "$D/qml/Quickshell" "$D/qml/org" "$D/qml/_common"
if [ -d "$SHIMS" ]; then
	(cd "$SHIMS" && find . -type f ! -name '*.md' -print0) | while IFS= read -r -d '' f; do
		mkdir -p "$D/qml/$(dirname "$f")"
		cp -f "$SHIMS/$f" "$D/qml/$f"
	done
else
	echo "warning: no shims found ($SHIMS)" >&2
fi

VDA_DLL="${VDA_DLL:-$DEPS/vda/VirtualDesktopAccessor.dll}"
cp -f "$VDA_DLL" "$D/VirtualDesktopAccessor.dll"
rm -rf "$D/win10"
if [ "$ARCH" = x64 ]; then
	mkdir -p "$D/win10"
	cp -f "$DEPS/vda/win10/VirtualDesktopAccessor.dll" "$D/win10/"
else
	echo "note: no win10/VirtualDesktopAccessor.dll for $ARCH - Windows 10 on ARM64 isn't a target" >&2
fi

rm -rf "$D/licenses"
mkdir -p "$D/licenses/unyxedshell" "$D/licenses/quickshell" "$D/licenses/Qt"
cp -f "$UNYX/LICENSE" "$D/licenses/unyxedshell/LICENSE.txt"
cp -f "$UNYX/THIRD-PARTY.md" "$D/licenses/THIRD-PARTY.md"
cp -f "$UNYX/quickshell/LICENSE" "$D/licenses/quickshell/LICENSE.txt"
cp -f "$UNYX/quickshell/LICENSE-GPL" "$D/licenses/quickshell/LICENSE-GPL.txt"
cp -f "$UNYX/quickshell/LICENSE" "$D/licenses/Qt/LICENSE-LGPL-3.0.txt"
cp -f "$UNYX/quickshell/LICENSE-GPL" "$D/licenses/Qt/LICENSE-GPL-3.0.txt"
printf 'Qt %s (The Qt Company Ltd. and other contributors) is used under the GNU Lesser General Public License v3.\nIts source code is available at https://download.qt.io/archive/qt/ and https://code.qt.io/.\nThe Qt libraries shipped with unyxedshell (Qt6*.dll, plugins and qml) are unmodified and can be replaced with other builds of the same version.\n' "$QT_VERSION" > "$D/licenses/Qt/NOTICE.txt"
cp -rf "$DEPS"/licenses/. "$D/licenses/"

MATUGEN_EXE="${MATUGEN_EXE:-$UNYX/toolchain/matugen.exe}"
if [ -f "$MATUGEN_EXE" ]; then
	cp -f "$MATUGEN_EXE" "$D/matugen.exe"
else
	echo "warning: no $MATUGEN_EXE - Windows wallpaper theming will fail" >&2
fi

SONGREC_DIR="${SONGREC_DIR:-$UNYX/tools/songrec/bin}"
if [ -f "$SONGREC_DIR/songrec.exe" ]; then
	cp -f "$SONGREC_DIR/songrec.exe" "$D/"
	mkdir -p "$D/licenses/songrec"
	cp -f "$SONGREC_DIR/COPYING" "$SONGREC_DIR/SOURCE.txt" "$D/licenses/songrec/"
else
	echo "warning: no $SONGREC_DIR/songrec.exe - music recognition will be unavailable" >&2
fi

MICROTEX_DIR="${MICROTEX_DIR:-$UNYX/toolchain/microtex}"
if [ -f "$MICROTEX_DIR/LaTeX.exe" ]; then
	cp -f "$MICROTEX_DIR/LaTeX.exe" "$D/"
	rm -rf "$D/res" && cp -r "$MICROTEX_DIR/res" "$D/res"
	mkdir -p "$D/licenses/microtex"
	cp -rf "$MICROTEX_DIR"/licenses/. "$D/licenses/microtex/"
else
	echo "warning: no $MICROTEX_DIR/LaTeX.exe - LaTeX rendering in the AI chat will be unavailable" >&2
fi

rm -rf "$D/config/unyxedshell"
mkdir -p "$D/config"
(cd "$UNYX/ii" && git ls-files -z --recurse-submodules) | while IFS= read -r -d '' f; do
	mkdir -p "$D/config/unyxedshell/$(dirname "$f")"
	cp -fp "$UNYX/ii/$f" "$D/config/unyxedshell/$f"
done

QMLCACHE_GEN="${QMLCACHE_GEN:-$UNYX/quickshell/tools/qmlcache-bundle.py}"
QMLCACHEGEN="${QMLCACHEGEN:-$QT_HOST/libexec/qmlcachegen}"
if [ -f "$QMLCACHE_GEN" ]; then
	"${PYTHON:-python3}" "$QMLCACHE_GEN" "$D/config/unyxedshell" -q \
		--qmlcachegen "$QMLCACHEGEN" --qt-version "$QT_VERSION" ||
		echo "warning: no QML bytecode bundle - ii will compile its QML from source at startup" >&2
else
	echo "warning: no $QMLCACHE_GEN - ii will compile its QML from source at startup" >&2
fi

rm -rf "$D/testconfigs"; cp -r "$UNYX/tools/testconfigs" "$D/testconfigs"
echo "staged $D ($(du -sh "$D" | cut -f1))"
