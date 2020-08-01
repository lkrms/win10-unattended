@ECHO OFF

SET "SCRIPT_DIR=%~dp0"

"%SCRIPT_DIR%setup.exe" /configure "%SCRIPT_DIR%Configuration.xml"

IF NOT EXIST "%SystemDrive%\Program Files\Microsoft Office\Office16" EXIT /B 1

