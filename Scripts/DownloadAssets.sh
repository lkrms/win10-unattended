#!/usr/bin/env bash

set -euo pipefail

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

download "https://community.chocolatey.org/install.ps1" Unattended/install.ps1

if [[ -d Office365 ]]; then
    download "https://go.microsoft.com/fwlink/?linkid=844652" Office365/OneDriveSetup.exe
    download "https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409" Office365/teamsbootstrapper.exe
    download "https://go.microsoft.com/fwlink/?linkid=2196106" Office365/MSTeams-x64.msix

    odt_url=$(curl -fsSL "https://www.microsoft.com/en-au/download/details.aspx?id=49117" |
        grep -Eo "https://download\.microsoft\.com/download/[0-9a-f-]+/officedeploymenttool_[0-9-]+\.exe" |
        head -n1) || die "unable to get Office Deployment Tool URL"
    echo "==> Downloading Office Deployment Tool from: $odt_url"
    curl -fL "$odt_url" | bsdtar -xf - -C Office365 EULA setup.exe ||
        die "error extracting Office Deployment Tool"
fi
