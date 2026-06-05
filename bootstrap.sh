#!/bin/bash
set -euo pipefail

# Install all the dotfiles

# Rudimentary flags parsing
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]
then
  usage='Usage: ./bootstrap.sh'
  echo "$usage"
  exit 1
fi

# Get bootstrap script directory
THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )
export DOTFILES="$THIS_DIR"

function backupFile ()
{
  local file=$1

	if [ -e ~/"$file" -a ! -L ~/"$file" ]; then
    echo "Backing up ${file}"
		mv ~/"$file" ~/"${file}".backup
  fi
}

function linkFileToHome ()
{
  echo "Creating a symlink for ${2}"
  rm -f ~/"${2}"
  ln -sf "${THIS_DIR}/${1}" ~/"${2}"
}

function linkSkillsDir ()
{
  local source_dir="$1"
  local target_dir="$2"

  # Migrate old whole-directory symlink to directory
  if [ -L "$target_dir" ]; then
    rm -f "$target_dir"
  fi

  mkdir -p "$target_dir"

  # Create/update symlinks for each skill in source
  for skill_path in "$source_dir"/*; do
    [ -d "$skill_path" ] || continue
    local skill_name
    skill_name=$(basename "$skill_path")
    local target_display
    if [[ "$target_dir" == "$HOME"/* ]]; then
      target_display="~${target_dir#"$HOME"}"
    else
      target_display="$target_dir"
    fi
    echo "Creating a symlink for ${target_display}/${skill_name}"
    rm -rf "$target_dir/$skill_name"
    ln -sf "$skill_path" "$target_dir/$skill_name"
  done

  # Remove stale symlinks (skills removed from dotfiles)
  for link_path in "$target_dir"/*; do
    [ -L "$link_path" ] || continue
    local link_target
    link_target=$(readlink "$link_path")
    if [ ! -d "$link_target" ]; then
      rm -f "$link_path"
    fi
  done
}

# Backup existing files and replace with symlinks

# Setup dev and gopath
mkdir -p "$HOME/dev/bin" || true
mkdir -p ~/dev/go/pkg
mkdir -p ~/dev/go/src/github.com/tribou || true
mkdir -p ~/dev/go/src/bitbucket.org || true
mkdir -p ~/dev/go/src/github.com/rocksauce || true
export GOPATH=~/dev/go

# Zoxide and its database migration are handled post-installation

# .bash_profile
backupFile ".bash_profile"
linkFileToHome bash_profile .bash_profile

# .vimrc
backupFile ".vimrc"
linkFileToHome init.vim .vimrc

# .gitconfig
backupFile ".gitconfig"
linkFileToHome gitconfig .gitconfig

# .zshrc
backupFile ".zshrc"
linkFileToHome "zshrc" ".zshrc"

# .tmux.conf
backupFile ".tmux.conf"
linkFileToHome "tmux/tmux-conf" ".tmux.conf"

# mise default packages
linkFileToHome "default-node-packages" ".default-node-packages"
linkFileToHome "default-gems" ".default-gems"
linkFileToHome "default-python-packages" ".default-python-packages"

tic -x tmux/xterm-256color-italic.terminfo || true
tic -x tmux/tmux-256color.terminfo || true

# .gnupg/gpg-agent.conf
mkdir -p ~/.gnupg
backupFile ".gnupg/gpg-agent.conf"
linkFileToHome "gpg-agent-conf" ".gnupg/gpg-agent.conf"
  chown -R "$(whoami)" ~/.gnupg/
  chmod 600 ~/.gnupg/* || true
  chmod 700 ~/.gnupg
# Restart gpg-agent
if [ "$(which gpgconf)" ] && [ "$(which gpg-agent)" ]
then
  echo "Restarting gpg-agent"
  gpgconf --kill gpg-agent
  eval "$(gpg-agent --daemon 2>/dev/null)" || true
fi

# .config/nvim/init.vim
# Exceptional Case: need to link to the same .vimrc for nvim
mkdir -p ~/.config/nvim
backupFile ".config/nvim/init.vim"
linkFileToHome "init.vim" ".config/nvim/init.vim"

# .config/alacritty/alacritty.toml
mkdir -p ~/.config/alacritty
backupFile ".config/alacritty/alacritty.toml"
linkFileToHome "alacritty.toml" ".config/alacritty/alacritty.toml"

# .config/mise/config.toml
mkdir -p ~/.config/mise
backupFile ".config/mise/config.toml"
linkFileToHome "mise-config.toml" ".config/mise/config.toml"

# .config/nvim/coc-settings.json
backupFile ".config/nvim/coc-settings.json"
linkFileToHome "coc-settings.json" ".config/nvim/coc-settings.json"

# Symlink helper scripts for SSH markdown preview
mkdir -p ~/.local/bin
linkFileToHome "scripts/dotfiles_remote_browser_open.sh" ".local/bin/dotfiles_remote_browser_open.sh"
linkFileToHome "scripts/dotfiles_local_browser_helper.sh" ".local/bin/dotfiles_local_browser_helper.sh"

# .claude/skills
linkSkillsDir "$THIS_DIR/skills" "$HOME/.claude/skills"

# .config/opencode/skills
linkSkillsDir "$THIS_DIR/skills" "$HOME/.config/opencode/skills"

# .gemini/config/skills
linkSkillsDir "$THIS_DIR/skills" "$HOME/.gemini/config/skills"

# .agents/skills
linkSkillsDir "$HOME/.agents/skills" "$HOME/.config/opencode/skills"

# setup API keys file
mkdir -p "$HOME/.ssh"
if [ ! -f "$HOME/.ssh/api_keys" ]
then
  touch "$HOME/.ssh/api_keys"

  echo "WARNING: ~/.ssh/api_keys did not exist. Created empty file."
fi

# Setup ssh key
if [ ! -f "$HOME/.ssh/id_rsa" ]
then
  ssh-keygen -t rsa -b 4096 -C "tribou@users.noreply.github.com" -N "" -f "$HOME/.ssh/id_rsa"
fi
if [ ! -f "$HOME/.ssh/id_ed25519" ]
then
  ssh-keygen -t ed25519 -C "tribou@users.noreply.github.com" -N ""
fi
## If macOS
if [[ "$OSTYPE" == "darwin"* ]] && ! grep -q "AddKeysToAgent" ~/.ssh/config
then

  if [ ! -f "$HOME/.ssh/config" ]
  then
    touch "$HOME/.ssh/config"
  else
    echo "" >> "$HOME/.ssh/config"
  fi

  echo "Host *" >> "$HOME/.ssh/config"
  echo "  AddKeysToAgent yes" >> "$HOME/.ssh/config"
  echo "  UseKeychain yes" >> "$HOME/.ssh/config"
  echo "  IdentityFile ~/.ssh/id_ed25519" >> "$HOME/.ssh/config"
fi

# Setup ssh-agent
## If agent socket isn't available, source it
[ -s "${SSH_AUTH_SOCK:-}" ] || eval "$(ssh-agent -s)"
## Add keys to keychain
if [[ "$OSTYPE" == "darwin"* ]]; then
  # --apple-use-keychain replaces -K (removed in macOS Ventura 13+); fall back to plain ssh-add
  [ -f "$HOME/.ssh/id_rsa" ] && { ssh-add --apple-use-keychain "$HOME/.ssh/id_rsa" 2>/dev/null || ssh-add "$HOME/.ssh/id_rsa" 2>/dev/null || true; }
  [ -f "$HOME/.ssh/id_ed25519" ] && { ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519" 2>/dev/null || ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true; }
else
  [ -f "$HOME/.ssh/id_rsa" ] && ssh-add "$HOME/.ssh/id_rsa" || true
  [ -f "$HOME/.ssh/id_ed25519" ] && ssh-add "$HOME/.ssh/id_ed25519" || true
fi

# Install tmux plugins
[ ! -d "$HOME/.tmux/plugins/tpm" ] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
if command -v tmux &> /dev/null; then
  if [ -n "${TMUX:-}" ]; then
    tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins/"
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
  else
    # Outside tmux: anchor the work in an ephemeral detached session so the
    # server stays alive across set-environment and install_plugins.
    tmux new-session -d -s _bootstrap_tpm
    tmux set-environment -t _bootstrap_tpm -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins/"
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
    tmux kill-session -t _bootstrap_tpm 2>/dev/null || true
  fi
fi

# Source all lib scripts
. "$DOTFILES/lib/index.sh"

if   command -v curl &>/dev/null
then

  if   ! command -v cargo &>/dev/null
    then
      _BOOTSTRAP_INSTALL="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
      echo "Installing rust:"
      echo "$_BOOTSTRAP_INSTALL"
      echo
      eval "$_BOOTSTRAP_INSTALL"
      export PATH="$HOME/.cargo/bin:$PATH"
      [ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
      echo
    fi

    export PATH="$HOME/.local/bin:$PATH"
    MISE_BIN="$(type -P mise 2>/dev/null || true)"

    if [ -z "$MISE_BIN" ] && [ -x "$HOME/.local/bin/mise" ]
    then
      MISE_BIN="$HOME/.local/bin/mise"
    fi

    if [ -z "$MISE_BIN" ]
    then
      echo "Installing mise:"
      curl https://mise.run | sh
      echo
      MISE_BIN="$HOME/.local/bin/mise"
    else
      echo "Updating mise:"
      "$MISE_BIN" self-update --yes || true
      echo
    fi

    if [ -x "$MISE_BIN" ]
    then
      eval "$("$MISE_BIN" activate bash)"
      # Install all tools from mise-config.toml (symlinked to ~/.config/mise/config.toml)
      mise install node go bun
      hash -r
      corepack enable
      # Try precompiled ruby first (fast), fall back to source compilation
      if ! MISE_RUBY_COMPILE=0 mise install ruby 2>/dev/null; then
        echo "No precompiled ruby available for this platform, compiling from source..."
        mise install ruby
      fi
      echo
    fi


  if  command -v npm &>/dev/null && ! command -v eslint_d &>/dev/null
  then
    _BOOTSTRAP_INSTALL="npm install --location=global neovim eslint_d editorconfig"
    echo "Installing global node modules:"
    echo "$_BOOTSTRAP_INSTALL"
    echo
    eval "$_BOOTSTRAP_INSTALL"
  else
    echo "npm not available or eslint_d already installed. Skipping..."
  fi

  # Sourcing z.sh is obsolete

  # Install brew prerequisites on Linux (needed before brew can install)
  if [[ "$OSTYPE" != "darwin"* ]]; then
    if command -v apt-get &>/dev/null; then
      sudo apt-get update
      sudo apt-get install -y curl git build-essential xdg-utils bash-completion
    elif command -v pacman &>/dev/null; then
      sudo pacman -Syu --noconfirm curl git base-devel bash-completion
    fi
  fi

  # Install brew if not present (macOS and Linux)
  if ! command -v brew &>/dev/null; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    else
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
  fi

  # Brew is required — exit if still not available
  if ! command -v brew &>/dev/null; then
    echo "ERROR: Homebrew installation failed. Install brew manually and re-run."
  exit 0
  fi

  brew install \
      bash \
      git \
      neovim \
      python \
      zlib \
      hashicorp/tap/terraform-ls \
      nmap \
      ansible \
      htop \
      gpg \
      editorconfig \
      watchman \
      tree \
      awscli \
      ssh-copy-id \
      git-extras \
      jq \
      dos2unix \
      tidy-html5 \
      fd \
      ripgrep \
      bat \
      navi \
      shellcheck \
      tlrc \
      lazydocker \
      lazygit \
      just \
      lynx \
      tree-sitter-cli \
      fzf \
      tmux \
      git-delta \
      gh \
      glow \
      beads \
      zoxide

  # Linux-only packages
  if [[ "$OSTYPE" != "darwin"* ]]; then
    brew install gcc
  fi

  # macOS-only packages
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install \
      bash-completion \
      rename \
      alacritty \
      ngrok/ngrok/ngrok \
      reattach-to-user-namespace \
      tfenv \
      tor \
      vimpager \
      renameutils \
      tmux-mem-cpu-load

    brew install --cask \
      cmake \
      1password \
      1password-cli \
      appcleaner \
      balenaetcher \
      bruno \
      firefox \
      imageoptim \
      orbstack \
      steam \
      font-fira-code-nerd-font \
      font-hack-nerd-font \
      font-fontawesome || echo "Did not install all casks"
  fi

  # vim-plug + Neovim plugins — must run after brew installs neovim
  if command -v nvim &>/dev/null && [ ! -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]
  then
    echo "Installing vim-plug for Neovim"
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    echo "Installing Neovim plugins"
    nvim --headless +"PlugInstall --sync" +qall
  fi

  # pynvim (Neovim Python support) — installed via pip since mise no longer manages Python
  if command -v python3 &>/dev/null && ! python3 -c "import pynvim" &>/dev/null
  then
    echo "Installing pynvim"
    pip3 install --user --break-system-packages pynvim
  fi

  # Automatically migrate legacy rupa/z history to zoxide if applicable
  if command -v zoxide &>/dev/null && [ -f "$HOME/.z" ]; then
    echo "Migrating legacy rupa/z history to zoxide..."
    if zoxide import --from z "$HOME/.z" --merge; then
      mv "$HOME/.z" "$HOME/.z.migrated"
      echo "Legacy history migrated successfully (~/.z -> ~/.z.migrated)."
    else
      echo "warning: zoxide history import failed"
    fi
  fi

  # neovim gem (Neovim Ruby support) — installed via mise-managed ruby
  if command -v ruby &>/dev/null && ! gem list neovim -i &>/dev/null
  then
    echo "Installing neovim gem"
    gem install neovim
  fi

  # Golang tools — install after mise provisions Go
  GO_BIN_DIR="${GOBIN:-$GOPATH/bin}"
  if [ -x "$(command -v go)" ] && [ ! -x "$GO_BIN_DIR/gopls" ]
  then
    echo "Installing gopls"
    go install golang.org/x/tools/gopls@latest
  fi

  # beads issue database — keep the Dolt remote in sync with config.yaml and
  # hydrate fresh clones. The embedded Dolt DB and its remote list are per-machine
  # local state (gitignored / not carried by git), so each machine must register
  # the remote and hydrate on its own. The remote uses a git+https URL so it
  # authenticates via git's credential helper (e.g. 'gh auth setup-git'), not SSH.
  if command -v bd &>/dev/null
  then
    _beads_remote="$(awk -F'"' '/^sync\.remote:/ {print $2; exit}' "$THIS_DIR/.beads/config.yaml")"
    if [ -n "$_beads_remote" ]
    then
      if [ ! -d "$THIS_DIR/.beads/embeddeddolt" ]
      then
        # Fresh clone: no local DB yet. Clone it from the remote.
        echo "Hydrating beads issue database from Dolt remote"
        bd -C "$THIS_DIR" bootstrap --yes || echo "warning: beads hydration failed; run 'bd bootstrap' manually"
      elif ! bd -C "$THIS_DIR" dolt remote list 2>/dev/null | grep -qF "$_beads_remote"
      then
        # Existing DB, but its 'origin' is missing or points elsewhere: re-register
        # to match config.yaml so 'bd dolt pull/push' works. Does not touch issues.
        echo "Registering beads Dolt remote (origin -> $_beads_remote)"
        bd -C "$THIS_DIR" dolt remote remove origin &>/dev/null || true
        bd -C "$THIS_DIR" dolt remote add origin "$_beads_remote" || echo "warning: could not register beads Dolt remote"
      fi
    fi
  fi

else
  echo "ERROR: curl not available! Skipping all installs"
  echo
fi
