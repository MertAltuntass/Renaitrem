:soul
cls
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a:%%b)
title SOUL
cls
echo --------------------------------------------------------------------------------
echo                    Welcome to SOUL    %mydate% - %mytime%
echo --------------------------------------------------------------------------------
echo.
echo.
echo "███████╗ ██████╗ ██╗   ██╗██╗     
echo "██╔════╝██╔═══██╗██║   ██║██║     
echo "███████╗██║   ██║██║   ██║██║     
echo "╚════██║██║   ██║██║   ██║██║     
echo "███████║╚██████╔╝╚██████╔╝███████╗
echo "╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝
echo.

echo "Soul - Has come to light the fire of that missing excitement in your soul. :)"
echo "============================================================="
echo "SmbBruteForce is a program that can be used to collect usernames and passwords of servers using SMB (Samba) by brute force attack."
echo " I am not responsible for the out of context usage of this program. Use only for pentesting. I am not going to visit you in jail. "
echo " How to use SOUL ? "
echo " .\Soul.ps1 127.0.0.1 this means that you can write any ip address you want here :) "
echo " If you're ready, we can start. Please You can press enter. :)"
pause


