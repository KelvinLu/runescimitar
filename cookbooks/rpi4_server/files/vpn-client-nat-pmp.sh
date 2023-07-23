#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

if [ "$#" -eq 1 ]; then
  INTERFACE=$1
elif [ "$#" -eq 2 ]; then
  if [ "$1" != '--check' ]; then
    echo 'Wrong number of arugments, expected "--check <interface>" or "<interface>"' >&2
    exit 2
  fi
  INTERFACE=$2
else
  echo 'Wrong number of arugments, expected "--check <interface>" or "<interface>"' >&2
  exit 2
fi

GATEWAY=$(cat "/etc/vpn-client-nat-pmp/${INTERFACE}/gateway")
PORT=$(cat "/etc/vpn-client-nat-pmp/${INTERFACE}/port")

if [ "$#" -eq 2 ]; then
  natpmpc -g "${GATEWAY}"
else
  natpmpc -g "${GATEWAY}" -a 0 "${PORT}" tcp 60
fi
