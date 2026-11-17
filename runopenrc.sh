#! /usr/bin/env bash

# run script for openrc service
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" || exit 1
exec ./net/netmon.sh outages.log
