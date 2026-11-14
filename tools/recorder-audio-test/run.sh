#!/usr/bin/env bash
set -euo pipefail
UNYX="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
src="${1:-$UNYX/engine/src/windows}"
build="$UNYX/build/recorder-audio-test${CXX:+-$(basename "$CXX")}"

cmake -S "$UNYX/tools/recorder-audio-test" -B "$build" -G Ninja -DQS_WINDOWS_SRC="$src" >/dev/null
cmake --build "$build" >/dev/null
"$build/recorder_audio_test"
