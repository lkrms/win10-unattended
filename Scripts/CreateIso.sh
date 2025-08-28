#!/usr/bin/env bash

set -euo pipefail

# die [<message>]
function die() {
    local s=$?
    printf '%s: %s\n' "${0##*/}" "${1-command failed}" >&2
    ((!s)) && exit 1 || exit $s
}

function usage() {
    printf 'Usage: %s [options]\n\nOptions:\n' "${0##*/}"
    printf '  %s    %s\n' \
        "--iso <path>" "Set output path (default: Dist/Unattended.iso)" \
        "--[no-]wifi" "Include or exclude Wi-Fi.xml (if present)" \
        "--[no-]office" "Include or exclude Office365 directory (if present)" \
        "--driver <path>..." "Add file or directory to Drivers" \
        "--driver2 <path>..." "Add file or directory to Drivers2" \
        "--update <path>..." "Add file or directory to Updates" \
        "--reg <path>..." "Add file to Unattended.reg.d"
    exit 1
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

# ask <option> <question> [<default>]
function ask() {
    local var=$1
    shift
    if confirm "$@"; then
        eval "$var=1"
    else
        eval "$var=0"
    fi
}

[[ ${BASH_SOURCE[0]} -ef Scripts/CreateIso.sh ]] ||
    die "must run from root of package folder"

iso=$PWD/Dist/Unattended.iso
wifi=
office=
driver=()
driver2=()
update=()
reg=()

reg_cmd=Unattended/Optional/ApplyRegistrySettings.cmd
reg_dir=Unattended/Optional/Unattended.reg.d

while [[ ${1-} == -* ]]; do
    case "$1" in
    --iso)
        shift
        iso=${1-}
        [[ -n $iso ]] || usage
        [[ $iso == /* ]] || iso=$PWD/$iso
        ;;
    --wifi)
        wifi=1
        ;;
    --no-wifi)
        wifi=0
        ;;
    --office)
        office=1
        ;;
    --no-office)
        office=0
        ;;
    --driver)
        while (($# > 1)) && [[ $2 != -* ]]; do
            shift
            [[ -e $1 ]] || die "file not found: $1"
            driver[${#driver[@]}]=$1
        done
        ;;
    --driver2)
        while (($# > 1)) && [[ $2 != -* ]]; do
            shift
            [[ -e $1 ]] || die "file not found: $1"
            driver2[${#driver2[@]}]=$1
        done
        ;;
    --update)
        while (($# > 1)) && [[ $2 != -* ]]; do
            shift
            [[ -e $1 ]] || die "file not found: $1"
            update[${#update[@]}]=$1
        done
        ;;
    --reg)
        [[ -f $reg_cmd ]] || die "--reg cannot be given without $reg_cmd"
        while (($# > 1)) && [[ $2 != -* ]]; do
            shift
            [[ -f $1 ]] || die "file not found: $1"
            reg[${#reg[@]}]=$1
        done
        ;;
    *)
        usage
        ;;
    esac
    shift
done

target=$(mktemp -d)
((EUID)) || chmod a+rx "$target" || true
trap 'rm -Rf "$target"' EXIT

sync=(Audit.xml Autounattend.xml Unattended)

for dir in Drivers Drivers2 MSI Tools Updates; do
    [[ ! -d $dir ]] || sync[${#sync[@]}]=$dir
done

[[ ! -f Wi-Fi.xml ]] ||
    { { [[ -n $wifi ]] || ask wifi "Include Wi-Fi.xml?" n; } && ((!wifi)); } ||
    sync+=(Wi-Fi.xml)

[[ ! -d Office365 ]] ||
    { { [[ -n $office ]] || ask office "Include Office365 directory?" n; } && ((!office)); } ||
    sync+=(Office365)

delete=(
    {Drivers,Drivers2,MSI,Tools,Unattended/Extra,Updates}/README.md
    Unattended/Optional/Unattended.reg.d/.gitignore
)

{
    echo "==> Creating ISO filesystem: $target"
    rsync -rtvi "${sync[@]}" "$target/"
    echo
    (
        cd "$target"
        echo " -> Removing unnecessary files"
        rm -fv "${delete[@]}"
        echo
    )

    echo " -> Syncing additional files"
    ((!${#driver[@]})) ||
        rsync -rtvi --mkpath "${driver[@]%/}" "$target/Drivers/"
    ((!${#driver2[@]})) ||
        rsync -rtvi --mkpath "${driver2[@]%/}" "$target/Drivers2/"
    ((!${#update[@]})) ||
        rsync -rtvi --mkpath "${update[@]%/}" "$target/Updates/"
    ((!${#reg[@]})) ||
        rsync -rtvi --mkpath "${reg[@]%/}" "$target/$reg_dir/"
    echo

    echo "==> ISO filesystem successfully created: $target"
    echo
    confirm "Create ISO file?" y || exit

    (
        cd "$target"

        echo " -> Removing empty directories"
        find . -type d -empty -print -delete
        echo

        echo " -> Creating ISO file"
        rm -f "$iso"
        mkdir -p "${iso%/*}"
        name=${iso%.*}
        name=${name##*/}
        mkisofs -o "$iso" -V "$name" -UDF .
        echo
    )

    echo "==> ISO file successfully created: $iso"

    exit
}
