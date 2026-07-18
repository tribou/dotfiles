---
name: just-doctor-health
description: Use when `scripts/doctor.sh` may have drifted from Ansible provisioning, especially after changes to managed symlinks, installed tools, remediation commands, or summary-count logic.
---

# just doctor Health Audit

## Overview

`scripts/doctor.sh` is derived from the Ansible role. Audit that contract—not
the machine—and report separate, non-duplicate issues. Scheduled audits are
read-only: never edit, commit, add `in-progress`, or run the Docker suite.

## Contract

| Doctor behavior | Source | Invariant |
|---|---|---|
| Symlinks | `roles/dotfiles/tasks/links.yml` | Each `dest`/`src` pair appears once; no extras |
| Brew | `roles/dotfiles/defaults/main.yml`, `tasks/brew.yml` | Membership and remediation match |
| mise | `roles/dotfiles/defaults/main.yml`, `tasks/mise.yml` | `mise` and every runtime, including Ruby, are checked; remediation matches |
| Delta | `tasks/brew.yml` | Check and install/reinstall guidance match |
| Summary | `scripts/doctor.sh`, `tests/doctor.bats` | `total_checks = symlinks + tools + delta`; comment and assertions agree |

Derive mappings and counts every run; never copy expected values into this skill.

## Audit

1. Run `git status --porcelain`. If non-empty, stop and report. Otherwise run
   `git pull --ff-only`.
2. Run `just test-unit tests/doctor.bats`; diagnose before filing.
3. Normalize every role link as `~/<dest>~<src>` and compare the complete sorted
   set with doctor's default array. Counts are only a summary; equal counts never
   replace set comparison.
4. Compare tool/delta membership **and remediation** with the role. Ruby is required.
5. Recalculate the summary invariant, comment, and both Bats assertions. A test
   failure and bad arithmetic with one cause belong in one issue.
6. Run `just doctor`. Report machine drift; file only when static evidence proves
   a false result or bad guidance.
7. Complete all independent checks unless a missing prerequisite blocks one.
   Partition findings by independently actionable root cause—not symptom or
   broad category.

## Deduplicate and File

Use a canonical lowercase `<surface>:<entity>:<defect>` key, excluding counts,
lines, and commits. Put its plain-text marker first in the body:

```text
just-doctor-health/finding/tool:mise:stale-remediation
```

Before **each** creation:

1. Search issue bodies and comments, then inspect candidates for the exact marker:
   ```bash
   repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
   marker='just-doctor-health/finding/tool:mise:stale-remediation'
   gh search issues "$marker" --repo "$repo" --match body --match comments \
     --limit 1000 --json number,title,state,url
   ```
2. Search all issues semantically by file, symbol, command, dependency, and
   symptom. Inspect bodies; titles and prefixes do not establish uniqueness.
3. Equivalent unmarked open issue: add one marker comment so later runs find it.
   Otherwise comment only for materially changed evidence. Never create another.
4. Equivalent closed issue: if closed as fixed and drift persists, reopen with
   evidence; if duplicate/superseded, use its canonical issue; if intentionally
   declined, report that disposition. Never create a duplicate.
5. Repeat the marker search immediately before `gh issue create`.

Body: marker, `What`, file-and-line `Evidence`, contract link to
`.agents/skills/just-doctor-health/SKILL.md`, suggested fix, and acceptance
criteria including the doctor Bats test.

Use `type::bug` for behavior, `type::chore` for comment-only cleanup, `P2` for
active false failures, otherwise `P3`.

## Quick Reference

```bash
git status --porcelain  # stop if non-empty
git pull --ff-only
just test-unit tests/doctor.bats
just doctor
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Filing symptoms or combining unrelated drift | One issue per actionable root cause |
| Checking only counts | Compare complete normalized sets |
| Searching only audit titles | Search markers and semantic candidates |
| Treating machine drift as script drift | Require static evidence |
| Fixing during the audit | Remain read-only |
| Using `just test` or later `bash -n` | Use doctor Bats; use `bashcheck` for edits |
