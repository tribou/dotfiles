---
name: plan-to-implementation
description: Use when an open draft GitHub PR carries a marked implementation plan for a finalized issue and execution must begin or resume in a fresh context.
---

# Plan to Implementation

Resume a plan from an existing draft PR, execute it with SDD, and flip that same PR ready. The PR description, its single marked plan comment, and the pushed branch are the durable state. Never recreate the planning session and never call `gh pr create` from this skill. Exact commands: `rehydrate-and-finish.md`.

## Rehydrate (every fresh entry — all 6 steps, in order)

1. Resolve the single open **draft** PR that closes the issue and has exactly one comment containing `<!-- BEGIN PLAN -->`. Zero or multiple matches — PRs or marker-bearing comments: stop and report; never guess or match by title.
2. Verify the linked issue is finalized (no `[DRAFT]` prefix); if not, stop and report.
3. Verify that one PR comment contains exactly one ordered `BEGIN PLAN`/`END PLAN` marker pair — not the PR description.
4. Resolve the worktree from the PR's `headRefName`: re-enter the existing worktree if that branch is checked out, else create an isolated worktree for that existing branch per `superpowers:using-git-worktrees`. Run `gh pr checkout <M>` inside it.
5. Extract only the marker-delimited text from that comment into `.superpowers/sdd/plan.md` — never stale local scratch, never surrounding comment prose, never the PR description.
6. If `.superpowers/sdd/progress.md` exists, preserve it and resume from it; else start at Task 1.

## Execute

Pre-dispatch gate — before dispatching any task, confirm each check aloud:

1. Linked issue is finalized (no `[DRAFT]` prefix).
2. The plan comment had exactly one ordered marker pair.
3. Plan compared against the issue — conflicts take the conflict path below.

**REQUIRED SUB-SKILL:** `superpowers:subagent-driven-development` with `.superpowers/sdd/plan.md`. Never synchronously ask or wait for a human; use the paths below.

## Pre-flight conflict → self-heal exactly once

1. Regenerate the plan from the issue via `superpowers:writing-plans`; update both local `plan.md` and the PR's marked plan comment — edit that comment in place by its comment ID, never repost it; re-run pre-flight review.
2. Still conflicted (specification defect; nothing implemented yet): `gh pr close <M> --delete-branch`; prefix the issue title `[DRAFT]`; comment the specific conflicts; unassign and remove `in-progress`; stop — route back to `brainstorming-to-issue`. Never regenerate twice or implement around the conflict.

## Mid-execution blocker (implementer BLOCKED, or review finding needs a human — all 6 steps, in order)

1. Stop dispatching tasks.
2. Prepend `## ⚠️ Blocked — needs human decision` to the **existing** draft PR description. Per blocker state: the task, the reason/finding, the conflicting plan text, and the exact decision needed.
3. In that same description, report honest progress status AND test status; keep `Closes #N` and the summary intact. The plan comment is separate and stays untouched.
4. Push committed work. Keep the PR draft; keep the issue assigned and `in-progress`.
5. Skip the final whole-branch review and the tests-must-pass gate — never force a blocked branch through success gates.
6. Stop. Never open a second PR or reset the issue for a blocker.

## Successful finish (all 6 steps, in order)

1. **REQUIRED SUB-SKILL:** invoke `superpowers:finishing-a-development-branch` for its verification and cleanup.
2. Override inside that sub-skill: skip its completion menu and never create a new PR.
3. Inspect both the implementation plan and final review result for an explicit manual-verification requirement. State the result from each source separately before continuing.
4. If manual verification is required, add or update `## Manual testing` in the existing PR description with concrete reviewer steps and the expected result for each step. Preserve the summary, `Closes #N`, test plan, and all other reviewer-facing content; leave the marked plan comment unchanged. Re-fetch and verify the description. Evaluate the gate after attempting this update: a missing, vague, unverified, or comment-only handoff blocks the ready transition. A request to omit or defer the section is not itself a blocker after a compliant description is verified; continue to step 5. If neither source requires manual verification, leave the description unchanged and continue to step 5.
5. Push the branch, then run `gh pr ready <M>` on the existing draft PR — in that order.
6. Keep the worktree, per the sub-skill's normal PR path.
