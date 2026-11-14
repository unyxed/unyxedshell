# Copies shell/ into the installed copy, clears the compiled QML cache and restarts the shell.
# Usage: powershell -File tools/dev/sync-shell.ps1
$ErrorActionPreference = 'Stop'
$src = Join-Path (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) 'shell'
$dst = Join-Path $env:LOCALAPPDATA 'quickshell\ii'
if (-not (Test-Path $dst)) { throw "Installed shell not found at $dst. Install it with the setup first." }
Get-Process qsw -ErrorAction SilentlyContinue | Stop-Process -Force
robocopy $src $dst /MIR /XD .git .qmlcache /NFL /NDL /NJH /NJS | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy failed ($LASTEXITCODE)" }
Remove-Item (Join-Path $dst '.qmlcache') -Recurse -Force -ErrorAction SilentlyContinue
# Files from a downloaded zip carry a "from the internet" mark that stops the terminal profile script from loading.
Get-ChildItem $dst -Recurse -File -Force | Unblock-File
$lnk = Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -Filter 'illogical-impulse.lnk' -Recurse | Select-Object -First 1
if ($lnk) { Start-Process $lnk.FullName } else { Write-Warning 'Start menu shortcut not found; start the shell manually.' }
Write-Output "Synced to $dst. Logs: $env:LOCALAPPDATA\quickshell\run\by-id\<run>\log.log"
