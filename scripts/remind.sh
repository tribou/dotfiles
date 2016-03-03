#!/bin/bash -l

# Remind me to do something when I get back to my desk

remind() {

  usage='Usage: remind MESSAGE

Example:
  remind '"'"'I need to remember this!!!'"'"'
'

  # Return usage if no args are passed
  if [ $# -eq 0 ]
  then
    echo -e "$usage"
    return 1
  fi

  SCREEN_LINES=`tput lines`
  MESSAGE_LINE=$(( $SCREEN_LINES / 2 ))

  for i in `seq 1 "$SCREEN_LINES"`
  do
    if [[ i -eq "$MESSAGE_LINE" ]]
    then
      echo "$1"
    else
      echo
    fi
  done

}
