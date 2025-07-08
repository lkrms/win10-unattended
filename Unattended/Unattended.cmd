@ECHO OFF

SETLOCAL

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 3
)

IF "%1"=="/start" GOTO :start
IF NOT EXIST %SystemDrive%\Unattended\Logs (
    MD %SystemDrive%\Unattended\Logs || EXIT /B 3
    IF EXIST %SystemDrive%\Unattended.log (MOVE /Y %SystemDrive%\Unattended.log %SystemDrive%\Unattended\Logs || EXIT /B 3)
)
SET "RETURN_CMD=%TEMP%\%~n0Return.cmd"
SET RETURN_CODE=0
(CMD /V:ON /C ""%~0" /start %* & ECHO SET RETURN_CODE=!ERRORLEVEL! >"%%RETURN_CMD%%"") 2>&1 | powershell -NoProfile -Command "$input | tee %SystemDrive%\Unattended\Logs\Unattended.log -Append"
CALL "%RETURN_CMD%"
DEL /F /Q "%RETURN_CMD%"
EXIT /B %RETURN_CODE%

:start
SHIFT /1
SET "SCRIPT_DIR=%~dp0"
SET ERRORS=0
SET RETURN_CODE=0
SET CHOCO_COUNT=0
SET CHOCO_ERRORS=0
SET DISABLE_UCPD=1

FOR /F "tokens=2,* skip=2" %%G IN (
    'REG QUERY HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State /v ImageState'
) DO SET SETUP_STATE=%%H
IF "%SETUP_STATE%"=="IMAGE_STATE_COMPLETE" SET SETUP_STATE=complete
IF "%SETUP_STATE%"=="IMAGE_STATE_GENERALIZE_RESEAL_TO_AUDIT" SET SETUP_STATE=generalize
IF "%SETUP_STATE%"=="IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE" SET SETUP_STATE=generalize
IF "%SETUP_STATE%"=="IMAGE_STATE_SPECIALIZE_RESEAL_TO_AUDIT" SET SETUP_STATE=specialize
IF "%SETUP_STATE%"=="IMAGE_STATE_SPECIALIZE_RESEAL_TO_OOBE" SET SETUP_STATE=specialize
IF "%SETUP_STATE%"=="IMAGE_STATE_UNDEPLOYABLE" SET SETUP_STATE=audit

IF "%1"=="/1" GOTO :pass1
IF "%1"=="/2" GOTO :pass2
IF "%1"=="/3" GOTO :pass3
IF "%1"=="/4" GOTO :pass4
ECHO Usage: Unattended.cmd ^(/1^|/2^|/3^|/4^) [/debug]
EXIT /B 3


:pass1

CALL :log ===== Starting %~f0 pass 1 ^(state: %SETUP_STATE%^)

SETLOCAL EnableDelayedExpansion

IF "%2"=="/debug" (
    CALL :log Enabling remote access to admin shares
    REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f
    SET RETURN_CODE=1
)

SET EXCLUDE=
IF EXIST %SystemDrive%\Unattended\Optional\Unattended.reg.d (
    SET "EXCLUDE="%SCRIPT_DIR%Optional\Unattended.reg.d""
)
IF NOT "%SCRIPT_DIR%"=="%SystemDrive%\Unattended\" (
    CALL :log Copying %SCRIPT_DIR:~0,-1% to %SystemDrive%\Unattended
    ROBOCOPY "%SCRIPT_DIR:~0,-1%" %SystemDrive%\Unattended /MIR /XD %SystemDrive%\Unattended\Logs %SystemDrive%\Unattended\Optional\Unattended.reg.d %EXCLUDE% /NJH /NJS /NP || (
        rem The first two bits of robocopy's exit code indicate success:
        rem - 1 = one or more files copied
        rem - 2 = excluded files detected
        IF !ERRORLEVEL! GEQ 4 EXIT /B 3
    )

    IF EXIST "%SCRIPT_DIR%..\Drivers2" (
        CALL :log Adding drivers
        FOR /F "delims=" %%G IN ('WHERE /R "%SCRIPT_DIR%..\Drivers2" *.inf 2^>NUL') DO (
            PNPUTIL /add-driver "%%G" /install || (
                IF !ERRORLEVEL! EQU 3010 (
                    SET RETURN_CODE=1
                ) ELSE (
                    CALL :log "PNPUTIL /add-driver" return value: !ERRORLEVEL!
                )
            )
        )

        FOR /F "delims=" %%G IN ('WHERE "%SCRIPT_DIR%..\Drivers2:*.msi" 2^>NUL') DO (
            CALL :installMsi "%%G" || IF !ERRORLEVEL! EQU 3010 SET RETURN_CODE=1
        )
    )
)

CALL :runOrReport ATTRIB +S +H "%SystemDrive%\Unattended"

IF %DISABLE_UCPD% NEQ 0 (
    rem - See https://kolbi.cz/blog/2024/04/03/userchoice-protection-driver-ucpd-sys/
    rem - Necessary if setting "TaskbarDa", for example
    CALL :log Disabling the "User Choice Protection" driver
    CALL :runOrReport REG ADD HKLM\SYSTEM\CurrentControlSet\Services\UCPD /v Start /t REG_DWORD /d 4 /f
    CALL :runOrReport SCHTASKS /Change /TN "\Microsoft\Windows\AppxDeploymentClient\UCPD velocity" /DISABLE
    SET RETURN_CODE=1
)

IF %RETURN_CODE% EQU 0 (
    CALL :log ===== %~f0 pass 1 finished
) ELSE (
    CALL :log ===== %~f0 pass 1 finished; reboot required to finalise driver installation
)
EXIT /B %RETURN_CODE%


:pass2

CALL :log ===== Starting %~f0 pass 2 ^(state: %SETUP_STATE%^)

SETLOCAL EnableDelayedExpansion

IF EXIST "%SCRIPT_DIR%..\Updates" (
    FOR /F "usebackq delims=" %%G IN (
        `powershell -NoProfile -Command "Get-ChildItem -Path '%SCRIPT_DIR%..\Updates' -Include *.cab, *.msu -Recurse | Select-Object -ExpandProperty Directory | ForEach-Object FullName | Sort-Object -Unique"`
    ) DO (
        IF !RETURN_CODE! EQU 1 (
            CALL :log ===== %~f0 pass 2 not finished; reboot required to continue update servicing
            EXIT /B 2
        )
        CALL :log Installing updates: %%G
        DISM /Online /Add-Package /PackagePath:"%%G" /IgnoreCheck /NoRestart || (
            IF !ERRORLEVEL! EQU 3010 (
                SET RETURN_CODE=1
            ) ELSE (
                CALL :log "DISM /Online /Add-Package /PackagePath:"%%G"" return value: !ERRORLEVEL!
            )
        )
    )
)

IF %RETURN_CODE% EQU 0 (
    CALL :log ===== %~f0 pass 2 finished
) ELSE (
    CALL :log ===== %~f0 pass 2 finished with no errors; reboot required to finalise update servicing
)
EXIT /B %RETURN_CODE%


:pass3

CALL :log ===== Starting %~f0 pass 3 ^(state: %SETUP_STATE%^)

CALL :optPs1 InstallOriginalProductKey.ps1 "Installing original product key"

IF EXIST "%SCRIPT_DIR%..\Wi-Fi.xml" (
    netsh wlan show interfaces >NUL || (
        CALL :log Skipping Wi-Fi setup ^(no WLAN interfaces^)
        GOTO :checkOnline
    )
    CALL :log Adding Wi-Fi profile from %SCRIPT_DIR%..\Wi-Fi.xml
    netsh wlan add profile filename="%SCRIPT_DIR%..\Wi-Fi.xml" || (
        CALL :error "netsh wlan add profile" failed
    )
)

:checkOnline
CALL :awaitConnectivity || EXIT /B 3

WHERE /Q choco && (
    CALL :log Updating Chocolatey
    CALL :runOrReport choco upgrade chocolatey -y --no-progress --fail-on-unfound || EXIT /B 3
    GOTO :skipChoco
)

CALL :log Installing Chocolatey
:: Install from %SystemDrive% for write access to install.ps1 if needed
CALL :runOrReport CALL "%SystemDrive%\Unattended\InstallChocolatey.cmd" || EXIT /B 3
SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

:skipChoco
choco feature enable -n=allowGlobalConfirmation -y
choco feature enable -n=useRememberedArgumentsForUpgrades -y

CALL :choco 7zip
CALL :choco Firefox
CALL :choco GoogleChrome --ignore-checksum && CALL :installInitialPreferences
CALL :choco notepadplusplus
CALL :choco sumatrapdf
CALL :choco vlc

CALL :optCmd InstallCustomApps.cmd "/unattended"

IF "%2"=="/debug" (
    rem Don't install procmon if it's already installed, e.g. via sysinternals
    WHERE /Q Procmon || CALL :choco procmon

    CALL :log Enabling Process Monitor log of next boot
    Procmon /AcceptEula /EnableBootLogging
)

CALL :log %CHOCO_COUNT% packages deployed by Chocolatey ^(errors: %CHOCO_ERRORS%^)

IF EXIST "%SCRIPT_DIR%..\MSI" (
    FOR /F "delims=" %%G IN ('WHERE /R "%SCRIPT_DIR%..\MSI" *.msi 2^>NUL') DO CALL :installMsi "%%G"
)

IF EXIST "%SCRIPT_DIR%..\Office365\OneDriveSetup.exe" (
    CALL :log Installing OneDrive for all users
    CALL :runOrReport "%SCRIPT_DIR%..\Office365\OneDriveSetup.exe" /silent /allusers
)

IF EXIST "%SCRIPT_DIR%..\Office365\teamsbootstrapper.exe" (
    IF EXIST "%SCRIPT_DIR%..\Office365\MSTeams-x64.msix" (
        CALL :log Installing Teams for all users
        CALL :runOrReport "%SCRIPT_DIR%..\Office365\teamsbootstrapper.exe" -p -o "%SCRIPT_DIR%..\Office365\MSTeams-x64.msix"
    )
)

IF NOT "%SETUP_STATE%"=="complete" DEL /F /Q "%PUBLIC%\Desktop\*.lnk" 2>NUL

CALL :optCmd ApplyRegistrySettings.cmd "/start"

:: Exclude "admin" from user list during sign-in
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v admin /t REG_DWORD /d 0 /f

IF EXIST "%SCRIPT_DIR%Optional\AppAssociations.xml" (
    CALL :log Importing default app associations
    CALL :runOrReport DISM /Online /Import-DefaultAppAssociations:"%SCRIPT_DIR%Optional\AppAssociations.xml"
)

IF %ERRORS% NEQ 0 GOTO :endPass3
IF NOT EXIST "%SCRIPT_DIR%..\Office365\install.cmd" GOTO :endPass3
IF EXIST "%SCRIPT_DIR%..\Office365\Office" GOTO :endPass3
CALL :log ===== %~f0 pass 3 finished with no errors; reboot required for Office 365 installer guest share access
EXIT /B 1

:endPass3
CALL :log ===== %~f0 pass 3 finished with %ERRORS% errors
IF %ERRORS% NEQ 0 EXIT /B 3
EXIT /B 0


:pass4

CALL :log ===== Starting %~f0 pass 4 ^(state: %SETUP_STATE%^)

IF EXIST "%SCRIPT_DIR%..\Office365\install.cmd" (
    CALL :awaitConnectivity || EXIT /B 3
    CALL :log Installing Office 365
    CALL :runOrReport "%SCRIPT_DIR%..\Office365\install.cmd"
)

CALL :optPs1 RemoveBloatware.ps1 "Removing bloatware"

IF NOT "%SETUP_STATE%"=="complete" (
    CALL :log Installing answer file for generalize and OOBE passes
    IF NOT EXIST "%WINDIR%\Panther\Unattend" MD "%WINDIR%\Panther\Unattend"
    COPY "%SCRIPT_DIR%..\Audit.xml" "%WINDIR%\Panther\Unattend\Unattend.xml" /Y || EXIT /B 3
)

CALL :log ===== %~f0 pass 4 finished with %ERRORS% errors
IF %ERRORS% NEQ 0 EXIT /B 3
EXIT /B 0


:awaitConnectivity
CALL :checkService mpssvc "Windows Defender Firewall"
CALL :checkService LanmanWorkstation Workstation
CALL :checkService WinHttpAutoProxySvc "WinHTTP Web Proxy Auto-Discovery Service"
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
:: Give up after 1 hour
IF %SECONDS% GEQ 3600 (
    >CON ECHO:
    CALL :log Exiting ^(no Internet connection after 1 hour^)
    ping -n 6 127.0.0.1 >NUL
    EXIT /B 1
)
:: Sleep for 2 seconds
ping -n 3 127.0.0.1 >NUL
GOTO :checkOnlineAgain

:connected
IF DEFINED SECONDS >CON ECHO:
CALL :log Connection established
EXIT /B 0


:now
FOR /F "usebackq delims=" %%G IN (
    `powershell -NoProfile -Command "[int32](Get-Date -UFormat '%%s')"`
) DO SET NOW=%%G
EXIT /B

:online
ping -4 -n 1 -w 1000 1.1.1.1 | FINDSTR /R /C:"TTL=[0-9][0-9]*$" >NUL
EXIT /B

:choco
CALL :log Deploying %1
SET /A "CHOCO_COUNT+=1"
CALL :runOrReport choco upgrade %* -y --no-progress --fail-on-unfound || SET /A "CHOCO_ERRORS+=1"
EXIT /B

:: See https://support.google.com/chrome/a/answer/187948?hl=en
:installInitialPreferences
IF NOT EXIST "%SCRIPT_DIR%Optional\initial_preferences" EXIT /B 0
SET "DIR=%ProgramFiles%\Google\Chrome\Application"
IF NOT EXIST "%DIR%" EXIT /B 1
COPY "%SCRIPT_DIR%Optional\initial_preferences" "%DIR%\initial_preferences" /Y
EXIT /B

:checkService
sc query "%~1" | FIND "STATE" | FIND "RUNNING" >NUL && EXIT /B
CALL :log Starting service %~1 ^(%~2^)
sc start "%~1"
:: Don't report an error if the service is already running
IF %ERRORLEVEL% EQU 1056 EXIT /B 0
IF %ERRORLEVEL% NEQ 0 CALL :error "sc start "%~1"" failed
EXIT /B

:installMsi
SET "PKG_FILE=%~1"
SET "LOG_FILE=%SystemDrive%\Unattended\Logs\%~n0WindowsInstaller-%~n1.log"
CALL :log Installing %PKG_FILE%
START /WAIT /B msiexec /i "%PKG_FILE%" /qn /norestart /L+*vx "%LOG_FILE%" && EXIT /B
IF %ERRORLEVEL% EQU 3010 EXIT /B
CALL :error "msiexec /i "%PKG_FILE%"" failed, see %LOG_FILE%
EXIT /B

:optCmd
SET "SCRIPT=%SCRIPT_DIR%Optional\%~1"
SET "ARGS=%~2"
IF EXIST "%SCRIPT%" (
    CALL "%SCRIPT%" %ARGS% || (
        CALL :error "%SCRIPT%" failed
    )
)
EXIT /B

:optPs1
SET "SCRIPT=%SCRIPT_DIR%Optional\%~1"
SET "MESSAGE=%~2"
IF EXIST "%SCRIPT%" (
    IF NOT "%MESSAGE%"=="" CALL :log %MESSAGE%
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" || (
        CALL :error "%SCRIPT%" failed
    )
)
EXIT /B

:runOrReport
%* || CALL :error "%*" failed
EXIT /B

:log
ECHO [%DATE% %TIME%] %*
EXIT /B

:error
SET RESULT=%ERRORLEVEL%
CALL :log ERROR ^(%RESULT%^): %*
SET /A "ERRORS+=1"
EXIT /B %RESULT%
