#!/bin/bash

function sizes ()
{

  usage='Usage: sizes [PATH]'

  # Add splat (*) to the end if omitted
  if [ $# == 0 ]
  then
    SIZES_PATH="*"
  elif [ $# -gt 1 ]
  then
    SIZES_PATH=$@
  elif [ "$1" == "*\*" ]
  then
    SIZES_PATH="$1"
  else
    SIZES_PATH="${1%/}/*"
  fi

  du -sh $SIZES_PATH
}
