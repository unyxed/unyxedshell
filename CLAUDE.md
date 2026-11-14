# Working in this repo

unyxedshell: a Windows desktop shell (Quickshell engine + QML shell + Tauri setup). See `README.md` for the layout.

## First run on a new clone
1. `git init` (if there is no `.git`), then `git config core.hooksPath .githooks`.
2. Install the upstream-built shell once with its setup, so `%LOCALAPPDATA%\quickshell\ii` exists.
3. Read `BACKLOG.local.md` if it exists. It is private.

## Private files (hard rule)
- `BACKLOG.local.md`, anything named `*.local.*`, and `.private/` are git-ignored and must never be committed.
- Never copy their contents, goals, plans or reasoning into code comments, docs, commit messages, PR text, issue text, branch names or file names.
- Commit messages: one short plain sentence saying what changed. End with the `Co-Authored-By` line only. No session links.
- Do not add TODO comments that describe plans. Keep unfinished work in `BACKLOG.local.md`.

## Try a QML change
`powershell -File tools/dev/sync-shell.ps1` copies `shell/` into the installed copy, clears the QML cache, restarts the shell. Logs: `%LOCALAPPDATA%\quickshell\run\by-id\<run>\log.log`.
Never edit `%LOCALAPPDATA%\quickshell\ii` directly; `shell/` is the source.

## Engine / setup builds
- Engine (C++20, Qt 6.11.2, clang-cl): `ci/upstream-build.yml.reference` lists every step and version. Output is `qs.exe` and `qsw.exe`; copy over the ones in `%LOCALAPPDATA%\ii-windows` to test.
- Setup: `cd installer && cargo build --release -p ii-windows-setup --target x86_64-pc-windows-msvc`.
- `tools/` has cross-compile helpers (`env.sh`, `clang-cl-xwin.cmake`). The upstream workflow is kept as a reference only and is not active.

## Code rules
- Match surrounding code and formatting (`.clang-format` in `engine/`, `.qmlformat.ini` in `shell/`).
- User-visible text goes through `Translation.tr()`.
- Windows-only behavior sits behind `Platform.isWindows`; Windows-only C++ goes in `engine/src/windows/`.
- C++/WinRT calls run on their own MTA thread and post results back to the Qt thread. Never block with `.get()` on the Qt thread.
- Do not copy code from projects whose license is not GPL-3.0 compatible (LGPL-3.0 for `engine/`). MIT/Apache-2.0 is fine with an entry in `THIRD-PARTY.md`.
- Do not change Windows settings (wallpaper, theme, security, execution policy) while testing, except what a task needs, and restore them.
- Do not push, publish, tag or create releases without being asked.

## Known hazards
- The shell, setup and installer still check the upstream project's GitHub releases for updates. Until re-pointed, an "Update" would replace this fork with upstream. Do not run Update or Repair from the upstream setup while testing.
- The setup's Update/Repair overwrite `%LOCALAPPDATA%\quickshell\ii`.
