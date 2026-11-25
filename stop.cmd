@echo off
rem Double-click to pause ClusterDojo (keeps your progress).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0stop.ps1"
pause
