# dotfiles

### Quick Start

```sh
git clone https://github.com/tribou/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
./bootstrap.sh
```

On a new Mac (Apple Silicon only; Intel is not supported):

1. Install the Xcode Command Line Tools first: `xcode-select --install`. Without them `git`, `clang` and `make` are stubs, and `bootstrap.sh` stops and tells you so.
2. Run the commands above. mise asks for your password once (sudo) to create `/opt/homebrew`.
3. Switch your login shell from zsh to Homebrew's bash. These dotfiles only configure bash, so zsh gets no Homebrew or mise on `PATH`. `bootstrap.sh` prints these commands when it finishes:

   ```sh
   grep -qx /opt/homebrew/bin/bash /etc/shells || echo /opt/homebrew/bin/bash | sudo tee -a /etc/shells
   chsh -s /opt/homebrew/bin/bash
   ```

4. Open a new terminal window.

mise downloads many tools from GitHub releases. If the install stops on a GitHub rate limit, export a token and re-run: `GITHUB_TOKEN=<token> ./bootstrap.sh`.

### Install Skills Without Cloning

Install the [AI agent skills](docs/DEVELOPMENT.md#ai-skills) from this repo directly into a coding agent, without cloning:

```sh
npx skills add tribou/dotfiles
```

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md#installing-skills-into-agent-tools) for more usage.

### Regenerate a new GPG key

https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key

### Runbook

Three ways to set up a machine:

| Method | When to use |
|--------|------------|
| `curl -fsSL https://raw.githubusercontent.com/tribou/dotfiles/main/bootstrap.sh \| bash` | Greenfield machines — installs standalone mise, then runs `mise bootstrap` |
| `git clone https://github.com/tribou/dotfiles.git ~/dev/dotfiles && cd ~/dev/dotfiles && ./bootstrap.sh` | Same as above with a local copy first |
| `just install` | Already-bootstrapped machines — re-runs `mise bootstrap` to repair or sync changes |

Greenfield bootstrap installs standalone `~/.local/bin/mise`, links the repository's `mise-config.toml` as the global config, trusts the repository's `mise.toml`, and runs `mise bootstrap`: host packages, the TPM and vim-plug checkouts, dotfile symlinks (an existing file is moved to `<file>.backup` first), all configured tools, then the `bootstrap` task (SSH keys, plugins, verification).

**`just install`** runs the same `mise bootstrap`, which changes only what differs from the config without upgrading installed versions. Arguments pass through: `just install --dry-run` previews, `just install --only dotfiles` applies one part.

**`just upgrade`** runs the `upgrade` mise task: OS packages, `mise bootstrap packages upgrade` (formulae and casks), `mise upgrade` (tools), repository and plugin updates.

After any run, open a new login shell (or `exec $SHELL -l`) so mise/gpg-agent/brew/cargo PATH changes take effect.

### Config

**`~/.ssh/api_keys`** file

- `GIT_SIGNING_KEY` - export the gpg public signing key if it should be used. Find it with `gpg --list-keys`.
