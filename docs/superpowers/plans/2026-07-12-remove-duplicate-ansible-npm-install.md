# Remove Duplicate Ansible npm Install Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make mise's `default-node-packages` the sole source of truth for global npm packages.

**Architecture:** The role links `.default-node-packages` before mise installs Node, allowing mise to install the complete package list. Remove the later Ansible npm task, its partial package variable, and its role import so package ownership is not duplicated.

**Tech Stack:** Ansible, mise, Bats

---

### Task 1: Remove the duplicate npm package path

**Files:**
- Modify: `tests/bootstrap.bats:38-42`
- Modify: `roles/dotfiles/tasks/main.yml:46-48`
- Modify: `roles/dotfiles/defaults/main.yml:92-96`
- Delete: `roles/dotfiles/tasks/npm.yml`

- [ ] **Step 1: Write the failing regression test**

Remove `npm` from the expected concern-file loop and add:

```bash
@test "role: mise default-node-packages is the sole global npm package source" {
  [ ! -e "$REPO_ROOT/roles/dotfiles/tasks/npm.yml" ]
  ! grep -q 'npm.yml' "$REPO_ROOT/roles/dotfiles/tasks/main.yml"
  ! grep -q 'dotfiles_npm_globals' "$REPO_ROOT/roles/dotfiles/defaults/main.yml"
}
```

- [ ] **Step 2: Run the focused test and verify it fails**

Run: `just test-unit tests/bootstrap.bats`

Expected: FAIL because `roles/dotfiles/tasks/npm.yml` still exists.

- [ ] **Step 3: Remove the duplicate implementation**

Delete `roles/dotfiles/tasks/npm.yml`, remove the `Include global npm modules` import from `roles/dotfiles/tasks/main.yml`, and remove `dotfiles_npm_globals` from `roles/dotfiles/defaults/main.yml`.

- [ ] **Step 4: Run verification**

Run: `just test-unit`

Expected: all unit tests pass.

Run: `just test`

Expected: the full Docker suite passes.

- [ ] **Step 5: Commit**

```bash
git add tests/bootstrap.bats roles/dotfiles/tasks/main.yml roles/dotfiles/defaults/main.yml roles/dotfiles/tasks/npm.yml
git commit -m "fix(ansible): delegate global npm packages to mise"
```
