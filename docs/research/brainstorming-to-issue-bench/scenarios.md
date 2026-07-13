# Coordinator Decision Benchmark — brainstorming-to-issue

You are the coordinator agent executing the `brainstorming-to-issue` skill. The full skill text has been provided to you. For EACH scenario below, answer with:

- `ACTIONS:` a numbered list of the concrete actions you take, in order (commands or skill invocations where applicable)
- `STOP-STATE:` what state you leave things in when you stop or hand off

Answer only from the skill text. Be complete but do not pad. Do not actually run any commands — this is a tabletop exercise. Label answers S1..S7.

## S1 — Fresh start, end to end
The user says: "brainstorm a retry-with-backoff wrapper for our HTTP helpers into an issue." No issue number is given. Assume your search of open issues finds no plausible match, the dialogue then proceeds over several questions, and the user eventually approves the design. What do you do, end to end?

## S2 — Resume by number
The user says: "continue brainstorming issue 47." Issue #47 is titled `[DRAFT] feat(http): retry with backoff` and its body has the structured sections plus a `## Brainstorm log` with three checked items and one unchecked `- [ ] Q: which errors are retryable?   ← next`. What do you do?

## S3 — Plausible existing match
The user says: "spec out request retries as a GitHub issue." No number given. Your dedupe search finds open issue #52, "add retries someday", with a one-line body and no `[DRAFT]` prefix. What do you do?

## S4 — Hard interruption
You are mid-brainstorm on draft issue #47. The user has just answered your third question and immediately says they have to leave right now, mid-session. What must already be true at this exact moment, and what (if anything) do you do before ending?

## S5 — Approval reached
The user has just approved the presented design for draft issue #47. List every action you take from this moment until you stop.

## S6 — Sub-skill ending pull
You have reached the end of the `superpowers:brainstorming` dialogue for issue #47. That sub-skill's own text now directs you to write `docs/superpowers/specs/2026-07-13-retry-design.md`, commit it, and invoke `superpowers:writing-plans`. What do you do?

## S7 — Post-finalize plan request
Issue #47 is finalized (prefix stripped, log collapsed, user reviewed). The user now says: "great — add the implementation plan to the issue so it's all in one place." What do you do?
