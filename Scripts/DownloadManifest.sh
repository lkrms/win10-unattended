#!/usr/bin/env bash

set -euo pipefail

shopt -s nocasematch

# die [<message>]
function die() {
    local s=$?
    printf '%s: %s\n' "${0##*/}" "${1-command failed}" >&2
    ((!s)) && exit 1 || exit $s
}

function usage() {
    printf 'Usage: %s <repo> <path> [<ref>]\n\nOptions:\n' "${0##*/}"
    printf '  %s    %s\n' \
        "<repo>" "GitHub repository, e.g. SpecterShell/winget-pkgs" \
        "<path>" "Path to manifest, e.g. manifests/g/Google/Chrome/143.0.7499.110" \
        "<ref> " "Branch, tag or commit in <repo>, e.g. Google.Chrome-143.0.7499.110-1602356508"
    printf '%s\n' '' \
        "- <path> must resolve to a directory in <repo>" \
        "- Singleton manifests are not supported" \
        "- Installers are not downloaded"
    exit 1
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

[[ ${BASH_SOURCE[0]} -ef Scripts/DownloadManifest.sh ]] ||
    die "must run from root of package folder"

(($# > 1)) || usage
[[ $1 == +([a-z0-9])*(-+([a-z0-9]))?(-)/+([-a-z0-9._]) ]] || die "invalid repo: $1"
[[ $2 == */*/* ]] || die "invalid path: $2"

temp=$(mktemp)
trap 'rm -f "$temp"' EXIT

replaced=()

repo=$1   # SpecterShell/winget-pkgs
path=$2   # manifests/g/Google/Chrome/143.0.7499.110
ref=${3-} # Google.Chrome-143.0.7499.110-1602356508

# Remove leading and trailing slashes from path
while [[ $path == /* ]]; do path=${path#/}; done
while [[ $path == */ ]]; do path=${path%/}; done

# Get manifest name from path
name=${path%/*}
while [[ $name == */*/* ]]; do
    name=${name#*/}
done
name=${name/\//.}

args=()
[[ -z ${GITHUB_TOKEN:+1} ]] || args=(-H "Authorization: Bearer $GITHUB_TOKEN")

IFS=$'\n'
# shellcheck disable=SC2207
urls=($(
    curl -fsSL ${args+"${args[@]}"} \
        "https://api.github.com/repos/$repo/contents/$path${ref:+?ref=$ref}" |
        jq -r '.[].download_url'
))

[[ -n ${urls+1} ]] || die "no files in manifest"

echo "==> Downloading manifest: $name"

mkdir -p "Unattended/Cache/Manifests/$name"
for url in "${urls[@]}"; do
    download "$url" "Unattended/Cache/Manifests/$name/${url##*/}"
done

[[ -z ${replaced+1} ]] || {
    echo
    echo "==> Downloaded:"
    du -hcD "${replaced[@]}" 2>/dev/null ||
        printf ' -> %s\n' "${replaced[@]}"
}
