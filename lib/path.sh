#!/bin/bash

# Note: PATH entries containing newlines are not supported. The read -d: + herestring
# pattern splits on newlines — an accepted tradeoff since POSIX discourages newlines
# in PATH entries and they are essentially invalid in practice.

# Note: Empty segments (::) are preserved as-is. An empty segment in PATH
# means the current directory — preservation is intentional.

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
