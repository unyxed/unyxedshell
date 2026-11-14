UNYX="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export UNYX
export ARCH="${ARCH:-x64}"
case "$ARCH" in
x64) QT_ARCH_DIR=msvc2022_64 ;;
arm64) QT_ARCH_DIR=msvc2022_arm64 ;;
*)
	echo "env.sh: unknown ARCH '$ARCH' (want x64 or arm64)" >&2
	return 1 2>/dev/null || exit 1
	;;
esac
export QT_VERSION=6.11.2
export QT_WIN="${QT_WIN:-$UNYX/toolchain/qt/$QT_VERSION/$QT_ARCH_DIR}"
export QT_HOST="${QT_HOST:-$UNYX/toolchain/qt/$QT_VERSION/gcc_64}"
export XWIN="$UNYX/toolchain/xwin"

export PATH="$PATH:$UNYX/toolchain/bin"

export VM_NAME=win11
export VM_URI=qemu:///system
export VM_KEY="$HOME/.ssh/unyxedshell-vm"
export VM_USER="${VM_USER:-}"
export VM_DIR='C:/unyxedshell'
if [ -f "$UNYX/tools/vm.local.sh" ]; then . "$UNYX/tools/vm.local.sh"; fi
