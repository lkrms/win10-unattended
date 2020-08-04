@ECHO OFF

:: Disable sleep when plugged in
POWERCFG /CHANGE standby-timeout-ac 0

:: Set public networks to private
powershell -NoProfile -Command "Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private"

:: Disable reserved storage
DISM /Online /Set-ReservedStorageState /State:Disabled
