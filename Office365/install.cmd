@ECHO OFF

SETLOCAL

SET "SCRIPT_DIR=%~dp0"

CD /D "%SCRIPT_DIR%"

IF NOT EXIST "%SCRIPT_DIR%Office" (
    rem - \\doo\unattend is a guest share
    rem - Without credentials, NET USE fails with: "System error 58 has occurred."
    rem - Workaround: connect using a random username and password
    CALL :log Connecting to \\doo\unattend
    NET USE \\doo\unattend /USER:LINAC\%COMPUTERNAME% d2hhdGV2YWgh || (
        CALL :error "NET USE \\doo\unattend /USER:LINAC\%COMPUTERNAME% ############" failed
        EXIT /B 1
    )
)

CALL :log Running the Office Deployment Tool
"%SCRIPT_DIR%setup.exe" /configure "%SCRIPT_DIR%Configuration.xml" || (
    CALL :error ""%SCRIPT_DIR%setup.exe" /configure "%SCRIPT_DIR%Configuration.xml"" failed
    EXIT /B 1
)
CALL :log Office 365 deployment complete
EXIT /B 0


:log
ECHO [%DATE% %TIME%] %*
EXIT /B

:error
CALL :log ERROR ^(%ERRORLEVEL%^): %*
EXIT /B
