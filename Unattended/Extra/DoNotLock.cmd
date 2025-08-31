@ECHO OFF

SETLOCAL

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 3
)

:: Registry settings for these can't be applied directly

:: System > Power > Screen time-out > Plugged in > Turn my screen off after > Never
POWERCFG /CHANGE monitor-timeout-ac 0 || EXIT /B
:: System > Power > Screen time-out > On battery > Turn my screen off after > Never
POWERCFG /CHANGE monitor-timeout-dc 0
