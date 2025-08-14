@ECHO OFF

SETLOCAL

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 3
)

SET "SCRIPT_DIR=%~dp0"

FOR %%G IN ("%SCRIPT_DIR%VMware-tools*.exe") DO (
    ECHO Running %%G
    "%%G" /s /v "/qn /L+*vx ""%SystemDrive%\Unattended\Logs\Drivers2-%%~nG.log"" REBOOT=ReallySuppress"
    EXIT /B
)

ECHO File not found: %SCRIPT_DIR%VMware-tools*.exe
