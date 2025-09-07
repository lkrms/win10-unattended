#!/usr/bin/env bash

set -euo pipefail

# Usage: DownloadOffice365.sh [<channel> [<arch>,... [<language>,...]]]
#
# - <channel>: (Current|MonthlyEnterprise|SemiAnnual); default: Current
# - <arch>: (x64|x32); default: x64
# - <language>: <id>; default: en-gb,en-us

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
        args=(--time-cond "$2" --dump-header "$temp")
        verb=Updating
    }
    echo " -> $verb ${2##*/} from: $1"
    curl -f#Lo "$2" --remote-time ${args+"${args[@]}"} "$1" || return
    [[ -n ${args+1} ]] &&
        awk '$1 ~ /^HTTP\// { sub(/\r/, ""); s = $2 } END { exit s == 304 ? 0 : 1 }' "$temp" ||
        replaced[${#replaced[@]}]=$2
}

# confirm <question> [<default>]
function confirm() {
    local answer default key='y/n'
    (($# < 2)) ||
        if [[ ${2,,} =~ ^y(es)?$ ]]; then
            key='Y/n'
            default=0
        else
            key='y/N'
            default=1
        fi
    while :; do
        read -rp "$1 [$key] " answer
        if [[ ${answer,,} =~ ^y(es)?$ ]]; then
            return 0
        elif [[ ${answer,,} =~ ^no?$ ]]; then
            return 1
        elif [[ -n ${default-} ]] && [[ -z $answer ]]; then
            return $default
        fi
    done
}

[[ ${BASH_SOURCE[0]} -ef Scripts/DownloadOffice365.sh ]] ||
    die "must run from root of package folder"

IFS=,
channel=${1:-Current}
# shellcheck disable=SC2206
arch=(${2:-x64})
# shellcheck disable=SC2206
lang=(${3:-en-gb,en-us})

# See https://learn.microsoft.com/en-us/intune/configmgr/sum/deploy-use/manage-office-365-proplus-updates#bkmk_channel
case "$channel" in
Current | Monthly)
    # "Current Channel" (previously "Monthly Channel")
    channel=Current
    channel_guid=492350f6-3a01-4f97-b9c0-c7c6ddf67d60
    ;;
MonthlyEnterprise)
    # "Monthly Enterprise Channel"
    channel_guid=55336b82-a18d-4dd6-b5f6-9e5095c314a6
    ;;
SemiAnnual)
    # "Semi-Annual Enterprise Channel" (previously "Semi-Annual Channel")
    channel_guid=7ffbc6bf-bc32-4f92-8982-f9dd17fd3114
    ;;
*)
    die "invalid channel: $channel"
    ;;
esac

temp=$(mktemp)
trap 'rm -f "$temp"' EXIT

lang[${#lang[@]}]=x-none
keep_args=()
replaced=()

version=$(
    url=https://mrodevicemgr.officeapps.live.com/mrodevicemgrsvc/api/v2/C2RReleaseData/$channel_guid
    curl -fsSL "$url" |
        jq -r .AvailableBuild
)

echo "==> Downloading Office $version (channel: $channel; arch: ${arch[*]}; language: ${lang[*]})"

while IFS=$'\t' read -r url relative_path hash_location hash_algorithm; do
    target=Office365/Office/Data/${relative_path#/office/data/}
    mkdir -p "${target%/*}"
    download "$url" "$target"
    if [[ ${hash_location:+$hash_algorithm} == Sha256 ]]; then
        hash_cab=${target%/*}/${hash_location%/*}
        [[ -f $hash_cab ]] || die "hashLocation cab not found: $hash_cab"
        echo " -> Verifying ${target##*/} with $hash_location"
        hash=$(cabextract -pF "${hash_location##*/}" "$hash_cab" 2>/dev/null | iconv -f UTF-16LE -t UTF-8) &&
            sha256sum -c <(printf '%s  %s\n' "$hash" "$target") ||
            die "hash check failed: $target"
    fi
    keep_args+=(${keep_args+-o} -path "$target")
done < <(
    IFS=
    lid=${lang[*]/#/"&lid="}
    for arch in "${arch[@]}"; do
        url="https://config.office.com/api/filelist?Channel=$channel&Arch=$arch&version=$version$lid"
        #echo " -> Retrieving file list from: $url" >&2
        curl -fsSL "$url" |
            jq -r '.files[] | select(.languageType != "proofingonly") | [ .url, (.relativePath + .name), .hashLocation, .hashAlgorithm ] | @tsv'
    done
)

[[ -n ${keep_args+1} ]] || die "nothing downloaded"

[[ -z ${replaced+1} ]] || {
    echo
    echo "==> Downloaded:"
    du -hc "${replaced[@]}" 2>/dev/null ||
        printf ' -> %s\n' "${replaced[@]}"
}

IFS=$'\n'
# shellcheck disable=SC2207
delete=($(find -H Office365/Office -type f ! \( "${keep_args[@]}" \) -print))
if [[ -n ${delete+1} ]]; then
    echo
    echo "==> Outdated files:"
    printf ' -> %s\n' "${delete[@]}"
    if confirm "Delete ${#delete[@]} outdated file(s)?"; then
        rm -fv "${delete[@]}"
        find -H Office365/Office -type d -empty -delete
    fi
fi
