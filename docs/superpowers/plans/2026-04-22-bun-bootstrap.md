# Bun Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add bun as a mise-managed tool so bootstrap.sh installs it on both macOS and Linux.

**Architecture:** Add `bun = "latest"` to `mise-config.toml` so mise tracks it, then include `bun` in the existing `mise install node go` call in `bootstrap.sh`.

**Tech Stack:** bash, mise

---

### Task 1: Add bun to mise-config.toml

**Files:**
- Modify: `mise-config.toml`

- [ ] **Step 1: Add bun to the tools section**

Edit `mise-config.toml` so it reads:

```toml
[tools]
node = "lts"
ruby = "3"
go = "latest"
bun = "latest"

[settings]
legacy_version_file = true
```

- [ ] **Step 2: Verify mise recognises bun**

```bash
mise install bun
```

Expected: bun installs (or prints "bun is already installed") with no errors.

- [ ] **Step 3: Commit**

```bash
git add mise-config.toml
git commit -m "feat: add bun to mise-config.toml"
```

---

### Task 2: Update bootstrap.sh to install bun

**Files:**
- Modify: `bootstrap.sh`

- [ ] **Step 1: Write the failing unit test**

Open `tests/bootstrap.bats` and add:

```bash
@test "bootstrap installs bun via mise" {
  grep -q 'mise install.*bun' bootstrap.sh
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
just test-unit
```

Expected: the new test FAILs with "grep: no match".

- [ ] **Step 3: Update the mise install line in bootstrap.sh**

Find the line:
```bash
mise install node go
```

Change it to:
```bash
mise install node go bun
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
just test-unit
```

Expected: all tests PASS including the new one.

- [ ] **Step 5: Commit**

```bash
git add bootstrap.sh
git commit -m "feat: install bun via mise in bootstrap.sh"
```
