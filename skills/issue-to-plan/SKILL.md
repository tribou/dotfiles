---
name: issue-to-plan
description: Use when a finalized non-[DRAFT] GitHub issue needs an implementation plan published for execution in a separate fresh context. Not for refining the specification or for a one-file, one-behavior change.
---

# Issue to Plan

## Overview

Turn a finalized issue into a draft PR that carries a machine-recoverable implementation plan, then stop. The draft PR is the durable boundary between planning and execution.

**Core principle:** planning and execution happen in separate contexts. This skill never runs SDD or dispatches Task 1.

## Entry Gate

1. Run `gh issue view <N> --json number,title,body,state`.
2. If the title starts with `[DRAFT]`, stop and route to `brainstorming-to-issue`.
3. If the entire change is one file, one behavior, and one red-green-commit review pass, use `superpowers:test-driven-development` directly. Uncertainty means it is not trivial.
4. Claim the issue per repository rules and retain `Closes #<N>` for the PR body.

## Generate the Plan

**REQUIRED SUB-SKILL:** Use `superpowers:writing-plans`, including its Self-Review, File Structure, Global Constraints, per-task Interfaces, and bite-sized TDD steps.

**REQUIRED SUB-SKILL:** Use `superpowers:using-git-worktrees` to create the execution worktree and branch before writing the plan.

<HARD-OVERRIDE>
Override only `writing-plans` persistence and handoff:

- Write the plan to `.superpowers/sdd/plan.md` in the execution worktree, protected by the nested scratch `.gitignore` convention.
- Never write it under `docs/` or commit it.
- Never offer execution approaches or start implementation.
</HARD-OVERRIDE>

## Publish the Durable Handoff

Use the exact commands and body shape in `plan-and-publish.md`:

1. Create an empty seed commit to anchor the branch.
2. Push the branch.
3. Open a **draft** PR whose body contains `Closes #N` and the complete plan between `<!-- BEGIN PLAN -->` and `<!-- END PLAN -->`.
4. Verify the PR is open and draft and that both markers are present.
5. Print the PR URL and: `Run plan-to-implementation for PR #M in a fresh session.`
6. **STOP.**

The plan remains untracked scratch locally; its durable copy is the draft PR body. The empty seed commit contains no plan and disappears under squash merge.

## Quick Reference

| Artifact | Required state |
|---|---|
| Source issue | Finalized, assigned, `in-progress` |
| Local plan | `.superpowers/sdd/plan.md`, ignored, uncommitted |
| Branch | Pushed, anchored by empty seed commit |
| PR | Open draft, `Closes #N`, marked plan block |
| Terminal action | Print handoff, then stop |

## Common Mistakes

| Mistake | Required correction |
|---|---|
| Auto-dispatching Task 1 or running SDD in this session | Stop at the published draft PR; execution requires a fresh context |
| Keeping the only plan copy in local scratch | Put the complete plan between markers in the PR body |
| Opening a non-draft PR | Use `gh pr create --draft`; it stays draft until execution finishes |
| Committing the plan | Commit only an empty seed; keep the plan untracked |
| Saving under `docs/superpowers/plans/` | Divert `writing-plans` output to `.superpowers/sdd/plan.md` |
| Asking which execution approach to use | There is no execution in this skill |

## Red Flags — STOP

- SDD is about to start or Task 1 is about to be dispatched.
- No open draft PR contains the complete marked plan.
- The plan or `.superpowers/` is staged.
- The PR is ready for review instead of draft.
- Planning and execution are still happening in one session.

Any red flag means restore the durable draft-PR handoff and stop without implementation.
