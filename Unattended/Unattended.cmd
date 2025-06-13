@ECHO OFF

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 1
)

IF "%1"=="/start" GOTO :start
CALL "%~0" /start %* 2>&1 | powershell -NoProfile -Command "$input | tee %SystemDrive%\Unattended.log -Append"
EXIT /B %ERRORLEVEL%

:start
SHIFT /1
SET "SCRIPT_DIR=%~dp0"
SET ERRORS=0
SET CHOCO_COUNT=0
SET CHOCO_EXTRAS=0
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
    EXIT /B 1
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

:: Disable UAC remote restrictions (required for access to admin shares)
:: REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f

:: Hide the "admin" user
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v admin /t REG_DWORD /d 0 /f

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

:skipChoco
choco feature enable -n=allowGlobalConfirmation -y
choco feature enable -n=useRememberedArgumentsForUpgrades -y

:: Otherwise SumatraPDF won't install
IF NOT EXIST "%USERPROFILE%\Desktop" MD "%USERPROFILE%\Desktop"

CALL :choco 7zip
CALL :choco Firefox
:: CALL :choco flashplayerplugin
CALL :choco GoogleChrome --ignore-checksum
:: CALL :choco keepassxc --ia="AUTOSTARTPROGRAM=0"
CALL :choco notepadplusplus
CALL :choco skype
CALL :choco sumatrapdf --ia="/d ""%ProgramFiles%\SumatraPDF"""
CALL :choco vlc

FOR %%a IN (%*) DO CALL :arg %%a

CALL :log %CHOCO_COUNT% packages installed or updated by Chocolatey ^(errors: %CHOCO_ERRORS%^)

IF NOT "%2"=="/debug" GOTO :noDebug
CALL :log Exporting registry settings
REG EXPORT HKLM\SOFTWARE %SystemDrive%\Unattended-HKLM-SOFTWARE.reg

CALL :log Enabling Process Monitor log of next boot
Procmon /AcceptEula /EnableBootLogging

:noDebug
CALL :log ===== %~f0 finished with %ERRORS% errors
IF %ERRORS% EQU 0 EXIT /B 0
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

:arg
SET ARG=%1
IF NOT %ARG:~0,1%==/ (
    IF %CHOCO_EXTRAS% EQU 0 CALL :log Installing command-line packages
    SET /A "CHOCO_EXTRAS+=1"
    CALL :choco %ARG%
)
EXIT /B

:log
ECHO [%DATE% %TIME%] %*
EXIT /B

:error
CALL :log ERROR ^(%ERRORLEVEL%^): %*
SET /A "ERRORS+=1"
EXIT /B
