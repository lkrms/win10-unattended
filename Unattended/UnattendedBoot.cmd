@ECHO OFF

SETLOCAL

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
SET "SCRIPT_DIR=%SystemDrive%\Unattended\"
SET ERRORS=0

CALL :log ===== Starting %~f0

CALL :optCmd ApplyRegistrySettings.cmd "/start /boot"

CALL :optPs1 RemoveBloatware.ps1 "Removing bloatware"

DEL /F /Q "%PUBLIC%\Desktop\Microsoft Edge.lnk" 2>NUL

IF %ERRORS% EQU 0 EXIT /B 0
EXIT /B 1


:optCmd
SET "SCRIPT=%SCRIPT_DIR%Optional\%~1"
SET "ARGS=%~2"
IF EXIST "%SCRIPT%" (
    CALL "%SCRIPT%" %ARGS% || (
        CALL :error "%SCRIPT%" failed
    )
)
EXIT /B

:optPs1
SET "SCRIPT=%SCRIPT_DIR%Optional\%~1"
SET "MESSAGE=%~2"
IF EXIST "%SCRIPT%" (
    IF NOT "%MESSAGE%"=="" CALL :log %MESSAGE%
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" || (
        CALL :error "%SCRIPT%" failed
    )
)
EXIT /B

:log
ECHO [%DATE% %TIME%] %*
EXIT /B

:error
CALL :log ERROR ^(%ERRORLEVEL%^): %*
SET /A "ERRORS+=1"
EXIT /B
