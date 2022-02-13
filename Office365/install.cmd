@ECHO OFF

SET "SCRIPT_DIR=%~dp0"

:: - \\doo\unattend is a guest share
:: - Without credentials, NET USE fails with: "System error 58 has occurred."
:: - Workaround: connect using a random username and password
NET USE \\doo\unattend /USER:LINAC\%COMPUTERNAME% d2hhdGV2YWgh || (
    CALL :error "NET USE \\doo\unattend /USER:LINAC\%COMPUTERNAME% ############" failed
    EXIT /B 1
)
"%SCRIPT_DIR%setup.exe" /configure "%SCRIPT_DIR%Configuration.xml" || (
    CALL :error ""%SCRIPT_DIR%setup.exe" /configure "%SCRIPT_DIR%Configuration.xml"" failed
    EXIT /B 1
)
EXIT /B 0


:log
ECHO [%DATE% %TIME%] %*
EXIT /B

:error
CALL :log ERROR ^(%ERRORLEVEL%^): %*
SET /A "ERRORS+=1"
EXIT /B
