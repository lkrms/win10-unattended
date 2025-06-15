@ECHO OFF

SETLOCAL

SET "SCRIPT_DIR=%~dp0"

IF NOT EXIST "%SCRIPT_DIR%install.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "((New-Object System.Net.WebClient).DownloadFile('https://community.chocolatey.org/install.ps1','%SCRIPT_DIR%install.ps1'))" || (
        CALL :log Chocolatey installer failed to download
        EXIT /B 1
    )
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPT_DIR%install.ps1' %*" || (
    CALL :log Chocolatey installation failed
    EXIT /B 1
)
CALL :log Chocolatey installation complete
EXIT /B 0


:log
ECHO [%DATE% %TIME%] %*
EXIT /B
