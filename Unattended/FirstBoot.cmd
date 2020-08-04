@ECHO OFF

SET "SCRIPT_DIR=%~dp0"

ECHO Disabling sleep when plugged in
POWERCFG /CHANGE standby-timeout-ac 0

:: Set public networks to private
IF EXIST "%SCRIPT_DIR%SetNetworkCategory.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%SetNetworkCategory.ps1"
)

ECHO Disabling reserved storage
DISM /Online /Set-ReservedStorageState /State:Disabled

IF EXIST "%SCRIPT_DIR%AddPrinters.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%AddPrinters.ps1"
)

IF EXIST "%SCRIPT_DIR%AppAssociations.xml" (
    ECHO Configuring default apps
    DISM /Online /Import-DefaultAppAssociations:"%SCRIPT_DIR%AppAssociations.xml"
)
