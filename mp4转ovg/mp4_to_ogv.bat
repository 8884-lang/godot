@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

REM Optional override: set FFMPEG to full path of ffmpeg.exe
REM set "FFMPEG=E:\path\to\ffmpeg.exe"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0mp4_to_ogv.ps1" %*
set "ERR=%ERRORLEVEL%"
echo.
pause
exit /b %ERR%
