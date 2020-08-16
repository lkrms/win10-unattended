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

CALL :log ===== Starting %~f0

IF EXIST "%SCRIPT_DIR%SetNetworkCategory.ps1" (
    CALL :log Setting network category to Private for all Public connection profiles
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%SetNetworkCategory.ps1" || (
        CALL :error "powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%SetNetworkCategory.ps1"" failed
    )
)

CALL :log Disabling reserved storage
DISM /Online /Set-ReservedStorageState /State:Disabled || (
    CALL :error "DISM /Online /Set-ReservedStorageState /State:Disabled" failed
)

IF EXIST "%SCRIPT_DIR%AddPrinters.ps1" (
    CALL :log Configuring printers
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%AddPrinters.ps1" || (
        CALL :error "powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%AddPrinters.ps1"" failed
    )
)

IF EXIST "%SCRIPT_DIR%AppAssociations.xml" (
    CALL :log Configuring default apps
    DISM /Online /Import-DefaultAppAssociations:"%SCRIPT_DIR%AppAssociations.xml" || (
        CALL :error "DISM /Online /Import-DefaultAppAssociations:"%SCRIPT_DIR%AppAssociations.xml"" failed
    )
)

IF EXIST %SystemDrive%\Office365\install.cmd (
    CALL :log Installing Office 365
    CALL %SystemDrive%\Office365\install.cmd || (
        CALL :error "%SystemDrive%\Office365\install.cmd" failed
    )
)

IF EXIST %SystemDrive%\Office365\OneDriveSetup.exe (
    CALL :log Installing OneDrive for all users
    %SystemDrive%\Office365\OneDriveSetup.exe /silent /allusers || (
        CALL :error "%SystemDrive%\Office365\OneDriveSetup.exe /silent /allusers" failed
    )
)

IF %ERRORS% EQU 0 (
    CALL :log Disabling first boot scheduled task
    SCHTASKS /Change /TN "Unattended - first boot" /DISABLE
    EXIT /B 0
)
EXIT /B 1


:log
ECHO [%DATE% %TIME%] %*
EXIT /B

:error
CALL :log ERROR ^(%ERRORLEVEL%^): %*
SET /A "ERRORS+=1"
EXIT /B
