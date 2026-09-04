---
name: issue-to-plan
description: Use when a finalized non-[DRAFT] GitHub issue needs an implementation plan published for execution in a separate fresh context. Not for refining the specification or for a one-file, one-behavior change.
---

# Issue to Plan

## Overview

Turn a finalized issue into a draft PR plus a single marked plan comment, then stop. The draft PR and its plan comment are the durable boundary between planning and execution.

**Core principle:** planning and execution happen in separate contexts. This skill never runs SDD or dispatches Task 1.

The plan lives in a PR comment, never the description. The description stays a concise, reviewer-facing summary (`Closes #N` + change summary + test plan): the simplest merge path — squash-merging from the GitHub web UI, which prefills the commit message from the PR body — then produces a clean commit message instead of a multi-kilobyte plan.

## Entry Gate (all 5 steps, in order)

1. Run `gh issue view <N> --json number,title,body,state`.
2. If the title starts with `[DRAFT]`, stop and route to `brainstorming-to-issue`.
3. If the entire change is one file, one behavior, and one red-green-commit review pass, use `superpowers:test-driven-development` directly. Uncertainty means it is not trivial.
4. Claim the issue per repository rules: assign it and add the `in-progress` label.
5. Retain `Closes #<N>` for the PR description.

## Generate the Plan (all 3 steps, in order)

1. **REQUIRED SUB-SKILL:** `superpowers:using-git-worktrees` — create the execution worktree and branch first, before any plan is written.
2. **REQUIRED SUB-SKILL:** `superpowers:writing-plans` — including its Self-Review, File Structure, Global Constraints, per-task Interfaces, and bite-sized TDD steps.
3. Override inside `writing-plans` — its persistence and handoff only:
   - Write the plan to `.superpowers/sdd/plan.md` in the execution worktree, protected by the nested scratch `.gitignore` convention.
   - Never write it under `docs/` and never commit it.
   - Never offer execution approaches and never start implementation.

## Publish the Durable Handoff (all 8 steps, in order)

Pre-publish gate — before creating anything, confirm each check aloud:

1. Source issue is finalized (no `[DRAFT]`), assigned, and labeled `in-progress`.
2. The plan is at `.superpowers/sdd/plan.md`, untracked and unstaged.
3. The description file contains `Closes #<N>`, a concise change summary, and a concise test plan — and contains no plan markers.
4. The comment file contains exactly one ordered `BEGIN PLAN`/`END PLAN` marker pair; the plan between the markers is the verbatim contents of `.superpowers/sdd/plan.md` — never a summary — and the comment file is within GitHub's 65,536-character comment limit.

Then, with the exact commands and shapes in `plan-and-publish.md`:

1. Create an empty seed commit to anchor the branch.
2. Push the branch.
3. Open a **draft** PR whose description carries `Closes #N`, the change summary, and the test plan.
4. Publish the plan as a single PR comment containing the complete plan between `<!-- BEGIN PLAN -->` and `<!-- END PLAN -->`.
5. Verify the published PR: state OPEN, `isDraft` true, and exactly one comment containing the ordered marker pair with the complete plan between them.
6. Print the PR URL.
7. Print exactly: `Run plan-to-implementation for PR #M in a fresh session.`
8. **STOP.**

The plan remains untracked scratch locally; its durable copy is the marked PR comment. When the plan later changes, that comment is edited in place by its comment ID — never reposted as a new comment. The empty seed commit contains no plan and disappears under squash merge.

## Quick Reference

| Artifact | Required state |
|---|---|
| Source issue | Finalized, assigned, `in-progress` |
| Local plan | `.superpowers/sdd/plan.md`, ignored, uncommitted |
| Branch | Pushed, anchored by empty seed commit |
| PR | Open draft; description = `Closes #N` + summary + test plan, no markers |
| Plan comment | Exactly one, holding the verbatim plan between markers |
| Terminal action | Print handoff, then stop |

## Common Mistakes

| Mistake | Required correction |
|---|---|
| Auto-dispatching Task 1 or running SDD in this session | Stop at the published draft PR; execution requires a fresh context |
| Keeping the only plan copy in local scratch | Put the complete plan between markers in the PR comment |
| Embedding the plan in the PR description | The description is reviewer-facing (`Closes #N`, summary, test plan); the plan belongs in the comment |
| Opening a non-draft PR | Use `gh pr create --draft`; it stays draft until execution finishes |
| Committing the plan | Commit only an empty seed; keep the plan untracked |
| Saving under `docs/superpowers/plans/` | Divert `writing-plans` output to `.superpowers/sdd/plan.md` |
| Asking which execution approach to use | There is no execution in this skill |
| Summarizing or trimming the plan to fit GitHub's 65k comment limit | Never compress the plan; stop, report the size, and split the source issue instead |

## Red Flags — STOP

- SDD is about to start or Task 1 is about to be dispatched.
- No open draft PR has exactly one comment containing the complete marked plan.
- Plan markers appear in the PR description instead of the comment.
- The plan or `.superpowers/` is staged.
- The PR is ready for review instead of draft.
- The plan in the comment is a summary or paraphrase instead of the verbatim `.superpowers/sdd/plan.md` contents.
- Planning and execution are still happening in one session.

Any red flag means: first restore the durable draft-PR handoff (for a non-draft PR, convert it back to draft or re-publish it as draft), then stop without implementation — restore, then stop, in that order.
