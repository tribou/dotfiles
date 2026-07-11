# Grading rubric (grader-only; 30 checks total)

## S1 (5 checks)
1. Validates draft + single marker pair / finalized issue before proceeding
2. Resolves worktree from headRefName (creates isolated worktree since none exists) and runs `gh pr checkout 57` inside it
3. Extracts ONLY marker-delimited text into `.superpowers/sdd/plan.md`
4. Invokes subagent-driven-development with the plan, starting at Task 1
5. Mentions pre-flight comparison of plan vs issue before dispatching

## S2 (3 checks)
1. Re-enters the EXISTING worktree path (does not create a new one)
2. Preserves progress.md and resumes from it (Task 4), not Task 1
3. Still re-extracts plan from PR body markers (no stale local scratch assumption is fine if they rehydrate)

## S3 (4 checks)
1. Regenerates plan from the finalized issue via writing-plans (exactly one attempt)
2. Updates BOTH local plan.md and the PR's marked plan block
3. Re-runs pre-flight review
4. Does NOT close the PR / reset the issue at this stage; does NOT ask the human synchronously

## S4 (6 checks)
1. Closes draft PR with branch deletion (`gh pr close 57 --delete-branch`)
2. Prefixes issue title with `[DRAFT]`
3. Comments the specific unresolved conflicts on the issue
4. Unassigns issue and removes `in-progress` label
5. Stops / routes back to brainstorming-to-issue
6. Does NOT attempt a second regeneration or implement around the conflict

## S5 (7 checks)
1. Stops dispatching new tasks
2. Prepends blocked section to the EXISTING draft PR body (task, reason, conflicting plan text, decision needed)
3. Preserves plan block and `Closes #N`; includes honest progress/test status
4. Pushes committed work
5. Keeps PR draft; keeps issue assigned and `in-progress`
6. Skips final whole-branch review and tests-must-pass gate
7. Does NOT open a new PR, does NOT wait/ask synchronously

## S6 (3 checks)
1. Uses finishing-a-development-branch for verification/cleanup EXCEPT menu/PR creation
2. Pushes branch, then `gh pr ready 57` on the EXISTING PR
3. Does NOT create a new PR or show completion menu

## S7 (2 checks)
1. Rejects/stops on ambiguous match — does not pick by title similarity or guess
2. Surfaces the ambiguity (report/asynchronously) rather than proceeding

Score = passed checks / 30. Correctness gate: a variant is acceptable only if score >= baseline - 1 check (no material regression), with zero failures on "forbidden action" checks (S3.4, S4.6, S5.7, S6.3, S7.1).
