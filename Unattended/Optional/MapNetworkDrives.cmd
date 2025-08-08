@ECHO OFF

SETLOCAL

SET ERRORS=0

SET PREFIX=
FOR /F "delims=" %%G IN (
    'powershell -NoProfile -Command "(Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred -PrefixOrigin Dhcp -SkipAsSource $false -Type Unicast).IPAddress -replace \"[^^^^.]+$\""'
) DO SET PREFIX=%%G
IF [%PREFIX%]==[] EXIT /B 0
IF [%PREFIX%]==[10.0.2.] (
    rem QEMU
    SET SERVER=10.0.2.2
) ELSE (
    rem libvirt/VMware
    SET SERVER=%PREFIX%1
)

(
    NET USE /PERSISTENT:NO

    rem Remove persistent connection from H:
    NET USE H: /DELETE
) >NUL 2>NUL

@ECHO ON
NET USE H: \\%SERVER%\%USERNAME% || @SET /A "ERRORS+=1"
@ECHO OFF

IF %ERRORS% EQU 0 EXIT /B 0
PAUSE
EXIT /B 1
