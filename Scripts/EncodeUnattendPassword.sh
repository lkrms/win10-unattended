#!/usr/bin/env bash

set -euo pipefail

while :; do
    read -rsp "Password: " PW
    echo
    read -rsp "Password (again): " PW2
    echo
    [[ $PW != "$PW2" ]] || break
    echo "Passwords did not match"
done

PW=$(printf '%sPassword' "$PW" | perl -pe 's/(.)/\1\0/g' | base64)

cat <<XML

<Password>
   <Value>$PW</Value>
   <PlainText>false</PlainText>
</Password>
XML
