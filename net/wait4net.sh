#! /usr/bin/env bash

if [ -n "$1" ] ; then
  tmpfile="$1"
  shift
else
  tmpfile="wait4net.tmp"
fi

# the time of the last break (ctrl-c)
lastbreak=0

# this function is called on ctrl-c
printtime() {
  # the current time
  total=$(date "+%s")
  # if less than 10 seconds have elapsed, exit this script
  if [ $((total-lastbreak)) -lt 10 ] ; then
    printf "Aborted\n"
    stty echoctl
    exit
  fi
  # if we have called this function before clear the previous output
  [ "$lastbreak" -gt 0 ] && printf '\e[A\e[K'
  # set the lastbreak to the current timestamp
  lastbreak="$total"
  # set total to the the total time elapsed since the start
  total=$((total-start))
  # print the elapsed time
  printf "Elapsed time: %s\n" "$(./util/secs2text.sh $total)"
}
# don't echo ctrl characters and trap on ctrl-c to the printtime function
stty -echoctl
trap 'printtime' SIGINT

# set the start time to the current timestamp
start=$(date "+%s")

# the url used with the curl command
url="ifconfig.me"

# print usage, ctrl-c can be used to print the elapsed time or quit early
cat <<EOF
###
# Press ctrl-c to print the current elapsed time
# Press ctrl-c twice within 10 seconds to quit
###
EOF

date
printf "\nWaiting for network . . .\n"
touch "$tmpfile"

abort() {
  stty echoctl
  # kill curl if it is running
  [ -n "$curl_pid" ] && kill -SIGTERM "$curl_pid" >/dev/null 2>&1
  # remove our tmpfile
  rm -f "$tmpfile"
  # remove SIGTERM trap
  trap - SIGTERM
  # resend SIGTERM
  kill -SIGTERM "$BASHPID"
}
trap 'abort' SIGTERM

while true ; do
  # try to get a response from curl
  curl --no-fail --connect-timeout 20 "$url" >"$tmpfile" 2>/dev/null &
  curl_pid="$!"
  wait "$curl_pid"
  curl_pid=
  if [ -s "$tmpfile" ] ; then
    printf "\n~ %s\n" "$(cat "$tmpfile")"
    break
  fi
done
rm -f "$tmpfile"

# set the total elapsed time
total=$(($(date "+%s")-start))

# if the elapsed time had been printed clear that output
[ "$lastbreak" -gt 0 ] && printf '\e[A\e[K'

# print the total elapsed time waiting for the network
printf "Network up !\n\nTotal elapsed time: %s\n" \
        "$(./util/secs2text.sh "$total")"
date
stty echoctl
