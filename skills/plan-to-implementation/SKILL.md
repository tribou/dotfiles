---
name: plan-to-implementation
description: Use when an open draft GitHub PR carries a marked implementation plan for a finalized issue and execution must begin or resume in a fresh context.
---

# Plan to Implementation

Resume a plan from an existing draft PR, execute it with SDD, and flip that same PR ready. The PR body and pushed branch are the durable state. Never recreate the planning session and never call `gh pr create` from this skill. Exact commands: `rehydrate-and-finish.md`.

## Rehydrate (every fresh entry)

1. Resolve the single open **draft** PR that closes the issue and contains `<!-- BEGIN PLAN -->`. Zero or multiple matches: stop and report; never guess or match by title.
2. Verify the linked issue is finalized and the body has exactly one ordered `BEGIN PLAN`/`END PLAN` pair.
3. Resolve the worktree from the PR's `headRefName`: re-enter the existing worktree if that branch is checked out, else create an isolated worktree for that existing branch per `superpowers:using-git-worktrees`. Run `gh pr checkout <M>` inside it.
4. Extract only the marker-delimited text into `.superpowers/sdd/plan.md` — never stale local scratch, never surrounding PR prose.
5. If `.superpowers/sdd/progress.md` exists, preserve it and resume from it; else start at Task 1.

## Execute

**REQUIRED SUB-SKILL:** `superpowers:subagent-driven-development` with `.superpowers/sdd/plan.md`. At pre-flight, compare plan vs issue before dispatching. Never synchronously ask or wait for a human; use the paths below.

## Pre-flight conflict → self-heal exactly once

1. Regenerate the plan from the issue via `superpowers:writing-plans`; update both local `plan.md` and the PR's marked plan block; re-run pre-flight review.
2. Still conflicted (specification defect; nothing implemented yet): `gh pr close <M> --delete-branch`; prefix the issue title `[DRAFT]`; comment the specific conflicts; unassign and remove `in-progress`; stop — route back to `brainstorming-to-issue`. Never regenerate twice or implement around the conflict.

## Mid-execution blocker (implementer BLOCKED, or review finding needs a human)

1. Stop dispatching tasks.
2. Prepend `## ⚠️ Blocked — needs human decision` to the **existing** draft PR body: per blocker give task, reason/finding, conflicting plan text, and exact decision needed; include honest progress/test status; preserve the plan block and `Closes #N`.
3. Push committed work. Keep the PR draft; keep the issue assigned and `in-progress`.
4. Skip the final whole-branch review and tests-must-pass gate — never force a blocked branch through success gates.
5. Stop. Never open a second PR or reset the issue for a blocker.

## Successful finish

**REQUIRED SUB-SKILL:** `superpowers:finishing-a-development-branch`, with this override:

<HARD-OVERRIDE>
No completion menu and no new PR. After tests and reviews pass, push, then `gh pr ready <M>` on the existing draft PR. Keep the worktree per the normal PR path.
</HARD-OVERRIDE>
