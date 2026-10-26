@echo off
title Explorer Stream Lag Fix - APPLY
echo.
echo  Applying fix: block "DLNA Media Servers Data Source" for the current user.
echo  (No admin rights needed. Undo any time with UNDO-fix.bat)
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\APPLY-fix.ps1"
echo.
pause
