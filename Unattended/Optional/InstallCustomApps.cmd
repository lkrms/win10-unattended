@ECHO OFF

NET SESSION >NUL 2>NUL || (
    ECHO Please use "Run as administrator"
    EXIT /B 3
)

IF [%~1]==[/unattended] GOTO :unattended

SETLOCAL

IF [%~1]==[/start] GOTO :start
IF NOT EXIST %SystemDrive%\Unattended\Logs (
    MD %SystemDrive%\Unattended\Logs || EXIT /B 3
    IF EXIST %SystemDrive%\Unattended.log (MOVE /Y %SystemDrive%\Unattended.log %SystemDrive%\Unattended\Logs || EXIT /B 3)
)
SET "RETURN_CMD=%TEMP%\%~n0Return.cmd"
SET RETURN_CODE=0
(CMD /V:ON /C ""%~0" /start %* & ECHO SET RETURN_CODE=!ERRORLEVEL! >"%%RETURN_CMD%%"") 2>&1 | powershell -NoProfile -Command "$input | tee %SystemDrive%\Unattended\Logs\Unattended.log -Append"
CALL "%RETURN_CMD%"
DEL /F /Q "%RETURN_CMD%"
EXIT /B %RETURN_CODE%

:start
SHIFT /1
SET ERRORS=0
SET PKG_COUNT=0
SET PKG_ERRORS=0

SET "INNO_DEFAULT=/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
SET MAX_ATTEMPTS=31

SET PKG_CRITICAL=

CALL :log ===== Starting %~f0

:unattended
SET "OPTIONAL_DIR=%~dp0"


:: Start custom apps


GOTO :skipCustomApps

CALL :enableDeveloperMode
CALL :osIs64Bit && CALL :winget Flameshot.Flameshot && CALL :deleteDesktopIcon Flameshot.lnk
CALL :osIs64Bit && CALL :winget Git.Git --override "%INNO_DEFAULT% /COMPONENTS=ext,ext\shellhere,gitlfs,assoc,assoc_sh,windowsterminal,scalar /o:EditorOption=Notepad++ /o:DefaultBranchOption=main /o:PathOption=Cmd /o:SSHOption=ExternalOpenSSH /o:CURLOption=WinSSL /o:EnableSymlinks=Enabled /o:PerformanceTweaksFSCache=Enabled" && (
    SETX MSYS winsymlinks:nativestrict /M
    sc config ssh-agent start=auto
)
CALL :osIs64Bit && CALL :winget dandavison.delta
CALL :osIs64Bit && CALL :winget GnuPG.Gpg4win && CALL :deleteDesktopIcon Kleopatra.lnk
CALL :osIs64Bit && CALL :winget jqlang.jq
CALL :osIs64Bit && CALL :winget lucasg.Dependencies
CALL :osIs64Bit && CALL :winget Inkscape.Inkscape && CALL :deleteDesktopIcon Inkscape.lnk
CALL :osIs64Bit && CALL :winget Nextcloud.NextcloudDesktop --custom "NO_DESKTOP_SHORTCUT=1"
CALL :osIs64Bit && CALL :winget Microsoft.PowerToys
CALL :winget sigoden.WindowSwitcher && IF EXIST "%OPTIONAL_DIR%WindowSwitcher.xml" (
    SCHTASKS /Create /F /TN "WindowSwitcher" /XML "%OPTIONAL_DIR%WindowSwitcher.xml"
)
CALL :winget OO-Software.ShutUp10
CALL :choco SourceCodePro

:: See https://keepassxc.org/docs/KeePassXC_UserGuide#_installer_options
CALL :osIs64Bit && CALL :winget KeePassXCTeam.KeePassXC --custom "LAUNCHAPPONEXIT=0 AUTOSTARTPROGRAM=0"

:skipCustomApps


:: End custom apps


IF [%~1]==[/unattended] EXIT /B 0
CALL :log Packages deployed: %PKG_COUNT% ^(errors: %PKG_ERRORS%^)
CALL :log ===== %~f0 finished with %ERRORS% errors
IF %ERRORS% NEQ 0 EXIT /B 1
EXIT /B 0


:enableDeveloperMode
CALL :log Enabling Developer Mode
CALL :runOrReport REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 1 /f
EXIT /B

:osIs64Bit
IF [%PROCESSOR_ARCHITECTURE%]==[AMD64] EXIT /B 0
IF [%PROCESSOR_ARCHITEW6432%]==[AMD64] EXIT /B 0
IF [%PROCESSOR_ARCHITECTURE%]==[ARM64] EXIT /B 0
IF [%PROCESSOR_ARCHITEW6432%]==[ARM64] EXIT /B 0
EXIT /B 1

:deleteDesktopIcon
DEL /F /Q "%PUBLIC%\Desktop\%~1" 2>NUL
DEL /F /Q "%USERPROFILE%\Desktop\%~1" 2>NUL
EXIT /B 0

:choco
CALL :log Deploying %1
SET /A "PKG_COUNT+=1"
choco upgrade %* -y --no-progress --fail-on-unfound && EXIT /B
IF NOT DEFINED PKG_CRITICAL (CALL :log WARNING ^(%ERRORLEVEL%^): "choco upgrade %1" failed & SET /A "PKG_ERRORS+=1" & EXIT /B 0)
CALL :error "choco upgrade %* -y --no-progress --fail-on-unfound" failed
SET /A "PKG_ERRORS+=1"
EXIT /B %RESULT%

:winget
CALL :log Deploying %1
SET /A "PKG_COUNT+=1"
SET "LOG_FILE=%SystemDrive%\Unattended\Logs\%~n0WinGet-%~nx1.log"
SET ATTEMPT=1
:wingetRetry
SET RETRY=0
winget install --id %* --scope machine --exact --silent --log "%LOG_FILE%" --accept-source-agreements --disable-interactivity && EXIT /B
:: DOWNLOAD_FAILED
IF %ERRORLEVEL% EQU -1978335224 SET RETRY=%ERRORLEVEL%
:: INSTALLER_HASH_MISMATCH
IF %ERRORLEVEL% EQU -1978335215 SET RETRY=%ERRORLEVEL%
:: ERROR_INTERNET_*, ERROR_WINHTTP_* (0x80072ee0 - 0x80072fa1)
IF %ERRORLEVEL% GEQ -2147012896 IF %ERRORLEVEL% LEQ -2147012703 SET RETRY=%ERRORLEVEL%
IF %RETRY% EQU 0 GOTO :wingetNoRetry
IF %ATTEMPT% GEQ %MAX_ATTEMPTS% (
    CALL :log Upstream error not resolved after %ATTEMPT% attempts, giving up: %1
    CALL :setErrorLevel %RETRY%
    GOTO :wingetError
)
CALL :log Upstream error on attempt %ATTEMPT% of %MAX_ATTEMPTS%, retrying in 2 minutes: %1
ping -n 121 127.0.0.1 >NUL
SET /A "ATTEMPT+=1"
GOTO :wingetRetry
:wingetNoRetry
:: UPDATE_NOT_APPLICABLE
IF %ERRORLEVEL% EQU -1978335189 EXIT /B 0
:: Ignore non-critical packages on unsupported hardware
IF NOT DEFINED PKG_CRITICAL (
    rem NO_APPLICABLE_INSTALLER
    IF %ERRORLEVEL% EQU -1978335216 (CALL :log WARNING ^(%ERRORLEVEL%^): "winget install %1" failed, see %LOG_FILE% & SET /A "PKG_ERRORS+=1" & EXIT /B 0)
)
:wingetError
CALL :error "winget install --id %* --scope machine --exact --silent --accept-source-agreements --disable-interactivity" failed, see %LOG_FILE%
SET /A "PKG_ERRORS+=1"
EXIT /B %RESULT%

:runOrReport
%* || CALL :error "%*" failed
EXIT /B

:log
ECHO [%DATE% %TIME%] %*
EXIT /B

:error
SET RESULT=%ERRORLEVEL%
CALL :log ERROR ^(%RESULT%^): %*
SET /A "ERRORS+=1"
EXIT /B %RESULT%

:setErrorLevel
EXIT /B %~1
