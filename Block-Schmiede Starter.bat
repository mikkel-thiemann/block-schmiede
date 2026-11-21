@echo off
title Block-Schmiede Starter
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0starter.ps1" %*
echo.
pause
