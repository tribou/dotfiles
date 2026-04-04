# mise Go Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `bootstrap.sh` install Go via `mise` instead of Homebrew while keeping `gopls` installed and verifiably working after bootstrap.

**Architecture:** Extend the existing `mise` runtime-install block in `bootstrap.sh` to include `go@latest`, remove `go` from the Homebrew package list, and keep `gopls` as a guarded `go install` step that runs only when the runtime is available. Add `goss.yaml` assertions for `go version` and `gopls version`, then verify the shell script with `bashcheck` and run the existing Docker-based test suite.

**Tech Stack:** bash, mise, Homebrew, goss, Docker Compose, just

---

## File Structure

- Modify: `bootstrap.sh`
  Responsibility: install runtimes and system packages during bootstrap, including the `mise` runtime setup and the retained `gopls` install step.
- Modify: `goss.yaml`
  Responsibility: assert the bootstrap result leaves working user-facing binaries on `PATH`.
- Verify: `justfile`
  Responsibility: existing test entry points only; no code changes expected.

### Task 1: Move Go Runtime Management Into `mise`

**Files:**
- Modify: `bootstrap.sh:196-205`
- Modify: `bootstrap.sh:266-301`

- [ ] **Step 1: Edit the `mise` runtime block to install Go**

Replace the current `mise` runtime block in `bootstrap.sh`:

```bash
if [ -x "$HOME/.local/bin/mise" ]
then
  mise use -g node@lts
  # Try precompiled ruby first (fast), fall back to source compilation
  if ! MISE_RUBY_COMPILE=0 mise use -g ruby@3 2>/dev/null; then
    echo "No precompiled ruby available for this platform, compiling from source..."
    mise use -g ruby@3
  fi
  echo
fi
```

with:

```bash
if [ -x "$HOME/.local/bin/mise" ]
then
  mise use -g node@lts
  # Try precompiled ruby first (fast), fall back to source compilation
  if ! MISE_RUBY_COMPILE=0 mise use -g ruby@3 2>/dev/null; then
    echo "No precompiled ruby available for this platform, compiling from source..."
    mise use -g ruby@3
  fi
  mise use -g go@latest
  echo
fi
```

- [ ] **Step 2: Remove Homebrew Go from the package list**

In the `brew install \` block in `bootstrap.sh`, remove this line:

```bash
      go \
```

The surrounding block should go directly from:

```bash
      hashicorp/tap/terraform-ls \
      nmap \
      elixir \
```

without any `go` entry between `nmap` and `elixir`.

- [ ] **Step 3: Run shell syntax validation**

Run:

```bash
bashcheck bootstrap.sh
```

Expected: no output and exit status `0`.

- [ ] **Step 4: Commit the runtime-source change**

Run:

```bash
git add bootstrap.sh
git commit -m "Install Go with mise instead of brew"
```

Expected: a single commit containing only the `bootstrap.sh` runtime-source update.

### Task 2: Keep `gopls` Working With The `mise`-Managed Go Toolchain

**Files:**
- Modify: `bootstrap.sh:345-346`

- [ ] **Step 1: Replace the unconditional `gopls` install with a guarded block**

Replace this code at the end of `bootstrap.sh`:

```bash
# Golang tools
go install golang.org/x/tools/gopls@latest
```

with:

```bash
# Golang tools — install after mise provisions Go
if [ -s "$(which go)" ] && [ ! -s "$(which gopls)" ]
then
  echo "Installing gopls"
  go install golang.org/x/tools/gopls@latest
fi
```

- [ ] **Step 2: Re-run shell syntax validation**

Run:

```bash
bashcheck bootstrap.sh
```

Expected: no output and exit status `0`.

- [ ] **Step 3: Review the resulting diff**

Run:

```bash
git diff -- bootstrap.sh
```

Expected: the diff shows only three logical changes in `bootstrap.sh`:
- `mise use -g go@latest` added
- `go` removed from the `brew install` list
- `gopls` install changed from unconditional to guarded

- [ ] **Step 4: Commit the `gopls` bootstrap behavior**

Run:

```bash
git add bootstrap.sh
git commit -m "Guard gopls install behind mise Go runtime"
```

Expected: a single commit containing the retained `gopls` install logic.

### Task 3: Add Regression Coverage For Go And `gopls`

**Files:**
- Modify: `goss.yaml:23-39`

- [ ] **Step 1: Add Go and `gopls` command assertions**

In the `command:` section of `goss.yaml`, add these entries immediately after the existing `mise --version` assertion:

```yaml
  # Go must be available via the mise-managed runtime installed by bootstrap
  "go version":
    exit-status: 0

  # gopls must remain available for editor integration after bootstrap
  "gopls version":
    exit-status: 0
```

The command block in that area should read:

```yaml
  # mise must be installed and functional
  "mise --version":
    exit-status: 0

  # Go must be available via the mise-managed runtime installed by bootstrap
  "go version":
    exit-status: 0

  # gopls must remain available for editor integration after bootstrap
  "gopls version":
    exit-status: 0

  # fd and bat must be available as canonical names (Ubuntu installs as fdfind/batcat)
  "fd --version":
    exit-status: 0
```

- [ ] **Step 2: Review the goss-only diff**

Run:

```bash
git diff -- goss.yaml
```

Expected: exactly two new command assertions and their comments, with no unrelated YAML movement.

- [ ] **Step 3: Commit the regression coverage**

Run:

```bash
git add goss.yaml
git commit -m "Add Go and gopls bootstrap assertions"
```

Expected: a single commit containing only the new `goss.yaml` checks.

### Task 4: Verify The Full Bootstrap Path

**Files:**
- Verify: `bootstrap.sh`
- Verify: `goss.yaml`
- Verify: `justfile`

- [ ] **Step 1: Confirm the worktree contains only the intended files**

Run:

```bash
git status --short
```

Expected:

```text
```

An empty result means all planned changes are committed before final verification.

- [ ] **Step 2: Rebuild the Docker image with current sources**

Run:

```bash
just build
```

Expected: Docker Compose builds the `ci` image successfully with no syntax or package-resolution failures in `bootstrap.sh`.

- [ ] **Step 3: Run the full test suite**

Run:

```bash
just test
```

Expected: the Docker-based suite completes successfully, including `goss` checks for `mise --version`, `go version`, and `gopls version`.

- [ ] **Step 4: Inspect the final diff against the starting point**

Run:

```bash
git log --oneline --decorate -3
git diff bb5d44b..HEAD -- bootstrap.sh goss.yaml
```

Expected:
- three intentional commits are visible for runtime source, guarded `gopls`, and goss assertions
- the diff shows only `bootstrap.sh` and `goss.yaml` changes described in the spec
