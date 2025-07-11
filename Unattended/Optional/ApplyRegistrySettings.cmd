@ECHO OFF

SETLOCAL

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 3
)

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
SET "SCRIPT_DIR=%~dp0"
SET ERRORS=0

CALL :log ===== Starting %~f0

CALL :log Applying registry settings

CALL :runOrReport REG LOAD HKLM\DEFAULT %SystemDrive%\Users\Default\NTUSER.DAT || EXIT /B 1

IF NOT EXIST "%SCRIPT_DIR%Unattended.reg" GOTO :skipImport
CALL :runOrReport REG IMPORT "%SCRIPT_DIR%Unattended.reg"
IF NOT EXIST "%SCRIPT_DIR%Unattended-HKLM-DEFAULT.reg" GOTO :skipImport
CALL :runOrReport REG IMPORT "%SCRIPT_DIR%Unattended-HKLM-DEFAULT.reg"
IF NOT EXIST "%SCRIPT_DIR%Unattended.reg.d" GOTO :skipImport
FOR /F "delims=" %%G IN ('WHERE "%SCRIPT_DIR%Unattended.reg.d:*.reg" 2^>NUL') DO CALL :runOrReport REG IMPORT "%%G"

:skipImport
IF EXIST "%SCRIPT_DIR%MapNetworkDrives.cmd" (
    CALL :runOrReport COPY "%SCRIPT_DIR%MapNetworkDrives.cmd" "%SystemRoot%" /Y
    CALL :runOrReport REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v MapNetworkDrives /t REG_EXPAND_SZ /d "%%SystemRoot%%\MapNetworkDrives.cmd" /f
)

:: REG ADD "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v {374DE290-123F-4565-9164-39C4925E467B} /t REG_EXPAND_SZ /d "\\doo\%%USERNAME%%\Downloads" /f
:: REG ADD "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop /t REG_EXPAND_SZ /d "\\doo\%%USERNAME%%\Desktop" /f
:: REG ADD "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Personal /t REG_EXPAND_SZ /d "\\doo\%%USERNAME%%\Documents" /f
:: REG ADD "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Pictures" /t REG_EXPAND_SZ /d "\\doo\%%USERNAME%%\Pictures" /f

CALL :isWin11 && IF EXIST "%SCRIPT_DIR%StartLayout11.reg" (
    CALL :log Applying Windows 11 Start layout policy
    CALL :runOrReport REG IMPORT "%SCRIPT_DIR%StartLayout11.reg"
)

CALL :isWin10 && IF EXIST "%SCRIPT_DIR%StartLayout10.xml" (
    CALL :log Applying Windows 10 Start layout policy
    CALL :runOrReport COPY "%SCRIPT_DIR%StartLayout10.xml" "%SystemDrive%\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml" /Y
)

IF "%1"=="/boot" GOTO :skipDeploymentActions

IF EXIST "%SCRIPT_DIR%ConfigurePrinting.ps1" (
    CALL :runOrReport REG ADD HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce /v !SetDefaultPrinter /t REG_EXPAND_SZ /d "powershell -NoProfile -Command \"^(New-Object -ComObject WScript.Network^).SetDefaultPrinter^('Brother HL-5450DN ^(black and white^)'^)\"" /f
)

:skipDeploymentActions

REG UNLOAD HKLM\DEFAULT

IF %ERRORS% EQU 0 EXIT /B 0
EXIT /B 1


:isWin11
IF NOT DEFINED BUILD_NUMBER FOR /F "delims=" %%G IN (
    'powershell -NoProfile -Command "[System.Environment]::OSVersion.Version.Build"'
) DO SET BUILD_NUMBER=%%G
IF %BUILD_NUMBER% GEQ 22000 EXIT /B 0
EXIT /B 1

:isWin10
IF NOT DEFINED BUILD_NUMBER FOR /F "delims=" %%G IN (
    'powershell -NoProfile -Command "[System.Environment]::OSVersion.Version.Build"'
) DO SET BUILD_NUMBER=%%G
IF %BUILD_NUMBER% LSS 10240 EXIT /B 1
IF %BUILD_NUMBER% GEQ 22000 EXIT /B 1
EXIT /B 0

:runOrReport
%* || CALL :error "%*" failed
EXIT /B

:log
ECHO [%DATE% %TIME%] %*
EXIT /B

:error
CALL :log ERROR ^(%ERRORLEVEL%^): %*
SET /A "ERRORS+=1"
EXIT /B
