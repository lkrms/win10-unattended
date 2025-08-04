@ECHO OFF

SETLOCAL

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 3
)

SCHTASKS /Change /TN "\Microsoft\Windows\Defrag\ScheduledDefrag" /DISABLE
