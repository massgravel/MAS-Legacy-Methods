@setlocal DisableDelayedExpansion
@echo off



::============================================================================
::
::   This script is a part of 'Microsoft Activation Scripts' (MAS) project.
::
::   Homepage: massgrave.dev
::      Email: windowsaddict@protonmail.com
::
::============================================================================



::  To activate, run the script with "/HWID" parameter or change 0 to 1 in below line
set _act=0

::  To activate with LockBox method, run the script with "/HWID-Lockbox" parameter or change 0 to 1 in below line
set _lock=0

::  To disable changing edition if current edition doesn't support HWID activation, change the value to 1 from 0 or run the script with "/HWID-NoEditionChange" parameter
set _NoEditionChange=0

::  If value is changed in above lines or parameter is used then script will run in unattended mode



::========================================================================================================================================

:: Re-launch the script with x64 process if it was initiated by x86 process on x64 bit Windows
:: or with ARM64 process if it was initiated by x86/ARM32 process on ARM64 Windows

set "_cmdf=%~f0"
for %%# in (%*) do (
if /i "%%#"=="r1" set r1=1
if /i "%%#"=="r2" set r2=1
)

if exist %SystemRoot%\Sysnative\cmd.exe if not defined r1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %* r1"
exit /b
)

:: Re-launch the script with ARM32 process if it was initiated by x64 process on ARM64 Windows

if exist %SystemRoot%\SysArm32\cmd.exe if %PROCESSOR_ARCHITECTURE%==AMD64 if not defined r2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %* r2"
exit /b
)

::  Set Path variable, it helps if it is misconfigured in the system

set "PATH=%SystemRoot%\System32;%SystemRoot%\System32\wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "PATH=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%PATH%"
)

::  Check LF line ending

pushd "%~dp0"
>nul findstr /rxc:".*" "%~nx0"
if not %errorlevel%==0 (
echo:
echo Error: Script either has LF line ending issue, or it failed to read itself.
echo:
ping 127.0.0.1 -n 6 > nul
popd
exit /b
)
popd

::========================================================================================================================================

cls
color 07
title  HWID Activation

set _args=
set _elev=
set _unattended=0

set _args=%*
if defined _args set _args=%_args:"=%
if defined _args (
for %%A in (%_args%) do (
if /i "%%A"=="/HWID"                  set _act=1
if /i "%%A"=="/HWID-Lockbox"          set _lock=1
if /i "%%A"=="/HWID-NoEditionChange"  set _NoEditionChange=1
if /i "%%A"=="-el"                    set _elev=1
)
)

for %%A in (%_act% %_lock% %_NoEditionChange%) do (if "%%A"=="1" set _unattended=1)

::========================================================================================================================================

set winbuild=1
set "nul=>nul 2>&1"
set psc=powershell.exe
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G

set _NCS=1
if %winbuild% LSS 10586 set _NCS=0
if %winbuild% GEQ 10586 reg query "HKCU\Console" /v ForceV2 2>nul | find /i "0x0" 1>nul && (set _NCS=0)

if %_NCS% EQU 1 (
for /F %%a in ('echo prompt $E ^| cmd') do set "esc=%%a"
set     "Red="41;97m""
set    "Gray="100;97m""
set   "Green="42;97m""
set "Magenta="45;97m""
set  "_White="40;37m""
set  "_Green="40;92m""
set "_Yellow="40;93m""
) else (
set     "Red="Red" "white""
set    "Gray="Darkgray" "white""
set   "Green="DarkGreen" "white""
set "Magenta="Darkmagenta" "white""
set  "_White="Black" "Gray""
set  "_Green="Black" "Green""
set "_Yellow="Black" "Yellow""
)

set "nceline=echo: &echo ==== ERROR ==== &echo:"
set "eline=echo: &call :dk_color %Red% "==== ERROR ====" &echo:"
if %~z0 GEQ 200000 (set "_exitmsg=Go back") else (set "_exitmsg=Exit")

::========================================================================================================================================

if %winbuild% LSS 10240 (
%eline%
echo Unsupported OS version detected.
echo HWID Activation is supported only for Windows 10/11.
echo Use Online KMS Activation option.
goto dk_done
)

if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" (
%eline%
echo HWID Activation is not supported for Windows Server.
echo Use KMS38 or Online KMS Activation option.
goto dk_done
)

for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" (
%nceline%
echo Unable to find powershell.exe in the system.
goto dk_done
)

::========================================================================================================================================

::  Fix for the special characters limitation in path name

set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"

set "_batf=%~f0"
set "_batp=%_batf:'=''%"

set _PSarg="""%~f0""" -el %_args%

set "_ttemp=%temp%"

setlocal EnableDelayedExpansion

::========================================================================================================================================

echo "!_batf!" | find /i "!_ttemp!" 1>nul && (
if /i not "!_work!"=="!_ttemp!" (
%eline%
echo Script is launched from the temp folder,
echo Most likely you are running the script directly from the archive file.
echo:
echo Extract the archive file and launch the script from the extracted folder.
goto dk_done
)
)

::========================================================================================================================================

::  Elevate script as admin and pass arguments and preventing loop

>nul fltmc || (
if not defined _elev %nul% %psc% "start cmd.exe -arg '/c \"!_PSarg:'=''!\"' -verb runas" && exit /b
%eline%
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'.
goto dk_done
)

::========================================================================================================================================

:dl_menu

if %_unattended%==0 (
cls
mode 76, 25
title  HWID Activation

echo:
echo:
echo:
echo:
echo         ____________________________________________________________
echo:
if !_lock!==0 (
call :dk_color2 %_White% "                [1] HWID Activation     " %_Green% "  [Downlevel Method]"
) else (
call :dk_color2 %_White% "                [1] HWID Activation       " %_Yellow% "  [LockBox Method]"
)
echo                 ____________________________________________
echo:      
echo                 [C] Change Method
echo:
echo                 [0] %_exitmsg%
echo         ____________________________________________________________
echo: 
call :dk_color2 %_White% "              " %_Green% "Enter a menu option in the Keyboard:"
choice /C:1C0 /N
set _el=!errorlevel!
if !_el!==3  exit /b
if !_el!==2  (
if !_lock!==0 (
set _lock=1
) else (
set _lock=0
)
cls
echo:
call :dk_color %_Green% " Downlevel Method:"
echo  It creates downlevelGTkey ticket for activation with simplest process.
echo:
call :dk_color %_Yellow% " LockBox Method:"
echo  It creates clientLockboxKey ticket which better mimics genuine activation,
echo  But requires more steps such as,
echo  - Cleaning ClipSVC licences
echo  - Deleting a volatile and protected registry key by taking ownership
echo  - System may need a restart for succesful activation
echo  - Microsoft Account and Store Apps may need relogin-restart in the system
echo:
call :dk_color2 %_White% " " %Green% "Note:"
echo  Microsoft accepts both types of tickets and that's unlikely to change.
echo  On a production system we suggest to use Downlevel [default] Method.
echo:
call :dk_color %_Yellow% " Press any key to go back..."
pause >nul
goto :dl_menu
)
if !_el!==1  goto :dl_menu2
goto :dl_menu
)

:dl_menu2

cls
mode 102, 38
set _title=title  HWID Activation
if %_lock%==0 (%_title% [Downlevel Method]) else (%_title% [Lockbox Method])

::========================================================================================================================================

echo:
echo Initializing...
call :dk_product
call :dk_ckeckwmic

::  Show info for potential script stuck scenario

sc start sppsvc %nul%
if %errorlevel% NEQ 1056 if %errorlevel% NEQ 0 (
echo:
echo Error code: %errorlevel%
call :dk_color %Red% "Failed to start [sppsvc] service, rest of the process may take a long time..."
echo:
)

::========================================================================================================================================

::  Check if system is permanently activated or not

call :dk_checkperm
if defined _perm (
cls
echo ___________________________________________________________________________________________
echo:
call :dk_color2 %_White% "     " %Green% "Checking: %winos% is Permanently Activated."
call :dk_color2 %_White% "     " %Gray% "Activation is not required."
echo ___________________________________________________________________________________________
if %_unattended%==1 goto dk_done
echo:
choice /C:10 /N /M ">    [1] Activate [0] %_exitmsg% : "
if errorlevel 2 exit /b
)
cls

::========================================================================================================================================

::  Check Windows Architecture 

set arch=
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do set arch=%%b

if not defined arch (
%eline%
echo Unable to detect Windows Architecture. Aborting...
goto dk_done
)

::========================================================================================================================================

::  Check files

set ARM64_file=
if /i "%arch%"=="ARM64" set ARM64_file=arm64_

for %%# in (%ARM64_file%gatherosstate.exe %ARM64_file%slc.dll) do (
if not exist "!_work!\BIN\%%#" (
%eline%
echo '%%#' file is missing in 'BIN' folder. Aborting...
goto dk_done
)
)

::  Verify gatherosstate.exe file

set _hash=
if /i "%arch%"=="ARM64" (set _orig=7E449AE5549A0D93CF65F4A1BB2AA7D1DC090D2D) else (set _orig=FABB5A0FC1E6A372219711152291339AF36ED0B5)
for /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile "!_work!\BIN\%ARM64_file%gatherosstate.exe" SHA1^|findstr /i /v CertUtil') do set "_hash=%%#"
set "_hash=%_hash: =%"

if /i not "%_hash%"=="%_orig%" (
%eline%
echo %ARM64_file%gatherosstate.exe SHA1 hash mismatch found.
echo:
echo Expected: %_orig%
echo Detected: %_hash%
goto dk_done
)

::========================================================================================================================================

::  Check Evaluation version

if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-*EvalEdition~*.mum" (
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionID 2>nul | find /i "Eval" 1>nul && (
%eline%
echo [%winos% ^| %winbuild%]
echo:
echo Evaluation Editions cannot be activated. 
echo You need to install full version of %winos%
echo:
echo Download it from here,
echo https://massgrave.dev/genuine-installation-media.html
goto dk_done
)
)

::========================================================================================================================================

::  Check SKU value / Check in multiple places to find Edition change corruption

set osSKU=
set regSKU=
set wmiSKU=

for /f "tokens=3 delims=." %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\ProductOptions" /v OSProductPfn 2^>nul') do set "regSKU=%%a"
if %_wmic% EQU 1 for /f "tokens=2 delims==" %%a in ('"wmic Path Win32_OperatingSystem Get OperatingSystemSKU /format:LIST" 2^>nul') do if not errorlevel 1 set "wmiSKU=%%a"
if %_wmic% EQU 0 for /f "tokens=1" %%a in ('%psc% "([WMI]'Win32_OperatingSystem=@').OperatingSystemSKU" 2^>nul') do if not errorlevel 1 set "wmiSKU=%%a"

set osSKU=%wmiSKU%
if not defined osSKU set osSKU=%regSKU%

if not defined osSKU (
%eline%
echo SKU value was not detected properly. Aborting...
goto dk_done
)

::========================================================================================================================================

set error=

cls
echo:
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do set arch=%%b
echo Checking OS Info                        [%winos% ^| %winbuild% ^| %arch%]

::  Check Internet connection

set _int=
for %%a in (l.root-servers.net resolver1.opendns.com download.windowsupdate.com google.com) do if not defined _int (
for /f "delims=[] tokens=2" %%# in ('ping -n 1 %%a') do (if not [%%#]==[] set _int=1)
)

if not defined _int (
%psc% "If([Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]'{DCB00C01-570F-4A9B-8D69-199FDBA5723B}')).IsConnectedToInternet){Exit 0}Else{Exit 1}"
if !errorlevel!==0 set _int=1
)

if defined _int (
echo Checking Internet Connection            [Connected]
) else (
set error=1
call :dk_color %Red% "Checking Internet Connection            [Not Connected]"
)

::========================================================================================================================================

::  Check Windows Script Host

set _WSH=1
reg query "HKCU\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _WSH=0)
reg query "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _WSH=0)

if %_WSH% EQU 0 (
reg add "HKLM\Software\Microsoft\Windows Script Host\Settings" /v Enabled /t REG_DWORD /d 1 /f %nul%
reg add "HKCU\Software\Microsoft\Windows Script Host\Settings" /v Enabled /t REG_DWORD /d 1 /f %nul%
if not "%arch%"=="x86" reg add "HKLM\Software\Microsoft\Windows Script Host\Settings" /v Enabled /t REG_DWORD /d 1 /f /reg:32 %nul%
echo Enabling Windows Script Host            [Successful]
)

::========================================================================================================================================

echo Initiating Diagnostic Tests...

set "_serv=ClipSVC wlidsvc sppsvc KeyIso LicenseManager Winmgmt wuauserv"

::  Client License Service (ClipSVC)
::  Microsoft Account Sign-in Assistant
::  Software Protection
::  CNG Key Isolation
::  Windows License Manager Service
::  Windows Management Instrumentation
::  Windows Update

call :dk_errorcheck

::  Check Windows updates and store app blockers

set updatesblock=
echo: %serv_ste% | findstr /i "wuauserv" %nul% && set updatesblock=1
for /f "skip=2 tokens=2*" %%a in ('reg query HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc /v Start 2^>nul') do if /i %%b equ 0x4 set updatesblock=1
if exist "%SystemRoot%\System32\WaaSMedicSvc.dll" (
for /f "skip=2 tokens=2*" %%a in ('reg query HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc /v Start 2^>nul') do if /i %%b equ 0x4 set updatesblock=1
)

reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer /v SettingsPageVisibility 2>nul | find /i "windowsupdate" %nul% && set updatesblock=1
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdateSysprepInProgress %nul% && set updatesblock=1
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /s 2>nul | findstr /i "NoAutoUpdate DisableWindowsUpdateAccess" %nul% && set updatesblock=1

if defined updatesblock (
call :dk_color %Gray% "Checking Windows Update Blockers        [Found]"
if defined applist echo: %serv_e% | find /i "wuauserv" %nul% && (
call :dk_color %Magenta% "Windows Update Service [wuauserv] is not working. Enable it incase if you have disabled it."
)
)

reg query "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableStoreApps 2>nul | find /i "0x1" %nul% && (
call :dk_color %Gray% "Checking Store App Blocker              [Found]"
)

::========================================================================================================================================

::  Detect Key

set key=
set altkey=
set changekey=
set curedition=
set altedition=
set notworking=
set actidnotfound=

for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v BuildBranch 2^>nul') do set "branch=%%b"

if defined applist call :hwiddata key attempt1
if not defined key call :hwiddata key attempt2

if defined notworking call :hwidfallback
if not defined key call :hwidfallback

if defined altkey (set key=%altkey%&set changekey=1&set notworking=)

if defined notworking if defined notfoundaltactID (
call :dk_color %Red% "Checking Alternate Edition For HWID     [%altedition% Activation ID Not Found]"
if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-*EvalEdition~*.mum" (
call :dk_color %Magenta% "Evaluation Windows Found. Install Full version of %winos%"
call :dk_color %Magenta% "Download it from https://massgrave.dev/genuine-installation-media.html"
)
)

if not defined key (
%eline%
echo [%winos% ^| %winbuild% ^| SKU:%osSKU%]
echo Unable to find this product in the supported product list.
echo Make sure you are using updated version of the script.
echo https://massgrave.dev
echo:
goto dk_done
)

if defined notworking set error=1

::========================================================================================================================================

::  Install key

echo:
if defined changekey (
call :dk_color %Magenta% "[%altedition%] Edition product key will be used to enable HWID activation."
echo:
)

if %_wmic% EQU 1 wmic path SoftwareLicensingService where __CLASS='SoftwareLicensingService' call InstallProductKey ProductKey="%key%" %nul%
if %_wmic% EQU 0 %psc% "(([WMISEARCHER]'SELECT Version FROM SoftwareLicensingService').Get()).InstallProductKey('%key%')" %nul%
if not %errorlevel%==0 cscript //nologo %windir%\system32\slmgr.vbs /ipk %key% %nul%
set errorcode=%errorlevel%
cmd /c exit /b %errorcode%
if %errorcode% NEQ 0 set "errorcode=[0x%=ExitCode%]"

if %errorcode% EQU 0 (
call :dk_refresh
echo Installing Generic Product Key          [%key%] [Successful]
) else (
call :dk_color %Red% "Installing Generic Product Key          [%key%] [Failed] %errorcode%"
if not defined error (
call :dk_color %Magenta% "In MAS, Goto Troubleshoot and run Fix Licensing option."
if defined actidnotfound call :dk_color %Red% "Activation ID not found for this key. Make sure you are using updated version of MAS."
set showfix=1
)
set error=1
)

::========================================================================================================================================

::  Files are copied to temp to generate ticket to avoid possible issues in case the path contains special character or non English names

echo:
set "temp_=%SystemRoot%\Temp\_Temp"
if exist "%temp_%\.*" rmdir /s /q "%temp_%\" %nul%
md "%temp_%\" %nul%

pushd "!_work!\BIN\"
copy /y /b "%ARM64_file%gatherosstate.exe" "%temp_%\gatherosstate.exe" %nul%
copy /y /b "%ARM64_file%slc.dll" "%temp_%\slc.dll" %nul%
popd

set copyf=
if not exist "%temp_%\gatherosstate.exe" set copyf=1
if not exist "%temp_%\slc.dll" set copyf=1

if defined copyf (
call :dk_color %Red% "Copying Required Files to Temp          [%temp_%] [Failed]"
goto :dl_final
) else (
echo Copying Required Files to Temp          [%temp_%] [Successful]
)

::========================================================================================================================================

::  Modify the Pfn value in gatherosstate with slc.dll as per the system, that way one gatherosstate can be used in all the editions

pushd "%temp_%\"
rundll32 "%temp_%\slc.dll",PatchGatherosstate %nul%
popd
if not exist "%temp_%\gatherosstatemodified.exe" (
call :dk_color %Red% "Creating Modified Gatherosstate         [Failed] Aborting..."
call :dk_color %Magenta% "Most likely Antivirus blocked the process, disable it and/or create proper exclsuions"
goto :dl_final
) else (
echo Creating Modified Gatherosstate         [Successful]
)

::========================================================================================================================================

::  Clean ClipSVC Licences
::  This code runs only if Lockbox method to generate ticket is manually set by the user in this script.

if %_lock%==1 (
for %%# in (ClipSVC) do (
sc query %%# | find /i "STOPPED" %nul% || net stop %%# /y %nul%
sc query %%# | find /i "STOPPED" %nul% || sc stop %%# %nul%
)

rundll32 clipc.dll,ClipCleanUpState

if %winbuild% LEQ 10240 (
echo Cleaning ClipSVC Licences               [Successful]
) else (
if exist "%ProgramData%\Microsoft\Windows\ClipSVC\tokens.dat" (
call :dk_color %Red% "Cleaning ClipSVC Licences               [Failed]"
) else (
echo Cleaning ClipSVC Licences               [Successful]
)
)
)

::========================================================================================================================================

::  Below registry key (Volatile & Protected) gets created after the ClipSVC License cleanup command, and gets automatically deleted after 
::  system restart. It needs to be deleted to activate the system without restart.

::  This code runs only if Lockbox method to generate ticket is manually set by the user in this script.

set "RegKey=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ClipSVC\Volatile\PersistedSystemState"
set "_ident=HKU\S-1-5-19\SOFTWARE\Microsoft\IdentityCRL"

if %_lock%==1 (
reg query "%RegKey%" %nul% && %nul% call :regownstart
reg delete "%RegKey%" /f %nul% 

reg query "%RegKey%" %nul% && (
call :dk_color %Red% "Deleting a Volatile Registry            [Failed]"
call :dk_color %Magenta% "Restart the system, that will delete this registry key automatically"
) || (
echo Deleting a Volatile Registry            [Successful]
)

REM Clear HWID token related registry to fix activation incase if there is any corruption

reg delete "%_ident%" /f %nul%
reg query "%_ident%" %nul% && (
call :dk_color %Red% "Deleting a Registry                     [Failed] [%_ident%]"
) || (
echo Deleting a Registry                     [Successful] [%_ident%]
)
)

::========================================================================================================================================

::  Multiple attempts to generate the ticket because in some cases, one attempt is not enough.

echo:
set "_noxml=if not exist "%temp_%\GenuineTicket.xml""

"%temp_%/gatherosstatemodified.exe"
%_noxml% timeout /t 3 %nul%
%_noxml% net stop sppsvc /y %nul%
%_noxml% call "%temp_%/gatherosstatemodified.exe"
%_noxml% timeout /t 3 %nul%

::  Refresh ClipSVC (required after cleanup) with below command, not related to generating tickets

if %_lock%==1 (
for %%# in (wlidsvc LicenseManager sppsvc) do (net stop %%# /y %nul% & net start %%# /y %nul%)
call :dk_refresh
)

%_noxml% (
call :dk_color %Red% "Generating GenuineTicket.xml            [Failed]"
goto :dl_final
)

if %_lock%==1 (
find /i "clientLockboxKey" "%temp_%\GenuineTicket.xml" >nul && (
echo Generating GenuineTicket.xml            [Successful] [clientLockboxKey Ticket Created]
) || (
call :dk_color %Red% "Generating GenuineTicket.xml            [Failed]"
call :dk_color %Red% "downlevelGTkey Ticket created. Aborting..."
goto :dl_final
)
) else (
echo Generating GenuineTicket.xml            [Successful]
)

::========================================================================================================================================

::  Change Windows region to USA to avoid activation issues as Windows store license is not available in many countries 

for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Control Panel\International\Geo" /v Name 2^>nul') do set "name=%%b"
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Control Panel\International\Geo" /v Nation 2^>nul') do set "nation=%%b"

set regionchange=
if not "%name%"=="US" (
set regionchange=1
%psc% "Set-WinHomeLocation -GeoId 244" %nul%
if !errorlevel! EQU 0 (
echo Changing Windows Region To USA          [Successful]
) else (
call :dk_color %Red% "Changing Windows Region To USA          [Failed]"
)
)

::==========================================================================================================================================

::  Generate GenuineTicket.xml and apply
::  In some cases clipup -v -o method fails and in some cases service restart method fails as well
::  To maximize success rate and get better error details, script will install tickets two times (service restart + clipup -v -o)

set "tdir=%ProgramData%\Microsoft\Windows\ClipSVC\GenuineTicket"
if exist "%tdir%\*.xml" del /f /q "%tdir%\*.xml" %nul%
if exist "%ProgramData%\Microsoft\Windows\ClipSVC\Install\Migration\*" del /f /q "%ProgramData%\Microsoft\Windows\ClipSVC\Install\Migration\*" %nul%
if not exist "%tdir%\" md "%tdir%\" %nul%
copy /y /b "%temp_%\GenuineTicket.xml" "%tdir%\GenuineTicket.xml" %nul%

if not exist "%tdir%\GenuineTicket.xml" (
call :dk_color %Red% "Copying Ticket to ClipSVC Location      [Failed]"
)

set "_xmlexist=if exist "%tdir%\GenuineTicket.xml""

%_xmlexist% (
net stop ClipSVC /y %nul%
net start ClipSVC /y %nul%
%_xmlexist% timeout /t 2 %nul%
%_xmlexist% timeout /t 2 %nul%

%_xmlexist% (
set error=1
if exist "%tdir%\*.xml" del /f /q "%tdir%\*.xml" %nul%
call :dk_color %Red% "Installing GenuineTicket.xml            [Failed With ClipSVC Service Restart, Wait...]"
)
)

clipup -v -o -altto %temp_%\

set rebuildinfo=

if exist %temp_%\GenuineTicket.xml (
set error=1
set rebuildinfo=1
call :dk_color %Red% "Installing GenuineTicket.xml            [Failed With clipup -v -o]"
)

if exist "%ProgramData%\Microsoft\Windows\ClipSVC\Install\Migration\*.xml" (
set error=1
set rebuildinfo=1
call :dk_color %Red% "Checking Ticket Migration               [Failed]"
)

if defined applist if not defined showfix if defined rebuildinfo (
set showfix=1
call :dk_color %Magenta% "In MAS, Goto Troubleshoot and run Fix Licensing option."
)

::==========================================================================================================================================

call :dk_product

echo:
echo Activating...

call :dk_act
call :dk_checkperm
if defined _perm (
echo:
call :dk_color %Green% "%winos% is permanently activated with a digital license."
goto :dl_final
)

::  Extended licensing servers tests incase error not found and activation failed

set resfail=
if not defined error (

ipconfig /flushdns %nul%
set "tls=$Tls12 = [Enum]::ToObject([System.Net.SecurityProtocolType], 3072); [System.Net.ServicePointManager]::SecurityProtocol = $Tls12;"

for %%# in (
login.live.com/ppsecure/deviceaddcredential.srf
purchase.mp.microsoft.com/v7.0/users/me/orders
) do if not defined resfail (
set "d1=Add-Type -AssemblyName System.Net.Http;"
set "d1=!d1! $client = [System.Net.Http.HttpClient]::new();"
set "d1=!d1! $response = $client.GetAsync('https://%%#').GetAwaiter().GetResult();"
set "d1=!d1! $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()"
%psc% "!tls! !d1!" 2>nul | findstr /i "PurchaseFD DeviceAddResponse" 1>nul || set resfail=1
)

if not defined resfail (
%psc% "!tls! irm https://licensing.mp.microsoft.com/v7.0/licenses/content -Method POST" | find /i "traceId" 1>nul || set resfail=1
)

if defined resfail (
set error=1
echo:
call :dk_color %Red% "Checking Licensing Servers              [Failed To Connect]"
call :dk_color2 %Magenta% "Check this page for help" %_Yellow% " https://massgrave.dev/licensing-servers-issue"
)
)

::  Clear store ID related registry to fix activation incase error not found

if not defined error (
echo:
set "_ident=HKU\S-1-5-19\SOFTWARE\Microsoft\IdentityCRL"
reg delete "!_ident!" /f %nul%
reg query "!_ident!" %nul% && (
call :dk_color %Red% "Deleting a Registry                     [Failed] [!_ident!]"
) || (
echo Deleting a Registry                     [Successful] [!_ident!]
)

REM Refresh some services and license status

for %%# in (wlidsvc LicenseManager sppsvc) do (net stop %%# /y %nul% & net start %%# /y %nul%)
call :dk_refresh
call :dk_act
call :dk_checkperm
)

echo:
if defined _perm (
call :dk_color %Green% "%winos% is permanently activated with a digital license."
) else (
call :dk_color %Red% "Activation Failed %error_code%"
if defined notworking (
call :dk_color %Magenta% "At the time of writing this, HWID Activation was not supported for this product."
call :dk_color %Magenta% "Use KMS38 Activation option."
) else (
if not defined error call :dk_color %Magenta% "In MAS, Goto Troubleshoot and run Fix Licensing option."
call :dk_color2 %Magenta% "Check this page for help" %_Yellow% " https://massgrave.dev/troubleshoot"
)
)

::========================================================================================================================================

:dl_final

echo:
if exist "%temp_%\.*" rmdir /s /q "%temp_%\" %nul%
if exist "%temp_%\" (
call :dk_color %Red% "Cleaning Temp Files                     [Failed]"
) else (
echo Cleaning Temp Files                     [Successful]
)

if defined regionchange (
%psc% "Set-WinHomeLocation -GeoId %nation%" %nul%
if !errorlevel! EQU 0 (
echo Restoring Windows Region                [Successful]
) else (
call :dk_color %Red% "Restoring Windows Region                [Failed] [%name% - %nation%]"
)
)

if %osSKU%==175 call :dk_color %Red% "%winos% does not support activation on non-azure platforms."

goto :dk_done

::========================================================================================================================================

:regownstart

%psc% "$f=[io.file]::ReadAllText('!_batp!') -split ':regown\:.*';iex ($f[1]);"
exit /b

::  Below code takes ownership of a volatile registry key and deletes it
::  HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ClipSVC\Volatile\PersistedSystemState

:regown:
$AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1)
$ModuleBuilder = $AssemblyBuilder.DefineDynamicModule(2, $False)
$TypeBuilder = $ModuleBuilder.DefineType(0)

$TypeBuilder.DefinePInvokeMethod('RtlAdjustPrivilege', 'ntdll.dll', 'Public, Static', 1, [int], @([int], [bool], [bool], [bool].MakeByRefType()), 1, 3) | Out-Null
$TypeBuilder.CreateType()::RtlAdjustPrivilege(9, $true, $false, [ref]$false) | Out-Null

$SID = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
$IDN = ($SID.Translate([System.Security.Principal.NTAccount])).Value
$Admin = New-Object System.Security.Principal.NTAccount($IDN)

$path = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ClipSVC\Volatile\PersistedSystemState'
$key = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Registry64').OpenSubKey($path, 'ReadWriteSubTree', 'takeownership')

$acl = $key.GetAccessControl()
$acl.SetOwner($Admin)
$key.SetAccessControl($acl)

$rule = New-Object System.Security.AccessControl.RegistryAccessRule($Admin,"FullControl","Allow")
$acl.SetAccessRule($rule)
$key.SetAccessControl($acl)
:regown:

::========================================================================================================================================

::  Get Windows permanent activation status

:dk_checkperm

if %_wmic% EQU 1 wmic path SoftwareLicensingProduct where (LicenseStatus='1' and GracePeriodRemaining='0' and PartialProductKey is not NULL) get Name /value 2>nul | findstr /i "Windows" 1>nul && set _perm=1||set _perm=
if %_wmic% EQU 0 %psc% "(([WMISEARCHER]'SELECT Name FROM SoftwareLicensingProduct WHERE LicenseStatus=1 AND GracePeriodRemaining=0 AND PartialProductKey IS NOT NULL').Get()).Name | %% {echo ('Name='+$_)}" 2>nul | findstr /i "Windows" 1>nul && set _perm=1||set _perm=
exit /b

::  Refresh license status

:dk_refresh

if %_wmic% EQU 1 wmic path SoftwareLicensingService where __CLASS='SoftwareLicensingService' call RefreshLicenseStatus %nul%
if %_wmic% EQU 0 %psc% "$null=(([WMICLASS]'SoftwareLicensingService').GetInstances()).RefreshLicenseStatus()" %nul%
exit /b

::  Activation command

:dk_act

set error_code=
if %_wmic% EQU 1 wmic path SoftwareLicensingProduct where "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' and PartialProductKey<>null" call Activate %nul%
if %_wmic% EQU 0 %psc% "(([WMISEARCHER]'SELECT ID FROM SoftwareLicensingProduct WHERE ApplicationID=''55c92734-d682-4d71-983e-d6ec3f16059f'' AND PartialProductKey IS NOT NULL').Get()).Activate()" %nul%
if not %errorlevel%==0 cscript //nologo %windir%\system32\slmgr.vbs /ato %nul%
set error_code=%errorlevel%
cmd /c exit /b %error_code%
if %error_code% NEQ 0 (set "error_code=[Error Code: 0x%=ExitCode%]") else (set error_code=)
exit /b

::  Get Windows Activation IDs

:dk_actids

set applist=
if %_wmic% EQU 1 set "chkapp=for /f "tokens=2 delims==" %%a in ('"wmic path SoftwareLicensingProduct where (ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f') get ID /VALUE" 2^>nul')"
if %_wmic% EQU 0 set "chkapp=for /f "tokens=2 delims==" %%a in ('%psc% "(([WMISEARCHER]'SELECT ID FROM SoftwareLicensingProduct WHERE ApplicationID=''55c92734-d682-4d71-983e-d6ec3f16059f''').Get()).ID ^| %% {echo ('ID='+$_)}" 2^>nul')"
%chkapp% do (if defined applist (call set "applist=!applist! %%a") else (call set "applist=%%a"))
exit /b

::  Check wmic.exe

:dk_ckeckwmic

set _wmic=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "computersystem" 1>nul && set _wmic=1
)
exit /b

::  Get Product name (WMI/REG methods are not reliable in all conditions, hence winbrand.dll method is used)

:dk_product

call :dk_reflection

set d1=%ref% $meth = $TypeBuilder.DefinePInvokeMethod('BrandingFormatString', 'winbrand.dll', 'Public, Static', 1, [String], @([String]), 1, 3);
set d1=%d1% $meth.SetImplementationFlags(128); $TypeBuilder.CreateType()::BrandingFormatString('%%WINDOWS_LONG%%')

set winos=
for /f "delims=" %%s in ('"%psc% %d1%"') do if not errorlevel 1 (set winos=%%s)
echo "%winos%" | find /i "Windows" 1>nul || (
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul') do set "winos=%%b"
if %winbuild% GEQ 22000 (
set winos=!winos:Windows 10=Windows 11!
)
)
exit /b

::  Common lines used in PowerShell reflection code

:dk_reflection

set ref=$AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1);
set ref=%ref% $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule(2, $False);
set ref=%ref% $TypeBuilder = $ModuleBuilder.DefineType(0);
exit /b

::========================================================================================================================================

:dk_errorcheck

::  Check disabled services

set serv_ste=
for %%# in (%_serv%) do (
set serv_dis=
reg query HKLM\SYSTEM\CurrentControlSet\Services\%%# /v ImagePath %nul% || set serv_dis=1
for /f "skip=2 tokens=2*" %%a in ('reg query HKLM\SYSTEM\CurrentControlSet\Services\%%# /v Start 2^>nul') do if /i %%b equ 0x4 set serv_dis=1
sc start %%# %nul%
if !errorlevel! EQU 1058 set serv_dis=1
sc query %%# %nul% || set serv_dis=1
if defined serv_dis (if defined serv_ste (set "serv_ste=!serv_ste! %%#") else (set "serv_ste=%%#"))
)

::  Change disabled services startup type to default

set serv_csts=
set serv_cste=

if defined serv_ste (
for %%# in (%serv_ste%) do (
if /i %%#==ClipSVC        (reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%#" /v "Start" /t REG_DWORD /d "3" /f %nul% & sc config %%# start= demand %nul%)
if /i %%#==wlidsvc        sc config %%# start= demand %nul%
if /i %%#==sppsvc         (reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%#" /v "Start" /t REG_DWORD /d "2" /f %nul% & sc config %%# start= delayed-auto %nul%)
if /i %%#==KeyIso         sc config %%# start= demand %nul%
if /i %%#==LicenseManager sc config %%# start= demand %nul%
if /i %%#==Winmgmt        sc config %%# start= auto %nul%
if /i %%#==wuauserv       sc config %%# start= demand %nul%
if !errorlevel!==0 (
if defined serv_csts (set "serv_csts=!serv_csts! %%#") else (set "serv_csts=%%#")
) else (
if defined serv_cste (set "serv_cste=!serv_cste! %%#") else (set "serv_cste=%%#")
)
)
)

if defined serv_csts call :dk_color %Gray% "Enabling Disabled Services              [Successful] [%serv_csts%]"

if defined serv_cste (
set error=1
call :dk_color %Red% "Enabling Disabled Services              [Failed] [%serv_cste%]"
)

::========================================================================================================================================

::  Check if the services are able to run or not
::  Workarounds are added to get correct status and error code because sc query doesn't output correct results in some conditions

set serv_e=
for %%# in (%_serv%) do (
set errorcode=
set checkerror=
net start %%# /y %nul%
set errorcode=!errorlevel!
sc query %%# | find /i "4  RUNNING" %nul% || set checkerror=1

sc start %%# %nul%
if !errorlevel! NEQ 1056 if !errorlevel! NEQ 0 (set errorcode=!errorlevel!&set checkerror=1)
if defined checkerror if defined serv_e (set "serv_e=!serv_e!, %%#-!errorcode!") else (set "serv_e=%%#-!errorcode!")
)

if defined serv_e (
set error=1
call :dk_color %Red% "Starting Services                       [Failed] [%serv_e%]"
echo %serv_e% | findstr /i "ClipSVC-1058 sppsvc-1058" %nul% && (
call :dk_color %Magenta% "Restart the system to fix disabled service error 1058."
)
)

::========================================================================================================================================

::  Various error checks

if defined safeboot_option (
set error=1
call :dk_color2 %Red% "Checking Boot Mode                      " %Magenta% "[System is running in safe mode. Run in normal mode.]"
)


reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State" 2>nul | find /i "IMAGE_STATE_COMPLETE" 1>nul || (
set error=1
call :dk_color2 %Red% "Checking Audit Mode                     " %Magenta% "[System is running in Audit mode. Run in normal mode.]"
)


reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinPE" /v InstRoot %nul% && (
set error=1
call :dk_color2 %Red% "Checking WinPE                          " %Magenta% "[System is running in WinPE mode. Run in normal mode.]"
)


for %%# in (wmic.exe) do @if "%%~$PATH:#"=="" (
call :dk_color %Gray% "Checking WMIC.exe                       [Not Found]"
)


%psc% $ExecutionContext.SessionState.LanguageMode 2>nul | find /i "Full" 1>nul || (
set error=1
call :dk_color %Red% "Checking Powershell                     [Not Responding]"
)


set wmifailed=
if %_wmic% EQU 1 wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "computersystem" 1>nul
if %_wmic% EQU 0 %psc% "Get-CIMInstance -Class Win32_ComputerSystem | Select-Object -Property CreationClassName" 2>nul | find /i "computersystem" 1>nul
if %errorlevel% NEQ 0 (
set error=1
set wmifailed=1
call :dk_color %Red% "Checking WMI                            [Not Responding] %_wmic%"
call :dk_color %Magenta% "In MAS, Goto Troubleshoot and run Fix WMI option."
)


if not "%regSKU%"=="%wmiSKU%" (
call :dk_color %Red% "Checking WMI/REG SKU                    [Difference Found - WMI:%wmiSKU% Reg:%regSKU%]"
)


DISM /English /Online /Get-CurrentEdition %nul%
set error_code=%errorlevel%
cmd /c exit /b %error_code%
if %error_code% NEQ 0 set "error_code=[0x%=ExitCode%]"
if %error_code% NEQ 0 (
call :dk_color %Red% "Checking DISM                           [Not Responding] %error_code%"
)


if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-*EvalEdition~*.mum" (
set error=1
call :dk_color %Red% "Checking Eval Packages                  [Non-Eval Licenses are installed in Eval Windows]"
)


cscript //nologo %windir%\system32\slmgr.vbs /dlv %nul%
set error_code=%errorlevel%
cmd /c exit /b %error_code%
if %error_code% NEQ 0 set "error_code=0x%=ExitCode%"
if %error_code% NEQ 0 (
set error=1
call :dk_color %Red% "Checking slmgr /dlv                     [Not Responding] %error_code%"
)


reg query "HKU\S-1-5-20\Software\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\PersistedTSReArmed" %nul% && (
set error=1
call :dk_color2 %Red% "Checking Rearm                          " %Magenta% "[System Restart Is Required]"
)


reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ClipSVC\Volatile\PersistedSystemState" %nul% && (
set error=1
call :dk_color2 %Red% "Checking ClipSVC                        " %Magenta% "[System Restart Is Required]"
)


for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v "SkipRearm" 2^>nul') do if /i %%b NEQ 0x0 (
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v "SkipRearm" /t REG_DWORD /d "0" /f %nul%
call :dk_color %Red% "Checking SkipRearm                      [Default 0 Value Not Found, Changing To 0]"
net stop sppsvc /y %nul%
net start sppsvc /y %nul%
set error=1
)


reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\Plugins\Objects\msft:rm/algorithm/hwid/4.0" /f ba02fed39662 /d %nul% || (
call :dk_color %Red% "Checking SPP Registry Key               [Incorrect ModuleId Found]"
set error=1
)


call :dk_actids
if not defined applist (
net stop sppsvc /y %nul%
cscript //nologo %windir%\system32\slmgr.vbs /rilc %nul%
if !errorlevel! NEQ 0 cscript //nologo %windir%\system32\slmgr.vbs /rilc %nul%
call :dk_refresh
call :dk_actids
if not defined applist (
set error=1
call :dk_color %Red% "Checking Activation IDs                 [Not Found]"
)
)


set tokenstore=
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v TokenStore 2^>nul') do call set "tokenstore=%%b"
if not exist "%tokenstore%\" (
set error=1
call :dk_color %Red% "Checking SPP Token Folder               [Not Found] [%tokenstore%\]"
)


if exist "%tokenstore%\" if not exist "%tokenstore%\tokens.dat" (
set error=1
call :dk_color %Red% "Checking SPP tokens.dat                 [Not Found] [%tokenstore%\]"
)


if not exist %ProgramData%\Microsoft\Windows\ClipSVC\tokens.dat (
set error=1
call :dk_color %Red% "Checking ClipSVC tokens.dat             [Not Found]"
)


if not exist %SystemRoot%\system32\sppsvc.exe (
set error=1
call :dk_color %Red% "Checking sppsvc.exe File                [Not Found]"
)


::  Below checks are performed if required services are not disabled + slmgr /dlv errorlevel is not Zero + Rearm restart is not required + WMI is working fine

set showfix=
set wpaerror=
set permerror=
if not defined serv_cste if /i not %error_code%==0 if /i not %error_code%==0xC004D302 if not defined wmifailed (

REM  This code checks for invalid registry keys in HKLM\SYSTEM\WPA. This issue may appear even on healthy systems.

if %winbuild% GEQ 14393 (
set /a count=0
for /f %%a in ('reg query "HKLM\SYSTEM\WPA" 2^>nul') do set /a count+=1
for /L %%# in (1,1,!count!) do (
reg query "HKLM\SYSTEM\WPA\8DEC0AF1-0341-4b93-85CD-72606C2DF94C-7P-%%#" /ve /t REG_BINARY %nul% || set wpaerror=1
)
if defined wpaerror call :dk_color %Red% "Checking WPA Registry Keys              [Error Found] [Registry Count - !count!]"
)

REM  This code checks if NT SERVICE\sppsvc has permission access to tokens folder and required registry keys. It's often caused by gaming spoofers. 

if not exist "%tokenstore%\" set permerror=1

for %%# in (
"%tokenstore%"
"HKLM:\SYSTEM\WPA"
"HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
) do if not defined permerror (
%psc% "$acl = Get-Acl '%%#'; if ($acl.Access.Where{ $_.IdentityReference -eq 'NT SERVICE\sppsvc' -and $_.AccessControlType -eq 'Deny' -or $acl.Access.IdentityReference -notcontains 'NT SERVICE\sppsvc'}) {Exit 2}" %nul%
if !errorlevel!==2 set permerror=1
)
if defined permerror call :dk_color %Red% "Checking SPP Permissions                [Error Found]"

set showfix=1
call :dk_color %Magenta% "In MAS, Goto Troubleshoot and run Fix Licensing option."
if not defined permerror call :dk_color %Magenta% "If activation still fails then run Fix WPA Registry option."
)

exit /b

::========================================================================================================================================

:dk_color

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[0m
) else (
%psc% write-host -back '%1' -fore '%2' '%3'
)
exit /b

:dk_color2

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[%~3%~4%esc%[0m
) else (
%psc% write-host -back '%1' -fore '%2' '%3' -NoNewline; write-host -back '%4' -fore '%5' '%6'
)
exit /b

::========================================================================================================================================

:dk_done

echo:
if %_unattended%==1 timeout /t 2 & exit /b
call :dk_color %_Yellow% "Press any key to %_exitmsg%..."
pause >nul
exit /b

::========================================================================================================================================

::  1st column = Activation ID
::  2nd column = Generic Retail/OEM/MAK Key
::  3rd column = SKU ID
::  4th column = Key part number
::  5th column = 1 = activation is not working (at the time of writing this), 0 = activation is working
::  6th column = Key Type
::  7th column = WMI Edition ID
::  8th column = Version name incase same Edition ID is used in different OS versions with different key
::  Separator  = _


:hwiddata

set f=
for %%# in (
8b351c9c-f398-4515-9900-09df49427262_XGV%f%PP-NM%f%H47-7TT%f%HJ-W%f%3FW7-8H%f%V2C___4_X19-99683_0_OEM:NONSLP_Enterprise
c83cef07-6b72-4bbc-a28f-a00386872839_3V6%f%Q6-NQ%f%XCX-V8Y%f%XR-9%f%QCYV-QP%f%FCT__27_X19-98746_0_Volume:MAK_EnterpriseN
4de7cb65-cdf1-4de9-8ae8-e3cce27b9f2c_VK7%f%JG-NP%f%HTM-C97%f%JM-9%f%MPGT-3V%f%66T__48_X19-98841_0_____Retail_Professional
9fbaf5d6-4d83-4422-870d-fdda6e5858aa_2B8%f%7N-8K%f%FHP-DKV%f%6R-Y%f%2C8J-PK%f%CKT__49_X19-98859_0_____Retail_ProfessionalN
f742e4ff-909d-4fe9-aacb-3231d24a0c58_4CP%f%RK-NM%f%3K3-X6X%f%XQ-R%f%XX86-WX%f%CHW__98_X19-98877_0_____Retail_CoreN
1d1bac85-7365-4fea-949a-96978ec91ae0_N24%f%34-X9%f%D7W-8PF%f%6X-8%f%DV9T-8T%f%YMD__99_X19-99652_0_____Retail_CoreCountrySpecific
3ae2cc14-ab2d-41f4-972f-5e20142771dc_BT7%f%9Q-G7%f%N6G-PGB%f%YW-4%f%YWX6-6F%f%4BT_100_X19-99661_0_____Retail_CoreSingleLanguage
2b1f36bb-c1cd-4306-bf5c-a0367c2d97d8_YTM%f%G3-N6%f%DKC-DKB%f%77-7%f%M9GH-8H%f%VX7_101_X19-98868_0_____Retail_Core
2a6137f3-75c0-4f26-8e3e-d83d802865a4_XKC%f%NC-J2%f%6Q9-KFH%f%D2-F%f%KTHY-KD%f%72Y_119_X19-99606_0_OEM:NONSLP_PPIPro
e558417a-5123-4f6f-91e7-385c1c7ca9d4_YNM%f%GQ-8R%f%YV3-4PG%f%Q3-C%f%8XTP-7C%f%FBY_121_X19-98886_0_____Retail_Education
c5198a66-e435-4432-89cf-ec777c9d0352_84N%f%GF-MH%f%BT6-FXB%f%X8-Q%f%WJK7-DR%f%R8H_122_X19-98892_0_____Retail_EducationN
cce9d2de-98ee-4ce2-8113-222620c64a27_KCN%f%VH-YK%f%WX8-GJJ%f%B9-H%f%9FDT-6F%f%7W2_125_X22-66075_1_Volume:MAK_EnterpriseS_VB
d06934ee-5448-4fd1-964a-cd077618aa06_43T%f%BQ-NH%f%92J-XKT%f%M7-K%f%T3KK-P3%f%9PB_125_X21-83233_0_OEM:NONSLP_EnterpriseS_RS5
706e0cfd-23f4-43bb-a9af-1a492b9f1302_NK9%f%6Y-D9%f%CD8-W44%f%CQ-R%f%8YTK-DY%f%JWX_125_X21-05035_0_OEM:NONSLP_EnterpriseS_RS1
faa57748-75c8-40a2-b851-71ce92aa8b45_FWN%f%7H-PF%f%93Q-4GG%f%P8-M%f%8RF3-MD%f%WWW_125_X19-99617_0_OEM:NONSLP_EnterpriseS_TH
2c060131-0e43-4e01-adc1-cf5ad1100da8_RQF%f%NW-9T%f%PM3-JQ7%f%3T-Q%f%V4VQ-DV%f%9PT_126_X22-66108_1_Volume:MAK_EnterpriseSN_VB
e8f74caa-03fb-4839-8bcc-2e442b317e53_M33%f%WV-NH%f%Y3C-R7F%f%PM-B%f%QGPT-23%f%9PG_126_X21-83264_1_Volume:MAK_EnterpriseSN_RS5
3d1022d8-969f-4222-b54b-327f5a5af4c9_2DB%f%W3-N2%f%PJG-MVH%f%W3-G%f%7TDK-9H%f%KR4_126_X21-04921_0_Volume:MAK_EnterpriseSN_RS1
60c243e1-f90b-4a1b-ba89-387294948fb6_NTX%f%6B-BR%f%YC2-K67%f%86-F%f%6MVQ-M7%f%V2X_126_X19-98770_0_Volume:MAK_EnterpriseSN_TH
eb6d346f-1c60-4643-b960-40ec31596c45_DXG%f%7C-N3%f%6C4-C4H%f%TG-X%f%4T3X-2Y%f%V77_161_X21-43626_0_____Retail_ProfessionalWorkstation
89e87510-ba92-45f6-8329-3afa905e3e83_WYP%f%NQ-8C%f%467-V2W%f%6J-T%f%X4WX-WT%f%2RQ_162_X21-43644_0_____Retail_ProfessionalWorkstationN
62f0c100-9c53-4e02-b886-a3528ddfe7f6_8PT%f%T6-RN%f%W4C-6V7%f%J2-C%f%2D3X-MH%f%BPB_164_X21-04955_0_____Retail_ProfessionalEducation
13a38698-4a49-4b9e-8e83-98fe51110953_GJT%f%YN-HD%f%MQY-FRR%f%76-H%f%VGC7-QP%f%F8P_165_X21-04956_0_____Retail_ProfessionalEducationN
df96023b-dcd9-4be2-afa0-c6c871159ebe_NJC%f%F7-PW%f%8QT-332%f%4D-6%f%88JX-2Y%f%V66_175_X21-41295_0_____Retail_ServerRdsh
d4ef7282-3d2c-4cf0-9976-8854e64a8d1e_V3W%f%VW-N2%f%PV2-CGW%f%C3-3%f%4QGF-VM%f%J2C_178_X21-32983_0_____Retail_Cloud
af5c9381-9240-417d-8d35-eb40cd03e484_NH9%f%J3-68%f%WK7-6FB%f%93-4%f%K3DF-DJ%f%4F6_179_X21-32987_0_____Retail_CloudN
8ab9bdd1-1f67-4997-82d9-8878520837d9_XQQ%f%YW-NF%f%FMW-XJP%f%BH-K%f%8732-CK%f%FFD_188_X21-99378_0_____OEM:DM_IoTEnterprise
ed655016-a9e8-4434-95d9-4345352c2552_QPM%f%6N-7J%f%2WJ-P88%f%HH-P%f%3YRH-YY%f%74H_191_X21-99682_0_OEM:NONSLP_IoTEnterpriseS_VB
d4bdc678-0a4b-4a32-a5b3-aaa24c3b0f24_K9V%f%KN-3B%f%GWV-Y62%f%4W-M%f%CRMQ-BH%f%DCD_202_X22-53884_0_____Retail_CloudEditionN
92fb8726-92a8-4ffc-94ce-f82e07444653_KY7%f%PN-VR%f%6RX-83W%f%6Y-6%f%DDYQ-T6%f%R4W_203_X22-53847_0_____Retail_CloudEdition
d4f9b41f-205c-405e-8e08-3d16e88e02be_J7N%f%JW-V6%f%KBM-CC8%f%RW-Y%f%29Y4-HQ%f%2MJ_205_X23-15027_0_OEM:NONSLP_IoTEnterpriseSK
) do (
for /f "tokens=1-9 delims=_" %%A in ("%%#") do (

if %1==key if %osSKU%==%%C (

REM Detect key attempt 1

if "%2"=="attempt1" if not defined key (
echo "!applist!" | find /i "%%A" 1>nul && (
if %%E==1 set notworking=1
set key=%%B
)
)

REM Detect key attempt 2

if "%2"=="attempt2" if not defined key (
set actidnotfound=1
set 8th=%%H
if not defined 8th (
if %%E==1 set notworking=1
set key=%%B
) else (
echo "%branch%" | find /i "%%H" 1>nul && (
if %%E==1 set notworking=1
set key=%%B
)
)
)
)

)
)
exit /b

::========================================================================================================================================

::  Below code is used to get alternate edition name and key if current edition doesn't support HWID activation

::  ProfessionalCountrySpecific won't be converted because it's not a good idea to change CountrySpecific editions

::  1st column = Current SKU ID
::  2nd column = Current Edition Name
::  3rd column = Current Edition Activation ID
::  4th column = Alternate Edition Activation ID
::  5th column = Alternate Edition HWID Key
::  6th column = Alternate Edition Name
::  Separator  = _


:hwidfallback

set notfoundaltactID=
if %_NoEditionChange%==1 exit /b

for %%# in (
125_EnterpriseS-2021___________cce9d2de-98ee-4ce2-8113-222620c64a27_ed655016-a9e8-4434-95d9-4345352c2552_QPM%f%6N-7J2%f%WJ-P8%f%8HH-P3Y%f%RH-YY%f%74H_IoTEnterpriseS-2021
191_IoTEnterpriseS-Win11_______59eb965c-9150-42b7-a0ec-22151b9897c5_d4f9b41f-205c-405e-8e08-3d16e88e02be_J7N%f%JW-V6K%f%BM-CC%f%8RW-Y29%f%Y4-HQ%f%2MJ_IoTEnterpriseSK-Win11
138_ProfessionalSingleLanguage_a48938aa-62fa-4966-9d44-9f04da3f72f2_4de7cb65-cdf1-4de9-8ae8-e3cce27b9f2c_VK7%f%JG-NPH%f%TM-C9%f%7JM-9MP%f%GT-3V%f%66T_Professional
) do (
for /f "tokens=1-6 delims=_" %%A in ("%%#") do if %osSKU%==%%A (
echo "!applist!" | find /i "%%C" 1>nul && (
echo "!applist!" | find /i "%%D" 1>nul && (
set altkey=%%E
set curedition=%%B
set altedition=%%F
) || (
set altedition=%%F
set notfoundaltactID=1
)
)
)
)
exit /b

::========================================================================================================================================