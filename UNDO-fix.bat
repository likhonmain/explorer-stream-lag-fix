@echo off
title Explorer Stream Lag Fix - UNDO
echo.
echo  Removing fix: re-enable "DLNA Media Servers Data Source" for the current user.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\UNDO-fix.ps1"
echo.
pause
