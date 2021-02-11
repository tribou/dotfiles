#!/bin/bash

# Display the current internet connection status to google

if [ -s "$(which curl)" ]
then
  if [ -n "$(curl -Is https://www.google.com --max-time 1 | head -n1 | awk '{print $2}')" ]
  then
    echo ✅
  else
    echo ⛔️
  fi
else
  echo "N/A"
fi
