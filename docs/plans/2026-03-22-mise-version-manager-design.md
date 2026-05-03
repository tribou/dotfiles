# mise Version Manager Migration Design

**Date:** 2026-03-22
**Scope:** Replace rbenv + nvm with mise in dotfiles

## Background

The official Ruby on Rails installation guide now recommends [mise](https://mise.jdx.dev/) as the version manager of choice. mise is a Rust-based multi-language version manager that handles Ruby, Node.js, and other runtimes in a single tool — replacing both rbenv (Ruby) and nvm (Node).

## Goals

- Replace rbenv and nvm with mise
- Preserve existing behavior: `.ruby-version`, `.nvmrc`, `.node-version` auto-activation on directory change
- Compatible with both macOS and Ubuntu

## What Changes

### `bash_profile`

**Remove:**
- rbenv block (lines 151-153): PATH addition + `rbenv init`
- nvm block (lines 158-165): `NVM_DIR` export, sourcing nvm.sh, bash_completion, `HAS_NVM` env var, `nvm use default`
- `use_node_version` function: mise handles version switching natively
- `.nvmrc`/cd auto-switch logic (PROMPT_COMMAND): replaced by mise's shell hook
- `$(nvm current)` from PS1

**Add:**
```bash
export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate bash)"
```

**Remove `HAS_NVM` guards** throughout — mise is always active after shell init, no conditional needed.

### `bootstrap.sh`

**Remove:**
- nvm install block (~lines 181-203)
- rbenv install block (~lines 248-262)

**Add** (not OS-gated — works on both macOS and Ubuntu):
```bash
if [ ! -n "$(command -v mise)" ]; then
  echo "Installing mise:"
  curl https://mise.run | sh
  export PATH="$HOME/.local/bin:$PATH"
  eval "$(mise activate bash)"
fi

if [ -n "$(command -v mise)" ]; then
  mise use -g node@lts
  mise use -g ruby@3
fi
```

**Add to Ubuntu apt-get install block** (Ruby build deps):
```bash
libssl-dev libreadline-dev zlib1g-dev libyaml-dev
```

## Compatibility Notes

### mise installer
`curl https://mise.run | sh` works on both macOS and Ubuntu. Installs to `~/.local/bin/mise` on both platforms.

### Existing project files
No changes needed — mise reads `.ruby-version`, `.nvmrc`, and `.node-version` files as-is. Zero migration cost for existing projects.

### Ubuntu build deps
When mise compiles Ruby from source on Ubuntu, it requires `libssl-dev`, `libreadline-dev`, `zlib1g-dev`, `libyaml-dev`. These go in the existing `apt-get install` block. Not needed on macOS (Homebrew handles it). Note: mise is moving toward precompiled Ruby binaries by default, which will eventually make these unnecessary.

### Auto-switching behavior
`eval "$(mise activate bash)"` installs a shell hook that replaces the custom `use_node_version` + PROMPT_COMMAND logic. Directory changes automatically activate the correct Ruby/Node version from `.ruby-version`/`.nvmrc`/`.node-version`/`.mise.toml`.

## Testing

- Update any `goss.yaml` assertions for rbenv/nvm → assert `mise` is present and functional
- Verify `mise current node` and `mise current ruby` return expected versions after bootstrap
- Test directory-change auto-switching works in both macOS and Ubuntu Docker environments

## References

- [Official Rails Install Guide](https://guides.rubyonrails.org/install_ruby_on_rails.html) — recommends mise
- [mise Ruby docs](https://mise.jdx.dev/lang/ruby.html)
- [mise activate bash](https://mise.jdx.dev/getting-started.html)
