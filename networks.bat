REM -------------------------------------------------------------------
REM NETWORKS GENEL MENÜ BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------
REM -------------------------------------------------------------------
REM NETWORKS  MENÜ BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------

:networks
cls
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a:%%b)
title NetworkTools
:network
cls
echo --------------------------------------------------------------------------------
echo                    Welcome to NetworkTools     %mydate% - %mytime%
echo --------------------------------------------------------------------------------
echo.
echo "       ____
echo "  ____|    \               
echo " (____|     `._____ 
echo "  ____|       _|___ 
echo " (____|     .'      
echo "      |____/	  
echo.	
color 0A
echo Please choose operation would you like to perform?
echo.
echo  [0] Back to menu
echo  [1] To troubleshoot a network problem / Ağ sorunlarını gidermek icin
echo  [2] List of running operations and services / Calısan islemlerin ve hizmetlerin listesi
echo  [3] Windows update cleaning / Windows güncellestirme temizleme
echo  [4] Stop or start the windows update service / Windows update hizmetlerini durdurma ve baslatma
echo  [5] IP address and network configuration information / IP adresi ve ag yapılandırma bilgileri
echo  [6] Installed drivers list / Yüklü sürücülerin listesi
echo  [7] System information / Sistem hakkında bilgiler
echo  [8] Cleaning the print queue / Printer yazdırma kuyrugu temizleme
echo  [9] Clean unnecessary Nvidia files / Gereksiz Nvidia dosyalarını temizleme
echo [10] End an application that is not responding. / Yanıt vermeyen bir uygulamayı sonlandırmak
echo [11] Data collection and telemetry services settings for Windows 10 /Windows10 için veri toplama ve telemetri hizmetleri.
echo [12] To Update or Upgrade everything on your computer / Bilgisayarınızdaki herseyi güncellemek ve yükseltmek icin
echo [13] Google Chrome to delete browsing data / Google Chrome tarama verilerini silmek için
echo.
set /p "select=Select:"
if %select% == 0  goto menu
if %select% == 1  goto troubleshoot
if %select% == 2  goto operations 
if %select% == 3  goto windowsupdatecls
if %select% == 4  goto windowsservicestopstart
if %select% == 5  goto networkconfigurationinformation
if %select% == 6  goto driverslist
if %select% == 7  goto systeminformation
if %select% == 8  goto printqueue
if %select% == 9  goto nvidiafiles
if %select% == 10 goto endapplication
if %select% == 11 goto datacollection
if %select% == 12 goto sabredate
if %select% == 13 goto Chrome
cls
goto networks

REM -------------------------------------------------------------------
REM NETWORKS  MENÜ BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------

:troubleshoot
cls
echo --------------------------------------------------------------------------------
echo.
echo Warning! this will reset some network settings and caches.
echo.
CHOICE /C YN /M "Do you want to continue"
IF ERRORLEVEL 2 goto networks
echo.
echo --------------------------------------------------------------------------------
echo.
netsh int ip reset reset.txt
netsh winsock reset
netsh advfirewall reset
netsh winhttp reset proxy
route -f
ipconfig /release
ipconfig /renew
netsh interface ip delete arpcache
nbtstat -R
nbtstat -RR
ipconfig /flushdns
ipconfig /registerdns
echo.
echo You must restart your computer for the changes to take effect.
echo.
CHOICE /C YN /M "Do you want to restart?"
IF ERRORLEVEL 2 goto choice
goto netboot

:operations
cls
echo.
echo --------------------------------------------------------------------------------
echo Please make a choice.
echo --------------------------------------------------------------------------------
echo.
color 0B
echo [0] Back to Menu
echo [1] Operations
echo [2] Services
echo.
set /p op=Select:
if %op% == 0 goto networks
if %op% == 1 goto 2tasklst
if %op% == 2 goto 2netserv
cls
goto operations

:2tasklst
echo.
echo --------------------------------------------------------------------------------
tasklist
echo --------------------------------------------------------------------------------
echo.
echo Press any key to return to the previous menu.
echo.
pause > nul
goto operations

:2netserv
echo.
echo --------------------------------------------------------------------------------
sc query type= service
echo --------------------------------------------------------------------------------
echo.
echo Press any key to return to the previous menu.
pause > nul
goto operations

:windowsupdatecls
cls
color 0C
echo --------------------------------------------------------------------------------
echo.
echo Warning!: This will clear your windows update history.
echo.
CHOICE /C EH /M "Do you want to continue"
IF ERRORLEVEL 2 goto networks
echo.
echo --------------------------------------------------------------------------------
taskkill /fi "Services eq wuauserv" /F > nul 2>&1
rmdir %windir%\softwaredistribution /s /q > nul 2>&1
rmdir %windir%\system32\softwaredistribution /s /q > nul 2>&1
regsvr32 /s wuaueng.dll
regsvr32 /s wuaueng1.dll
regsvr32 /s atl.dll
regsvr32 /s wups.dll
regsvr32 /s wups2.dll
regsvr32 /s wuweb.dll
regsvr32 /s wucltui.dll
echo.
CHOICE /C YN /M "Windows update history cleared. Would you like to restart this service now?"
IF ERRORLEVEL 2 goto choice
echo.
net start wuauserv
goto wuchoice

:windowsservicestopstart
cls
color 0D
echo Please wait while windows services restarts.
echo.
sc query "wuauserv" | find "RUNNING" > nul
if %ErrorLevel% EQU 0 goto askstop (
if %ErrorLevel% EQU 1 goto askstart
) else (
  echo --------------------------------------------------------------------------------
  echo.
  echo I don't know what it is :), start the process again.
  goto choice
)

:askstop
echo --------------------------------------------------------------------------------
echo.
echo Stopping Windows update service, press "Y" to stop or "N" to return to the main menu.
echo.
set /P c=">"
if /I "%c%" EQU "Y" goto stop
if /I "%c%" EQU "N" goto networks
cls
goto askstop

:askstart
echo --------------------------------------------------------------------------------
echo.
echo Starting Windows update service, press "Y" to stop or "N" to return to the main menu..
echo.
set /P c=">"
if /I "%c%" EQU "Y" goto start
if /I "%c%" EQU "N" goto networks
cls
goto askstart

:stop
taskkill /fi "Services eq wuauserv" /F > nul
echo.
echo Windows Update service has stopped.
goto choice

:start
net start wuauserv > nul
echo.
echo Windows Update service started.
goto choice


:networkconfigurationinformation
cls
color 0E
echo --------------------------------------------------------------------------------
echo Please make a choice.
echo --------------------------------------------------------------------------------
echo.
echo [0] Back to Menu
echo [1] Windows network configuration and local ip address
echo [2] Public ip address
echo.
set /p op=Select:

if %op% == 0 goto networks
if %op% == 1 goto lip
if %op% == 2 goto gip
cls
goto networkconfigurationinformation

:lip
echo.
ipconfig /all
echo.
echo --------------------------------------------------------------------------------
echo.
echo Press any key to return to the previous menu.
echo.
pause > nul
goto networkconfigurationinformation

:gip
echo.
echo --------------------------------------------------------------------------------
echo.
echo Please wait, this process may take a while.
echo.
powershell -command " (Invoke-WebRequest https://wtfismyip.com/text).Content "
echo.
echo --------------------------------------------------------------------------------
echo.
echo Press any key to return to the previous menu.
echo.
pause > nul
goto networkconfigurationinformation

:driverslist
cls
color 0C
echo This tool will create a list of all the src's installed on your system and save this list in the driverslist folder on your desktop.
echo.
echo --------------------------------------------------------------------------------
cd %userprofile%\Desktop
mkdir driverslist
cd driverslist
driverquery | more >> driverslist.txt
echo.
echo Press any key and your files are saved on the "DESKTOP".
pause > nul
goto networks

:systeminformation
cls
color 0D
echo This contains your system information and the results will be on your desktop in a file called systeminfo.
echo.
echo --------------------------------------------------------------------------------
cd %userprofile%\Desktop
mkdir systeminfo
cd systeminfo
systeminfo | more >> systeminfo.txt
echo.
goto wuchoice

:printqueue
cls
color 3
echo.
echo --------------------------------------------------------------------------------
echo The print spooler service is being stopped.
taskkill /fi "Services eq spooler" /F > nul 2>&1
echo Service has been suspended.
echo.
echo Clearing the print queue.
del %systemroot%\System32\spool\printers\* /Q /F /S  > nul 2>&1
echo It's done.
echo.
echo Service is restarting.
net start spooler  > nul 2>&1
echo Service started.
echo.
echo Press any key to return to the previous menu.
pause > nul
goto networks

:nvidiafiles
cls
color 0F
echo --------------------------------------------------------------------------------
echo.
echo Warning: This will clean up unnecessary Nvidia files on your system. Do not use this tool if your system does not have an Nvidia video card.
echo.
CHOICE /C YN /M "Do you want to continue"
IF ERRORLEVEL 2 goto networks
echo.
echo --------------------------------------------------------------------------------
echo.
echo Please wait...
RD /S /Q "C:\PROGRAM FILES\NVIDIA CORPORATION\INSTALLER" > nul 2>&1
RD /S /Q "C:\PROGRAM FILES\NVIDIA CORPORATION\INSTALLER2" > nul 2>&1
RD /S /Q "C:\NVIDIA" > nul 2>&1
echo.
echo Operation completed.
timeout /t 2
goto networks


:endapplication
cls
color 3
echo ====...**...**...========...**...**...========...**...**...========...**...**...====
echo 	This tool allows you to terminate an application that is not responding.
echo ====...**...**...========...**...**...========...**...**...========...**...**...====
echo.
echo [0] Back to menu
echo.
echo --------------------------------------------------------------------------------
echo Please type the name of the application you want to terminate. ("rn, explorer.exe)
echo.
set /p "app=> "
if %app% EQU 0 goto networks
taskkill /im %app% /f > nul 2>&1
if %errorlevel% EQU 128 goto tkrrr
echo.
echo The process is terminated.
echo.
echo --------------------------------------------------------------------------------
echo.
echo Press any key to return to the previous menu.
pause > nul
goto networks

:tkrrr
echo.
echo An error occurred. Make sure you have typed the name of the application correctly.
echo.
echo --------------------------------------------------------------------------------
echo.
echo Press any key to return to the previous menu.
pause > nul
goto networks

:datacollection
cls
color 0E
echo --------------------------------------------------------------------------------
echo Data Collection and Telemetry Services for Windows 10
echo --------------------------------------------------------------------------------
echo.
echo [0] Back to menu
echo [1] Deactivate
echo [2] Enable
echo.
set /p op=Select:
if %op% == 0 goto networks
if %op% == 1 goto teldis13
if %op% == 2 goto talen13
cls
goto datacollection

:teldis13
echo.
echo --------------------------------------------------------------------------------
echo.
echo This will disable Data Collection and Telemetry Services for Windows 10.
echo.
CHOICE /C YN /M "Do you want to continue"
IF ERRORLEVEL 2 goto datacollection
sc config dmwappushservice start= disabled > nul 2>&1
sc stop "dmwappushservice" > nul 2>&1
sc config diagtrack start= disabled > nul 2>&1
sc stop "DiagTrack" > nul 2>&1
start reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection /v AllowTelemetry /t REG_DWORD /d 0 /f > nul 2>&1
start reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection /v AllowTelemetry /t REG_DWORD /d 0 /f > nul 2>&1
echo.
echo Operation completed.
goto datacollection

:telen13
echo.
echo --------------------------------------------------------------------------------
echo.
echo This will enable Data Collection and Telemetry Services for Windows 10.
echo.
CHOICE /C YN /M "Do you want to continue"
IF ERRORLEVEL 2 goto datacollection
sc config dmwappushservice start= auto > nul 2>&1
sc start "dmwappushservice" > nul 2>&1
sc config diagtrack start= auto > nul 2>&1
sc start "DiagTrack" > nul 2>&1
start reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection /v AllowTelemetry /t REG_DWORD /d 1 /f > nul 2>&1
start reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection /v AllowTelemetry /t REG_DWORD /d 1 /f > nul 2>&1
ping localhost -n 5 > nul
reg delete HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection /f > nul 2>&1
echo.
echo Operation completed.
goto datacollection


:sabredate
cls
color 0F
echo --------------------------------------------------------------------------------
echo.
echo Warning: This command will update everything on your computer, so your computer should be on until it is finished.
echo.
CHOICE /C YN /M "Do you want to continue"
IF ERRORLEVEL 2 goto networks
echo.
echo --------------------------------------------------------------------------------
echo.
echo Please wait...
winget upgrade --all
echo.
echo Operation completed.
timeout /t 2
goto networks

:Chrome
@echo off
cls
color 0F
echo --------------------------------------------------------------------------------
echo.
echo This command will clear Google Chrome browsing data.
echo.
tasklist /FI "IMAGENAME eq chrome.exe" 2>NUL | find /I /N "chrome.exe">NUL
if %ERRORLEVEL% EQU 0 goto choice
if %ERRORLEVEL% NEQ 0 goto clean

:clean
rem Using %LOCALAPPDATA% to ensure compatibility across Windows versions
cd /d "%LOCALAPPDATA%\Google\Chrome\User Data\Default"

echo Deleting browsing data...
del /q archiv~1 > nul 2>&1
del /q archiv~2 > nul 2>&1
del /q curren~1 > nul 2>&1
del /q curren~2 > nul 2>&1
del /q history > nul 2>&1
del /q histor~1 > nul 2>&1
del /q histor~2 > nul 2>&1
del /q histor~3 > nul 2>&1
del /q histor~4 > nul 2>&1
del /q lastse~1 > nul 2>&1
del /q lastta~1 > nul 2>&1
del /q topsit~1 > nul 2>&1
del /q topsit~2 > nul 2>&1
del /q visite~1 > nul 2>&1

rem Removing specific directories
rd /s /q Cache > nul 2>&1
rd /s /q "Media Cache" > nul 2>&1
rd /s /q "Local Storage" > nul 2>&1
rd /s /q GPUCache > nul 2>&1

rem Recreate directories
md Cache
md "Media Cache"
md "Local Storage"
md GPUCache

rem Deleting additional data files
del /s /q "Web Data" > nul 2>&1
del /s /q "Web Data-journal" > nul 2>&1
del /s /q "Cookies" > nul 2>&1
del /s /q "Cookies-journal" > nul 2>&1
del /s /q "Favicons" > nul 2>&1
del /s /q "Favicons-journal" > nul 2>&1

echo.
echo Google Chrome browsing data deleted successfully.
echo Press any key to exit...
pause > nul
exit

:choice
echo.
CHOICE /C EH /M "Google Chrome is currently running. Would you like to terminate it now? (E = Yes / H = No)"
if %errorlevel% equ 1 goto kill
if %errorlevel% equ 2 goto :eof

:kill
echo Terminating Chrome...
taskkill /im chrome.exe /f > nul 2>&1
timeout /t 2 >nul
goto clean




REM -------------------------------------------------------------------
REM NETWORKS GENEL MENÜ BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------

:netboot
shutdown /r /t 0
exit

