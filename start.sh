#! /usr/bin/env bash

(
  cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" || exit 1
  nice -n 19 ./net/netmon.sh outages.log &
  echo "$!" > pid
)
