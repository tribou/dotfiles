#!/bin/bash -l

# Remind me to do something when I get back to my desk

remind() {

  local usage='Usage: remind MESSAGE

Example:
  remind '"'"'I need to remember this!!!'"'"'
'

  local MESSAGE="${@:-`cat -`}"
  local SCREEN_LINES=`tput lines`
  local SCREEN_COLUMNS=`tput cols`
  local MESSAGE_LENGTH=1
  local MESSAGE_LINE_COUNTS
  local N=0
  local X
  while read X
  do
    local CURRENT_LINE_COUNT=${#X}
    if [ $CURRENT_LINE_COUNT -gt $MESSAGE_LENGTH ]
    then
      MESSAGE_LENGTH=$CURRENT_LINE_COUNT
    fi
    MESSAGE_LINE_COUNTS[$((++N))]=${CURRENT_LINE_COUNT}
  done <<<"$MESSAGE"
  # Echo, count lines, trim whitespace
  local MESSAGE_HEIGHT=$(echo "$MESSAGE" | wc -l | xargs)
  local ECHO_LINES=$(( $SCREEN_LINES - $MESSAGE_HEIGHT ))
  local MESSAGE_START_LINE="$(( $ECHO_LINES / 2 ))"
  local SCREEN_COLUMNS_HALF=$(( $SCREEN_COLUMNS / 2 ))

  for i in `seq 1 "$ECHO_LINES"`
  do
    if [[ i -eq "$MESSAGE_START_LINE" ]]
    then

      while read X
      do
        local CLEANED_LINE=$(printf "%s" "$X" | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g')
        local CURRENT_LINE_LENGTH=${#CLEANED_LINE}
        local MESSAGE_LENGTH_HALF=$(( $CURRENT_LINE_LENGTH / 2 ))
        local MESSAGE_COLUMN=$(( $SCREEN_COLUMNS_HALF - $MESSAGE_LENGTH_HALF ))

        for i in `seq 1 "$MESSAGE_COLUMN"`
        do
          printf " "
        done

        printf "%s" "$X"
        echo

      done <<<"$MESSAGE"

    else
      echo
    fi
  done

}
