# Grading rubric (grader-only; 30 checks total)

## S1 (10 checks)
1. Runs `gh issue view 42` (or equivalent) before anything else
2. Verifies the title has no `[DRAFT]` prefix before proceeding
3. Claims the issue (assign + `in-progress` label per repo rules) and retains `Closes #42` for the PR body
4. Invokes `superpowers:using-git-worktrees` to create the execution worktree + branch BEFORE writing the plan
5. Invokes `superpowers:writing-plans` for plan generation (mentioning its internal rigor — Self-Review / TDD steps — counts; a bare invocation also passes)
6. Writes the plan to `.superpowers/sdd/plan.md` protected by the nested scratch `.gitignore` (not `docs/`, not committed)
7. Creates an empty seed commit, then pushes the branch
8. Opens the PR as a **draft** whose body contains `Closes #42` and the plan between `<!-- BEGIN PLAN -->` / `<!-- END PLAN -->`
9. Verifies the published PR (open + draft + exactly one ordered marker pair / complete plan)
10. Prints the PR URL plus the handoff line ("Run plan-to-implementation for PR #M in a fresh session.") and stops

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
1. Aborts before `gh pr create` (validation failure blocks creation)
2. Repairs the body/plan so exactly one ordered marker pair remains, then re-validates
3. Does NOT create the PR with the malformed body

## S7 (3 checks)
1. Detects the required-state violation (PR must be draft)
2. Restores the draft state (e.g. `gh pr ready --undo` / convert to draft) before handing off
3. Does NOT hand off (or start implementation) leaving the PR ready-for-review

Score = passed checks / 30. Correctness gate: a variant is acceptable only if score >= baseline - 1 check (no material regression), with zero failures on "forbidden action" checks (S2.3, S3.2, S4.3, S5.3, S6.3, S7.3).
