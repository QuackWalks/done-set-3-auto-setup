@echo off
REM Download the latest version of the script from github
Powershell.exe Invoke-WebRequest -Uri https://raw.githubusercontent.com/QuackWalks/done-set-3-auto-setup/refs/heads/main/done-auto.ps1 -OutFile "./done-auto.ps1"
REM Run the script
Powershell.exe -ExecutionPolicy Bypass -File "./done-auto.ps1"
