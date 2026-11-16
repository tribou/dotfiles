#!/usr/bin/env bash
# Run `mise bootstrap` for bootstrap.sh and `just install`, or, with -n or
# --dry-run, preview it on any machine, including one never bootstrapped.
#
# `mise bootstrap --dry-run` neither clones [bootstrap.repos] nor runs the
# pre-dotfiles hook, so its dotfiles check fails on sources those would create
# (vim-plug's plug.vim) and on files the hook would back up (an existing
# ~/.gitconfig), and the parts after dotfiles are never previewed. So mise
# previews every selected part except dotfiles, and dotfiles are previewed here
# with the hook's own dry run plus `mise dot diff`.
#
# Usage: run.sh MISE_BIN [mise bootstrap args]
set -euo pipefail

mise_bin="$1"
shift
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

dry_run=0
for arg in "$@"; do
  case "$arg" in -n | --dry-run) dry_run=1 ;; esac
done
if [ "$dry_run" = 0 ]; then
  exec "$mise_bin" -C "$repo" bootstrap --yes "$@"
fi

args=()
only_given=0    # any --only seen
only_dotfiles=0 # an --only listed dotfiles
only_others=0   # an --only listed some other part
dotfiles=1      # whether the dotfiles part is selected

# keep_parts FLAG SEP LIST: re-emit an --only flag without the dotfiles part.
keep_parts() {
  local flag="$1" sep="$2" list="$3" part kept=()
  IFS=, read -ra parts <<<"$list"
  for part in "${parts[@]}"; do
    if [ "$part" = dotfiles ]; then
      only_dotfiles=1
    else
      kept+=("$part")
    fi
  done
  [ "${#kept[@]}" -eq 0 ] && return 0
  only_others=1
  local joined
  joined="$(IFS=,; echo "${kept[*]}")"
  if [ "$sep" = = ]; then
    args+=("$flag=$joined")
  else
    args+=("$flag" "$joined")
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --only)
      only_given=1
      keep_parts --only ' ' "${2:-}"
      shift
      ;;
    --only=*)
      only_given=1
      keep_parts --only = "${1#--only=}"
      ;;
    --skip)
      [[ ",${2:-}," == *,dotfiles,* ]] && dotfiles=0
      args+=("$1" "${2:-}")
      shift
      ;;
    --skip=*)
      [[ ",${1#--skip=}," == *,dotfiles,* ]] && dotfiles=0
      args+=("$1")
      ;;
    *) args+=("$1") ;;
  esac
  shift
done

if [ "$only_given" = 1 ]; then
  dotfiles="$only_dotfiles"
  # With only dotfiles selected, there is nothing left for mise to preview.
  if [ "$only_others" = 1 ]; then
    "$mise_bin" -C "$repo" bootstrap --yes "${args[@]}"
  fi
elif [ "$dotfiles" = 1 ]; then
  "$mise_bin" -C "$repo" bootstrap --yes "${args[@]}" --skip dotfiles
else
  "$mise_bin" -C "$repo" bootstrap --yes "${args[@]}"
fi

[ "$dotfiles" = 1 ] || exit 0

echo "mise bootstrap: dotfiles (preview)"
"$repo/scripts/bootstrap/pre_dotfiles.sh" --dry-run "$repo/mise.toml"
echo "Dotfiles whose source comes from a [bootstrap.repos] clone show as missing until the repo is cloned."
"$mise_bin" -C "$repo" dot diff
