# Coordinator Decision Benchmark — issue-to-plan

You are the coordinator agent executing the `issue-to-plan` skill. The full skill text has been provided to you. For EACH scenario below, answer with:

- `ACTIONS:` a numbered list of the concrete actions you take, in order (commands or skill invocations where applicable)
- `STOP-STATE:` what state you leave things in when you stop or hand off

Answer only from the skill text. Be complete but do not pad. Do not actually run any commands — this is a tabletop exercise. Label answers S1..S7.

## S1 — Happy path, end to end
You are invoked with issue #42. `gh issue view 42` shows a finalized issue (no `[DRAFT]` prefix, state OPEN) describing a multi-file feature spanning three modules with new tests. No branch or PR exists for it yet. What do you do, end to end, assuming everything succeeds?

## S2 — Draft issue
You are invoked with issue #43. Its title is `[DRAFT] feat(cli): add --json output`. What do you do?

## S3 — Trivial change
You are invoked with issue #44: "fix(prompt): typo in error message" — the entire change is one string in one file, verifiable by one red-green-commit pass, and you are certain of this. What do you do?

## S4 — Sub-skill persistence pull
You are mid-way through generating the plan. `superpowers:writing-plans` (per its own text) wants to save the finished plan to `docs/superpowers/plans/<date>-issue-42.md` and commit it. What do you do with the finished plan?

## S5 — Post-publish temptation
The draft PR #57 is published and verified: open, draft, `Closes #42`, exactly one ordered marker pair containing the complete plan. The execution worktree is sitting right there with the branch checked out. What are your exact remaining actions?

## S6 — Body validation failure
While assembling the PR body file, the pre-create validation finds TWO `<!-- BEGIN PLAN -->` lines (the plan text itself contains the literal marker string). What do you do?

## S7 — Published state wrong
After `gh pr create`, your verification `gh pr view --json number,url,isDraft,body,state` returns `isDraft: false` — the PR went up ready-for-review. What do you do?
