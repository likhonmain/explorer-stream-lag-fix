@echo off
title Explorer Stream Lag Fix - TEST
echo.
echo  Measures your router ping while Windows loads "This PC" (what Explorer and
echo  every Open/Save dialog do). Changes nothing. Takes about 20 seconds.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\TEST-lag.ps1"
echo.
pause
