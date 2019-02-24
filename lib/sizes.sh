#!/bin/bash

function sizes ()
{

  local usage='Usage: sizes [PATH]'

  # Add splat (*) to the end if omitted
  if [ $# == 0 ]
  then
    local SIZES_PATH="*"
  elif [ $# -gt 1 ]
  then
    local SIZES_PATH=$@
  elif [ "$1" == "*\*" ]
  then
    local SIZES_PATH="$1"
  else
    local SIZES_PATH="${1%/}/*"
  fi

  du -sh $SIZES_PATH
}
