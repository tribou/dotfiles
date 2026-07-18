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
| `curl -fsSL https://raw.githubusercontent.com/tribou/dotfiles/main/bootstrap.sh \| bash` | Greenfield machines — bootstraps Homebrew, Ansible, then runs the playbook |
| `git clone https://github.com/tribou/dotfiles.git && cd dotfiles && ./bootstrap.sh` | Same as above with a local copy first |
| `just install` | Already-bootstrapped machines — re-runs the Ansible role to repair or sync changes |

**`just install`** runs the Ansible role with `dotfiles_state=present` (default), ensuring symlinks, tools, and config are in place.

**`just upgrade`** runs with `dotfiles_state=latest` and the `upgrade` tag, targeting upgrade-only tasks (brew upgrade, mise upgrade, npm update).

After any run, open a new login shell (or `exec $SHELL -l`) so mise/gpg-agent/brew/cargo PATH changes take effect.

### Config

**`~/.ssh/api_keys`** file

- `GIT_SIGNING_KEY` - export the gpg public signing key if it should be used. Find it with `gpg --list-keys`.
