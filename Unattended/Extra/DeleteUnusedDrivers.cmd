@ECHO OFF

SETLOCAL

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 3
)

FOR /F "tokens=2,* delims= " %%G IN ('PNPUTIL /enum-drivers ^| FINDSTR /B "Published Name:"') DO PNPUTIL /delete-driver %%H
