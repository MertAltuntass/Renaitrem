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
REM Sabre .bat BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------

taskkil explorer.exe

For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a:%%b)
title Overkill
echo --------------------------------------------------------------------------------
echo                       RenaitreSabre     %mydate% - %mytime%
echo --------------------------------------------------------------------------------
echo.
echo ">>======================================================<<";
echo "|| ________  ________  ________  ________  _______      ||";
echo "|||\   ____\|\   __  \|\   __  \|\   __  \|\  ___ \     ||";
echo "||\ \  \___|\ \  \|\  \ \  \|\ /\ \  \|\  \ \   __/|    ||";
echo "|| \ \_____  \ \   __  \ \   __  \ \   _  _\ \  \_|/__  ||";
echo "||  \|____|\  \ \  \ \  \ \  \|\  \ \  \\  \\ \  \_|\ \ ||";
echo "||    ____\_\  \ \__\ \__\ \_______\ \__\\ _\\ \_______\||";
echo "||   |\_________\|__|\|__|\|_______|\|__|\|__|\|_______|||";
echo "||   \|_________|                                       ||";
echo ">>======================================================<<";
echo.
color 3
@echo off
echo " The bat file you are using deletes whatever is available in the computer, and it is not possible to return the deleted files, it is the responsibility of the person using it and no responsibility is accepted by me in any data loss. !!!!Press any key and the process will start, if you don't want to continue close the corresponding .bat file. !!!!"

echo "Bu bat dosyası bilgisayarda bulunan her şeyi siler ve silinen dosyaların geri dönüşü mümkün değildir. Bu işlemi kullanan kişi sorumludur ve herhangi bir veri kaybında tarafımca hiçbir sorumluluk kabul edilmez."

pause >nul

REM -------------------------------------------------------------------
REM Sabre .bat BÖLÜMÜ UYARI SONRASI İŞLEMLERİN BAŞLANGICI
REM -------------------------------------------------------------------

set "log_folder=%userprofile%\Desktop\loglar"
set "log_file=%log_folder%\silinen_dosyalar.txt"

if not exist "%log_folder%" mkdir "%log_folder%"
if exist "%log_file%" del "%log_file%"

set "folders_to_clean=%SystemDrive%\*.old %SystemDrive%\*.bak %SystemDrive%\*.log %SystemDrive%\*.tmp %SystemDrive%\*.chk %WinDir%\Temp\*.* %userprofile%\appdata\local\temp\*.* %WinDir%\Prefetch\*.* %WinDir%\Driver Cache\i386\*.* %WinDir%\system32\dllcache\*.* %systemdrive%\WINDOWS\$hf_mig$\*.* %systemdrive%\WINDOWS\Driver Cache\*.* %systemdrive%\WINDOWS\addins\*.* %systemdrive%\WINDOWS\LastGood\*.* %systemdrive%\WINDOWS\Offline Web Pages\*.* %systemdrive%\WINDOWS\$NtServicePackUninstall$\*.* %systemdrive%\WINDOWS\Provisioning\*.* %systemdrive%\WINDOWS\ServicePackFiles\*.* %systemdrive%\WINDOWS\Web\*.* %systemdrive%\WINDOWS\Connection Wizard\*.* %systemdrive%\WINDOWS\EHome\*.* %systemdrive%\WINDOWS\Assembly\*.* %systemdrive%\WINDOWS\SoftwareDistribution\Download\*.* %systemdrive%\WINDOWS\mui\*.* %systemdrive%\WINDOWS\Config\*.* %systemdrive%\WINDOWS\msapps\*.* %systemdrive%\RECYCLER*.*"

for %%i in (%folders_to_clean%) do (
    echo Temizleniyor: %%i
    del /f /q /s "%%i" >> "%log_file%" 2>&1
    if errorlevel 1 (
        echo Hata: %%i temizlenemedi. >> "%log_file%"
    ) else (
        echo Başarılı: %%i temizlendi. >> "%log_file%"
    )
)
echo Temizlik işlemi tamamlandı. Tüm detaylar '%log_file%' dosyasında kaydedildi.


@echo. Restore Contacts
if not exist "%UserProfile%\Contacts" mkdir "%UserProfile%\Contacts"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "{56784854-C6CB-462B-8169-88E350ACB882}" /t REG_SZ /d "C:\Users\%USERNAME%\Contacts" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "{56784854-C6CB-462B-8169-88E350ACB882}" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Contacts" /f
echo Kayıt defteri girdileri eklendi.
attrib +r -s -h "%USERPROFILE%\Contacts" /S /D
echo Contacts klasörü öznitelikleri ayarlandı.
timeout /t 1 /nobreak >nul
echo İşlem tamamlandı.

@echo. Restore Desktop
if not exist "%UserProfile%\Desktop" mkdir "%UserProfile%\Desktop"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Desktop" /t REG_SZ /d "C:\Users\%USERNAME%\Desktop" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "Desktop" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Desktop" /f
echo Desktop girdileri eklendi.
attrib +r -s -h "%USERPROFILE%\Desktop" /S /D
echo Desktop klasörü öznitelikleri ayarlandı.
timeout /t 1 /nobreak >nul
echo İşlem tamamlandı.

@echo. Restore Documents
if not exist "%UserProfile%\Documents" mkdir "%UserProfile%\Documents"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Personal" /t REG_SZ /d "C:\Users\%USERNAME%\Documents" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "{f42ee2d3-909f-4907-8871-4c22fc0bf756}" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Documents" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "Personal" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Documents" /f
echo Documents girdileri eklendi.
attrib +r -s -h "%USERPROFILE%\Documents" /S /D
echo Documents klasörü öznitelikleri ayarlandı.
timeout /t 1 /nobreak >nul
echo İşlem tamamlandı.


@echo. Restore Downloads
if not exist "%UserProfile%\Downloads" mkdir "%UserProfile%\Downloads"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "{374DE290-123F-4565-9164-39C4925E467B}" /t REG_SZ /d "C:\Users\%USERNAME%\Downloads" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "{374DE290-123F-4565-9164-39C4925E467B}" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Downloads" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "{7D83EE9B-2244-4E70-B1F5-5393042AF1E4}" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Downloads" /f
echo Downloads girdileri eklendi.
attrib +r -s -h "%USERPROFILE%\Downloads" /S /D
echo Downloads klasörü öznitelikleri ayarlandı.
timeout /t 1 /nobreak >nul
echo İşlem tamamlandı.


@echo. Restore Favorites
if not exist "%UserProfile%\Favorites" mkdir "%UserProfile%\Favorites"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Favorites" /t REG_SZ /d "C:\Users\%USERNAME%\Favorites" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "Favorites" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Favorites" /f
echo Favorites girdileri eklendi.
attrib +r -s -h "%USERPROFILE%\Favorites" /S /D
echo Favorites klasörü öznitelikleri ayarlandı.
timeout /t 1 /nobreak >nul
echo İşlem tamamlandı.

@echo. Restore Links
if not exist "%UserProfile%\Links" mkdir "%UserProfile%\Links"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "{BFB9D5E0-C6A9-404C-B2B2-AE6DB6AF4968}" /t REG_SZ /d "C:\Users\%USERNAME%\Links" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "{BFB9D5E0-C6A9-404C-B2B2-AE6DB6AF4968}" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Links" /f
echo  Links girdileri eklendi.
attrib +r -s -h "%USERPROFILE%\Links" /S /D
echo  Links klasörü öznitelikleri ayarlandı.
timeout /t 1 /nobreak >nul
echo İşlem tamamlandı.

@echo. Restore Music
if not exist "%UserProfile%\Music" mkdir "%UserProfile%\Music"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "My Music" /t REG_SZ /d "C:\Users\%USERNAME%\Music" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "{A0C69A99-21C8-4671-8703-7934162FCF1D}" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Music" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Music" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Music" /f
echo  Music girdileri eklendi.
attrib +r -s -h "%USERPROFILE%\Music" /S /D
echo  Music klasörü öznitelikleri ayarlandı.
timeout /t 1 /nobreak >nul
echo İşlem tamamlandı.

@echo. Restore Pictures
if not exist "%UserProfile%\Pictures" mkdir "%UserProfile%\Pictures"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "My Pictures" /t REG_SZ /d "C:\Users\%USERNAME%\Pictures" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "{0DDD015D-B06C-45D5-8C4C-F59713854639}" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Pictures" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Pictures" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Pictures" /f
echo  Pictures girdileri eklendi.
attrib +r -s -h "%USERPROFILE%\Pictures" /S /D
echo  Pictures klasörü öznitelikleri ayarlandı.
timeout /t 1 /nobreak >nul
echo İşlem tamamlandı.


@echo. Restore Saved Games
if not exist "%UserProfile%\Saved Games" mkdir "%UserProfile%\Saved Games"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "{4C5C32FF-BB9D-43B0-B5B4-2D72E54EAAA4}" /t REG_SZ /d "C:\Users\%USERNAME%\Saved Games" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "{4C5C32FF-BB9D-43B0-B5B4-2D72E54EAAA4}" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Saved Games" /f
echo  Saved Games girdileri eklendi.
attrib +r -s -h "%USERPROFILE%\Saved Games" /S /D
echo  Saved Games klasörü öznitelikleri ayarlandı.
timeout /t 1 /nobreak >nul
echo İşlem tamamlandı.

@echo. Restore Searches
if not exist "%UserProfile%\Searches" mkdir "%UserProfile%\Searches"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "{7D1D3A04-DEBB-4115-95CF-2F29DA2920DA}" /t REG_SZ /d "C:\Users\%USERNAME%\Searches" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "{7D1D3A04-DEBB-4115-95CF-2F29DA2920DA}" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Searches" /f
echo  Searches girdileri eklendi.
attrib +r -s -h "%USERPROFILE%\Searches" /S /D
echo  Searches klasörü öznitelikleri ayarlandı.
timeout /t 1 /nobreak >nul
echo İşlem tamamlandı.

@echo. Restore Videos
if not exist "%UserProfile%\Videos" mkdir "%UserProfile%\Videos"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "My Video" /t REG_SZ /d "C:\Users\%USERNAME%\Videos" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "{35286A68-3C57-41A1-BBB1-0EAE73D76C95}" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Videos" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Video" /t REG_EXPAND_SZ /d %%USERPROFILE%%"\Videos" /f
echo  Videos girdileri eklendi.
attrib +r -s -h "%USERPROFILE%\Videos" /S /D
echo  Videos klasörü öznitelikleri ayarlandı.
timeout /t 1 /nobreak >nul
echo İşlem tamamlandı.

echo Reset Windows Update Policies

:: Reset Windows Update policies
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\WindowsUpdate" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\WindowsUpdate" /f
echo Grup politikası ayarlarını günceller ve değişikliklerin hemen uygulanmasını sağlar.
gpupdate /force

:: Reset the BITS service and the Windows Update service to the default security descriptor
sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)
sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)

:: Reregister the BITS files and the Windows Update files
cd /d %windir%\system32
regsvr32.exe /s atl.dll 
regsvr32.exe /s urlmon.dll 
regsvr32.exe /s mshtml.dll 
regsvr32.exe /s shdocvw.dll 
regsvr32.exe /s browseui.dll 
regsvr32.exe /s jscript.dll 
regsvr32.exe /s vbscript.dll 
regsvr32.exe /s scrrun.dll 
regsvr32.exe /s msxml.dll 
regsvr32.exe /s msxml3.dll 
regsvr32.exe /s msxml6.dll 
regsvr32.exe /s actxprxy.dll 
regsvr32.exe /s softpub.dll 
regsvr32.exe /s wintrust.dll 
regsvr32.exe /s dssenh.dll 
regsvr32.exe /s rsaenh.dll 
regsvr32.exe /s gpkcsp.dll 
regsvr32.exe /s sccbase.dll 
regsvr32.exe /s slbcsp.dll 
regsvr32.exe /s cryptdlg.dll 
regsvr32.exe /s oleaut32.dll 
regsvr32.exe /s ole32.dll 
regsvr32.exe /s shell32.dll 
regsvr32.exe /s initpki.dll 
regsvr32.exe /s wuapi.dll 
regsvr32.exe /s wuaueng.dll 
regsvr32.exe /s wuaueng1.dll 
regsvr32.exe /s wucltui.dll 
regsvr32.exe /s wups.dll 
regsvr32.exe /s wups2.dll 
regsvr32.exe /s wuweb.dll 
regsvr32.exe /s qmgr.dll 
regsvr32.exe /s qmgrprxy.dll 
regsvr32.exe /s wucltux.dll 
regsvr32.exe /s muweb.dll 
regsvr32.exe /s wuwebv.dll
regsvr32.exe /s wudriver.dll
netsh winsock reset
netsh winsock reset proxy
:: Set the startup type as automatic
sc config wuauserv start= auto
sc config bits start= auto 
sc config DcomLaunch start= auto 
:Start
net start bits
net start wuauserv
net start appidsvc
net start cryptsvc

c:
cd c:\windows\temp
del *.* /f/q/s
cd c:\windows\prefetch
del *.* /f/q/s
cd ..
cd..
del *.tmp /f/q/s
del *.bak /f/q/s
del *.old /f/q/s
del *.log /f/q/s

color 4
echo ====...**...**...====

echo  " Tüm işlemler başarıyla tamamlanmıştır :) klavyenizden "m" harfine bastığınızda sistem tamamen kapanacaktır. " 

echo  " All operations have been completed successfully :) press the letter "m" on your keyboard and the system will shut down completely. "
echo.
echo [m] Exit
set /p "select=Select:"
if %select% ==m exit > nul 2>&1
if %select% ==M exit > nul 2>&1
cls


REM -------------------------------------------------------------------
REM Sabre .bat BÖLÜMÜ UYARI SONRASI İŞLEMLERİN BİTİŞİ
REM -------------------------------------------------------------------

REM -------------------------------------------------------------------
REM Sabre .bat BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------
