# Dotfiles Docker Testing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Docker-based CI and interactive testing for dotfiles bootstrap (tmux plugins, vim-plug, Neovim plugins) with goss assertions, replacing the Makefile with a justfile.

**Architecture:** An Ubuntu Dockerfile caches slow apt installs as layers; `scripts/bootstrap-test.sh` runs the targeted dotfiles subset (TPM + vim-plug only); goss validates the resulting environment. Two compose services — `ci` (exits 0/1) and `dev` (interactive bash).

**Tech Stack:** Docker, docker compose, goss, just, bash

---

### Task 1: Migrate Makefile to justfile

**Files:**
- Create: `justfile`
- Delete: `Makefile`

**Step 1: Create `justfile`**

```just
# Run goss assertions in container (CI mode — exits 0 or 1)
test:
    docker compose run --rm ci

# Spin up interactive dev environment (manual tmux/plugin inspection)
dev:
    docker compose run --rm dev

# Rebuild Docker image from scratch (run when Dockerfile changes)
build:
    docker compose build --no-cache

# Run existing bash unit tests (phase 2)
test-unit:
    ./tests/test_grep_ticket_number.sh
    ./tests/test_commit_message.sh
```

**Step 2: Verify `just --version` is available**

```bash
just --version
```

Expected: prints a version string (just is in brew installs)

**Step 3: Verify `just` reads the file**

```bash
just --list
```

Expected: lists `test`, `dev`, `build`, `test-unit`

**Step 4: Remove Makefile**

```bash
rm Makefile
```

**Step 5: Commit**

```bash
git add justfile
git rm Makefile
git commit -m "Migrate Makefile to justfile"
```

---

### Task 2: Create `scripts/bootstrap-test.sh`

**Files:**
- Create: `scripts/bootstrap-test.sh`

This script runs inside the container. It only installs the hard-to-test pieces: TPM + plugins, vim-plug + Neovim plugins. It does NOT run language runtimes, cask apps, or anything outside the SSH dev environment scope.

**Step 1: Create the script**

```bash
#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Linking dotfiles configs..."
mkdir -p ~/.config/nvim
ln -sf "$DOTFILES/tmux/tmux-conf" ~/.tmux.conf
ln -sf "$DOTFILES/init.vim" ~/.config/nvim/init.vim

echo "==> Installing TPM..."
if [ ! -d ~/.tmux/plugins/tpm ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "==> Installing tmux plugins..."
~/.tmux/plugins/tpm/bin/install_plugins

echo "==> Installing vim-plug..."
if [ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo "==> Installing Neovim plugins..."
nvim --headless +PlugInstall +qall 2>&1

echo "==> Bootstrap complete."
touch ~/.dotfiles-bootstrap-done
```

**Step 2: Make it executable**

```bash
chmod +x scripts/bootstrap-test.sh
```

**Step 3: Syntax-check it**

```bash
bashcheck scripts/bootstrap-test.sh
```

Expected: no errors

**Step 4: Commit**

```bash
git add scripts/bootstrap-test.sh
git commit -m "Add scripts/bootstrap-test.sh for targeted Docker bootstrap"
```

---

### Task 3: Create `Dockerfile`

**Files:**
- Create: `Dockerfile`

The `apt-get` layer is intentionally first so it caches even when dotfiles change. Goss is installed as a binary directly from GitHub releases.

**Step 1: Create `Dockerfile`**

```dockerfile
FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# System deps — cached layer, only re-runs when this block changes
RUN apt-get update && apt-get install -y \
    tmux \
    neovim \
    git \
    curl \
    python3 \
    python3-pip \
  && rm -rf /var/lib/apt/lists/*

# Install goss for infrastructure assertions
RUN curl -fsSL https://github.com/goss-org/goss/releases/latest/download/goss-linux-amd64 \
    -o /usr/local/bin/goss \
  && chmod +x /usr/local/bin/goss

WORKDIR /dotfiles

# Copy dotfiles — changes here don't bust the apt cache
COPY . .
```

**Step 2: Verify it builds**

```bash
docker build -t dotfiles-test .
```

Expected: build succeeds, all layers cached on re-run

**Step 3: Verify goss is present**

```bash
docker run --rm dotfiles-test goss --version
```

Expected: prints goss version string

**Step 4: Commit**

```bash
git add Dockerfile
git commit -m "Add Dockerfile for dotfiles testing environment"
```

---

### Task 4: Create `docker-compose.yml`

**Files:**
- Create: `docker-compose.yml`

**Step 1: Create `docker-compose.yml`**

```yaml
services:
  base:
    build: .
    volumes:
      - .:/dotfiles

  ci:
    extends:
      service: base
    command: >
      bash -c "scripts/bootstrap-test.sh && goss validate --format tap"

  dev:
    extends:
      service: base
    stdin_open: true
    tty: true
    command: >
      bash -c "scripts/bootstrap-test.sh && bash"
```

**Step 2: Verify compose parses correctly**

```bash
docker compose config
```

Expected: prints merged config with no errors

**Step 3: Commit**

```bash
git add docker-compose.yml
git commit -m "Add docker-compose.yml with ci and dev services"
```

---

### Task 5: Create `goss.yaml`

**Files:**
- Create: `goss.yaml`

Assertions are derived from the TPM plugin list in `tmux/tmux-conf` (lines 333-340) and the vim-plug setup in `init.vim`.

**Step 1: Create `goss.yaml`**

```yaml
# Core binaries functional
command:
  "tmux -V":
    exit-status: 0
    stdout:
      - "tmux"
  "nvim --version":
    exit-status: 0
    stdout:
      - "NVIM"
  "git --version":
    exit-status: 0

# TPM and all plugins installed
file:
  /root/.tmux/plugins/tpm:
    exists: true
    filetype: directory
  /root/.tmux/plugins/tmux-sensible:
    exists: true
    filetype: directory
  /root/.tmux/plugins/tmux-resurrect:
    exists: true
    filetype: directory
  /root/.tmux/plugins/tmux-mem-cpu-load:
    exists: true
    filetype: directory
  /root/.tmux/plugins/tmux-copycat:
    exists: true
    filetype: directory
  /root/.tmux/plugins/tmux-open:
    exists: true
    filetype: directory
  /root/.tmux/plugins/tmux-yank:
    exists: true
    filetype: directory
  /root/.tmux/plugins/tmux-prefix-highlight:
    exists: true
    filetype: directory

  # vim-plug installed
  /root/.local/share/nvim/site/autoload/plug.vim:
    exists: true

  # Neovim plugins installed (plug#begin dir)
  /root/.local/share/nvim/plugged:
    exists: true
    filetype: directory

  # Bootstrap completed successfully
  /root/.dotfiles-bootstrap-done:
    exists: true
```

**Step 2: Commit**

```bash
git add goss.yaml
git commit -m "Add goss.yaml with tmux plugin and neovim assertions"
```

---

### Task 6: End-to-end verification

**Step 1: Run CI mode**

```bash
just test
```

Expected: all goss assertions pass, container exits 0, TAP output shows all `ok` lines

**Step 2: If any assertion fails, debug interactively**

```bash
just dev
# Inside container:
ls ~/.tmux/plugins/
ls ~/.local/share/nvim/plugged/
cat ~/.dotfiles-bootstrap-done
```

**Step 3: Run dev mode smoke test**

```bash
just dev
# Inside container, start tmux and verify plugins load:
tmux new-session -d -s test
tmux list-sessions
# Verify tmux starts without errors
exit
```

**Step 4: Commit any fixes, then final commit**

```bash
git add -p
git commit -m "Fix: <describe what needed fixing>"
```

---

### Notes

- **Neovim version**: Ubuntu apt ships an older neovim. If `nvim --headless +PlugInstall` fails due to version constraints, add a PPA or snap install step to `Dockerfile`: `snap install nvim --classic`
- **TPM non-interactive**: `tpm/bin/install_plugins` parses `~/.tmux.conf` directly — no running tmux session required
- **Plugin home paths**: goss asserts `/root/` paths since the container runs as root. If the user changes, update paths accordingly
- **Phase 2**: Wire `test-unit` into `just test` once existing bash tests are confirmed working in Ubuntu
