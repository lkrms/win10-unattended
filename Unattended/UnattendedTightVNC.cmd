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

IF "%1"=="" GOTO :usage
IF "%2"=="" GOTO :usage

CALL :log Installing TightVNC Server
choco upgrade tightvnc --ia="ADDLOCAL=Server SET_ACCEPTHTTPCONNECTIONS=1 SET_CONTROLPASSWORD=1 SET_PASSWORD=1 SET_RUNCONTROLINTERFACE=1 SET_USECONTROLAUTHENTICATION=1 SET_USEVNCAUTHENTICATION=1 VALUE_OF_ACCEPTHTTPCONNECTIONS=0 VALUE_OF_CONTROLPASSWORD=%~1 VALUE_OF_PASSWORD=%~2 VALUE_OF_RUNCONTROLINTERFACE=0 VALUE_OF_USECONTROLAUTHENTICATION=1 VALUE_OF_USEVNCAUTHENTICATION=1" -y --no-progress || (
    CALL :error "choco upgrade tightvnc -y --no-progress" failed
    EXIT /B 1
)

EXIT /B 0


:usage
ECHO Usage: UnattendedTightVNC.cmd ^<CONTROLPASSWORD^> ^<PASSWORD^>
EXIT /B 1

:log
ECHO [%DATE% %TIME%] %*
EXIT /B

:error
CALL :log ERROR ^(%ERRORLEVEL%^): %*
EXIT /B
