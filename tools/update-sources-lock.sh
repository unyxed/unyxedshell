#!/usr/bin/env bash
set -euo pipefail
UNYX="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for repo in quickshell ii; do
	if [ -n "$(git -C "$UNYX/$repo" status --porcelain --untracked-files=no)" ]; then
		echo "$repo has uncommitted changes" >&2
		exit 1
	fi
done

{
	echo "quickshell https://github.com/nunreasonable/quickshell $(git -C "$UNYX/quickshell" rev-parse HEAD)"
	echo "ii https://github.com/nunreasonable/dots-hyprland $(git -C "$UNYX/ii" rev-parse HEAD)"
} > "$UNYX/sources.lock"
cat "$UNYX/sources.lock"
