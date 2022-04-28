#!/bin/bash

# Display the current battery percentage

if [ -s "$(which pmset)" ]
then
  pmset -g batt | grep [0-9]% | awk '{print $3}' | cut -c 1-4 | sed -E 's/;//'
else
  echo "N/A"
fi
