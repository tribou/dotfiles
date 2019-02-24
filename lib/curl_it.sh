#!/bin/bash -l

# Curl continuously for HTTP status

curlit() {

  local usage='Usage: curlit URL [interval_seconds]

  Example: curlit https://www.google.com/ 5
  '

  # Return usage if 0 or more than 1 args are passed
  if [ $# -eq 0 ] || [ $# -gt 2 ]
  then
    echo "$usage"
    return 1
  fi

  if [ "$1" = "help" ]
  then
    echo "$usage"
    return 0
  fi

  if [ $# -eq 1 ]
  then
    local interval=1
  elif [ "$2" -gt 0 ]
  then
    local interval="$2"
  else
    local interval=1
  fi

  while true; do
    local RESULT_OUTPUT=$(curl -Is $1 | head -n1)
    printf $(date +%Y-%m-%dT%H:%M:%S%z)
    echo " $RESULT_OUTPUT"

    if [ "$?" -ne 0 ]
    then
      echo "Call to $1 failed"
      return 1
    fi

    sleep $interval
  done
}
