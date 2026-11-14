# unyxedshell

A minimal desktop shell for Windows 10 and 11: bar, sidebars, launcher, notifications and settings, built on Quickshell.

Status: early development. Not ready for general use.

## Layout

| Folder | What it is |
|---|---|
| `shell/` | The shell itself (QML) |
| `engine/` | Quickshell with a native Windows backend (C++) |
| `installer/` | The setup (Rust, Tauri) |
| `tools/` | Build, packaging and dev scripts |

## Based on

unyxedshell is derived from [Illogical Windows](https://github.com/nunreasonable/ii-windows), a Windows port of [end-4's illogical-impulse](https://github.com/end-4/dots-hyprland), which runs on [Quickshell](https://quickshell.org). It is an independent project and is not affiliated with or supported by any of them. See `THIRD-PARTY.md` and `NOTICE.md`.

## License

GPL-3.0 for the shell, setup and tooling (`LICENSE`). The engine is LGPL-3.0 (`engine/LICENSE`).
