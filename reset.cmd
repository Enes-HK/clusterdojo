@echo off
rem Double-click for a completely fresh attempt (new clusters and images, progress is lost, old scores are kept).
choice /m "Throw away the current exam clusters and start fresh"
if errorlevel 2 exit /b
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0reset.ps1"
pause
