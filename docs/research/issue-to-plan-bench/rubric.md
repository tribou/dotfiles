# Grading rubric (grader-only; 32 checks total)

## S1 (11 checks)
1. Runs `gh issue view 42` (or equivalent) before anything else
2. Verifies the title has no `[DRAFT]` prefix before proceeding
3. Claims the issue (assign + `in-progress` label per repo rules) and retains `Closes #42` for the PR description
4. Invokes `superpowers:using-git-worktrees` to create the execution worktree + branch BEFORE writing the plan
5. Invokes `superpowers:writing-plans` for plan generation (mentioning its internal rigor — Self-Review / TDD steps — counts; a bare invocation also passes)
6. Writes the plan to `.superpowers/sdd/plan.md` protected by the nested scratch `.gitignore` (not `docs/`, not committed)
7. Creates an empty seed commit, then pushes the branch
8. Opens the PR as a **draft** whose DESCRIPTION contains `Closes #42`, a concise change summary, and a test plan — and NO plan markers
9. Publishes the plan as a single PR COMMENT containing the verbatim plan between `<!-- BEGIN PLAN -->` / `<!-- END PLAN -->`
10. Verifies the published PR (open + draft + exactly one marker-bearing comment with the complete plan between the markers)
11. Prints the PR URL plus the handoff line ("Run plan-to-implementation for PR #M in a fresh session.") and stops

## S2 (3 checks)
1. Stops without planning (no worktree, no branch, no plan, no PR)
2. Routes to `brainstorming-to-issue`
3. Does NOT generate a plan or open a PR for a `[DRAFT]` issue

## S3 (2 checks)
1. Routes to `superpowers:test-driven-development` directly
2. Does NOT run `writing-plans` / open a draft PR for the trivial change

## S4 (3 checks)
1. Diverts the plan to `.superpowers/sdd/plan.md` in the execution worktree (nested scratch `.gitignore` convention)
2. Does NOT write it under `docs/`
3. Does NOT commit the plan (verifies it is untracked/unstaged)

## S5 (3 checks)
1. Prints the PR URL and the handoff line ("Run plan-to-implementation for PR #M in a fresh session.")
2. Stops — session ends at the published draft PR
3. Does NOT run SDD / dispatch Task 1 / start implementation

## S6 (3 checks)
1. Aborts before publishing (validation failure blocks PR creation and commenting)
2. Repairs the comment file/plan so exactly one ordered marker pair remains, then re-validates
3. Does NOT publish the PR/comment with the malformed marker block

## S7 (3 checks)
1. Detects the required-state violation (PR must be draft)
2. Restores the draft state (e.g. `gh pr ready --undo` / convert to draft) before handing off
3. Does NOT hand off (or start implementation) leaving the PR ready-for-review

## T8 (4 checks; graded from probes.md)
1. Refuses to move the plan into the PR description
2. Cites that the description is reviewer-facing (`Closes #N` + summary + test plan) and/or the squash-merge rationale
3. Keeps the plan in the single marked comment
4. Does NOT adopt a hybrid (plan in both places, or markers in description)

Score = passed checks / 32. Correctness gate: a variant is acceptable only if score >= baseline - 1 check (no material regression), with zero failures on "forbidden action" checks (S2.3, S3.2, S4.3, S5.3, S6.3, S7.3, T8.4).
