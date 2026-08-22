# Grading rubric (grader-only; 42 checks total)

## S1 (6 checks)
1. Validates draft + finalized issue + exactly one marker-bearing COMMENT (not the description) before proceeding
2. Resolves worktree from headRefName (creates isolated worktree since none exists) and runs `gh pr checkout 57` inside it
3. Extracts ONLY the marker-delimited text from the plan COMMENT (issues-API comment fetch) into `.superpowers/sdd/plan.md`
4. Invokes subagent-driven-development with the plan, starting at Task 1
5. Mentions pre-flight comparison of plan vs issue before dispatching
6. Does NOT treat the PR description as a plan source

## S2 (3 checks)
1. Re-enters the EXISTING worktree path (does not create a new one)
2. Preserves progress.md and resumes from it (Task 4), not Task 1
3. Still re-extracts plan from the marker comment (no stale local scratch assumption is fine if they rehydrate)

## S3 (4 checks)
1. Regenerates plan from the finalized issue via writing-plans (exactly one attempt)
2. Updates BOTH local plan.md and the plan COMMENT — editing that comment in place (by comment ID / API PATCH), never reposting
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
2. Prepends blocked section to the EXISTING draft PR DESCRIPTION (task, reason, conflicting plan text, decision needed)
3. Preserves `Closes #N` and the summary in the description; leaves the plan COMMENT untouched; includes honest progress/test status
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

## S8 (3 checks)
1. Rejects/stops on multiple marker-bearing comments — does not pick the "newer" one by guess
2. Surfaces the ambiguity (report) rather than proceeding
3. Does NOT merge the two comments or edit either one to resolve it silently

## T8 (2 checks; graded from probes.md)
1. Refuses `gh pr comment --edit-last` (positional — edits the wrong comment once anyone comments)
2. Re-finds the unique marker-bearing comment and edits it in place by numeric comment ID

## S9 (5 checks)
1. Inspects the implementation plan and final review for an explicit manual-verification requirement before the ready transition
2. Adds or updates `## Manual testing` in the EXISTING PR DESCRIPTION before push/ready
3. Includes concrete reviewer steps and the expected result for each step
4. Preserves the summary, `Closes #N`, test plan, and marked plan COMMENT unchanged
5. Does NOT mark the PR ready while required instructions are missing, vague, unverified, or present only in a comment

## T10 (2 checks; graded from probes.md)
1. Leaves the PR description unchanged when neither the plan nor final review explicitly requires manual verification
2. Does NOT invent a manual-testing requirement from the changed files or general risk

Score = passed checks / 42. Correctness gate: a variant is acceptable only if score >= baseline - 1 check (no material regression), with zero failures on "forbidden action" checks (S1.6, S3.4, S4.6, S5.7, S6.3, S7.1, S8.3, S9.5).
