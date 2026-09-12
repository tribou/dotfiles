# dotfiles

### Quick Start

```sh
git clone https://github.com/tribou/dotfiles.git
cd dotfiles
./bootstrap.sh
```

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
| `curl -fsSL https://raw.githubusercontent.com/tribou/dotfiles/main/bootstrap.sh \| bash` | Greenfield machines — bootstraps standalone mise, packages, tools, and then runs the playbook |
| `git clone https://github.com/tribou/dotfiles.git && cd dotfiles && ./bootstrap.sh` | Same as above with a local copy first |
| `just install` | Already-bootstrapped machines — enters Ansible through mise to repair or sync changes |

Greenfield bootstrap installs standalone `~/.local/bin/mise`, exposes the repository's `mise-config.toml` as the global config, runs `mise bootstrap packages apply --yes`, installs all configured tools, and performs smoke verification. It then invokes `mise exec -- ansible-playbook` so Ansible repeats and completes convergence from the environment mise just provisioned.

**`just install`** runs `mise exec -- ansible-playbook` with `dotfiles_state=present` (default), ensuring symlinks, packages, tools, and config are in place without upgrading installed versions.

**`just upgrade`** uses the same mise-Ansible entry point with `dotfiles_state=latest` and the `upgrade` tag. Formula upgrades are explicit through `mise bootstrap packages upgrade`, versioned tool upgrades use `mise upgrade`, and the real Homebrew CLI handles retained macOS casks only.

After any run, open a new login shell (or `exec $SHELL -l`) so mise/gpg-agent/brew/cargo PATH changes take effect.

### Config

**`~/.ssh/api_keys`** file

- `GIT_SIGNING_KEY` - export the gpg public signing key if it should be used. Find it with `gpg --list-keys`.
