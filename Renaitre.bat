chcp 65001 > nul
REM -------------------------------------------------------------------
REM PROGRAMIN ADMİN OLARAK ÇALIŞTIRILMA SORGU BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------
@echo off
:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------
REM -------------------------------------------------------------------
REM PROGRAMIN ADMİN OLARAK ÇALIŞTIRILMA SORGU BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------

REM -------------------------------------------------------------------
REM PROGRAMIN GENEL MENÜ BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------

:menu
cls
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a:%%b)
title RenaitreSabre 
echo --------------------------------------------------------------------------------
echo                       RenaitreSabre     %mydate% - %mytime%
echo --------------------------------------------------------------------------------
echo.
echo "     _____                                                       ";
echo " ___|__  _|__  ______  ____    ______  _____  ____    __  ______ ";
echo "|  \/  \|  | ||   ___||    |  |   ___|/     \|    \  /  ||   ___|";
echo "|     /\   | ||   ___||    |_ |   |__ |     ||     \/   ||   ___|";
echo "|____/  \__|_||______||______||______|\_____/|__/\__/|__||______|";
echo "    |_____|                                                      ";
echo.
echo which operation would you like to perform? 
echo ====...**...**...====
echo.
echo [0] Exit
echo [1] Info
echo [2] App Store
echo [3] Network Tools
echo [4] Pentest Tools
echo [5] Overkill Renaitre Sabre .bat ( I do not recommend using this )
echo.
set /p "select=Select:"
if %select% ==0 exit > nul 2>&1
if %select% ==1 goto info
if %select% ==2 goto appstore
if %select% ==3 goto networks
if %select% ==4 goto pentest
if %select% ==5 goto sabre
cls
goto menu

REM -------------------------------------------------------------------
REM PROGRAMIN GENEL MENÜ BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------



REM -------------------------------------------------------------------
REM İNFO BAT BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------

:info
call "info.bat"
echo İlk bat dosyasına geri dönüldü.
pause > nul
goto menu


REM -------------------------------------------------------------------
REM İNFO BAT BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------


REM -------------------------------------------------------------------
REM APPSTORE BAT BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------

:appstore
call "appstore.bat"
echo İlk bat dosyasına geri dönüldü.
pause > nul
goto menu

REM -------------------------------------------------------------------
REM APPSTORE BAT BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------

REM -------------------------------------------------------------------
REM NETWORKS BAT BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------

:networks
call "networks.bat"
echo İlk bat dosyasına geri dönüldü.
pause > nul
goto menu

REM -------------------------------------------------------------------
REM NETWORKS BAT BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------

REM -------------------------------------------------------------------
REM NETWORKS BAT BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------

:pentest
call "pentest.bat"
echo İlk bat dosyasına geri dönüldü.
pause > nul
goto menu

REM -------------------------------------------------------------------
REM NETWORKS BAT BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------

REM -------------------------------------------------------------------
REM SABRE BAT BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------

:sabre
call "sabre.bat"
echo İlk bat dosyasına geri dönüldü.
pause > nul
goto menu

REM -------------------------------------------------------------------
REM SABRE BAT BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------

