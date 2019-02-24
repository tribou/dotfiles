#!/bin/bash

function notify ()
{

  local usage='Usage: notify [MESSAGE]'

  if [ ! $(which osascript) ]
  then
    echo "osascript needs to be installed and available"
    return 1
  fi

  # Defaults
  local MESSAGE=""
  local TITLE="ALERT"
  local SUBTITLE=""

  # Add splat (*) to the end if omitted
  # if [ $# == 0 ]
  # then
  #   # Use Defaults
  if [ $# -eq 1 ]
  then
    local MESSAGE="$1"
  elif [ $# -eq 2 ]
  then
    local MESSAGE="$1"
    local TITLE="$2"
  else
    local MESSAGE="$1"
    local TITLE="$2"
    local SUBTITLE="$3"
  fi

  osascript -e 'display notification "'"$MESSAGE"'" with title "'"$TITLE"'" subtitle "'"$SUBTITLE"'"'
}

