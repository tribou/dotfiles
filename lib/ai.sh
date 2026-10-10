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

function _dotfiles_ai_track_history ()
{
  _DOTFILES_AI_PROMPT_HISTCMD="$HISTCMD"
}

function _dotfiles_qq_history_question ()
{
  if [ -z "${_DOTFILES_AI_PROMPT_HISTCMD+x}" ] || \
    [ "$HISTCMD" != "$_DOTFILES_AI_PROMPT_HISTCMD" ]
  then
    return 2
  fi

  local had_histtimeformat=0 saved_histtimeformat history_line history_number command_line
  if [ -n "${HISTTIMEFORMAT+x}" ]
  then
    had_histtimeformat=1
    saved_histtimeformat="$HISTTIMEFORMAT"
  fi
  HISTTIMEFORMAT=
  history_line=$(history 1)
  if [ "$had_histtimeformat" -eq 1 ]
  then
    HISTTIMEFORMAT="$saved_histtimeformat"
  else
    unset HISTTIMEFORMAT
  fi

  history_number=$(printf '%s\n' "$history_line" | sed -E 's/^[[:space:]]*([0-9]+).*/\1/')
  [ "$history_number" = "$HISTCMD" ] || return 2
  command_line=$(printf '%s\n' "$history_line" | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//')
  case "$command_line" in
    qq) return 0 ;;
    qq[[:space:]]*) printf '%s' "${command_line#qq}" | sed -E 's/^[[:space:]]//' ;;
    *) return 2 ;;
  esac
}

function _dotfiles_qq ()
{
  local question=""
  if [[ $- == *i* ]] && [ "$#" -eq 0 ]
  then
    question=$(_dotfiles_qq_history_question)
    local history_status=$?
    if [ "$history_status" -eq 2 ]
    then
      printf '%s\n' 'qq: question not in history (leading space?); run bare qq instead' >&2
      return 1
    fi
  else
    question="$*"
  fi

  if [ -z "$question" ]
  then
    IFS= read -e -r -p 'qq> ' question
    local read_status=$?
    if [ "$read_status" -ne 0 ]
    then
      [ "$read_status" -eq 130 ] && return 130
      return 1
    fi
  fi
  [ -n "$question" ] || return 1

  local backend model timeout_secs wrapped_question
  backend=$(_dotfiles_ai_backend)
  model=$(_dotfiles_ai_model "$backend")
  timeout_secs=$(_dotfiles_qq_timeout)
  wrapped_question="Answer concisely for display in a terminal. Prefer short answers; use code blocks for commands.

$question"

  if ! command -v "$backend" >/dev/null 2>&1
  then
    printf 'qq: %s not found\n' "$backend" >&2
    return 1
  fi

  local tmpdir workdir outfile
  tmpdir=$(mktemp -d) || return 1
  workdir="$tmpdir/work"
  mkdir "$workdir" || { rm -rf "$tmpdir"; return 1; }
  outfile="$tmpdir/answer"

  case "$backend" in
    opencode)
      (
        cd "$workdir" || exit 1
        OPENCODE_PERMISSION='"deny"' \
          opencode run --pure --model "$model" "$wrapped_question" \
          >"$outfile" 2>/dev/null
      ) &
      ;;
    agy)
      (
        cd "$workdir" || exit 1
        agy -p "$wrapped_question" --model "$model" \
          >"$outfile" 2>/dev/null
      ) &
      ;;
    *)
      (
        cd "$workdir" || exit 1
        claude -p --model "$model" --tools "" \
          --disallowedTools 'mcp__*' --safe-mode --no-session-persistence \
          -- "$wrapped_question" >"$outfile" 2>/dev/null
      ) &
      ;;
  esac
  local pid=$!

  local backend_label
  backend_label="$(printf '%s' "$backend" | head -c 1 | tr '[:lower:]' '[:upper:]')$(printf '%s' "$backend" | tail -c +2)"
  _dotfiles_ai_spinner_wait "$pid" "Asking ${backend_label}..." "$timeout_secs"
  local wait_status=$?

  case "$wait_status" in
    130)
      rm -rf "$tmpdir"
      printf '%s\n' 'qq canceled' >&2
      return 130
      ;;
    124)
      rm -rf "$tmpdir"
      printf 'qq: %s timed out after %ss\n' "$backend" "$timeout_secs" >&2
      return 124
      ;;
    0) ;;
    *)
      rm -rf "$tmpdir"
      printf 'qq: %s returned no answer\n' "$backend" >&2
      return 1
      ;;
  esac

  local answer
  answer=$(awk '
    {
      lines[NR] = $0
      if ($0 !~ /^[[:space:]]*$/) {
        if (first == 0) first = NR
        last = NR
      }
    }
    END {
      if (first != 0) {
        for (i = first; i <= last; i++) print lines[i]
      }
    }
  ' "$outfile")
  rm -rf "$tmpdir"

  if [ -z "$answer" ]
  then
    printf 'qq: %s returned no answer\n' "$backend" >&2
    return 1
  fi
  printf '%s\n' "$answer"
}

if [[ $- == *i* ]] && [[ ";${PROMPT_COMMAND:-};" != *";_dotfiles_ai_track_history;"* ]]
then
  if [ -n "${PROMPT_COMMAND:-}" ]
  then
    PROMPT_COMMAND="${PROMPT_COMMAND%;};_dotfiles_ai_track_history"
  else
    PROMPT_COMMAND=_dotfiles_ai_track_history
  fi
fi

shopt -s expand_aliases
alias qq='_dotfiles_qq #'
