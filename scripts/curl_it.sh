#!/bin/bash -l

# Curl continuously for status

curlit() {

  usage='Usage: curlit URL'
  search_dir='.'

  # Return usage if 0 or more than 1 args are passed
  if [ $# -eq 0 ] || [ $# -gt 1 ]
  then
    echo "$usage"
    return 1
  fi

  while true; do
    RESULT_OUTPUT=$(curl -Is $1 | head -n1)
    printf $(date +%Y-%m-%dT%H:%M:%S%z)
    echo " $RESULT_OUTPUT"
    sleep 1
  done
}
