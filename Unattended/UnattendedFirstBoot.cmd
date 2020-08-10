@ECHO OFF

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 1
)

SET "SCRIPT_DIR=%~dp0"
SET ERRORS=0

ECHO Disabling sleep when plugged in
POWERCFG /CHANGE standby-timeout-ac 0 || (
    CALL :error "POWERCFG /CHANGE standby-timeout-ac 0" failed
)

:: Set public networks to private
IF EXIST "%SCRIPT_DIR%SetNetworkCategory.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%SetNetworkCategory.ps1" || (
        CALL :error "powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%SetNetworkCategory.ps1"" failed
    )
)

ECHO Disabling reserved storage
DISM /Online /Set-ReservedStorageState /State:Disabled || (
    CALL :error "DISM /Online /Set-ReservedStorageState /State:Disabled" failed
)

IF EXIST "%SCRIPT_DIR%AddPrinters.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%AddPrinters.ps1" || (
        CALL :error "powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%AddPrinters.ps1"" failed
    )
)

IF EXIST "%SCRIPT_DIR%AppAssociations.xml" (
    ECHO Configuring default apps
    DISM /Online /Import-DefaultAppAssociations:"%SCRIPT_DIR%AppAssociations.xml" || (
        CALL :error "DISM /Online /Import-DefaultAppAssociations:"%SCRIPT_DIR%AppAssociations.xml"" failed
    )
)

IF %ERRORS% EQU 0 EXIT /B 0
EXIT /B 1


:error
ECHO ERROR ^(%ERRORLEVEL%^): %*
SET /A "ERRORS+=1"
EXIT /B
