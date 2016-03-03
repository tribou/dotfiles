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
  SCREEN_COLUMNS=`tput cols`
  MESSAGE_LENGTH=${#1}
  MESSAGE_LINE=$(( $SCREEN_LINES / 2 ))
  SCREEN_COLUMNS_HALF=$(( $SCREEN_COLUMNS / 2 ))
  MESSAGE_LENGTH_HALF=$(( $MESSAGE_LENGTH / 2 ))
  MESSAGE_COLUMN=$(( $SCREEN_COLUMNS_HALF - $MESSAGE_LENGTH_HALF ))
  echo "$MESSAGE_COLUMN"

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
