#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/env.sh"

VERSION="$(tr -d '[:space:]' < "$UNYX/VERSION")"
SRC="$UNYX/dist/unyxedshell"
OUT="$UNYX/dist/release"
SETUP="${SETUP_EXE:-$UNYX/installer/target/x86_64-pc-windows-msvc/release/unyxedshell-setup.exe}"
[ -d "$SRC" ] || { echo "no dist/unyxedshell - run tools/deploy-shell.sh first" >&2; exit 1; }

CARGO_VERSION="$(sed -n 's/^version = "\(.*\)"/\1/p' "$UNYX/installer/Cargo.toml" | head -n1)"
VERSION_CORE="${VERSION%%[-+]*}"
CARGO_EXPECTED="$(echo "$VERSION_CORE" | cut -d. -f1-3)${VERSION#"$VERSION_CORE"}"
if [ "$CARGO_VERSION" != "$VERSION" ] && [ "$CARGO_VERSION" != "$CARGO_EXPECTED" ]; then
	echo "installer/Cargo.toml says $CARGO_VERSION, VERSION says $VERSION" >&2
	exit 1
fi

if [ "${GITHUB_EVENT_NAME:-}" = push ] && [ "${GITHUB_REF_TYPE:-}" = tag ]; then
	TAG_VERSION="${GITHUB_REF_NAME#v}"
	OLDEST="$(printf '%s\n' "$TAG_VERSION" "$VERSION" | sort -V | head -n1)"
	if [ "$VERSION" != "$TAG_VERSION" ] && [ "$OLDEST" = "$VERSION" ]; then
		echo "VERSION says $VERSION, older than release tag $GITHUB_REF_NAME" >&2
		exit 1
	fi
fi

if [ "${SKIP_SETUP_BUILD:-}" != 1 ]; then
	(cd "$UNYX/installer" && cargo xwin build --release --target x86_64-pc-windows-msvc -p unyxedshell-setup)
fi
[ -f "$SETUP" ] || { echo "no $SETUP" >&2; exit 1; }

STAGE="$UNYX/build/release-stage"
rm -rf "$STAGE"
mkdir -p "$STAGE" "$OUT"

(cd "$SRC" && find . -mindepth 1 -maxdepth 1 ! -name testconfigs ! -name install.ps1 ! -name uninstall.ps1 -print0) |
	while IFS= read -r -d '' entry; do
		cp -a "$SRC/${entry#./}" "$STAGE/"
	done
printf '%s\n' "$VERSION" > "$STAGE/VERSION"
cp -f "$SETUP" "$STAGE/unyxedshell-setup.exe"

if [ "$ARCH" = x64 ]; then
	ZIP="unyxedshell-$VERSION.zip"
else
	ZIP="unyxedshell-$VERSION-$ARCH.zip"
fi
rm -f "$OUT/$ZIP" "$OUT/$ZIP.sha256"
if command -v zip >/dev/null; then
	(cd "$STAGE" && zip -rqX "$OUT/$ZIP" .)
else
	"${PYTHON:-python3}" "$UNYX/tools/zipdir.py" "$STAGE" "$OUT/$ZIP"
fi
(cd "$OUT" && sha256sum "$ZIP" > "$ZIP.sha256")
cp -f "$SETUP" "$OUT/unyxedshell-setup.exe"

echo "release $VERSION ($ARCH) in $OUT:"
(cd "$OUT" && ls -l "$ZIP" "$ZIP.sha256" unyxedshell-setup.exe)
