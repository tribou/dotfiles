# Coordinator Decision Benchmark — brainstorming-to-issue

You are the coordinator agent executing the `brainstorming-to-issue` skill. The full skill text has been provided to you; the corpus includes the wrapper skill (`brainstorming-to-issue`) and the v7 `brainstorming` skill it delegates to. For EACH scenario below, answer with:

- `ACTIONS:` a numbered list of the concrete actions you take, in order (commands, messages to the user, or skill invocations where applicable)
- `STOP-STATE:` what state you leave things in when you stop or hand off

Answer only from the skill text. Be complete but do not pad. Do not actually run any commands — this is a tabletop exercise. Label answers S1..S15.

## S1 — Fresh project, end to end
The user says: "brainstorm a retry-with-backoff wrapper for our HTTP helpers into an issue." No issue number is given. Assume your search of open issues finds no plausible match. The conversation then runs over several of the user's replies, and it turns out to be a project. The builder check comes back with two questions that only the user can answer, and the user answers them. What do you do, end to end, from the user's first message until you stop?

## S2 — Resume a pending playback
The user says: "continue brainstorming issue 47." Issue #47 is titled `[DRAFT] feat(http): retry with backoff`; its design sections describe what the wrapper is for and how retries are scheduled, and its body ends with:

```markdown
## Brainstorm state
Size: not sized yet
Next: playback check — how retries are scheduled
Visual companion declined.
```

What do you do?

## S3 — Plausible existing match
The user says: "spec out request retries as a GitHub issue." No number given. Your dedupe search finds open issue #52, "add retries someday", with a one-line body, no `[DRAFT]` prefix, and no `## Brainstorm state` section. What do you do?

## S4 — Hard interruption
You are mid-brainstorm on `[DRAFT]` issue #47. The user has just answered your third question and immediately says they have to leave right now. What must already be true at this exact moment, and what (if anything) do you do before ending?

## S5 — Small change, description confirmed
`[DRAFT]` issue #47 ("log the request id on retry") has been sized a small change and its state section says `Size: small change`. You played back the short description and the user has just said the description is right. List every action you take from this moment until you stop.

## S6 — v7 ending pull
You have reached the end of the v7 `brainstorming` conversation for project #47. v7's text now directs you to write `docs/superpowers/specs/2026-10-10-retry-design.md`, commit it, and invoke `writing-plans`. What do you do?

## S7 — Opt-out on a project-sized request
You are brainstorming "add multi-tenant support to the job scheduler" into `[DRAFT]` issue #47, which clearly needs a written design. The user's first reply to your opening message is: "skip the questions, just write it up." What do you do until you stop?

## S8 — Resume with pending builder-check questions
The user says: "continue brainstorming issue 47." `[DRAFT]` issue #47 has a full written design and its body ends with:

```markdown
## Brainstorm state
Size: project
Next: the builder check's two questions below
Builder check: ran on this version. Questions for the user:
1. Should retries apply to non-idempotent POST requests?
2. What is the longest total time a caller should wait across all retries?
```

What do you do, until you stop?

## S9 — Resume an old-format draft
The user says: "continue brainstorming issue 61." `[DRAFT]` issue #61 has `## Summary` and `## Requirements` sections and ends with an old `## Brainstorm log`:

```markdown
## Brainstorm log
- [x] Q: Which helpers get retries? A: fetchJson and postJson
- [x] Q: How many attempts? A: 3
- [x] Q: Should the delay use jitter? A: yes, full jitter
- [ ] Q: Which errors are retryable?   ← next
```

The helpers and the attempt count appear in `## Requirements`; the jitter answer appears nowhere in the sections. No `## Brainstorm state` section exists. What do you do?

## S10 — Change request on a handed-over project
The user says: "brainstorming-to-issue #47 — retries should also cover HTTP 429." Issue #47 is titled `feat(http): retry with backoff` (no `[DRAFT]`) and its body ends with:

```markdown
## Brainstorm state
Size: project — plan it: run `issue-to-plan #47` in a fresh session.
```

An open draft PR #60 already carries an implementation plan for #47. What do you do, until you stop?

## S11 — Sent back by plan-to-implementation
The user says: "continue brainstorming issue 47." Issue #47 is titled `[DRAFT] feat(http): retry with backoff`; it was handed over earlier, and `plan-to-implementation` has since closed its draft PR, re-added `[DRAFT]` to the title, and commented. The body holds a full written design and ends with:

```markdown
## Brainstorm state
Size: project — plan it: run `issue-to-plan #47` in a fresh session.
```

The issue's latest comment, posted by `plan-to-implementation` after the body's last edit, lists two conflicts: the design caps retries at 3 attempts but also says "retry until the deadline", and the design logs every attempt while the non-goals exclude logging changes. What do you do, until you stop?

## S12 — Several projects in one request
The user says: "brainstorm a CLI, a web dashboard, and a billing integration into issues." No number given; the dedupe search finds nothing. These turn out to be three independent projects. What do you do?

## S13 — Building after handover
(a) You have just handed over small change #47 ("log the request id on retry"). The user says: "build it now." Midway through the build they add: "also add a metrics dashboard for retry rates." What do you do?

(b) Separately, you have just handed over project #47. The user says: "while it's fresh, just start building it here." What do you do?

## S14 — Sent back after growing mid-build
The user says: "continue brainstorming issue 47." Issue #47 is titled `feat(http): log the request id on retry` (no `[DRAFT]`). It was handed over as a small change; midway through the build the user asked to add a metrics dashboard for retry rates, so the build stopped and sent the issue back. Its short description of the request-id logging is unchanged, and its body ends with:

```markdown
## Brainstorm state
Size: not sized yet
Next: re-brainstorm — grew from small change: a metrics dashboard for retry rates
```

The user's replies go on to show that the dashboard makes #47 a project. What do you do, until you stop?

## S15 — Sent back, never brainstormed
The user says: "continue brainstorming issue 70." Issue #70 is titled `[DRAFT] feat(cache): add a TTL to the response cache`. It was written by hand before this skill existed: its body has `## Problem` and `## Acceptance criteria` sections and no `## Brainstorm state` section or log of any kind. `issue-to-plan` planned it; `plan-to-implementation` then closed the draft PR, re-added `[DRAFT]` to the title, and commented. The issue's latest comment, posted by `plan-to-implementation` after the body's last edit, lists one conflict: the acceptance criteria require a TTL per route, while the problem statement asks for one global TTL. What do you do, until you stop?
