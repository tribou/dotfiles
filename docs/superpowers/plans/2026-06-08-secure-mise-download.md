# Secure Mise Download Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Secure the installation of `mise` in `bootstrap.sh` and `Dockerfile` by adding `-fsSL` flags to `curl`, and adding a unit test to enforce it.

**Architecture:** We will add a unit test in `tests/bootstrap.bats` verifying that the `curl` command for `mise` utilizes `-fsSL` flags, and then update both `bootstrap.sh` and `Dockerfile` accordingly.

**Tech Stack:** Bash, bats-core, Docker

---

### Task 1: Add unit test in tests/bootstrap.bats

**Files:**
- Modify: `tests/bootstrap.bats`

- [ ] **Step 1: Write the failing test**
  Add a new test at the end of `tests/bootstrap.bats` that asserts `curl -fsSL` is used to download `mise.run`.
  
  ```bash
  @test "bootstrap: installs mise using curl with -fsSL flags" {
    grep -q 'curl -fsSL https://mise.run' "$REPO_ROOT/bootstrap.sh"
  }
  ```

- [ ] **Step 2: Run test to verify it fails**
  Run: `just test-unit`
  Expected: The new test `bootstrap: installs mise using curl with -fsSL flags` fails.

- [ ] **Step 3: Commit**
  ```bash
  git add tests/bootstrap.bats
  git commit -m "test: add test for secure mise download in bootstrap.sh"
  ```

---

### Task 2: Update bootstrap.sh

**Files:**
- Modify: `bootstrap.sh:259`

- [ ] **Step 1: Write minimal implementation**
  Change line 259 of `bootstrap.sh`:
  ```bash
        curl -fsSL https://mise.run | sh
  ```

- [ ] **Step 2: Run test to verify it passes**
  Run: `just test-unit`
  Expected: The new test and all existing unit tests pass.

- [ ] **Step 3: Commit**
  ```bash
  git add bootstrap.sh
  git commit -m "fix: download mise via secure HTTPS with fail-fast flags"
  ```

---

### Task 3: Update Dockerfile

**Files:**
- Modify: `Dockerfile:34`

- [ ] **Step 1: Write minimal implementation**
  Change line 34 of `Dockerfile`:
  ```dockerfile
  RUN curl -fsSL https://mise.run | sh \
  ```

- [ ] **Step 2: Commit**
  ```bash
  git add Dockerfile
  git commit -m "fix: use secure/fail-fast flags when installing mise in Dockerfile"
  ```
