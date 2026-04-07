#!/bin/bash

# Removes PATH entries matching any of the given glob patterns.
# Usage: _path_strip "*homebrew*" "*linuxbrew*"
_path_strip() {
  local new_path="" dir match pattern
  while IFS= read -r -d: dir; do
    match=0
    for pattern in "$@"; do
      case "$dir" in $pattern) match=1; break ;; esac
    done
    [ "$match" -eq 0 ] && new_path="${new_path:+$new_path:}$dir"
  done <<< "${PATH}:"
  export PATH="$new_path"
}

# Deduplicates PATH entries, preserving first-occurrence order.
# Usage: _path_dedup
_path_dedup() {
  local new_path="" dir
  while IFS= read -r -d: dir; do
    case ":$new_path:" in
      *":$dir:"*) ;;
      *) new_path="${new_path:+$new_path:}$dir" ;;
    esac
  done <<< "${PATH}:"
  export PATH="$new_path"
}
