#!/bin/bash
# Ghostty shell integration (see ghostty/config.ghostty).
#
# Ghostty cannot auto-inject into macOS's /bin/bash, so the config sets
# `shell-integration = none` and bash_profile sources the script itself on
# every platform:
#
#   if _dotfiles_ghostty_bash_integration; then
#     builtin source "$_DOTFILES_GHOSTTY_SCRIPT"
#   fi
#
# It must be sourced at top level, not from inside a function, so the script's
# declarations stay global. Inside tmux the integration is skipped: tmux owns
# the prompt there, and GHOSTTY_RESOURCES_DIR may be stale in a tmux server
# environment.

# Succeeds, with _DOTFILES_GHOSTTY_SCRIPT set to the script path, when this
# shell runs directly in Ghostty and the integration is not loaded yet.
_dotfiles_ghostty_bash_integration() {
  _DOTFILES_GHOSTTY_SCRIPT=""
  [ -n "${GHOSTTY_RESOURCES_DIR:-}" ] || return 1
  [ -z "${TMUX:-}" ] || return 1
  declare -F __ghostty_precmd >/dev/null && return 1
  local script="$GHOSTTY_RESOURCES_DIR/shell-integration/bash/ghostty.bash"
  [ -r "$script" ] || return 1
  _DOTFILES_GHOSTTY_SCRIPT="$script"
}
