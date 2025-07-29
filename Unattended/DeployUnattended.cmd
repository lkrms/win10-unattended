@ECHO OFF

SETLOCAL EnableDelayedExpansion

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 3
)

IF [%~1]==[/start] GOTO :start
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
SET RETURN_CODE=0

CALL "%SCRIPT_DIR%Unattended.cmd" /start /1 %* || IF !ERRORLEVEL! GEQ 3 (EXIT /B) ELSE (RETURN_CODE=!ERRORLEVEL!)
CALL "%SCRIPT_DIR%Unattended.cmd" /start /2 %* || IF !ERRORLEVEL! GEQ 3 (EXIT /B) ELSE (RETURN_CODE=!ERRORLEVEL!)
CALL "%SCRIPT_DIR%Unattended.cmd" /start /3 %* || IF !ERRORLEVEL! GEQ 3 (EXIT /B) ELSE (RETURN_CODE=!ERRORLEVEL!)
CALL "%SCRIPT_DIR%Unattended.cmd" /start /4 %* || RETURN_CODE=!ERRORLEVEL!
CALL "%SCRIPT_DIR%UnattendedFirstBoot.cmd" /start %* || RETURN_CODE=!ERRORLEVEL!

EXIT /B %RETURN_CODE%

