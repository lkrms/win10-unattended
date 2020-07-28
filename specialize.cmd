@ECHO OFF

SET "SCRIPT_DIR=%~dp0"
SET ERRORS=0
SET CHOCO_COUNT=0
SET CHOCO_ERRORS=0

IF EXIST "%SCRIPT_DIR%InstallEmbeddedProductKey.ps1" (

    ECHO Installing embedded product key for Windows
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%InstallEmbeddedProductKey.ps1" || (
        CALL :error "%SCRIPT_DIR%InstallEmbeddedProductKey.ps1" failed
    )
    ECHO:

)

IF EXIST "%SCRIPT_DIR%Wi-Fi.xml" (

    netsh wlan show interfaces >nul || (
        ECHO Skipping Wi-Fi setup ^(no WLAN interfaces^)
        GOTO :checkOnline
    )

    ECHO Adding Wi-Fi profile from %SCRIPT_DIR%Wi-Fi.xml
    netsh wlan add profile filename="%SCRIPT_DIR%Wi-Fi.xml" || (
        CALL :error "netsh wlan add profile" failed
    )

)

:checkOnline
CALL :now
SET START=%NOW%
SET SECONDS=
ECHO Waiting for Internet connection

:checkOnlineAgain
CALL :online && GOTO :connected
:: Output a full stop after every failure
<NUL >&2 SET /P "_NUL=."
CALL :now
SET /A "SECONDS=NOW-START"
:: Give up after 5 minutes
IF %SECONDS% GEQ 300 (
    ECHO:
    ECHO No Internet connection
    ECHO Will try again after rebooting
    ping -n 6 127.0.0.1 >nul
    EXIT /B 2
)
:: Sleep for 2 seconds
ping -n 3 127.0.0.1 >nul
GOTO :checkOnlineAgain

:connected
IF DEFINED SECONDS >&2 ECHO:
ECHO Connection established
ECHO:

ECHO Installing Chocolatey
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" || (
    ECHO Exiting ^(Chocolatey installation failed^)
    EXIT /B 3
)
SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
ECHO:

:: choco feature enable -n=logEnvironmentValues -y
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
CALL :choco sumatrapdf --ia="/d ""%ProgramFiles%\SumatraPDF"""
CALL :choco tightvnc --ia="ADDLOCAL=Server SET_ACCEPTHTTPCONNECTIONS=1 SET_CONTROLPASSWORD=1 SET_PASSWORD=1 SET_RUNCONTROLINTERFACE=1 SET_USECONTROLAUTHENTICATION=1 SET_USEVNCAUTHENTICATION=1 VALUE_OF_ACCEPTHTTPCONNECTIONS=0 VALUE_OF_CONTROLPASSWORD=nZ4yUJ3O VALUE_OF_PASSWORD=Shabbyr= VALUE_OF_RUNCONTROLINTERFACE=0 VALUE_OF_USECONTROLAUTHENTICATION=1 VALUE_OF_USEVNCAUTHENTICATION=1"
CALL :choco vlc

ECHO %CHOCO_COUNT% packages installed by Chocolatey ^(errors: %CHOCO_ERRORS%^)
ECHO:

IF NOT EXIST "%SCRIPT_DIR%Office365\setup.exe" GOTO :skipOffice
IF EXIST "%SCRIPT_DIR%Office365\sources" XCOPY "%SCRIPT_DIR%Office365\sources" C:\OfficeDeploymentTool\sources /E /I /Q /Y
ECHO Downloading Office 365
"%SCRIPT_DIR%Office365\setup.exe" /download "%SCRIPT_DIR%Office365\Configuration.xml" || (
    CALL :error "%SCRIPT_DIR%Office365\setup.exe" /download "%SCRIPT_DIR%Office365\Configuration.xml" failed
    GOTO :skipOffice
)
ECHO Installing Office 365
"%SCRIPT_DIR%Office365\setup.exe" /configure "%SCRIPT_DIR%Office365\Configuration.xml" || (
    CALL :error "%SCRIPT_DIR%Office365\setup.exe" /configure "%SCRIPT_DIR%Office365\Configuration.xml" failed
)

:skipOffice
IF EXIST "%SCRIPT_DIR%AppAssociations.xml" (
    ECHO Configuring default apps
    DISM /Online /Import-DefaultAppAssociations:"%SCRIPT_DIR%AppAssociations.xml" || (
        CALL :error "DISM /Online /Import-DefaultAppAssociations" failed
    )
)

ECHO Exiting ^(end of script^)
ECHO Errors: %ERRORS%
EXIT /B 0


:now
FOR /F "usebackq tokens=*" %%l IN (
    `powershell -NoProfile -Command "& {[int32](Get-Date -UFormat "%%s")}"`
) DO SET NOW=%%l
EXIT /B 0

:online
ping -4 -n 1 -w 1000 1.1.1.1 | FINDSTR /R /C:"TTL=[0-9][0-9]*$" >nul
EXIT /B

:choco
ECHO Installing %1
SET /A "CHOCO_COUNT+=1"
choco install %* -y --no-progress || (
    CALL :error "choco install %* -y --no-progress" failed
    SET /A "CHOCO_ERRORS+=1"
)
EXIT /B

:error
ECHO ERROR ^(%ERRORLEVEL%^): %*
SET /A "ERRORS+=1"
EXIT /B
