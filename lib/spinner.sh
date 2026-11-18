#!/bin/bash

# Spinner shared by the `commit` command (lib/git.sh) and the bootstrap
# converge task (scripts/bootstrap/converge.sh). Standalone: no other lib file
# is needed, so plain scripts can source it.

# _dotfiles_spinner_wait PID LABEL [TIMEOUT_SECS]
# Animates "<frame> LABEL" on one stderr line while PID runs, then clears the
# line and returns PID's exit status: 124 on timeout and 130 on Ctrl-C, after
# killing PID. When stderr is not a terminal it prints LABEL once instead.
function _dotfiles_spinner_wait ()
{
  local pid="$1"
  local label="$2"
  local timeout_secs="${3:-0}"
  local interrupted=0
  local is_tty=0
  local frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  local frame_index=0

  # Enable a timeout only for a positive integer; anything else means "wait forever".
  local max_iterations=0
  if [ "$timeout_secs" -gt 0 ] 2> /dev/null
  then
    max_iterations=$(( timeout_secs * 10 ))
  fi
  local iterations=0

  trap 'interrupted=1' INT

  if [ -t 2 ]
  then
    is_tty=1
  else
    printf '%s\n' "$label" >&2
  fi

  while kill -0 "$pid" 2> /dev/null
  do
    if [ "$interrupted" -eq 1 ]
    then
      kill "$pid" 2> /dev/null
      [ "$is_tty" -eq 1 ] && printf '\r\033[K' >&2
      trap - INT
      return 130
    fi

    if [ "$max_iterations" -gt 0 ] && [ "$iterations" -ge "$max_iterations" ]
    then
      kill "$pid" 2> /dev/null
      [ "$is_tty" -eq 1 ] && printf '\r\033[K' >&2
      trap - INT
      return 124
    fi

    if [ "$is_tty" -eq 1 ]
    then
      printf '\r%s %s' "${frames[frame_index]}" "$label" >&2
      frame_index=$(( (frame_index + 1) % 10 ))
    fi

    sleep 0.1
    iterations=$(( iterations + 1 ))
  done

  [ "$is_tty" -eq 1 ] && printf '\r\033[K' >&2

  wait "$pid"
  local status=$?
  trap - INT
  return "$status"
}
