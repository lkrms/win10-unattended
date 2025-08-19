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
SET PKG_CRITICAL=

SET "INNO_DEFAULT=/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART"

CALL :log ===== Starting %~f0

:unattended


:: Start custom apps


GOTO :skipCustomApps

CALL :enableDeveloperMode
CALL :osIs64Bit && CALL :winget Espanso.Espanso
CALL :osIs64Bit && CALL :winget Flameshot.Flameshot
CALL :osIs64Bit && CALL :winget Git.Git --override "%INNO_DEFAULT% /COMPONENTS=ext,ext\shellhere,gitlfs,assoc,assoc_sh,windowsterminal,scalar /o:EditorOption=Notepad++ /o:DefaultBranchOption=main /o:PathOption=Cmd /o:SSHOption=ExternalOpenSSH /o:CURLOption=WinSSL /o:EnableSymlinks=Enabled /o:PerformanceTweaksFSCache=Enabled" && (
    SETX MSYS winsymlinks:nativestrict /M
    sc config ssh-agent start=auto
)
CALL :osIs64Bit && CALL :winget dandavison.delta
CALL :osIs64Bit && CALL :winget jqlang.jq
CALL :osIs64Bit && CALL :winget Inkscape.Inkscape
CALL :osIs64Bit && CALL :winget Nextcloud.NextcloudDesktop
CALL :osIs64Bit && CALL :winget Microsoft.PowerToys
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

:choco
CALL :log Deploying %1
SET /A "PKG_COUNT+=1"
choco upgrade %* -y --no-progress --fail-on-unfound && EXIT /B
IF NOT DEFINED PKG_CRITICAL (SET /A "PKG_ERRORS+=1" & EXIT /B 0)
CALL :error "choco upgrade %* -y --no-progress --fail-on-unfound" failed
SET /A "PKG_ERRORS+=1"
EXIT /B %RESULT%

:winget
CALL :log Deploying %1
SET /A "PKG_COUNT+=1"
winget install --id %* --scope machine --exact --silent --accept-source-agreements --disable-interactivity && EXIT /B
:: UPDATE_NOT_APPLICABLE
IF %ERRORLEVEL% EQU -1978335189 EXIT /B 0
:: Ignore non-critical packages on unsupported hardware
IF NOT DEFINED PKG_CRITICAL (
    rem NO_APPLICABLE_INSTALLER
    IF %ERRORLEVEL% EQU -1978335216 (SET /A "PKG_ERRORS+=1" & EXIT /B 0)
)
CALL :error "winget install --id %* --scope machine --exact --silent --accept-source-agreements --disable-interactivity" failed
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
