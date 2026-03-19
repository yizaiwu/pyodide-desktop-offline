@echo off
chcp 65001 > nul

:: delegate everything to PowerShell (JSON parsing is too complex for pure batch)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0download_pyodide.ps1"
