#!/bin/bash -l

# Curl continuously for status

curlit() {

  usage='Usage: curlit URL [interval_seconds]

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

  if [ "$2" -gt 0 ]
  then
    interval="$2"
  else
    interval=1
  fi

  while true; do
    RESULT_OUTPUT=$(curl -Is $1 | head -n1)
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
