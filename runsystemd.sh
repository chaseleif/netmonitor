#! /usr/bin/env bash

# run script for systemd service
(
  cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" || exit 1
  ./net/netmon.sh outages.log &
  echo "$!" > pid
)
