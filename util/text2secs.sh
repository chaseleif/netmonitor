#! /usr/bin/env bash

# handle either command-line arguments or text pipe
if [[ "${*}" ]] ; then
  : # we have command-line arguments already
elif [[ ! -t 0 ]] ; then
  # gather pipe into the array 'arg'
  read -ra args
  # treat args as command-line arguments
  set -- "${args[@]}"
fi

numba=0
seconds=0
# for each argument, numbers are preceded by their type
while (( $# )) ; do
  arg="$1"
  shift
  # 1 week, 5 minutes
  # numbers precede their type, store the number when encountered
  # when the type is encountered increment seconds by the type
  # types may end in an s and may have a trailing comma
  if [[ "$arg" =~ ^[1-9][0-9]*$ ]] ; then
    numba="$arg"
  elif [[ "$arg" =~ ^week[s]?[,]?$ ]] ; then
    seconds=$((seconds+numba*604800))
  elif [[ "$arg" =~ ^day[s]?[,]?$ ]] ; then
    seconds=$((seconds+numba*86400))
  elif [[ "$arg" =~ ^hour[s]?[,]?$ ]] ; then
    seconds=$((seconds+numba*3600))
  elif [[ "$arg" =~ ^minute[s]?[,]?$ ]] ; then
    seconds=$((seconds+numba*60))
  elif [[ "$arg" =~ ^second[s]?$ ]] ; then
    seconds=$((seconds+numba))
  fi
done

# print the number of seconds
printf "%d\n" "$seconds"
