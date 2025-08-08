@ECHO OFF

SETLOCAL EnableDelayedExpansion

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 3
)

SET BACKUP=1
SET RESTORE=0
SET PROCESS=1
SET EXPORT=1
IF [%~1]==[/clean] (
    SET RESTORE=1
    SHIFT /1
) ELSE (
    IF [%~1]==[/nobackup] (
        SET BACKUP=0
        SHIFT /1
    )
)
IF [%~1]==[/noexport] (
    SET EXPORT=0
    SHIFT /1
) ELSE (
    IF [%~1]==[/exportonly] (
        SET PROCESS=0
        SHIFT /1
    )
)
IF [%1]==[] GOTO :usage
IF NOT EXIST %1 GOTO :usage

SET "SCRIPT_DIR=%~dp0"
SET "IMAGE_FILE=%~f1"
SET "IMAGE_DRIVE=%~d1"
SET "MOUNT_DIR=%SystemDrive%\images\mount\%IMAGE_DRIVE:~0,-1%%~p1"
SET "MOUNT_DIR=%MOUNT_DIR:~0,-1%"
SET "BACKUP_DIR=%~d1\images\backup%~p1"
SET "BACKUP_FILE=%BACKUP_DIR%%~nx1"
SET "EXPORT_DIR=%SystemDrive%\images\export\%IMAGE_DRIVE:~0,-1%%~p1"
SET "EXPORT_FILE=%EXPORT_DIR%%~n1-temp%~x1"
SHIFT /1

IF NOT EXIST "%SCRIPT_DIR%..\..\Updates" (
    CALL :log Directory not found: %SCRIPT_DIR%..\..\Updates
    EXIT /B 1
)
IF NOT EXIST "%MOUNT_DIR%" (
    MD "%MOUNT_DIR%" || EXIT /B 1
)
IF %BACKUP% EQU 1 (
    IF NOT EXIST "%BACKUP_DIR:~0,-1%" (
        MD "%BACKUP_DIR:~0,-1%" || EXIT /B 1
    )
    IF NOT EXIST "%BACKUP_FILE%" (
        CALL :log Copying %IMAGE_FILE% to %BACKUP_FILE%
        COPY "%IMAGE_FILE%" "%BACKUP_FILE%" || EXIT /B 1
    ) ELSE (
        IF %RESTORE% EQU 1 (
            CALL :log Restoring %IMAGE_FILE% from %BACKUP_FILE%
            COPY "%BACKUP_FILE%" "%IMAGE_FILE%" /Y || EXIT /B 1
        )
    )
)
IF %EXPORT% EQU 1 (
    IF NOT EXIST "%EXPORT_DIR:~0,-1%" (
        MD "%EXPORT_DIR:~0,-1%" || EXIT /B 1
    )
)

:loop
CALL :log ===== Starting %~f0: %IMAGE_FILE%
IF %PROCESS% NEQ 1 GOTO :skipProcess
CALL :processImage %1 || EXIT /B

:skipProcess
IF %EXPORT% NEQ 1 GOTO :skipExport
SET VOLUME=%1
SET VOLUME=%VOLUME:/=/Source%
CALL :log Exporting %IMAGE_FILE%[%1] to %EXPORT_FILE%
DISM /Export-Image /SourceImageFile:"%IMAGE_FILE%" /DestinationImageFile:"%EXPORT_FILE%" %VOLUME% || EXIT /B

:skipExport
SHIFT /1
IF NOT [%1]==[] GOTO :loop

IF %EXPORT% EQU 1 (
    MOVE /Y "%EXPORT_FILE%" "%IMAGE_FILE%" || EXIT /B
)

CALL :log ===== %~f0 finished: %IMAGE_FILE%
EXIT /B


:processImage
CALL :log Mounting %IMAGE_FILE%[%1] at %MOUNT_DIR%
DISM /Mount-Image /ImageFile:"%IMAGE_FILE%" /MountDir:"%MOUNT_DIR%" %1 || EXIT /B

FOR /F "usebackq delims=" %%G IN (
    `powershell -NoProfile -Command "Get-ChildItem -Path '%SCRIPT_DIR%..\..\Updates' -Include *.cab, *.msu -Recurse | Select-Object -ExpandProperty Directory | ForEach-Object FullName | Sort-Object -Unique"`
) DO (
    CALL :log Installing updates: %%G
    DISM /Image:"%MOUNT_DIR%" /Add-Package /PackagePath:"%%G" /IgnoreCheck || EXIT /B
)

CALL :log Cleaning up %IMAGE_FILE%[%1] mounted at %MOUNT_DIR%
:: Add /ResetBase to remove "all superseded versions of every component in the
:: component store", along with the ability to remove updates installed so far
DISM /Image:"%MOUNT_DIR%" /Cleanup-Image /StartComponentCleanup || EXIT /B

CALL :log Unmounting %IMAGE_FILE%[%1] from %MOUNT_DIR%
DISM /Unmount-Image /MountDir:"%MOUNT_DIR%" /Commit || EXIT /B

CALL :log Updated successfully: %IMAGE_FILE%[%1]
EXIT /B 0


:usage
ECHO Usage: UpdateImageOffline.cmd [/clean^|/nobackup] [/noexport^|/exportonly] ^<image_file^> [/Index:^<image_index^>^|/Name:^<image_name^>...]
EXIT /B 1

:log
ECHO [%DATE% %TIME%] %*
EXIT /B
