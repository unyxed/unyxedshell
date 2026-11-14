[CmdletBinding()]
param(
	[switch]$RemoveConfig
)

$ErrorActionPreference = 'Stop'

function Remove-SelfTask {
	$name = 'unyxedshell-' + [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
	if (Get-Command Unregister-ScheduledTask -ErrorAction SilentlyContinue) {
		try { Unregister-ScheduledTask -TaskName $name -TaskPath '\' -Confirm:$false -ErrorAction SilentlyContinue } catch {}
	}
}

$InstallDir = Join-Path $env:LOCALAPPDATA 'unyxedshell'
$QuickshellIiDir = Join-Path $env:LOCALAPPDATA 'quickshell\unyxedshell'
$UnyxedshellConfigDir = Join-Path $env:LOCALAPPDATA 'unyxedshell-config'
$StartMenuDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$RunKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'

Write-Host "Uninstalling unyxedshell ..."

Get-Process -Name 'qsw', 'qs' -ErrorAction SilentlyContinue |
	Where-Object { $_.Path -like "$InstallDir\*" } |
	Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

Remove-ItemProperty -Path $RunKey -Name 'unyxedshell' -ErrorAction SilentlyContinue
Remove-SelfTask

foreach ($name in 'unyxedshell.lnk', 'unyxedshell Settings.lnk') {
	$path = Join-Path $StartMenuDir $name
	if (Test-Path $path) { Remove-Item -Force $path }
}

if (Test-Path $InstallDir) {
	try {
		Remove-Item -Recurse -Force $InstallDir -ErrorAction Stop
	} catch {
		Write-Warning "Could not fully remove $InstallDir right now ($($_.Exception.Message)); scheduling cleanup in the background."
		Start-Process -WindowStyle Hidden cmd.exe -ArgumentList "/c timeout /t 2 /nobreak >nul & rmdir /s /q `"$InstallDir`""
	}
}

if ($RemoveConfig) {
	Write-Host "Removing ii config and settings (-RemoveConfig) ..."
	foreach ($dir in $QuickshellIiDir, $UnyxedshellConfigDir) {
		if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
	}
} else {
	Write-Host "Keeping config: $QuickshellIiDir, $UnyxedshellConfigDir"
	Write-Host "Re-run with -RemoveConfig to also delete those."
}

Write-Host "Done."
