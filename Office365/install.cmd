@ECHO OFF

SET "SCRIPT_DIR=%~dp0"

IF EXIST "%ProgramFiles%\Microsoft Office\Office16" (
    REG DELETE HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v InstallOffice /f
    EXIT /B 0
)

"%SCRIPT_DIR%setup.exe" /configure "%SCRIPT_DIR%Configuration.xml"

