@echo off
rem Runs every check CI runs. Double-click, or: ci.bat -Fix
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ci.ps1" %*
pause
