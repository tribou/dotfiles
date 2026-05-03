#!/bin/bash

function notify ()
{

  local usage='Usage: notify [MESSAGE]'

  [[ "$OSTYPE" != "darwin"* ]] && return 0

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

  local SAFE_MESSAGE="${MESSAGE//\"/\\\"}"
  local SAFE_TITLE="${TITLE//\"/\\\"}"
  local SAFE_SUBTITLE="${SUBTITLE//\"/\\\"}"
  osascript -e 'display notification "'"$SAFE_MESSAGE"'" with title "'"$SAFE_TITLE"'" subtitle "'"$SAFE_SUBTITLE"'"'
}

