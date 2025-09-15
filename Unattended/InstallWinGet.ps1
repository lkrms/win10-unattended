$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Download a file unless already downloaded and up-to-date
function Get-Asset($Uri, $File) {
    # Follow any redirects and check for a Last-Modified header
    $response = Invoke-WebRequest $Uri -UseBasicParsing -Method Head
    if ($lastModified = $response.Headers["Last-Modified"]) {
        $lastModified = [DateTime]::Parse($lastModified)
        if ((Test-Path $File) -and ($lastModified -le (Get-Item $File).LastWriteTime)) {
            Write-Host " -> Not modified: $File"
            return
        }
    }
    try {
        Write-Host " -> Downloading: $File"
        Invoke-WebRequest $response.BaseResponse.ResponseUri -OutFile $File
        if ($lastModified) {
            (Get-Item $File).LastWriteTime = $lastModified
        }
    } catch {
        if (Test-Path $File) {
            Remove-Item $File
        }
        throw
    }
}

# Remove a directory recursively if it exists
function Remove-Directory($Directory) {
    if (Test-Path $Directory) {
        Remove-Item $Directory -Recurse -Force
    }
}

$arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLower()
$cache = "$PSScriptRoot\Cache"
if (!(Test-Path $cache)) {
    New-Item $cache -ItemType Directory | Out-Null
}
Set-Location $cache

Write-Host "==> Downloading WinGet and its dependencies from GitHub"
Get-Asset `
    -Uri "https://github.com/microsoft/winget-cli/releases/latest/download/DesktopAppInstaller_Dependencies.zip" `
    -File "DesktopAppInstaller_Dependencies.zip"
Get-Asset `
    -Uri "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" `
    -File "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

Remove-Directory DesktopAppInstaller_Dependencies
Expand-Archive DesktopAppInstaller_Dependencies.zip
$packages = Get-ChildItem "DesktopAppInstaller_Dependencies\$arch\*" -Include *.appx
$packages += Get-Item Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
$packages | ForEach-Object {
    Write-Host "==> Installing $($_.BaseName)"
    Add-AppxPackage $_
}
Remove-Directory DesktopAppInstaller_Dependencies

if (!(Get-Module Microsoft.WinGet.Client -ListAvailable)) {
    Write-Host "==> Installing PowerShell module for WinGet"
    if (!(Get-PackageProvider -ListAvailable | Where-Object Name -EQ NuGet)) {
        Install-PackageProvider -Name NuGet -Force | Out-Null
    }
    Install-Module Microsoft.WinGet.Client -Force | Out-Null
}
