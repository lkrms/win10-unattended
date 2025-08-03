@ECHO OFF

SETLOCAL

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 3
)

IF [%~1]==[] GOTO :usage
IF NOT EXIST %1 GOTO :usage

SET "SCRIPT_DIR=%~dp0"
SET "BOOT_WIM=%~f1\boot.wim"
SET "INSTALL_WIM=%~f1\install.wim"
SET "IMAGE_DRIVE=%~d1"
SET "MOUNT_DIR=%SystemDrive%\images\mount\%IMAGE_DRIVE:~0,-1%%~pnx1"

IF NOT EXIST "%BOOT_WIM%" GOTO :usage
IF NOT EXIST "%INSTALL_WIM%" GOTO :usage

IF NOT EXIST "%SCRIPT_DIR%..\..\Drivers" (
    CALL :log Directory not found: %SCRIPT_DIR%..\..\Drivers
    EXIT /B 1
)
IF NOT EXIST "%SCRIPT_DIR%..\..\Drivers2" (
    CALL :log Directory not found: %SCRIPT_DIR%..\..\Drivers2
    EXIT /B 1
)
IF NOT EXIST "%MOUNT_DIR%" (
    MD "%MOUNT_DIR%" || EXIT /B 1
)

CALL :log ===== Starting %~f0: %~1
CALL :processWim "%BOOT_WIM%" "%SCRIPT_DIR%..\..\Drivers" || EXIT /B
CALL :processWim "%INSTALL_WIM%" "%SCRIPT_DIR%..\..\Drivers2" || EXIT /B
CALL :log ===== %~f0 finished: %~1
EXIT /B


:: CALL :processWim "image_file" "drivers_dir"
:processWim
SET MAX_INDEX=0
FOR /F "tokens=2 delims=: " %%G IN (
    'DISM /Get-ImageInfo /ImageFile:"%~1" ^| FINDSTR /R /B "Index *: *[1-9][0-9]* *$"'
) DO SET MAX_INDEX=%%G
CALL :log Images found in %~1: %MAX_INDEX%
FOR /L %%G IN (1, 1, %MAX_INDEX%) DO (
    CALL :processImage "%~1" %%G "%~2" || EXIT /B
)
CALL :log Finished with %MAX_INDEX% image^(s^): %~1
EXIT /B

:: CALL :processImage "image_file" image_index "drivers_dir"
:processImage
CALL :log Mounting %~1[/Index:%2] at %MOUNT_DIR%
DISM /Mount-Image /ImageFile:"%~1" /MountDir:"%MOUNT_DIR%" /Index:%2 /Optimize || EXIT /B

CALL :log Installing drivers: %~3
DISM /Image:"%MOUNT_DIR%" /Add-Driver /Driver:"%~3" /Recurse /ForceUnsigned || EXIT /B

CALL :log Unmounting %~1[/Index:%2] from %MOUNT_DIR%
DISM /Unmount-Image /MountDir:"%MOUNT_DIR%" /Commit || EXIT /B

CALL :log Updated successfully: %~1[/Index:%2]
EXIT /B

:usage
ECHO Usage: AddDriversOffline.cmd ^<sources_dir^>
ECHO:
ECHO - ^<sources_dir^> must contain image files boot.wim and install.wim
ECHO - Drivers in %~dp0..\..\Drivers are added to every image in boot.wim
ECHO - Drivers in %~dp0..\..\Drivers2 are added to every image in install.wim
EXIT /B 1

:log
ECHO [%DATE% %TIME%] %*
EXIT /B
