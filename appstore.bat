:appstore
cls
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a:%%b)
title AppStore
cls
echo --------------------------------------------------------------------------------
echo                    Welcome to App Store     %mydate% - %mytime%
echo --------------------------------------------------------------------------------
echo.
echo.
echo   █████╗ ██████╗ ██████╗ ███████╗████████╗ ██████╗ ██████╗ ███████╗
echo   ██╔══██╗██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
echo   ███████║██████╔╝██████╔╝███████╗   ██║   ██║   ██║██████╔╝█████╗  
echo   ██╔══██║██╔═══╝ ██╔═══╝ ╚════██║   ██║   ██║   ██║██╔══██╗██╔══╝  
echo   ██║  ██║██║     ██║     ███████║   ██║   ╚██████╔╝██║  ██║███████╗
echo   ╚═╝  ╚═╝╚═╝     ╚═╝     ╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝
echo.
echo Please choose operation would you like to perform?
echo.
echo  [0] Back to menu
echo  [1] Gaming
echo  [2] Developers
echo  [3] Search for what you want
echo  [4] 
echo.
set /p "select=Select:"
if %select% == 0  goto menu
if %select% == 1  goto gaming
if %select% == 2  goto developers
if %select% == 3  goto mainloop

cls
goto appstore

REM -------------------------------------------------------------------
REM APPSTORE MENÜ BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------

REM -------------------------------------------------------------------
REM GAMİNG MENÜ BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------

:gaming
cls
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a:%%b)
title Gaming Tools
:gaming
cls
echo --------------------------------------------------------------------------------
echo                    Welcome to Gaming Tools    %mydate% - %mytime%
echo --------------------------------------------------------------------------------
echo.
color 0A
echo Please choose operation would you like to perform?
echo.
echo  [0] Back to menu
echo  [1] Steam
echo  [2] Discord
echo  [3] Epic Games
echo  [4] Playnite
echo  [5] Moonlight 
echo  [6] EA App		
echo  [7] Origin

set /p "select=Select:"
if %select% == 0  goto appstore
if %select% == 1  goto steam
if %select% == 2  goto discord
if %select% == 3  goto epicgames
if %select% == 4  goto playnite 
if %select% == 5  goto moonlight
if %select% == 6  goto eapp
if %select% == 7  goto origin
cls
goto gaming

:steam
echo The Steam tool will start downloading soon.
winget install --id=Valve.Steam  -e
echo Downloading successfully.
echo.
timeout /t 5
goto gaming

:discord
echo The Discord tool will start downloading soon.
winget install --id=Discord.Discord  -e
echo Downloading successfully.
echo.
timeout /t 5
goto gaming

:epicgames
echo The EpicGames tool will start downloading soon.
winget install --id=EpicGames.EpicGamesLauncher  -e
echo Downloading successfully.
echo.
timeout /t 5
goto gaming

:playnite
echo The Playnite tool will start downloading soon.
winget install --id=Playnite.Playnite  -e
echo Downloading successfully.
echo.
timeout /t 5
goto gaming

:moonlight
echo The MoonlightGameStreamingProject tool will start downloading soon.
winget install --id=MoonlightGameStreamingProject.Moonlight  -e
echo Downloading successfully.
echo.
timeout /t 5
goto gaming

:eapp
echo The ElectronicArts tool will start downloading soon.
winget install --id=ElectronicArts.EADesktop  -e
echo Downloading successfully.
echo.
timeout /t 5
goto gaming

:origin
echo The Origin tool will start downloading soon.
winget install --id=ElectronicArts.Origin  -e
echo Downloading successfully.
echo.
timeout /t 5
goto gaming

REM -------------------------------------------------------------------
REM GAMİNG MENÜ BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------


REM -------------------------------------------------------------------
REM DELELOPERS MENÜ BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------


:developers
cls
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a:%%b)
title Gaming Tools
:developers
cls
echo --------------------------------------------------------------------------------
echo                    Welcome to Developers Tools    %mydate% - %mytime%
echo --------------------------------------------------------------------------------
echo.
color 0A
echo Please choose operation would you like to perform?
echo.
echo  [0] Back to menu
echo  [1] Java Tools
echo  [2] C# Tools
echo  [3] Python Tools

set /p "select=Select:"
if %select% == 0  goto appstore
if %select% == 1  goto java
if %select% == 2  goto C#
if %select% == 3  goto python
if %select% == 4  goto 
if %select% == 5  goto 

cls
goto developers

REM -------------------------------------------------------------------
REM DELELOPERS MENÜ BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------


REM -------------------------------------------------------------------
REM JAVA BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------

:java
cls
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a:%%b)
title JavaTools
:java
cls
echo --------------------------------------------------------------------------------
echo                    Welcome to Java Tools    %mydate% - %mytime%
echo --------------------------------------------------------------------------------
echo.
color 0A
echo Please choose operation would you like to perform?
echo.
echo  [0] Back to menu
echo  [1] IntelliJ IDEA Community Edition
echo  [2] Microsoft Visual Studio Code
echo  [3] Eclipse (link)
echo  [4] Java JDK

set /p "select=Select:"
if %select% == 0  goto developers
if %select% == 1  goto IntelliJ
if %select% == 2  goto VisualStudioCode
if %select% == 3  goto Eclipse
if %select% == 4  goto javajdk
cls
goto java


:IntelliJ
echo The IntelliJ IDEA Community Edition tool will start downloading soon.
winget install --id=JetBrains.IntelliJIDEA.Community  -e
echo Downloading successfully.
echo.
timeout /t 5
goto java


:VisualStudioCode
echo The Microsoft Visual Studio Code tool will start downloading soon.
winget install --id=Microsoft.VisualStudioCode  -e
echo Downloading successfully.
echo.
timeout /t 5
goto java

:eclipse
echo The Eclipse tool will start downloading soon.
start chrome https://www.eclipse.org/downloads/
echo Downloading successfully.
echo.
timeout /t 5
goto java

:javajdk
echo Java JDK tool will start downloading soon.
start chrome https://www.java.com/en/download/help/windows_manual_download.html
echo Downloading successfully.
echo.
timeout /t 5
goto java


REM -------------------------------------------------------------------
REM JAVA BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------


REM -------------------------------------------------------------------
REM C# BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------

:C#
cls
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a:%%b)
title C#Tools
:C#
cls
echo --------------------------------------------------------------------------------
echo                    Welcome to C# Tools    %mydate% - %mytime%
echo --------------------------------------------------------------------------------
echo.
color 0A
echo Please choose operation would you like to perform?
echo.
echo  [0] Back to menu
echo  [1] Visual Studio Code
echo  [2] Notepad++
echo  [3] Microsoft .NET Framework 4.5.1 Developer Pack
echo  [4] .NET Framework

set /p "select=Select:"
if %select% == 0  goto developers
if %select% == 1  goto VisualStudioCode
if %select% == 2  goto notepad++
if %select% == 3  goto developerpack
if %select% == 4  goto netframework
cls
goto C#

:VisualStudioCode
echo The Microsoft Visual Studio Code tool will start downloading soon.
winget install --id=Microsoft.VisualStudioCode  -e
echo Downloading successfully.
echo.
timeout /t 5
goto C#

:notepad++
echo Notepad++ tool will start downloading soon.
winget install --id=Notepad++.Notepad++  -e
echo Downloading successfully.
echo.
timeout /t 5
goto C#

:developerpack
echo Microsoft .NET Framework 4.5.1 Developer Pack tool will start downloading soon.
winget install --id=Microsoft.DotNet.Framework.DeveloperPack.4.5  -e
echo Downloading successfully.
echo.
timeout /t 5
goto C#

:netframework
echo .NET Framework tool will start downloading soon.
winget install --id=Microsoft.DotNet.Framework.DeveloperPack_4  -e
echo Downloading successfully.
echo.
timeout /t 5
goto C#

REM -------------------------------------------------------------------
REM C# BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------

REM -------------------------------------------------------------------
REM PYTHON BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------

:python
cls
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a:%%b)
title PythonTools
:python
cls
echo --------------------------------------------------------------------------------
echo                    Welcome to Python Tools    %mydate% - %mytime%
echo --------------------------------------------------------------------------------
echo.
color 0A
echo Please choose operation would you like to perform?
echo.
echo  [0] Back to menu
echo  [1] Python Versions
echo  [2] Visual Studio Code
echo  [3] PyCharm Community Edition
echo  [4] Spyder
echo  [5] Sublime Text 3
echo  [6] Atom 
echo  [7] JupyterLab

set /p "select=Select:"
if %select% == 0  goto developers
if %select% == 1  goto pythonversions
if %select% == 2  goto VisualStudioCode
if %select% == 3  goto PyCharm
if %select% == 4  goto Spyder
if %select% == 5  goto sublimetext3
if %select% == 6  goto atom 
if %select% == 7  goto JupyterLab
cls
goto python


:VisualStudioCode
echo The Microsoft Visual Studio Code tool will start downloading soon.
winget install --id=Microsoft.VisualStudioCode  -e
echo Downloading successfully.
echo.
timeout /t 5
goto C#

:PyCharm
echo PyCharm tool will start downloading soon.
winget install --id=JetBrains.PyCharm.Community  -e
echo Downloading successfully.
echo.
timeout /t 5
goto C#

:Spyder
echo Spyder tool will start downloading soon.
winget install --id=Spyder.Spyder  -e
echo Downloading successfully.
echo.
timeout /t 5
goto C#

:sublimetext3
echo Sublime Text 3 tool will start downloading soon.
winget install --id=SublimeHQ.SublimeText.3  -e
echo Downloading successfully.
echo.
timeout /t 5
goto C#

:atom
echo Atom Text 3 tool will start downloading soon.
winget install --id=GitHub.Atom  -e
echo Downloading successfully.
echo.
timeout /t 5
goto C#

:JupyterLab
echo JupyterLab Text 3 tool will start downloading soon.
winget install --id=ProjectJupyter.JupyterLab  -e
echo Downloading successfully.
echo.
timeout /t 5
goto C#

REM -------------------------------------------------------------------
REM PYTHON VERSİONS MENÜ BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------

:pythonversions
cls
title pythonversions
:pythonversions
cls
color 0A
echo Please choose operation would you like to perform?
echo.
echo  [0] Back to menu
echo  [1] Ptyhon 2
echo  [2] Python 3.3
echo  [3] Python 3.4
echo  [4] Python 3.7

set /p "select=Select:"
if %select% == 0  goto python
if %select% == 1  goto python2
if %select% == 2  goto python33
if %select% == 3  goto python34
if %select% == 4  goto python37
cls
goto pythonversions

:python2
echo Ptyhon 2 will start downloading soon.
winget install --id=Python.Python.2  -e
echo Downloading successfully.
echo.
timeout /t 5
goto pythonversions

:python33
echo Python 3.3 will start downloading soon.
winget install --id=Python.Python.3.3  -e
echo Downloading successfully.
echo.
timeout /t 5
goto pythonversions

:python34
echo Python 3.4 will start downloading soon.
winget install --id=Python.Python.3.4  -e
echo Downloading successfully.
echo.
timeout /t 5
goto pythonversions

:python37
echo Python 3.7 will start downloading soon.
winget install --id=Python.Python.3.7  -e
echo Downloading successfully.
echo.
timeout /t 5
goto pythonversions

REM -------------------------------------------------------------------
REM PYTHON VERSİONS MENÜ BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------

REM -------------------------------------------------------------------
REM PYTHON BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------


REM -------------------------------------------------------------------
REM APPLICATION SEARCH MENÜ BÖLÜMÜ BAŞLANGIÇ
REM -------------------------------------------------------------------

@echo off
:mainloop
cls
color 07
echo =====================================
echo =          Application Search       =
echo 		 Created by Mert ALTUNTAS 
echo =====================================
echo.
set /p app_name=Enter the name of the application you want to search (press 'q' to quit): 
if /i "%app_name%"=="q" (
    color 0C
    echo Exiting... Thank you for using the application.
    color 07
    pause
    exit
)

:: Perform application search
echo.
echo Searching for applications, please wait...
echo.
winget search "%app_name%"
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo Error: Unable to perform search. Please check your input and try again.
    color 07
    pause
    goto mainloop
)

:install_prompt
echo.
set /p install_choice=Do you want to install the found application? (y/n, 'q' to quit): 
if /i "%install_choice%"=="q" (
    color 0C
    echo Exiting... Thank you for using the application.
    color 07
    pause
    exit
) else if /i "%install_choice%"=="y" (
    set /p install_name=Enter the exact name or ID of the application you want to install: 

    :: Check installed applications
    echo Checking installed applications...
    winget list > installed_apps.txt
    if %errorlevel% neq 0 (
        color 0C
        echo Error: Unable to list installed applications.
        color 07
        del installed_apps.txt >nul 2>&1
        pause
        goto mainloop
    )

    :: Check if the application is already installed
    findstr /i /c:"%install_name%" installed_apps.txt >nul
    if %errorlevel% equ 0 (
        color 0E
        echo.
        echo "%install_name%" is already installed!
        del installed_apps.txt >nul 2>&1
        pause
        goto mainloop
    )

    del installed_apps.txt >nul 2>&1
    echo.
    echo Installing "%install_name%", please wait...
    winget install "%install_name%"
    if %errorlevel% equ 0 (
        color 0A
        echo.
        echo Installation successful: "%install_name%"!
    ) else (
        color 0C
        echo.
        echo Error: Unable to install "%install_name%". Please check the application name or ID.
    )
    color 07
    pause
    goto mainloop
) else if /i "%install_choice%"=="n" (
    goto mainloop
) else (
    color 0C
    echo Invalid input. Please enter 'y', 'n', or 'q'.
    color 07
    pause
    goto install_prompt
)

:end
color 07
echo Exited. Have a great day!
pause
exit



REM -------------------------------------------------------------------
REM APPLICATION SEARCH MENÜ BİTİŞ
REM -------------------------------------------------------------------





REM -------------------------------------------------------------------
REM APPSTORE GENEL MENÜ BÖLÜMÜ BİTİŞ
REM -------------------------------------------------------------------

