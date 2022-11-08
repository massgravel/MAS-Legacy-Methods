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
echo Error: This is not a correct file. It has LF line ending issue.
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
echo Project is supported for Windows 10/11.
goto dk_done
)

if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" (
%eline%
echo HWID Activation is not supported for Windows Server.
echo Use KMS38 or KMS Activation.
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
mode 102, 37
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

::  Check files

if not exist "!_work!\BIN\gatherosstate.exe" (
%eline%
echo 'gatherosstate.exe' file is missing in 'BIN' folder. Aborting...
goto dk_done
)

::  Verify gatherosstate.exe file

set _hash=
for /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile "!_work!\BIN\gatherosstate.exe" SHA1^|findstr /i /v CertUtil') do set "_hash=%%#"
set "_hash=%_hash: =%"

if /i not "%_hash%"=="FABB5A0FC1E6A372219711152291339AF36ED0B5" (
if /i not "%_hash%"=="0CC709275767E0AA7BD69236E364A45E66AAD9AB" (
%eline%
echo gatherosstate.exe SHA1 hash mismatch found.
echo:
echo Detected: %_hash%
goto dk_done
)
)

::========================================================================================================================================

::  Check Evaluation version

if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-*EvalEdition~*.mum" (
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionID 2>nul | find /i "Eval" 1>nul && (
%eline%
echo [%winos% ^| %winbuild%]
echo Evaluation Editions cannot be activated. Download ^& Install full version of Windows OS.
echo:
echo https://massgrave.dev/
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

::  Check Internet connection

cls
echo:
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do set arch=%%b
echo Checking OS Info                        [%winos% ^| %winbuild% ^| %arch%]

set _intcon=
for /f "delims=[] tokens=2" %%# in ('ping -n 1 licensing.mp.microsoft.com') do if not [%%#]==[] set _intcon=1

%psc% "$t = New-Object Net.Sockets.TcpClient;try{$t.Connect("""licensing.mp.microsoft.com""", 443)}catch{};$t.Connected" | findstr /i true 1>nul
if %errorlevel% EQU 0 (
echo Checking Internet Connection            [Connected]
) else (
set error=1
if defined _intcon (
call :dk_color %Red% "Checking Internet Connection            [Internet Found But Cant Connect licensing.mp.microsoft.com]"
call :dk_color %Magenta% "Make sure restricted Internet [Office/College] is not connected and URL is not blocked in the system"
) else (
call :dk_color %Red% "Checking Internet Connection            [Not Connected]"
)
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

set "_serv=ClipSVC wlidsvc sppsvc LicenseManager Winmgmt wuauserv"

::  Client License Service (ClipSVC)
::  Microsoft Account Sign-in Assistant
::  Software Protection
::  Windows License Manager Service
::  Windows Management Instrumentation
::  Windows Update

::  Check disabled services

set serv_ste=
for %%# in (%_serv%) do (
set serv_dis=
reg query HKLM\SYSTEM\CurrentControlSet\Services\%%# /v Start %nul% || set serv_dis=1
for /f "skip=2 tokens=2*" %%a in ('reg query HKLM\SYSTEM\CurrentControlSet\Services\%%# /v Start 2^>nul') do if /i %%b equ 0x4 set serv_dis=1
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
if /i %%#==LicenseManager sc config %%# start= demand %nul%
if /i %%#==Winmgmt        sc config %%# start= auto %nul%
if /i %%#==wuauserv       sc config %%# start= demand %nul%
if !errorlevel!==0 (
if defined serv_csts (set "serv_csts=!serv_csts! %%#") else (set "serv_csts=%%#")
) else (
set error=1
if defined serv_cste (set "serv_cste=!serv_cste! %%#") else (set "serv_cste=%%#")
)
)
)

if defined serv_csts echo Enabling Disabled Services              [Successful] [%serv_csts%]

if defined serv_cste (
echo %serv_cste% | findstr /i "ClipSVC sppsvc" %nul% && (
call :dk_color %Red% "Enabling Disabled Services              [Failed] [%serv_cste%] [Restart System]"
) || (
call :dk_color %Red% "Enabling Disabled Services              [Failed] [%serv_cste%]"
)
)

::========================================================================================================================================

::  Check if the services are able to run or not
::  Workarounds are added to get correct status and error code because sc query doesn't output correct results in some conditions

set serv_e=
for %%# in (%_serv%) do (
set errorcode=
set checkerror=
net start %%# /y %nul%
sc query %%# | find /i "4  RUNNING" %nul% || set checkerror=1

sc start %%# %nul%
set errorcode=!errorlevel!
if !errorcode! NEQ 1056 if !errorcode! NEQ 0 set checkerror=1
if defined checkerror if defined serv_e (set "serv_e=!serv_e!, %%#-!errorcode!") else (set "serv_e=%%#-!errorcode!")
)

if defined serv_e (
set error=1
call :dk_color %Red% "Starting Services                       [Failed] [%serv_e%]"
)

::========================================================================================================================================

::  Various error checks

for %%# in (wmic.exe) do @if "%%~$PATH:#"=="" (
call :dk_color %Gray% "Checking WMIC.exe                       [Not Found]"
)


%psc% $ExecutionContext.SessionState.LanguageMode 2>nul | find /i "Full" 1>nul || (
set error=1
call :dk_color %Red% "Checking Powershell                     [Not Responding]"
)


if %_wmic% EQU 1 wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "computersystem" 1>nul
if %_wmic% EQU 0 %psc% "Get-CIMInstance -Class Win32_ComputerSystem | Select-Object -Property CreationClassName" 2>nul | find /i "computersystem" 1>nul
if %errorlevel% NEQ 0 (
set error=1
call :dk_color %Red% "Checking WMI                            [Not Responding] %_wmic%"
)


if not "%regSKU%"=="%wmiSKU%" (
set error=1
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
call :dk_color %Red% "Checking Rearm                          [System Restart Is Required]"
)


reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ClipSVC\Volatile\PersistedSystemState" %nul% && (
set error=1
call :dk_color %Red% "Checking ClipSVC                        [System Restart Is Required]"
)


for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v "SkipRearm" 2^>nul') do if /i %%b NEQ 0x0 (
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v "SkipRearm" /t REG_DWORD /d "0" /f %nul%
call :dk_color %Red% "Checking SkipRearm                      [Default 0 Value Not Found, Changing To 0]"
net stop sppsvc /y %nul%
net start sppsvc /y %nul%
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


set token=0
if exist %Systemdrive%\Windows\System32\spp\store\2.0\tokens.dat set token=1
if exist %Systemdrive%\Windows\System32\spp\store_test\2.0\tokens.dat set token=1
if %token%==0 (
set error=1
call :dk_color %Red% "Checking SPP tokens.dat                 [Not Found]"
)

if not exist %SystemRoot%\system32\sppsvc.exe (
set error=1
call :dk_color %Red% "Checking sppsvc.exe File                [Not Found]"
)

if /i %error_code% EQU 0xc0000022 (
echo "%serv_e%" | find /i "sppsvc" %nul% && (
call :dk_color %Magenta% "Looks like you may have used a Gaming spoofer. Check Activation Troubleshoot option in MAS."
)
)

::========================================================================================================================================

::  Detect Key

set key=
set pfn=
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
call :dk_color %Magenta% "Evaluation Windows Found. Install Full version of Windows. https://massgrave.dev/"
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
set error=1
call :dk_color %Red% "Installing Generic Product Key          [%key%] [Failed] %errorcode%"
if defined applist if defined actidnotfound call :dk_color %Red% "Activation ID not found for this key. Make sure you are using updated version of MAS."
)

::========================================================================================================================================

::  Files are copied to temp to generate ticket to avoid possible issues in case the path contains special character or non English names

echo:
set "temp_=%SystemRoot%\Temp\_Temp"
if exist "%temp_%\.*" rmdir /s /q "%temp_%\" %nul%
md "%temp_%\" %nul%

pushd "!_work!\BIN\"
copy /y /b "gatherosstate.exe" "%temp_%\gatherosstate.exe" %nul%
popd

if not exist "%temp_%\gatherosstate.exe" (
call :dk_color %Red% "Copying Required Files to Temp          [%temp_%] [Failed]"
goto :dl_final
) else (
echo Copying Required Files to Temp          [%temp_%] [Successful]
)

::========================================================================================================================================

if /i "%_hash%"=="0CC709275767E0AA7BD69236E364A45E66AAD9AB" (
echo Checking gatherosstate.exe              [Already Modified]
%nul% ren "%temp_%\gatherosstate.exe" "gatherosstatemodified.exe"
goto :dlskipmod
)

::  Modify gatherosstate.exe

pushd "%temp_%\"
%nul% %psc% "$f=[io.file]::ReadAllText('!_batp!') -split ':hex\:.*';iex ($f[1]);"
popd

if not exist "%temp_%\gatherosstatemodified.exe" (
call :dk_color %Red% "Creating Modified Gatherosstate         [Failed] Aborting..."
goto :dl_final
)

set _hash=
for /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile "%temp_%\gatherosstatemodified.exe" SHA1^|findstr /i /v CertUtil') do set "_hash=%%#"
set "_hash=%_hash: =%"

if /i not "%_hash%"=="0CC709275767E0AA7BD69236E364A45E66AAD9AB" (
call :dk_color %Red% "Creating Modified Gatherosstate         [Failed] [Hash Not Matched] Aborting..."
goto :dl_final
) else (
echo Creating Modified Gatherosstate         [Successful]
)

:dlskipmod

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

"%temp_%/gatherosstatemodified.exe" Pfn=%pfn%;DownlevelGenuineState=1
%_noxml% timeout /t 3 %nul%
%_noxml% net stop sppsvc /y %nul%
%_noxml% call "%temp_%/gatherosstatemodified.exe" Pfn=%pfn%;DownlevelGenuineState=1
%_noxml% timeout /t 3 %nul%

::  Refresh ClipSVC (required after cleanup) with below command, not related to generating tickets

if %_lock%==1 (
for %%# in (wlidsvc LicenseManager sppsvc) do (net stop %%# /y %nul% & net start %%# /y %nul%)
call :dk_refresh
)

%_noxml% (
call :dk_color %Red% "Generating GenuineTicket.xml            [Failed] [%pfn%]"
goto :dl_final
)

if %_lock%==1 (
find /i "clientLockboxKey" "%temp_%\GenuineTicket.xml" >nul && (
echo Generating GenuineTicket.xml            [Successful] [clientLockboxKey Ticket Created]
) || (
call :dk_color %Red% "Generating GenuineTicket.xml            [Failed] [%pfn%]"
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
%psc% Set-WinHomeLocation -GeoId 244
if !errorlevel! EQU 0 (
echo Changing Windows Region To USA          [Successful]
) else (
call :dk_color %Red% "Changing Windows Region To USA          [Failed]"
)
)

::==========================================================================================================================================

::  Generate GenuineTicket.xml and apply
::  Most correct way to apply a ticket is by restarting ClipSVC service but we can not check the log details in this way
::  To get the log details and also to correctly apply ticket, script will install tickets two times (service restart + clipup -v -o)

set "tdir=%ProgramData%\Microsoft\Windows\ClipSVC\GenuineTicket"
if exist "%tdir%\*.xml" del /f /q "%tdir%\*.xml" %nul%
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
if exist "%tdir%\*.xml" del /f /q "%tdir%\*.xml" %nul%
call :dk_color %Red% "Installing GenuineTicket.xml            [Failed With ClipSVC Service Restart, Wait...]"
)
)

clipup -v -o -altto %temp_%\

::==========================================================================================================================================

call :dk_product

echo:
echo Activating...
echo:

call :dk_act
call :dk_checkperm
if defined _perm (
call :dk_color %Green% "%winos% is permanently activated."
goto :dl_final
)


if not defined error (

REM Clear store ID related registry to fix activation incase if there is any corruption

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

if defined _perm (
call :dk_color %Green% "%winos% is permanently activated."
) else (
call :dk_color %Red% "Activation Failed %error_code%"
if defined notworking (
call :dk_color %Magenta% "At the time of writing this, HWID Activation was not supported for this product."
) else (
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
%psc% Set-WinHomeLocation -GeoId %nation%
if !errorlevel! EQU 0 (
echo Restoring Windows Region                [Successful]
) else (
call :dk_color %Red% "Restoring Windows Region                [Failed] [%name%-%nation%]"
)
)

if %osSKU%==175 call :dk_color %Red% "ServerRdsh Editon does not officially support activation on non-azure platforms."

goto :dk_done

::========================================================================================================================================

:regownstart

setlocal
set "TMP=%SystemRoot%\Temp"
set "TEMP=%SystemRoot%\Temp"
%psc% "$f=[io.file]::ReadAllText('!_batp!') -split ':regown\:.*';iex ($f[1]);"
endlocal
exit /b

::  Below code runs only if Lockbox method is manually set by the user in this script
::  It takes ownership of a volatile registry key and deletes it, which gets created in Lockbox method

::  Thanks to Remko Weijnen for the code and thanks to abbodi1406 for the help
::  remkoweijnen.nl/blog/2012/01/16/take-ownership-of-a-registry-key-in-powershell/

:regown:
$definition = @"
using System;
using System.Runtime.InteropServices;
namespace Win32Api
{
    public class NtDll
    {
        [DllImport("ntdll.dll", EntryPoint="RtlAdjustPrivilege")]
        public static extern int RtlAdjustPrivilege(int Privilege, bool Enable, bool CurrentThread, ref bool Enabled);
    }
}
"@

Add-Type -TypeDefinition $definition -PassThru | Out-Null
[Win32Api.NtDll]::RtlAdjustPrivilege(9, $true, $false, [ref]$false) | Out-Null

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

::  Get Product name (WMI/REG methods are not reliable in all conditions, hence winbrand.dll method is used)

:dk_product

set winos=
set d1=[DllImport(\"winbrand\",CharSet=CharSet.Unicode)]public static extern string BrandingFormatString(string s);
set d2=$AP=Add-Type -Member '%d1%' -Name D1 -PassThru; $AP::BrandingFormatString('%%WINDOWS_LONG%%')
for /f "delims=" %%s in ('"%psc% %d2%"') do if not errorlevel 1 (set winos=%%s)
echo "%winos%" | find /i "Windows" 1>nul || (
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul') do set "winos=%%b"
if %winbuild% GEQ 22000 (
set winos=!winos:Windows 10=Windows 11!
)
)
exit /b

::  Check wmic.exe

:dk_ckeckwmic

set _wmic=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "computersystem" 1>nul && set _wmic=1
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

for %%# in (
8b351c9c-f398-4515-9900-09df49427262_XGVPP-NMH47-7TTHJ-W3FW7-8HV2C___4_X19-99683_0_OEM:NONSLP_Enterprise
c83cef07-6b72-4bbc-a28f-a00386872839_3V6Q6-NQXCX-V8YXR-9QCYV-QPFCT__27_X19-98746_0_Volume:MAK_EnterpriseN
4de7cb65-cdf1-4de9-8ae8-e3cce27b9f2c_VK7JG-NPHTM-C97JM-9MPGT-3V66T__48_X19-98841_0_____Retail_Professional
9fbaf5d6-4d83-4422-870d-fdda6e5858aa_2B87N-8KFHP-DKV6R-Y2C8J-PKCKT__49_X19-98859_0_____Retail_ProfessionalN
f742e4ff-909d-4fe9-aacb-3231d24a0c58_4CPRK-NM3K3-X6XXQ-RXX86-WXCHW__98_X19-98877_0_____Retail_CoreN
1d1bac85-7365-4fea-949a-96978ec91ae0_N2434-X9D7W-8PF6X-8DV9T-8TYMD__99_X19-99652_0_____Retail_CoreCountrySpecific
3ae2cc14-ab2d-41f4-972f-5e20142771dc_BT79Q-G7N6G-PGBYW-4YWX6-6F4BT_100_X19-99661_0_____Retail_CoreSingleLanguage
2b1f36bb-c1cd-4306-bf5c-a0367c2d97d8_YTMG3-N6DKC-DKB77-7M9GH-8HVX7_101_X19-98868_0_____Retail_Core
2a6137f3-75c0-4f26-8e3e-d83d802865a4_XKCNC-J26Q9-KFHD2-FKTHY-KD72Y_119_X19-99606_0_OEM:NONSLP_PPIPro
e558417a-5123-4f6f-91e7-385c1c7ca9d4_YNMGQ-8RYV3-4PGQ3-C8XTP-7CFBY_121_X19-98886_0_____Retail_Education
c5198a66-e435-4432-89cf-ec777c9d0352_84NGF-MHBT6-FXBX8-QWJK7-DRR8H_122_X19-98892_0_____Retail_EducationN
cce9d2de-98ee-4ce2-8113-222620c64a27_KCNVH-YKWX8-GJJB9-H9FDT-6F7W2_125_X22-66075_1_Volume:MAK_EnterpriseS_VB
d06934ee-5448-4fd1-964a-cd077618aa06_43TBQ-NH92J-XKTM7-KT3KK-P39PB_125_X21-83233_0_OEM:NONSLP_EnterpriseS_RS5
706e0cfd-23f4-43bb-a9af-1a492b9f1302_NK96Y-D9CD8-W44CQ-R8YTK-DYJWX_125_X21-05035_0_OEM:NONSLP_EnterpriseS_RS1
faa57748-75c8-40a2-b851-71ce92aa8b45_FWN7H-PF93Q-4GGP8-M8RF3-MDWWW_125_X19-99617_0_OEM:NONSLP_EnterpriseS_TH
2c060131-0e43-4e01-adc1-cf5ad1100da8_RQFNW-9TPM3-JQ73T-QV4VQ-DV9PT_126_X22-66108_1_Volume:MAK_EnterpriseSN_VB
e8f74caa-03fb-4839-8bcc-2e442b317e53_M33WV-NHY3C-R7FPM-BQGPT-239PG_126_X21-83264_1_Volume:MAK_EnterpriseSN_RS5
3d1022d8-969f-4222-b54b-327f5a5af4c9_2DBW3-N2PJG-MVHW3-G7TDK-9HKR4_126_X21-04921_0_Volume:MAK_EnterpriseSN_RS1
60c243e1-f90b-4a1b-ba89-387294948fb6_NTX6B-BRYC2-K6786-F6MVQ-M7V2X_126_X19-98770_0_Volume:MAK_EnterpriseSN_TH
eb6d346f-1c60-4643-b960-40ec31596c45_DXG7C-N36C4-C4HTG-X4T3X-2YV77_161_X21-43626_0_____Retail_ProfessionalWorkstation
89e87510-ba92-45f6-8329-3afa905e3e83_WYPNQ-8C467-V2W6J-TX4WX-WT2RQ_162_X21-43644_0_____Retail_ProfessionalWorkstationN
62f0c100-9c53-4e02-b886-a3528ddfe7f6_8PTT6-RNW4C-6V7J2-C2D3X-MHBPB_164_X21-04955_0_____Retail_ProfessionalEducation
13a38698-4a49-4b9e-8e83-98fe51110953_GJTYN-HDMQY-FRR76-HVGC7-QPF8P_165_X21-04956_0_____Retail_ProfessionalEducationN
df96023b-dcd9-4be2-afa0-c6c871159ebe_NJCF7-PW8QT-3324D-688JX-2YV66_175_X21-41295_0_____Retail_ServerRdsh
d4ef7282-3d2c-4cf0-9976-8854e64a8d1e_V3WVW-N2PV2-CGWC3-34QGF-VMJ2C_178_X21-32983_0_____Retail_Cloud
af5c9381-9240-417d-8d35-eb40cd03e484_NH9J3-68WK7-6FB93-4K3DF-DJ4F6_179_X21-32987_0_____Retail_CloudN
8ab9bdd1-1f67-4997-82d9-8878520837d9_XQQYW-NFFMW-XJPBH-K8732-CKFFD_188_X21-99378_0_____OEM:DM_IoTEnterprise
ed655016-a9e8-4434-95d9-4345352c2552_QPM6N-7J2WJ-P88HH-P3YRH-YY74H_191_X21-99682_0_OEM:NONSLP_IoTEnterpriseS_VB
d4bdc678-0a4b-4a32-a5b3-aaa24c3b0f24_K9VKN-3BGWV-Y624W-MCRMQ-BHDCD_202_X22-53884_0_____Retail_CloudEditionN
92fb8726-92a8-4ffc-94ce-f82e07444653_KY7PN-VR6RX-83W6Y-6DDYQ-T6R4W_203_X22-53847_0_____Retail_CloudEdition
d4f9b41f-205c-405e-8e08-3d16e88e02be_J7NJW-V6KBM-CC8RW-Y29Y4-HQ2MJ_205_X23-15027_0_OEM:NONSLP_IoTEnterpriseSK
) do (
for /f "tokens=1-9 delims=_" %%A in ("%%#") do (

if %1==key if %osSKU%==%%C (

REM Detect key attempt 1

if "%2"=="attempt1" if not defined key (
echo "!applist!" | find /i "%%A" 1>nul && (
if %%E==1 set notworking=1
set key=%%B
set pfn=Microsoft.Windows.%%C.%%D_8wekyb3d8bbwe
)
)

REM Detect key attempt 2

if "%2"=="attempt2" if not defined key (
set actidnotfound=1
set 8th=%%H
if not defined 8th (
if %%E==1 set notworking=1
set key=%%B
set pfn=Microsoft.Windows.%%C.%%D_8wekyb3d8bbwe
) else (
echo "%branch%" | find /i "%%H" 1>nul && (
if %%E==1 set notworking=1
set key=%%B
set pfn=Microsoft.Windows.%%C.%%D_8wekyb3d8bbwe
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
125_EnterpriseS-2021___________cce9d2de-98ee-4ce2-8113-222620c64a27_ed655016-a9e8-4434-95d9-4345352c2552_QPM6N-7J2WJ-P88HH-P3YRH-YY74H_IoTEnterpriseS-2021
191_IoTEnterpriseS-Win11_______59eb965c-9150-42b7-a0ec-22151b9897c5_d4f9b41f-205c-405e-8e08-3d16e88e02be_J7NJW-V6KBM-CC8RW-Y29Y4-HQ2MJ_IoTEnterpriseSK-Win11
138_ProfessionalSingleLanguage_a48938aa-62fa-4966-9d44-9f04da3f72f2_4de7cb65-cdf1-4de9-8ae8-e3cce27b9f2c_VK7JG-NPHTM-C97JM-9MPGT-3V66T_Professional
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

::  Script changes below values in official gatherosstate.exe so that it can generate usable ticket in Windows unlicensed state
::  github.com/Gamers-Against-Weed/GamersOsState

:hex:[
$bytes  = [System.IO.File]::ReadAllBytes("gatherosstate.exe")
$bytes[320] = 0xf8
$bytes[321] = 0xfb
$bytes[322] = 0x05
$bytes[324] = 0x03
$bytes[13672] = 0x25
$bytes[13674] = 0x73
$bytes[13676] = 0x3b
$bytes[13678] = 0x00
$bytes[13680] = 0x00
$bytes[13682] = 0x00
$bytes[13684] = 0x00
$bytes[32748] = 0xe9
$bytes[32749] = 0x9e
$bytes[32750] = 0x00
$bytes[32751] = 0x00
$bytes[32752] = 0x00
$bytes[32894] = 0x8b
$bytes[32895] = 0x44
$bytes[32897] = 0x64
$bytes[32898] = 0x85
$bytes[32899] = 0xc0
$bytes[32900] = 0x0f
$bytes[32901] = 0x85
$bytes[32902] = 0x1c
$bytes[32903] = 0x02
$bytes[32904] = 0x00
$bytes[32906] = 0xe9
$bytes[32907] = 0x3c
$bytes[32908] = 0x01
$bytes[32909] = 0x00
$bytes[32910] = 0x00
$bytes[32911] = 0x85
$bytes[32912] = 0xdb
$bytes[32913] = 0x75
$bytes[32914] = 0xeb
$bytes[32915] = 0xe9
$bytes[32916] = 0x69
$bytes[32917] = 0xff
$bytes[32918] = 0xff
$bytes[32919] = 0xff
$bytes[33094] = 0xe9
$bytes[33095] = 0x80
$bytes[33096] = 0x00
$bytes[33097] = 0x00
$bytes[33098] = 0x00
$bytes[33449] = 0x64
$bytes[33576] = 0x8d
$bytes[33577] = 0x54
$bytes[33579] = 0x24
$bytes[33580] = 0xe9
$bytes[33581] = 0x55
$bytes[33582] = 0x01
$bytes[33583] = 0x00
$bytes[33584] = 0x00
$bytes[33978] = 0xc3
$bytes[34189] = 0x59
$bytes[34190] = 0xeb
$bytes[34191] = 0x28
$bytes[34238] = 0xe9
$bytes[34239] = 0x4f
$bytes[34240] = 0x00
$bytes[34241] = 0x00
$bytes[34242] = 0x00
$bytes[34346] = 0x24
$bytes[34376] = 0xeb
$bytes[34377] = 0x63
[System.IO.File]::WriteAllBytes("gatherosstatemodified.exe", $bytes)
:hex:]

::========================================================================================================================================