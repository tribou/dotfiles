# dotfiles

### Quick Start

Setting up a new machine takes three steps. Step 1 lists everything that must be installed beforehand; you do not need Homebrew, mise, `just`, SSH keys or a GitHub login.

#### 1. Before you start

**macOS** (Apple Silicon only; Intel is not supported):

- Install the Xcode Command Line Tools and wait for the installer to finish:

  ```sh
  xcode-select --install
  ```

  Until then `git`, `clang` and `make` are stubs. `bootstrap.sh` checks for the tools and stops with this instruction if they are missing.
- Use an admin account. mise asks for your password once (sudo) to create `/opt/homebrew`.

**Linux** (Debian/Ubuntu or Arch): use an account with sudo, and install `curl` and `git` if the machine lacks them:

```sh
sudo apt-get update && sudo apt-get install -y curl git   # Debian/Ubuntu
sudo pacman -S --needed curl git                          # Arch
```

`bootstrap.sh` installs the compiler toolchain itself.

#### 2. Get the script and run it

Either command works once step 1 is done.

- **Without cloning first.** The script clones the repo to `~/dev/dotfiles` and continues from there:

  ```sh
  curl -fsSL https://raw.githubusercontent.com/tribou/dotfiles/main/bootstrap.sh | bash
  ```

- **With a local copy first:**

  ```sh
  git clone https://github.com/tribou/dotfiles.git ~/dev/dotfiles
  cd ~/dev/dotfiles
  ./bootstrap.sh
  ```

To preview without applying anything, add `--dry-run`: `./bootstrap.sh --dry-run`, or `curl … | bash -s -- --dry-run`. A dry run still installs mise and links its global config.

mise downloads many tools from GitHub releases. If the install stops on a GitHub rate limit, set a token and run it again: `GITHUB_TOKEN=<token> ./bootstrap.sh`.

#### 3. After it finishes

- **macOS:** switch your login shell from zsh to Homebrew's bash. These dotfiles only configure bash, so zsh gets no Homebrew or mise on `PATH`. `bootstrap.sh` prints these commands when it finishes; it does not run them:

  ```sh
  grep -qx /opt/homebrew/bin/bash /etc/shells || echo /opt/homebrew/bin/bash | sudo tee -a /etc/shells
  chsh -s /opt/homebrew/bin/bash
  ```

- Then open a new terminal window (or `exec $SHELL -l` on Linux) so the new `PATH` takes effect.

From then on, use `just install` to repair or sync and `just upgrade` to update; see the [Runbook](#runbook).

### Install Skills Without Cloning

Install the [AI agent skills](docs/DEVELOPMENT.md#ai-skills) from this repo directly into a coding agent, without cloning:

```sh
npx skills add tribou/dotfiles
```

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md#installing-skills-into-agent-tools) for more usage.

### Regenerate a new GPG key

https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key

### Runbook

| Command | When to use |
|---------|-------------|
| `bootstrap.sh`, piped from curl or run from a clone | New machines — see [Quick Start](#quick-start). Installs standalone mise, then runs `mise bootstrap` |
| `just install` | Already-bootstrapped machines — re-runs `mise bootstrap` to repair or sync changes |
| `just upgrade` | Already-bootstrapped machines — upgrades packages, tools, repositories and plugins |

Greenfield bootstrap installs standalone `~/.local/bin/mise`, links the repository's `mise-config.toml` as the global config, trusts the repository's `mise.toml`, and runs `mise bootstrap`: host packages, the TPM and vim-plug checkouts, dotfile symlinks (an existing file is moved to `<file>.backup` first), all configured tools, then the `bootstrap` task (SSH keys, plugins, verification).

**`just install`** runs the same `mise bootstrap`, which changes only what differs from the config without upgrading installed versions. Arguments pass through: `just install --dry-run` previews, `just install --only dotfiles` applies one part.

**`just upgrade`** runs the `upgrade` mise task: OS packages, `mise bootstrap packages upgrade` (formulae and casks), `mise upgrade` (tools), repository and plugin updates.

After any run, open a new login shell (or `exec $SHELL -l`) so mise/gpg-agent/brew/cargo PATH changes take effect.

### Config

**`~/.ssh/api_keys`** file

