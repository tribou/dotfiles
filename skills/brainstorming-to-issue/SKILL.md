---
name: brainstorming-to-issue
description: Use when brainstorming a feature or change whose written design should live in a GitHub issue instead of a docs/ file — including starting, pausing, and resuming a brainstorm across sittings or harnesses, and revising an issue already handed over. Triggers include "brainstorm this into an issue", "spec it out as a GitHub issue", "file an issue for this feature", "continue/resume brainstorming issue #N", "pick up the draft brainstorm", "brainstorming-to-issue #N".
---

# Brainstorming Into a GitHub Issue

## Core principle

**REQUIRED SUB-SKILL:** run `superpowers:brainstorming` (v7) as written. This skill is the "human partner's preference" v7 allows: the written design lives in a GitHub issue, not `docs/`. It adds only what v7 lacks: persistence to the issue, resume from the issue alone (any session, any harness), the `[DRAFT]` title prefix ("still being brainstormed"), and splits. Do not restate or reinterpret v7's dialogue, playbacks, sizing, spikes, visual companion, design shape, or builder check — follow them.

Exact `gh` commands, body shapes, and the `## Brainstorm state` section: `issue-lifecycle.md`.

## Entry

**No number given:**
1. Search open issues by keywords.
2. Search `[DRAFT] in:title`.
3. Plausible match → show it and ask: adopt #N or start fresh? Never reuse or duplicate silently.
4. No match (or "fresh") → create the `[DRAFT]` issue, ending in a state section, before the first question; its `Next:` is the opening question.
5. Send v7's opening message — unless v7's first check finds a quick, clear task: then write the request as the issue, size it `quick task`, and hand over instead (no opening question; build only when asked).

**Number given:** load it with `gh issue view N --json title,body,comments`, then route:

| The issue has | Route |
|---|---|
| `[DRAFT]` + `## Brainstorm state` | Resume |
| `[DRAFT]` + old `## Brainstorm log` or `<details>` log | Convert it (`issue-lifecycle.md`), then resume |
| `[DRAFT]` + neither (sent back before it was ever brainstormed) | Add a state section, keeping the body as it is, then resume; with no conflict comment (below), continue at Entry step 5 |
| no `[DRAFT]` + a state section or an old `<details>` log | Revision (a `Next:` line means one is in progress: resume it) |
| no `[DRAFT]` + neither | A placeholder: on adopt, add `[DRAFT]`, fold its body into the design, add a state section, then continue at Entry step 5 |

On any `[DRAFT]` resume, read the latest comments (by `createdAt`). A `plan-to-implementation` conflict comment not yet reflected in `Next:` or the design sets `Next:` to "resolve these conflicts with the user"; then run all 5 Revision steps below (it keeps `[DRAFT]` until the handover strips it).

## Persistence

As soon as **each** user reply arrives, before anything else (so a hard stop at any moment owes nothing):
1. Fetch the current body.
2. Rewrite it from that body, never from conversation memory: put the outcome into the matching design section.
3. Set `Next:` to exactly what your next message waits on (and add any remember line that just became true); if what your message waits on changes before you send it, push again.
4. Push the body.

When you tell the user the size in plain words (v7's Size the Work), record it as `Size:` in the same rewrite. Save outcomes only. The design sections carry v7's marks: a guess is marked as my guess, a choice I made as my call, and only what the user said goes in unmarked. Do not save playback text, Q&A logs, decision history, or quotes of the user. Redo cheap work instead of saving it mid-way: recon, an unfinished builder check, the companion server.

## Resume

Never re-ask anything settled; a line marked as my guess stays a guess until the user confirms it. Act on `Next:`:
- a question → re-ask it verbatim
- a playback → re-present it, rebuilt from the design sections
- builder-check questions → re-ask them verbatim, in one message; never re-run the check; once answered, update the design and hand over
- a handover step → redo it
- `re-brainstorm — grew from <size>: <what was added>` → run all 5 Revision steps, scoped to what was added

Honor the remember lines (`Opted out of questions.`, `Visual companion declined.`, `Split:`). Persistence continues after every reply.

## Harness gaps

No subagent tool: read the issue as the builder yourself. No browser: describe the choices in text. Write visual-companion selections and spike lessons into the design in words.

## Builder check — projects only

Point `builder-check-prompt.md`'s document at the issue: "Read issue #N with `gh issue view N --json title,body`." Record the result in the state section (`Builder check: ran on this version. Questions for the user: …`); remove each question once answered.

## Handover — the only override of v7's ending

No `docs/` spec, no commit, no `writing-plans`. Where v7 hands over the document (project) or has the description approved (quick task, small change), do all 6 steps, in order:
1. Check the body has the size's shape: a project's written design, or for a quick task or small change a short description with no required sections (and no builder check).
2. Strip `[DRAFT]` from the title.
3. Reduce the state section to the post-handover form for the size.
4. Give the issue link + the list of my calls.
5. Give the size's handover line:
   - project: "Run `issue-to-plan #N` in a fresh session."
   - quick task / small change: "Implement #N directly, no plan", then the build steps from the state section.
6. Stop (for a split, first offer the next sibling). There is no further review; running the next step is the approval. Changes come back through `brainstorming-to-issue #N`.

## Opt-out

When the user opts out of the questions (at the opening or later): write the issue from the request, keeping any answers so far; mark my calls; size it; add `Opted out of questions.`; hand over. No builder check, even for a project.

## Revision

1. Never re-add `[DRAFT]`. An old `<details>` log is converted now (`issue-lifecycle.md`). Until the fresh handover, the state section takes the drafting form, `Next:` included, and persistence runs as usual.
2. Run a v7 conversation scoped to what the user wants changed; play back the changed parts only.
3. A project whose design changed gets a fresh builder check on the new version.
4. Re-size, then hand over again with an updated list of my calls.
5. If an open draft PR #M carries a plan for the issue, say in the handover that its plan is now stale, and make the handover line "close draft PR #M, then run `issue-to-plan #N` in a fresh session." Do not edit or close the PR or the plan yourself.

## Same-session build

A quick task or small change may be built in this session when the user asks, following the issue's build steps; starting the build counts as approval. Projects never are: point to `issue-to-plan #N` in a fresh session.

## Splits

When v7 finds several independent projects and you agree an order: give each its own `[DRAFT]` issue with the `Split:` line on each, and brainstorm them one at a time. After a handover, offer the next sibling (the user may stop and resume it with `brainstorming-to-issue #next`). A real build dependency between siblings goes into each design as a constraint. Splitting a body for the 65k limit needs the user's agreement.

## Guardrails

- GitHub issues via `gh` only; run from the repo; never `--repo`.
- Never compress, drop, or paraphrase recorded content. If a body nears 65,536 characters, ask the user to split.
