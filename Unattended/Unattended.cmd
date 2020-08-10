@ECHO OFF

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 1
)

IF "%1"=="/start" GOTO :start
CALL "%~0" /start | powershell -NoProfile -Command "$input | tee %SystemDrive%\Unattended.log -Append"
EXIT /B

:start
SET "SCRIPT_DIR=%~dp0"
SET ERRORS=0
SET CHOCO_COUNT=0
SET CHOCO_ERRORS=0

CALL :log ===== Starting %~f0

IF NOT "%SCRIPT_DIR%"=="%SystemDrive%\Unattended\" (
    XCOPY "%SCRIPT_DIR%" %SystemDrive%\Unattended /E /I /Q /Y
    SCHTASKS /Create /F /TN "Unattended - first boot" /TR "%%SystemDrive%%\Unattended\UnattendedFirstBoot.cmd" /SC ONSTART /RU SYSTEM
)

IF EXIST "%SCRIPT_DIR%InstallOriginalProductKey.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%InstallOriginalProductKey.ps1" || (
        CALL :error "%SCRIPT_DIR%InstallOriginalProductKey.ps1" failed
    )
    ECHO:
)

IF EXIST "%SCRIPT_DIR%..\Wi-Fi.xml" (
    netsh wlan show interfaces >nul || (
        CALL :log Skipping Wi-Fi setup ^(no WLAN interfaces^)
        ECHO:
        GOTO :checkOnline
    )
    CALL :log Adding Wi-Fi profile from %SCRIPT_DIR%..\Wi-Fi.xml
    netsh wlan add profile filename="%SCRIPT_DIR%..\Wi-Fi.xml" || (
        CALL :error "netsh wlan add profile" failed
    )
    ECHO:
)

:checkOnline
CALL :now
SET START=%NOW%
SET SECONDS=
CALL :log Waiting for Internet connection

:checkOnlineAgain
CALL :online && GOTO :connected
:: Output a full stop after every failure
<NUL >&2 SET /P "_NUL=."
CALL :now
SET /A "SECONDS=NOW-START"
:: Give up after 10 minutes
IF %SECONDS% GEQ 600 (
    ECHO:
    CALL :log Exiting ^(no Internet connection after 10 minutes^)
    ping -n 6 127.0.0.1 >nul
    EXIT /B 1
)
:: Sleep for 2 seconds
ping -n 3 127.0.0.1 >nul
GOTO :checkOnlineAgain

:connected
IF DEFINED SECONDS >&2 ECHO:
CALL :log Connection established
ECHO:

IF EXIST "%SCRIPT_DIR%RemoveProvisionedPackages.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%RemoveProvisionedPackages.ps1" || (
        CALL :error "%SCRIPT_DIR%RemoveProvisionedPackages.ps1" failed
    )
    ECHO:
)

IF EXIST "%SCRIPT_DIR%SetRegistrySettings.cmd" (
    CALL "%SCRIPT_DIR%SetRegistrySettings.cmd" || (
        CALL :error "%SCRIPT_DIR%SetRegistrySettings.cmd" failed
    )
    ECHO:
)

WHERE /Q choco && (
    CALL :log Updating Chocolatey
    choco upgrade chocolatey -y --no-progress || (
        CALL :log Exiting ^("choco upgrade chocolatey -y --no-progress" failed^)
        EXIT /B 1
    )
    GOTO :skipChoco
)
CALL :log Installing Chocolatey
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" || (
    CALL :log Exiting ^(Chocolatey installation failed^)
    EXIT /B 1
)
SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
ECHO:

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
ECHO:

IF EXIST "%SCRIPT_DIR%..\Office365" (
    XCOPY "%SCRIPT_DIR%..\Office365" %SystemDrive%\Office365 /E /I /Q /Y
)

CALL :log Exiting ^(end of script^)
ECHO Errors: %ERRORS%
EXIT /B 0


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
