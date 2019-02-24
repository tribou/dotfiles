#!/bin/bash -l

# Remind me to do something when I get back to my desk

remind() {

  local usage='Usage: remind MESSAGE

Example:
  remind '"'"'I need to remember this!!!'"'"'
'

  # Return usage if no args are passed
  if [ $# -eq 0 ]
  then
    echo -e "$usage"
    return 1
  fi

  local SCREEN_LINES=`tput lines`
  local SCREEN_COLUMNS=`tput cols`
  local MESSAGE_LENGTH=${#1}
  local MESSAGE_LINE=$(( $SCREEN_LINES / 2 ))
  local SCREEN_COLUMNS_HALF=$(( $SCREEN_COLUMNS / 2 ))
  local MESSAGE_LENGTH_HALF=$(( $MESSAGE_LENGTH / 2 ))
  local MESSAGE_COLUMN=$(( $SCREEN_COLUMNS_HALF - $MESSAGE_LENGTH_HALF ))

  for i in `seq 1 "$SCREEN_LINES"`
  do
    if [[ i -eq "$MESSAGE_LINE" ]]
    then

      for i in `seq 1 "$MESSAGE_COLUMN"`
      do
        printf " "
      done

      echo "$1"

    else
      echo
    fi
  done

}
