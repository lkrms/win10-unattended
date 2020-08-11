@ECHO OFF

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 1
)

IF "%1"=="/start" GOTO :start
CALL "%~0" /start %* 2>&1 | powershell -NoProfile -Command "$input | tee %SystemDrive%\Unattended.log -Append"
EXIT /B

:start
SHIFT /1
SET "SCRIPT_DIR=%~dp0"
SET ERRORS=0

CALL :log ===== Starting %~f0

CALL :log Applying registry settings
REG LOAD HKLM\DEFAULT %SystemDrive%\Users\Default\NTUSER.DAT || (
    CALL :error "REG LOAD HKLM\DEFAULT %SystemDrive%\Users\Default\NTUSER.DAT" failed
    EXIT /B 1
)
IF NOT EXIST "%SCRIPT_DIR%Unattended.reg" GOTO :skipRegImport
REG IMPORT "%SCRIPT_DIR%Unattended.reg" || (
    CALL :error "REG IMPORT "%SCRIPT_DIR%Unattended.reg"" failed
)
IF NOT EXIST "%SCRIPT_DIR%Unattended-HKLM-DEFAULT.reg" GOTO :skipRegImport
REG IMPORT "%SCRIPT_DIR%Unattended-HKLM-DEFAULT.reg" || (
    CALL :error "REG IMPORT "%SCRIPT_DIR%Unattended-HKLM-DEFAULT.reg"" failed
)
:skipRegImport
:: Must exist or GPSvcDebugLevel will not take effect
IF NOT EXIST "%SystemRoot%\Debug\UserMode" MD "%SystemRoot%\Debug\UserMode"
IF EXIST "%SCRIPT_DIR%MapNetworkDrives.cmd" (
    COPY "%SCRIPT_DIR%MapNetworkDrives.cmd" "%SystemRoot%" /Y
    REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v MapNetworkDrives /t REG_EXPAND_SZ /d "%%SystemRoot%%\MapNetworkDrives.cmd" /f
)
REG ADD "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v {374DE290-123F-4565-9164-39C4925E467B} /t REG_EXPAND_SZ /d "\\hub\%%USERNAME%%\Downloads" /f
REG ADD "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop /t REG_EXPAND_SZ /d "\\hub\%%USERNAME%%\Desktop" /f
REG ADD "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Personal /t REG_EXPAND_SZ /d "\\hub\%%USERNAME%%\Documents" /f
REG ADD "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Pictures" /t REG_EXPAND_SZ /d "\\hub\%%USERNAME%%\Pictures" /f
IF EXIST "%SCRIPT_DIR%ResetTaskbar.reg" (
    COPY "%SCRIPT_DIR%ResetTaskbar.reg" "%SystemRoot%" /Y
    :: After each user's first login, reset their taskbar to remove Edge and Mail
    REG ADD HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce /v !ResetTaskbar /t REG_EXPAND_SZ /d "CMD /C REG IMPORT \"%%SystemRoot%%\ResetTaskbar.reg\" && TASKKILL /F /IM explorer.exe && start explorer.exe" /f
)
IF EXIST "%SCRIPT_DIR%AddPrinters.ps1" (
    REG ADD HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce /v !SetDefaultPrinter /t REG_EXPAND_SZ /d "powershell -NoProfile -Command \"^(New-Object -ComObject WScript.Network^).SetDefaultPrinter^('Brother HL-5450DN ^(black and white^)'^)\"" /f
)
REG UNLOAD HKLM\DEFAULT

IF %ERRORS% EQU 0 EXIT /B 0
EXIT /B 1


:log
ECHO [%DATE% %TIME%] %*
EXIT /B

:error
CALL :log ERROR ^(%ERRORLEVEL%^): %*
SET /A "ERRORS+=1"
EXIT /B
