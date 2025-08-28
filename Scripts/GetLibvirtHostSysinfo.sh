#!/usr/bin/env bash

set -euo pipefail

# die [<message>]
function die() {
    local s=$?
    printf '%s: %s\n' "${0##*/}" "${1-command failed}" >&2
    ((!s)) && exit 1 || exit $s
}

# assign <var> <file> [<dmidecode-string>]
function assign() {
    if [[ -z $2 ]] && (($# < 3)); then
        eval "$1="
        return
    fi
    local file=$dir/$2 value
    # shellcheck disable=SC2034
    if { [[ -f $file ]] && [[ -r $file ]] &&
        value=$(<"$file") 2>/dev/null; } ||
        { [[ ! -f $file ]] && (($# > 2)) && ((!EUID)) &&
            value=$(dmidecode --string "$3") 2>/dev/null; }; then
        # Escape for use in XML
        value=${value//"&"/"&amp;"}
        value=${value//"'"/"&apos;"}
        value=${value//'"'/"&quot;"}
        value=${value//"<"/"&lt;"}
        value=${value//">"/"&gt;"}
        eval "$1=\$value"
    else
        unreadable[${#unreadable[@]}]=$1
        eval "$1="
    fi
}

dir=/sys/devices/virtual/dmi/id
unreadable=()

[[ -d $dir ]] || die "directory not found: $dir"

assign bios_vendor bios_vendor bios-vendor
assign bios_version bios_version bios-version
assign bios_date bios_date bios-release-date
assign bios_release bios_release bios-revision

assign system_manufacturer sys_vendor system-manufacturer
assign system_product product_name system-product-name
assign system_version product_version system-version
assign system_serial product_serial system-serial-number
assign system_uuid product_uuid system-uuid
assign system_sku product_sku system-sku-number
assign system_family product_family system-family

assign baseBoard_manufacturer board_vendor baseboard-manufacturer
assign baseBoard_product board_name baseboard-product-name
assign baseBoard_version board_version baseboard-version
assign baseBoard_serial board_serial baseboard-serial-number
assign baseBoard_asset board_asset_tag baseboard-asset-tag
assign baseBoard_location ''

assign chassis_manufacturer chassis_vendor chassis-manufacturer
assign chassis_version chassis_version chassis-version
assign chassis_serial chassis_serial chassis-serial-number
assign chassis_asset chassis_asset_tag chassis-asset-tag
assign chassis_sku ''

# shellcheck disable=SC2154
cat <<XML
<domain>
  <os>
    <smbios mode="sysinfo" />
  </os>
  <sysinfo type="smbios">
    <bios>
      <entry name="vendor">${bios_vendor}</entry>
      <entry name="version">${bios_version}</entry>
      <entry name="date">${bios_date}</entry>
      <entry name="release">${bios_release}</entry>
    </bios>
    <system>
      <entry name="manufacturer">${system_manufacturer}</entry>
      <entry name="product">${system_product}</entry>
      <entry name="version">${system_version}</entry>
      <entry name="serial">${system_serial}</entry>
      <entry name="uuid">${system_uuid}</entry>
      <entry name="sku">${system_sku}</entry>
      <entry name="family">${system_family}</entry>
    </system>
    <baseBoard>
      <entry name="manufacturer">${baseBoard_manufacturer}</entry>
      <entry name="product">${baseBoard_product}</entry>
      <entry name="version">${baseBoard_version}</entry>
      <entry name="serial">${baseBoard_serial}</entry>
      <entry name="asset">${baseBoard_asset}</entry>
      <entry name="location">${baseBoard_location}</entry>
    </baseBoard>
    <chassis>
      <entry name="manufacturer">${chassis_manufacturer}</entry>
      <entry name="version">${chassis_version}</entry>
      <entry name="serial">${chassis_serial}</entry>
      <entry name="asset">${chassis_asset}</entry>
      <entry name="sku">${chassis_sku}</entry>
    </chassis>
  </sysinfo>
</domain>

XML

{
    [[ -z ${unreadable+1} ]] || {
        printf 'Run %s as root to include privileged values:\n' "${0##*/}"
        printf -- '- %s\n' "${unreadable[@]}"
        printf '\n'
    }

    printf 'To pass your Windows product key to a VM, copy:\n'
    printf '  %s -> %s\n' /sys/firmware/acpi/tables/MSDM /path/to/MSDM.bin
    printf 'Then add the following XML to the relevant domain:\n'
    cat <<XML
  <qemu:commandline xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0">
    <qemu:arg value="-acpitable" />
    <qemu:arg value="file=/path/to/MSDM.bin" />
  </qemu:commandline>

XML
} >&2
