#! /usr/bin/env bash

# This is meant to run as a daemon, try to set nice to lowest priority
renice -n 19 -p "$BASHPID" >/dev/null 2>&1

outageslog="$1"
shift
[ -n "$outageslog" ] || outageslog="outages.log"

exec >> "$outageslog"
exec 2>&1

# domains to ping to test connectivity
domains=(8.8.8.8
          4.2.2.2
          8.8.4.4
          4.1.1.1)
# domain index increments until it reaches len, start at -1
domaini=-1

# try to ping and return whether it was successful
try_ping() {
  ((++domaini))
  [ "$domaini" -eq "${#domains[@]}" ] && domaini=0
  ping -c1 -q "${domains[$domaini]}" >/dev/null 2>&1 && return 0
  return 1
}

# interruptibly await a new background process
await() {
  "$@" &
  bg_process="$!"
  wait "$bg_process"
  local rc="$?"
  bg_process=
  return "$rc"
}

# if we have an outages file with a total outage time
if grep -c1 -q "Total" "$outageslog" 2>/dev/null ; then
  # retain the total outage time from the prior process
  totaloutage=$(
    grep -E "^Total" "$outageslog" |
    tail -n1 |
    cut -c16- |
    ./util/text2secs.sh
  )
else
  totaloutage=0
fi

timer=0
startoutage() {
  printf " ~ Outage start: %s\n" "$(date)"
  timer=1
  # always returns "failure" to set $?
  return 1
}

endoutage() {
  if [ "$timer" -eq 1 ] ; then
    outage=$(($(date "+%s")-loopstart))
    totaloutage=$((totaloutage+outage))
    # log outage times
    printf "This outage: %s\n" "$(./util/secs2text.sh "$outage")"
    printf "Total outages: %s\n" "$(./util/secs2text.sh "$totaloutage")"
    [ $# -eq 0 ] && printf " ~ Outage end: %s\n" "$(date)"
    timer=0
  fi
}

# log the signal to terminate or interrupt and exit
signal() {
  endoutage "signal"
  printf " ~ Monitor received %s: %s\n" "$1" "$(date)"
  [ -n "$bg_process" ] && kill -SIGTERM "$bg_process" >/dev/null 2>&1
  exit
}
trap 'signal SIGTERM' SIGTERM
trap 'signal SIGINT' SIGINT

# begin monitoring connectivity
printf " ~ Monitor starting: %s\n" "$(date)"
while true ; do
  loopstart="$(date "+%s")"
  # sleep for 60-120 seconds
  await sleep "$((RANDOM%61+60))"
  # if we can ping restart the loop
  try_ping && continue
  # sleep for 30-60 seconds
  await sleep "$((RANDOM%31+30))"
  # if we can ping restart the loop
  try_ping && continue
  # if we can connect to ifconfig.me for an ip address then restart the loop
  if await curl --no-fail --connect-timeout 5 ifconfig.me >/dev/null 2>&1 ;
    then continue
  fi
  # we are in an outage
  startoutage
  # wait for the network to come back up
  while [ "$?" -ne 0 ] ; do
    # this script will not exit until a (likely) successful net connection
    ./net/wait4net.sh >/dev/null 2>&1
    # call the script to determine+handle if our ip changed
    # this script can exit with failure to restart the loop
    python3 -B ip/ipmon.py
  done
  # the outage has ended
  endoutage
done
