@echo off
REM Starts the watcher: the checks run by themselves whenever a file changes.
powershell -ExecutionPolicy Bypass -File "%~dp0watch_checks.ps1"
pause
