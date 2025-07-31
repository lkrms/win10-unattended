#!/usr/bin/env bash

set -euo pipefail

rufus=4.9

# die [<message>]
function die() {
    local s=$?
    printf '%s: %s\n' "${0##*/}" "${1-command failed}" >&2
    ((!s)) && exit 1 || exit $s
}

# download <url> <path>
function download() {
    local args verb=Downloading
    [[ ! -s $2 ]] || {
        args=(--time-cond "$2")
        verb=Updating
    }
    echo "==> $verb ${2##*/} from: $1"
    curl -fLo "$2" --remote-time ${args+"${args[@]}"} "$1"
    echo
}

[[ ${BASH_SOURCE[0]} -ef Scripts/DownloadAssets.sh ]] ||
    die "must run from root of package folder"

mkdir -p Cache

download "https://community.chocolatey.org/install.ps1" Unattended/install.ps1

if [[ -d Office365 ]]; then
    download "https://go.microsoft.com/fwlink/?linkid=844652" Office365/OneDriveSetup.exe
    download "https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409" Office365/teamsbootstrapper.exe
    download "https://go.microsoft.com/fwlink/?linkid=2196106" Office365/MSTeams-x64.msix

    odt_url=$(curl -fsSL "https://www.microsoft.com/en-au/download/details.aspx?id=49117" |
        grep -Eo "\<https://download\.microsoft\.com/download/[0-9a-f/-]+/officedeploymenttool_[0-9-]+\.exe\>" |
        head -n1) || die "unable to get Office Deployment Tool URL"
    odt_file=Cache/${odt_url##*/}
    download "$odt_url" "$odt_file"
    bsdtar -xf "$odt_file" -C Office365 EULA setup.exe ||
        die "error extracting Office Deployment Tool"

    download "https://github.com/Fleex255/PolicyPlus/releases/latest/download/PolicyPlus.exe" Tools/PolicyPlus.exe
    download "https://github.com/pbatard/rufus/releases/download/v${rufus}/rufus-${rufus}.exe" Tools/rufus.exe
    download "https://github.com/pbatard/rufus/releases/download/v${rufus}/rufus-${rufus}_x86.exe" Tools/rufus_x86.exe
    download "https://github.com/pbatard/rufus/releases/download/v${rufus}/rufus-${rufus}_arm64.exe" Tools/rufus_arm64.exe

    lgpo_url=$(curl -fsSL "https://www.microsoft.com/en-au/download/details.aspx?id=55319" |
        grep -Eo "\<https://download\.microsoft\.com/download/[0-9a-f/-]+/LGPO.zip\>" |
        head -n1) || die "unable to get LGPO URL"
    download "$lgpo_url" Cache/LGPO.zip
    bsdtar -xf Cache/LGPO.zip -C Tools --strip-components 1 "*/LGPO.exe" ||
        die "error extracting LGPO"

    download "https://download.sysinternals.com/files/ProcessExplorer.zip" Cache/ProcessExplorer.zip
    bsdtar -xf Cache/ProcessExplorer.zip -C Tools procexp.exe ||
        die "error extracting Process Explorer"

    download "https://download.sysinternals.com/files/ProcessMonitor.zip" Cache/ProcessMonitor.zip
    bsdtar -xf Cache/ProcessMonitor.zip -C Tools Procmon.exe ||
        die "error extracting Process Monitor"
fi
