@ECHO OFF

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 3
)

IF "%1"=="/unattended" GOTO :unattended

SETLOCAL

IF "%1"=="/start" GOTO :start
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
SET CHOCO_COUNT=0
SET CHOCO_ERRORS=0

CALL :log ===== Starting %~f0

:unattended


:: Start custom apps


CALL :choco shutup10

:: See https://keepassxc.org/docs/KeePassXC_UserGuide#_installer_options
CALL :osIs64Bit && CALL :choco keepassxc --install-args="'LAUNCHAPPONEXIT=0 AUTOSTARTPROGRAM=0'"


:: End custom apps


IF "%1"=="/unattended" EXIT /B 0
CALL :log %CHOCO_COUNT% packages deployed by Chocolatey ^(errors: %CHOCO_ERRORS%^)
CALL :log ===== %~f0 finished with %ERRORS% errors
IF %ERRORS% NEQ 0 EXIT /B 1
EXIT /B 0


:osIs64Bit
IF "%PROCESSOR_ARCHITECTURE%"=="AMD64" EXIT /B 0
IF "%PROCESSOR_ARCHITEW6432%"=="AMD64" EXIT /B 0
IF "%PROCESSOR_ARCHITECTURE%"=="ARM64" EXIT /B 0
IF "%PROCESSOR_ARCHITEW6432%"=="ARM64" EXIT /B 0
EXIT /B 1

:choco
CALL :log Deploying %1
SET /A "CHOCO_COUNT+=1"
CALL :runOrReport choco upgrade %* -y --no-progress --fail-on-unfound || SET /A "CHOCO_ERRORS+=1"
EXIT /B

:runOrReport
%* || CALL :error "%*" failed
EXIT /B

:log
ECHO [%DATE% %TIME%] %*
EXIT /B

:error
SET RESULT=%ERRORLEVEL%
CALL :log ERROR ^(%RESULT%^): %*
SET /A "ERRORS+=1"
EXIT /B %RESULT%
