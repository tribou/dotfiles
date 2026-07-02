---
name: plan-to-implementation
description: Use when an open draft GitHub PR carries a marked implementation plan for a finalized issue and execution must begin or resume in a fresh context.
---

# Plan to Implementation

## Overview

Resume a plan from an existing draft PR, execute it with SDD in a fresh context, and make that same PR ready for review. The PR body and pushed branch are the durable state; local scratch is reconstructible.

**Core principle:** never recreate the planning session. Rehydrate from the marked PR plan, resume any progress ledger, and update the existing PR.

## Entry and Rehydration

Given an issue or PR number:

1. Find the open **draft** PR that closes the issue and contains `<!-- BEGIN PLAN -->`. Reject zero or ambiguous matches rather than guessing.
2. Confirm the linked issue is finalized and the PR body contains exactly one ordered `BEGIN PLAN` / `END PLAN` pair.
3. Resolve the isolated worktree deterministically from the PR's `headRefName`. Re-enter its exact path if that branch is already checked out; otherwise create an isolated worktree for that existing branch using `superpowers:using-git-worktrees` directory and safety rules. Run `gh pr checkout <M>` inside the resolved worktree.
4. Extract only the text between the markers into `.superpowers/sdd/plan.md`; do not treat surrounding PR prose as plan text.
5. If `.superpowers/sdd/progress.md` exists, preserve it and resume from it. Otherwise start at Task 1.

Exact recipes: `rehydrate-and-finish.md`.

## Execute

**REQUIRED SUB-SKILL:** Use `superpowers:subagent-driven-development` with `.superpowers/sdd/plan.md`.

At pre-flight, compare the plan against the issue before dispatching work. During execution, use the asynchronous escape paths below; never synchronously wait for a human decision.

## Pre-flight Plan Conflict

Attempt exactly one self-heal:

1. Regenerate the plan from the finalized issue using `superpowers:writing-plans`.
2. Update both local `plan.md` and the existing PR's marked plan block.
3. Re-run pre-flight review.

If the conflict remains, it is a specification defect. Because no implementation has started:

1. Close the draft PR and delete its remote/local branch with `gh pr close <M> --delete-branch`.
2. Prefix the source issue title with `[DRAFT]`.
3. Comment with the specific unresolved conflicts.
4. Unassign the issue and remove `in-progress` per repository convention.
5. Stop and route it back to `brainstorming-to-issue`.

Do not ask the human synchronously and do not implement around the conflict.

## Mid-execution Blocker

This path applies when an implementer returns BLOCKED because the plan is wrong, or a required/conflicting review finding needs a human decision.

1. Stop dispatching new tasks.
2. Prepend `## ⚠️ Blocked — needs human decision` to the **existing** draft PR body. For every blocker include the task, reason or finding, conflicting plan text, and exact decision needed. Include progress and honest test/verification status; preserve the plan block and `Closes #N`.
3. Push committed work.
4. Keep the PR draft and keep the issue assigned and `in-progress`.
5. Skip the final whole-branch review and the finishing tests-must-pass gate.
6. Stop. Do not synchronously ask or wait.

## Successful Finish

**REQUIRED SUB-SKILL:** Use `superpowers:finishing-a-development-branch` for normal verification and cleanup decisions, with this override:

<HARD-OVERRIDE>
Do not show the completion menu and do not create another PR. After all normal tests and reviews pass, push the branch and run `gh pr ready <M>` on the existing draft PR. Keep the worktree according to the normal PR path.
</HARD-OVERRIDE>

## Quick Reference

| Condition | Outcome |
|---|---|
| Valid plan, no progress ledger | Start SDD at Task 1 |
| Valid plan plus progress ledger | Resume SDD |
| Pre-flight conflict | Regenerate once; if still bad, close/delete/reset to `[DRAFT]` |
| Mid-run blocker | Annotate existing draft PR, push committed work, keep issue active, stop |
| Success | Verify, push, flip existing PR ready |

## Common Mistakes

| Mistake | Required correction |
|---|---|
| Creating a new PR for a blocker or opening a non-draft PR | Annotate the existing draft PR and keep it draft |
| Unassigning/resetting the issue mid-run | Keep it assigned and `in-progress`; reset only after failed pre-flight regeneration |
| Bouncing to `[DRAFT]` immediately | Regenerate and re-review exactly once first |
| Leaving the PR open or branch undeleted after pre-flight bounce | Close PR and delete branch before resetting the issue |
| Asking the human synchronously | Surface asynchronously in PR/issue, then stop |
| Running final review or tests-must-pass on a blocked branch | Short-circuit those completion gates and report honest status |
| Creating a new PR at successful finish | Run `gh pr ready` on the existing PR |
| Using stale local plan scratch | Rehydrate from the PR body markers on every fresh entry |

## Red Flags — STOP

- Execution starts without rehydrating the marked plan.
- More than one plan regeneration is attempted.
- A blocker opens a second PR, resets the issue, or waits on live user input.
- A blocked partial branch is forced through success-only gates.
- A persistent pre-flight conflict leaves its draft PR or branch behind.
- Successful execution creates another PR instead of readying the existing one.

Any red flag means return to the appropriate deterministic path above before dispatching more work.
