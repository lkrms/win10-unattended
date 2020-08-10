@ECHO OFF

SET "SCRIPT_DIR=%~dp0"

:: - \\hub\unattend is a guest share
:: - Without credentials, NET USE fails with: "System error 58 has occurred."
:: - Workaround: connect using a random username and password
NET USE \\hub\unattend /USER:LINAC\%COMPUTERNAME% d2hhdGV2YWgh && (
    "%SCRIPT_DIR%setup.exe" /configure "%SCRIPT_DIR%Configuration.xml"
) || EXIT /B 1
