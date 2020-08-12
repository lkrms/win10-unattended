@ECHO OFF

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    GOTO :exitError
)

IF "%1"=="/start" GOTO :start
CALL "%~0" /start %* 2>&1 | powershell -NoProfile -Command "$input | tee %SystemDrive%\Unattended.log -Append"
IF "%1"=="/exit" EXIT 1
EXIT /B

:start
SHIFT /1
SET "SCRIPT_DIR=%~dp0"
SET ERRORS=0
SET CHOCO_COUNT=0
SET CHOCO_ERRORS=0

CALL :log ===== Starting %~f0

IF NOT "%SCRIPT_DIR%"=="%SystemDrive%\Unattended\" (
    CALL :log Copying %SCRIPT_DIR% to %SystemDrive%\Unattended
    XCOPY "%SCRIPT_DIR%" %SystemDrive%\Unattended /E /I /Q /Y
    IF EXIST "%SCRIPT_DIR%..\Office365" (
        CALL :log Copying %SCRIPT_DIR%..\Office365 to %SystemDrive%\Office365
        XCOPY "%SCRIPT_DIR%..\Office365" %SystemDrive%\Office365 /I /Q /Y
    )
    CALL :log Scheduling %SystemDrive%\Unattended\UnattendedFirstBoot.cmd
    SCHTASKS /Create /F /TN "Unattended - first boot" /TR "%%SystemDrive%%\Unattended\UnattendedFirstBoot.cmd" /SC ONSTART /RU SYSTEM
)

IF EXIST "%SCRIPT_DIR%InstallOriginalProductKey.ps1" (
    CALL :log Installing original product key
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%InstallOriginalProductKey.ps1" || (
        CALL :error "%SCRIPT_DIR%InstallOriginalProductKey.ps1" failed
    )
)

IF EXIST "%SCRIPT_DIR%..\Wi-Fi.xml" (
    netsh wlan show interfaces >nul || (
        CALL :log Skipping Wi-Fi setup ^(no WLAN interfaces^)
        GOTO :checkOnline
    )
    CALL :log Adding Wi-Fi profile from %SCRIPT_DIR%..\Wi-Fi.xml
    netsh wlan add profile filename="%SCRIPT_DIR%..\Wi-Fi.xml" || (
        CALL :error "netsh wlan add profile" failed
    )
)

:checkOnline
CALL :now
SET START=%NOW%
SET SECONDS=
CALL :log Waiting for Internet connection

:checkOnlineAgain
CALL :online && GOTO :connected
:: Output a full stop after every failure
<NUL >CON SET /P "_NUL=."
CALL :now
SET /A "SECONDS=NOW-START"
:: Give up after 10 minutes
IF %SECONDS% GEQ 600 (
    >CON ECHO:
    CALL :log Exiting ^(no Internet connection after 10 minutes^)
    ping -n 6 127.0.0.1 >nul
    GOTO :exitError
)
:: Sleep for 2 seconds
ping -n 3 127.0.0.1 >nul
GOTO :checkOnlineAgain

:connected
IF DEFINED SECONDS >CON ECHO:
CALL :log Connection established

IF EXIST "%SCRIPT_DIR%RemoveProvisionedPackages.ps1" (
    CALL :log Checking for unnecessary packages
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%RemoveProvisionedPackages.ps1" || (
        CALL :error "%SCRIPT_DIR%RemoveProvisionedPackages.ps1" failed
    )
)

IF EXIST "%SCRIPT_DIR%SetRegistrySettings.cmd" (
    CALL "%SCRIPT_DIR%SetRegistrySettings.cmd" /start || (
        CALL :error "%SCRIPT_DIR%SetRegistrySettings.cmd" failed
    )
)

WHERE /Q choco && (
    CALL :log Updating Chocolatey
    choco upgrade chocolatey -y --no-progress || (
        CALL :log Exiting ^("choco upgrade chocolatey -y --no-progress" failed^)
        GOTO :exitError
    )
    GOTO :skipChoco
)
CALL :log Installing Chocolatey
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" || (
    CALL :log Exiting ^(Chocolatey installation failed^)
    GOTO :exitError
)
SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

:skipChoco
choco feature enable -n=allowGlobalConfirmation -y
choco feature enable -n=useRememberedArgumentsForUpgrades -y

:: Otherwise SumatraPDF won't install
IF NOT EXIST "%USERPROFILE%\Desktop" MD "%USERPROFILE%\Desktop"

CALL :choco 7zip
CALL :choco Firefox
CALL :choco flashplayerplugin
CALL :choco GoogleChrome --ignore-checksum
CALL :choco keepassxc --ia="AUTOSTARTPROGRAM=0"
CALL :choco nextcloud-client
CALL :choco notepadplusplus
CALL :choco skype
CALL :choco sumatrapdf --ia="/d ""%ProgramFiles%\SumatraPDF"""
CALL :choco sysinternals
CALL :choco tightvnc --ia="ADDLOCAL=Server SET_ACCEPTHTTPCONNECTIONS=1 SET_CONTROLPASSWORD=1 SET_PASSWORD=1 SET_RUNCONTROLINTERFACE=1 SET_USECONTROLAUTHENTICATION=1 SET_USEVNCAUTHENTICATION=1 VALUE_OF_ACCEPTHTTPCONNECTIONS=0 VALUE_OF_CONTROLPASSWORD=nZ4yUJ3O VALUE_OF_PASSWORD=Shabbyr= VALUE_OF_RUNCONTROLINTERFACE=0 VALUE_OF_USECONTROLAUTHENTICATION=1 VALUE_OF_USEVNCAUTHENTICATION=1"
CALL :choco vlc

CALL :log %CHOCO_COUNT% packages installed or updated by Chocolatey ^(errors: %CHOCO_ERRORS%^)

IF "%1"=="/exit" GOTO :exit
CALL :log ===== %~f0 finished with %ERRORS% errors
IF %ERRORS% EQU 0 EXIT /B 0
EXIT /B 1

:exit
CALL :log ===== Quitting CMD after %~f0 finished with %ERRORS% errors
IF %ERRORS% EQU 0 EXIT 0
EXIT 1

:exitError
IF "%1"=="/exit" EXIT 1
EXIT /B 1


:now
FOR /F "usebackq tokens=*" %%l IN (
    `powershell -NoProfile -Command "[int32](Get-Date -UFormat "%%s")"`
) DO SET NOW=%%l
EXIT /B

:online
ping -4 -n 1 -w 1000 1.1.1.1 | FINDSTR /R /C:"TTL=[0-9][0-9]*$" >nul
EXIT /B

:choco
CALL :log Installing %1
SET /A "CHOCO_COUNT+=1"
choco upgrade %* -y --no-progress || (
    CALL :error "choco upgrade %* -y --no-progress" failed
    SET /A "CHOCO_ERRORS+=1"
)
EXIT /B

:log
ECHO [%DATE% %TIME%] %*
EXIT /B

:error
CALL :log ERROR ^(%ERRORLEVEL%^): %*
SET /A "ERRORS+=1"
EXIT /B
