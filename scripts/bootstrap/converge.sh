#!/usr/bin/env bash
# The `bootstrap` mise task (see mise.toml): setup that mise's declarative
# bootstrap sections cannot express. mise runs it after packages, repos,
# dotfiles, and tools, with [tools] on PATH, on every `mise bootstrap`, so every
# step is idempotent and prints "changed: ..." only when it changes something.
#
# Sourcing this file defines the steps without running them (for tests).
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DOTFILES_SSH_KEY_EMAIL="${DOTFILES_SSH_KEY_EMAIL:-tribou@users.noreply.github.com}"

_uname() { printf '%s\n' "${DOTFILES_UNAME:-$(uname -s)}"; }
_mise() { "${MISE_BIN:-$(command -v mise || echo "$HOME/.local/bin/mise")}" "$@"; }
_mode() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"; }

step_ssh_keys() {
  local type args
  for type in rsa ed25519; do
    [ -f "$HOME/.ssh/id_$type" ] && continue
    args=(-q -t "$type")
    [ "$type" = rsa ] && args+=(-b 4096)
    ssh-keygen "${args[@]}" -N "" -C "$DOTFILES_SSH_KEY_EMAIL" -f "$HOME/.ssh/id_$type"
    chmod 600 "$HOME/.ssh/id_$type"
    echo "changed: generated ~/.ssh/id_$type"
  done
}

# Store SSH passphrases in the macOS keychain (fixes #45).
step_macos_ssh() {
  [ "$(_uname)" = Darwin ] || return 0
  local config="$HOME/.ssh/config"
  if ! grep -qxF '# BEGIN dotfiles' "$config" 2>/dev/null; then
    {
      echo '# BEGIN dotfiles'
      echo 'Host *'
      echo '  AddKeysToAgent yes'
      echo '  UseKeychain yes'
      echo '  IdentityFile ~/.ssh/id_ed25519'
      echo '# END dotfiles'
    } >> "$config"
    chmod 600 "$config"
    echo "changed: added keychain block to ~/.ssh/config"
  fi
  local key
  for key in id_rsa id_ed25519; do
    ssh-add --apple-use-keychain "$HOME/.ssh/$key" >/dev/null 2>&1 || true
  done
}

# bsu/esu (synchronized output, DEC mode 2026) capabilities. Bubble Tea-based
# TUIs (opencode, lazygit, gh dash) detect these caps at startup; without them
# they fall back to 256-color approximation and stream each redraw unbracketed,
# which over SSH+tmux visibly renders "piece by piece". Do NOT strip these caps
# when editing the .terminfo sources or opencode will jank again.
step_terminfo() {
  local entry
  for entry in xterm-256color-italic.terminfo tmux-256color.terminfo; do
    tic -x "$DOTFILES_REPO/tmux/$entry"
  done
}

step_gnupg_perms() {
  [ -d "$HOME/.gnupg" ] || return 0
  local file
  while IFS= read -r -d '' file; do
    chmod 600 "$file"
    echo "changed: made ${file/#$HOME/\~} 0600"
  done < <(find "$HOME/.gnupg" -maxdepth 1 -type f ! -perm 600 -print0)
}

step_nvim_plugins() {
  if [ ! -d "$HOME/.local/share/nvim/plugged" ]; then
    nvim --headless "+PlugInstall --sync" +qall
    echo "changed: installed Neovim plugins"
  fi
  # :CocInstall needs explicit names; it won't read g:coc_global_extensions in
  # a headless run, so pass that list through.
  if [ ! -d "$HOME/.config/coc/extensions/node_modules" ]; then
    nvim --headless -c "execute 'CocInstall -sync ' . join(g:coc_global_extensions)" -c qall
    echo "changed: installed CoC extensions"
  fi
}

step_tmux_plugins() {
  [ -d "$HOME/.tmux/plugins/tmux-sensible" ] && return 0
  local plugins="$HOME/.tmux/plugins/"
  if [ -n "${TMUX:-}" ]; then
    tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$plugins"
    "$HOME/.tmux/plugins/tpm/bin/install_plugins"
  else
    # TPM needs a running server; use a throwaway detached session.
    tmux new-session -d -s _bootstrap_tpm
    tmux set-environment -t _bootstrap_tpm -g TMUX_PLUGIN_MANAGER_PATH "$plugins"
    "$HOME/.tmux/plugins/tpm/bin/install_plugins"
    tmux kill-session -t _bootstrap_tpm 2>/dev/null || true
  fi
  echo "changed: installed tmux plugins"
}

step_zoxide() {
  [ -f "$HOME/.z" ] && command -v zoxide >/dev/null 2>&1 || return 0
  if zoxide import --from z "$HOME/.z" --merge; then
    mv "$HOME/.z" "$HOME/.z.migrated"
    echo "changed: imported ~/.z into zoxide"
  fi
}

# python's postinstall only runs when mise installs that python, so converge
# pynvim explicitly for an already-present python.
step_pynvim() {
  local out
  out="$(python -m pip install pynvim 2>&1)"
  if [[ "$out" == *"Successfully installed"* ]]; then
    echo "changed: installed pynvim"
  fi
}

# Node 25+ no longer bundles corepack; npm:corepack provides it. Check the
# yarn/pnpm shims every run so a node major bump that drops them is repaired.
step_corepack() {
  _mise which yarn >/dev/null 2>&1 && _mise which pnpm >/dev/null 2>&1 && return 0
  corepack enable
  _mise reshim
  echo "changed: enabled corepack yarn and pnpm"
}

step_brew_cleanup() {
  "$DOTFILES_REPO/scripts/brew_cleanup.sh"
}

step_verify() {
  MISE_BIN="${MISE_BIN:-$HOME/.local/bin/mise}" "$DOTFILES_REPO/scripts/verify_mise_tools.sh" >/dev/null
}

step_marker() {
  [ -f "$HOME/.dotfiles-bootstrap-done" ] && return 0
  touch "$HOME/.dotfiles-bootstrap-done"
  echo "changed: marked bootstrap complete"
}

main() {
  step_ssh_keys
  step_macos_ssh
  step_terminfo
  step_gnupg_perms
  step_nvim_plugins
  step_tmux_plugins
  step_zoxide
  step_pynvim
  step_corepack
  step_brew_cleanup
  step_verify
  step_marker
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
