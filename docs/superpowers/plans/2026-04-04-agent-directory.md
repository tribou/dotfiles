# Agent Directory Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Isolate the agent-user feature under a dedicated top-level `agent/` directory and restore generic `lib/` auto-sourcing.

**Architecture:** Move the agent override and setup script out of globally loaded directories, point the setup flow at the new paths, and update tests/docs so the repository documents that boundary clearly.

**Tech Stack:** bash, bats

---

### Task 1: Enforce generic `lib/` sourcing

**Files:**
- Modify: `tests/lib_index.bats`
- Modify: `lib/index.sh`

- [ ] Write a failing test that proves `lib/index.sh` sources every non-`index.sh` file.
- [ ] Run `./tests/test_helper/bats-core/bin/bats tests/lib_index.bats` and confirm it fails because `agent_overrides.sh` is excluded.
- [ ] Remove the one-off exclusion from `lib/index.sh`.
- [ ] Re-run `./tests/test_helper/bats-core/bin/bats tests/lib_index.bats` and confirm it passes.

### Task 2: Move agent-specific files under `agent/`

**Files:**
- Create: `agent/overrides.sh`
- Create: `agent/setup-user.sh`
- Delete: `lib/agent_overrides.sh`
- Delete: `scripts/setup-agent-user.sh`

- [ ] Copy the agent override contents into `agent/overrides.sh`.
- [ ] Copy the setup script into `agent/setup-user.sh` and update the symlink target to `agent/overrides.sh`.
- [ ] Delete the old files from `lib/` and `scripts/`.

### Task 3: Update repository guidance

**Files:**
- Modify: `CLAUDE.md`
- Modify: `docs/plans/2026-04-04-ssh-git-permissions-design.md`
- Modify: `docs/plans/2026-04-04-ssh-git-permissions-plan.md`

- [ ] Document the purpose of the `agent/` directory in `CLAUDE.md`.
- [ ] Update existing design/plan docs to reference `agent/overrides.sh` and `agent/setup-user.sh`.

### Task 4: Verify

**Files:**
- Test: `tests/lib_index.bats`

- [ ] Run `./tests/test_helper/bats-core/bin/bats tests/lib_index.bats`.
- [ ] Run `bash -lic 'printf "USER=%s\nHOME=%s\nPS1=%q\n" "$USER" "$HOME" "$PS1"'` and confirm the normal user prompt does not contain `[llm]`.
