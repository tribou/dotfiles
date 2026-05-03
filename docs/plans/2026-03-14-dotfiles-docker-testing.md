# Dotfiles Docker Testing Design

## Goal

Make it easy to test dotfiles changes that affect the remote SSH environment — specifically tmux plugin installation, vim-plug and Neovim plugin installation, and nested tmux session support — using an Ubuntu Docker container.

Existing bash unit tests (test_grep_ticket_number.sh, test_commit_message.sh) are out of scope (phase 2).

## Architecture

```
dotfiles/
├── justfile                        # replaces Makefile
├── Dockerfile                      # Ubuntu + apt deps as cached layers
├── docker-compose.yml              # named services: ci vs dev
├── goss.yaml                       # infra assertions
└── scripts/
    └── bootstrap-test.sh           # targeted subset: tmux plugins + vim-plug only
```

## Two Workflows

1. `just test` — runs goss assertions in container, exits 0/1 (CI-friendly)
2. `just dev` — interactive container with tmux-ready env for manual inspection

## Dockerfile

Layered for cache efficiency — system deps cached, dotfiles copied late:

```dockerfile
FROM ubuntu:latest
RUN apt-get update && apt-get install -y \
    tmux neovim git curl python3 python3-pip
WORKDIR /dotfiles
COPY . .
```

## docker-compose.yml

```yaml
services:
  base:
    build: .
    volumes:
      - .:/dotfiles

  ci:
    extends: base
    command: >
      sh -c "scripts/bootstrap-test.sh && goss validate --format tap"

  dev:
    extends: base
    stdin_open: true
    tty: true
    command: >
      sh -c "scripts/bootstrap-test.sh && bash"
```

- **ci**: no TTY, runs bootstrap then goss, exits with pass/fail code
- **dev**: allocates TTY, drops into bash after bootstrap for manual tmux/plugin inspection

## scripts/bootstrap-test.sh

Targeted subset — only the hard-to-test environment pieces:

1. Install TPM → `~/.tmux/plugins/tpm`
2. Run `tpm/bin/install_plugins` non-interactively
3. Install vim-plug → `~/.local/share/nvim/site/autoload/plug.vim`
4. Run `nvim --headless +PlugInstall +qall`
5. Source `lib/index.sh`
6. Write marker file `~/.dotfiles-bootstrap-done`

## justfile

```just
# Run goss assertions (CI mode)
test:
    docker compose run --rm ci

# Interactive dev environment
dev:
    docker compose run --rm dev

# Rebuild image (when Dockerfile changes)
build:
    docker compose build --no-cache

# Existing bash unit tests (phase 2)
test-unit:
    ./tests/test_grep_ticket_number.sh
    ./tests/test_commit_message.sh
```

## goss.yaml

Assertions cover:

- tmux, nvim, git binaries present and functional
- TPM directory and plugin directories exist
- vim-plug installed
- Neovim plugged directory exists
- Bootstrap marker file present

Plugin dirs asserted under `~/.tmux/plugins/` should match the TPM plugin list in `tmux/tmux-conf`.

## Out of Scope

- Full bootstrap.sh (language runtimes, cask apps, fonts, etc.)
- Nested tmux session automation (manual inspection via `just dev`)
- Phase 2: integrating existing bash unit tests into justfile
