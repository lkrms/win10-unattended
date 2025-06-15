@ECHO OFF

SETLOCAL

SET "SCRIPT_DIR=%~dp0"

CD /D "%SCRIPT_DIR%"

CALL :log Running the Office Deployment Tool
"%SCRIPT_DIR%setup.exe" /download "%SCRIPT_DIR%Configuration.xml" || (
    CALL :error ""%SCRIPT_DIR%setup.exe" /download "%SCRIPT_DIR%Configuration.xml"" failed
    EXIT /B 1
)
CALL :log Office 365 download complete
EXIT /B 0


:log
ECHO [%DATE% %TIME%] %*
EXIT /B

:error
CALL :log ERROR ^(%ERRORLEVEL%^): %*
EXIT /B
