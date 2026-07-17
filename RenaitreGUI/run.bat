@echo off
cd /d "%~dp0"
dotnet build -c Debug >nul 2>&1
start "" "bin\Debug\net8.0-windows\RenaitreSabre.exe"
pause
