#!/bin/bash

function notify ()
{

  usage='Usage: notify [MESSAGE]'

  if [ ! $(which osascript) ]
  then
    echo "osascript needs to be installed and available"
    return 1
  fi

  # Defaults
  MESSAGE=""
  TITLE="ALERT"
  SUBTITLE=""

  # Add splat (*) to the end if omitted
  # if [ $# == 0 ]
  # then
  #   # Use Defaults
  if [ $# -eq 1 ]
  then
    MESSAGE="$1"
  elif [ $# -eq 2 ]
  then
    MESSAGE="$1"
    TITLE="$2"
  else
    MESSAGE="$1"
    TITLE="$2"
    SUBTITLE="$3"
  fi

  osascript -e 'display notification "'"$MESSAGE"'" with title "'"$TITLE"'" subtitle "'"$SUBTITLE"'"'
}

