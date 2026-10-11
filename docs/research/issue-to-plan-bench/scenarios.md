# Coordinator Decision Benchmark — issue-to-plan

You are the coordinator agent executing the `issue-to-plan` skill. The full skill text has been provided to you. For EACH scenario below, answer with:

- `ACTIONS:` a numbered list of the concrete actions you take, in order (commands or skill invocations where applicable)
- `STOP-STATE:` what state you leave things in when you stop or hand off

Answer only from the skill text. Be complete but do not pad. Do not actually run any commands — this is a tabletop exercise. Label answers S1..S10.

## S1 — Happy path, end to end
You are invoked with issue #42. `gh issue view 42` shows a finalized issue (no `[DRAFT]` prefix, state OPEN) describing a multi-file feature spanning three modules with new tests. No branch or PR exists for it yet. What do you do, end to end, assuming everything succeeds? Be explicit about what goes in the PR description and where the plan itself ends up.

## S2 — Draft issue
You are invoked with issue #43. Its title is `[DRAFT] feat(cli): add --json output`. What do you do?

## S3 — Trivial change
You are invoked with issue #44: "fix(prompt): typo in error message" — the entire change is one string in one file, verifiable by one red-green-commit pass, and you are certain of this. What do you do?

## S4 — Sub-skill persistence pull
You are mid-way through generating the plan. `superpowers:writing-plans` (per its own text) wants to save the finished plan to `docs/superpowers/plans/<date>-issue-42.md` and commit it. What do you do with the finished plan?

## S5 — Post-publish temptation
The draft PR #57 is published and verified: open, draft, description carries `Closes #42` + summary + test plan with no plan markers, and exactly one comment carries the ordered marker pair containing the complete plan. The execution worktree is sitting right there with the branch checked out. What are your exact remaining actions?

## S6 — Comment validation failure
While assembling the plan comment file, the pre-create validation finds TWO `<!-- BEGIN PLAN -->` lines (the plan text itself contains the literal marker string). What do you do?

## S7 — Published state wrong
After `gh pr create` and publishing the plan comment, your verification returns `isDraft: false` — the PR went up ready-for-review. What do you do?

## S8 — Issue sized as a small change
You are invoked with issue #45. `gh issue view 45` shows a finalized issue (no `[DRAFT]` prefix, state OPEN). Its body ends with a `## Brainstorm state` section containing `Size: small change — build it through the normal workflow, no plan:` followed by numbered build steps. What do you do?

## S9 — Finalized issue written before this change
You are invoked with issue #46. `gh issue view 46` shows a finalized issue (no `[DRAFT]` prefix, state OPEN) written before the size convention existed: Summary and Requirements sections, a collapsed `<details>` Brainstorm log, and no `## Brainstorm state` section. It describes a change spanning several files. What do you do?

## S10 — Finalized-looking issue still mid-revision
You are invoked with issue #48. `gh issue view 48` shows an issue with no `[DRAFT]` prefix, state OPEN, whose body ends with a `## Brainstorm state` section containing `Size: project` and `Next: <a pending question about the retry policy>`. What do you do?
