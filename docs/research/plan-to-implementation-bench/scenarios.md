# Coordinator Decision Benchmark — plan-to-implementation

You are the coordinator agent executing the `plan-to-implementation` skill. The full skill text has been provided to you. For EACH scenario below, answer with:

- `ACTIONS:` a numbered list of the concrete actions you take, in order (commands or skill invocations where applicable)
- `STOP-STATE:` what state you leave things in when you stop or hand off

Answer only from the skill text. Be complete but do not pad. Do not actually run any commands — this is a tabletop exercise. Label answers S1..S7.

## S1 — Fresh entry
You are invoked with issue #42. `gh pr list` shows exactly one open draft PR, #57, whose `closingIssuesReferences` includes #42 and whose body contains `<!-- BEGIN PLAN -->` and `<!-- END PLAN -->` exactly once each, in order. Issue #42 is finalized (no `[DRAFT]` prefix). No worktree has branch `feat-42` checked out. `.superpowers/sdd/progress.md` does not exist. What do you do, end to end, assuming execution then proceeds without incident?

## S2 — Resume
Same as S1, but `git worktree list --porcelain` shows exactly one worktree with `refs/heads/feat-42` checked out, and inside it `.superpowers/sdd/progress.md` exists showing Tasks 1-3 complete. What do you do differently from S1?

## S3 — Pre-flight conflict, first occurrence
During pre-flight you compare the rehydrated plan against issue #42 and find the plan contradicts an acceptance criterion. This is the first conflict seen. No implementation has started. What do you do?

## S4 — Pre-flight conflict persists
You already regenerated the plan once (S3) and re-ran pre-flight review; the conflict remains. No implementation has started. List every action you take before stopping.

## S5 — Mid-execution blocker
Task 4's implementer subagent returns BLOCKED: the plan specifies writing to a config file that was deleted by an earlier task per the same plan. Tasks 1-3 are committed locally but not pushed. What do you do? Be explicit about what you do NOT do.

## S6 — Successful finish
All tasks completed, final review passed, all tests pass. What are your exact finishing actions?

## S7 — Ambiguous entry
You are invoked with issue #42. Two open draft PRs (#57 and #61) both reference #42 in `closingIssuesReferences` and both contain plan markers. What do you do?
