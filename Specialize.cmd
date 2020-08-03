@ECHO OFF

SET "SCRIPT_DIR=%~dp0"
SET ERRORS=0
SET CHOCO_COUNT=0
SET CHOCO_ERRORS=0

IF EXIST "%SCRIPT_DIR%InstallOriginalProductKey.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%InstallOriginalProductKey.ps1" || (
        CALL :error "%SCRIPT_DIR%InstallOriginalProductKey.ps1" failed
    )
    ECHO:
)

IF EXIST "%SCRIPT_DIR%Wi-Fi.xml" (
    netsh wlan show interfaces >nul || (
        ECHO Skipping Wi-Fi setup ^(no WLAN interfaces^)
        ECHO:
        GOTO :checkOnline
    )
    ECHO Adding Wi-Fi profile from %SCRIPT_DIR%Wi-Fi.xml
    netsh wlan add profile filename="%SCRIPT_DIR%Wi-Fi.xml" || (
        CALL :error "netsh wlan add profile" failed
    )
    ECHO:
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
:: Give up after 10 minutes
IF %SECONDS% GEQ 600 (
    ECHO:
    ECHO Exiting ^(no Internet connection after 10 minutes^)
    ping -n 6 127.0.0.1 >nul
    EXIT /B 1
)
:: Sleep for 2 seconds
ping -n 3 127.0.0.1 >nul
GOTO :checkOnlineAgain

:connected
IF DEFINED SECONDS >&2 ECHO:
ECHO Connection established
ECHO:

IF EXIST "%SCRIPT_DIR%RemoveProvisionedPackages.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%RemoveProvisionedPackages.ps1" || (
        CALL :error "%SCRIPT_DIR%RemoveProvisionedPackages.ps1" failed
    )
    ECHO:
)

ECHO Applying registry settings
REG LOAD HKLM\DEFAULT %SystemDrive%\Users\Default\NTUSER.DAT || (
    CALL :error "REG LOAD HKLM\DEFAULT %SystemDrive%\Users\Default\NTUSER.DAT" failed
    GOTO :skipReg
)
IF NOT EXIST "%SCRIPT_DIR%Specialize.reg" GOTO :skipRegImport
REG IMPORT "%SCRIPT_DIR%Specialize.reg" || (
    CALL :error "REG IMPORT "%SCRIPT_DIR%Specialize.reg"" failed
)
:skipRegImport
REG ADD "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v {374DE290-123F-4565-9164-39C4925E467B} /t REG_EXPAND_SZ /d "\\hub\%%USERNAME%%\Downloads" /f
REG ADD "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop /t REG_EXPAND_SZ /d "\\hub\%%USERNAME%%\Desktop" /f
REG ADD "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Personal /t REG_EXPAND_SZ /d "\\hub\%%USERNAME%%\Documents" /f
IF EXIST "%SCRIPT_DIR%ResetTaskbar.reg" (
    COPY "%SCRIPT_DIR%ResetTaskbar.reg" "%SystemRoot%" /Y
    :: After each user's first login, reset their taskbar to remove Edge and Mail
    REG ADD HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce /v !ResetTaskbar /t REG_EXPAND_SZ /d "CMD /C REG IMPORT \"%%SystemRoot%%\ResetTaskbar.reg\" && TASKKILL /F /IM explorer.exe && start explorer.exe" /f
)
REG UNLOAD HKLM\DEFAULT

:skipReg
ECHO:
ECHO Installing Chocolatey
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" || (
    ECHO Exiting ^(Chocolatey installation failed^)
    EXIT /B 1
)
SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
ECHO:

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

ECHO %CHOCO_COUNT% packages installed by Chocolatey ^(errors: %CHOCO_ERRORS%^)
ECHO:

IF EXIST "%SCRIPT_DIR%Office365" (
    XCOPY "%SCRIPT_DIR%Office365" %SystemDrive%\Office365 /E /I /Q /Y
)

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
    `powershell -NoProfile -Command "[int32](Get-Date -UFormat "%%s")"`
) DO SET NOW=%%l
EXIT /B

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
