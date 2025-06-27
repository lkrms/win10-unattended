@ECHO OFF

SETLOCAL

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 3
)

IF "%~1"=="/start" GOTO :start
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
SET ERRORS=0

IF "%~1"=="" GOTO :usage
IF "%~2"=="" GOTO :usage

CALL :log ===== Starting %~f0

:: See https://www.tightvnc.com/docs.php
CALL :log Deploying TightVNC Server
"%ALLUSERSPROFILE%\chocolatey\bin\choco" upgrade tightvnc --install-args="'ADDLOCAL=Server SET_ACCEPTHTTPCONNECTIONS=1 SET_CONTROLPASSWORD=1 SET_PASSWORD=1 SET_RUNCONTROLINTERFACE=1 SET_USECONTROLAUTHENTICATION=1 SET_USEVNCAUTHENTICATION=1 VALUE_OF_ACCEPTHTTPCONNECTIONS=0 VALUE_OF_CONTROLPASSWORD=""%~1"" VALUE_OF_PASSWORD=""%~2"" VALUE_OF_RUNCONTROLINTERFACE=0 VALUE_OF_USECONTROLAUTHENTICATION=1 VALUE_OF_USEVNCAUTHENTICATION=1'" -y --no-progress --fail-on-unfound || (
    CALL :error "choco upgrade tightvnc" failed
)

CALL :log ===== %~f0 finished with %ERRORS% errors
IF %ERRORS% NEQ 0 EXIT /B 1
EXIT /B 0


:usage
ECHO Usage: UnattendedTightVNC.cmd ^<CONTROLPASSWORD^> ^<PASSWORD^>
EXIT /B 1

:log
ECHO [%DATE% %TIME%] %*
EXIT /B

:error
SET RESULT=%ERRORLEVEL%
CALL :log ERROR ^(%RESULT%^): %*
SET /A "ERRORS+=1"
EXIT /B %RESULT%
