@ECHO OFF

SET ERRORS=0

(

    NET USE /PERSISTENT:NO

    :: In case of persistent connections
    NET USE H: /DELETE
    NET USE S: /DELETE

) >NUL 2>NUL

@ECHO ON
NET USE H: \\hub\%USERNAME% || SET /A "ERRORS+=1"
NET USE S: \\hub\family || SET /A "ERRORS+=1"
@ECHO OFF

IF %ERRORS% EQU 0 EXIT /B 0
PAUSE
EXIT /B 1
