#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/env.sh"

SRC="$UNYX/dist/unyxedshell"
[ -d "$SRC" ] || { echo "no dist/unyxedshell - run tools/deploy-shell.sh first" >&2; exit 1; }

DATE="$(date +%Y%m%d)"
STAGE="$UNYX/build/package-stage"
if [ "$ARCH" = x64 ]; then
	OUT="$UNYX/dist/unyxedshell-$DATE.zip"
else
	OUT="$UNYX/dist/unyxedshell-$DATE-$ARCH.zip"
fi

rm -rf "$STAGE"
mkdir -p "$STAGE"

(cd "$SRC" && find . -mindepth 1 -maxdepth 1 ! -name testconfigs -print0) |
	while IFS= read -r -d '' entry; do
		cp -a "$SRC/${entry#./}" "$STAGE/"
	done

cp -f "$UNYX/tools/install.ps1" "$UNYX/tools/uninstall.ps1" "$STAGE/"

rm -f "$OUT"
(cd "$STAGE" && zip -rq "$OUT" .)

echo "packaged $OUT ($(du -sh "$OUT" | cut -f1))"
