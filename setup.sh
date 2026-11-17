#! /usr/bin/env bash

sed "s|@PWD@|$PWD|g" netmonitor.service.in > netmonitor.service
sed -i "s/@USER@/$USER/g" netmonitor.service

sed "s|@PWD@|$PWD|g" netmonitor.in > netmonitor
sed -i "s/@USER@/$USER/g" netmonitor
group="$(id -gn "${USER}" 2>/dev/null)"
[ -n "$group" ] || group="nobody"
sed -i "s/@GROUP@/$group/g" netmonitor
