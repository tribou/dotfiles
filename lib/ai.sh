#!/bin/bash

function _dotfiles_ai_backend ()
{
  local backend
  if [ -n "${DOTFILES_AI_BACKEND+x}" ]
  then
    backend="${DOTFILES_AI_BACKEND:-opencode}"
  elif [ -n "${DOTFILES_COMMIT_BACKEND+x}" ]
  then
    printf '%s\n' 'DOTFILES_COMMIT_BACKEND is deprecated; use DOTFILES_AI_BACKEND' >&2
    backend="${DOTFILES_COMMIT_BACKEND:-opencode}"
  else
    backend=opencode
  fi

  case "$backend" in
    claude|opencode|agy) printf '%s' "$backend" ;;
    *)
      printf 'unknown DOTFILES_AI_BACKEND=%s, using opencode\n' "$backend" >&2
      printf '%s' opencode
      ;;
  esac
}

function _dotfiles_ai_model ()
{
  local backend="$1"
  local model
  if [ -n "${DOTFILES_AI_MODEL+x}" ]
  then
    model="$DOTFILES_AI_MODEL"
  elif [ -n "${DOTFILES_COMMIT_MODEL+x}" ]
  then
    printf '%s\n' 'DOTFILES_COMMIT_MODEL is deprecated; use DOTFILES_AI_MODEL' >&2
    model="$DOTFILES_COMMIT_MODEL"
  fi

  if [ -n "$model" ]
  then
    printf '%s' "$model"
    return 0
  fi

  case "$backend" in
    opencode) printf '%s' 'opencode-go/kimi-k2.7-code' ;;
    agy) printf '%s' 'gemini-3.7-flash-low' ;;
    *) printf '%s' 'haiku' ;;
  esac
}

function _dotfiles_ai_timeout ()
{
  local variable_name="$1"
  local default_secs="$2"
  local timeout_secs="${!variable_name:-}"
  case "$timeout_secs" in
    ''|*[!0-9]*) timeout_secs="$default_secs" ;;
  esac
  printf '%s' "$timeout_secs"
}

function _dotfiles_qq_timeout ()
{
  _dotfiles_ai_timeout DOTFILES_QQ_TIMEOUT 60
}

function _dotfiles_ai_spinner_wait ()
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
