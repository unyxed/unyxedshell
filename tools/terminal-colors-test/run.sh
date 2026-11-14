#!/usr/bin/env bash
set -euo pipefail
UNYX="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
src="${1:-$UNYX/engine/src/windows}"
shift || true
build="$UNYX/build/terminal-colors-test${CXX:+-$(basename "$CXX")}"
python="${II_PYTHON:-$HOME/.local/state/quickshell/.venv/bin/python}"

cmake -S "$UNYX/tools/terminal-colors-test" -B "$build" -G Ninja -DQS_WINDOWS_SRC="$src" >/dev/null
cmake --build "$build" >/dev/null
"$python" "$UNYX/tools/terminal-colors-test/compare.py" "$build/terminal_colors_test" "$@"
