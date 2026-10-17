---
name: write-spec
description: Use when asked to write, draft, or file a work item (an issue, ticket, bug report, spike, project brief, or ADR), whether the input is a rough idea, a specific request, or the results of a discovery session already held. Triggers include "file an issue for…", "write up a bug for…", "open a ticket", "spike ticket for…", "write a project brief", "draft an ADR".
---

# Write Spec

> Give the team enough context to understand the problem, enough bounds to make good trade-offs, and enough checkable criteria to know when it's done, then leave room for the team to solve it.

Good work items are contextual, bounded, testable, small, and negotiable. You are a strict editor: write the minimum durable context needed for the next good decision. Spare capacity is no reason to write more.

## Input and what you may claim

- Input is whatever is in context, from a rough idea to a discovery session's output. Never explore the codebase or interview the user at length to ground content. Repo reading only finds the tracker and an ADR's directory, and checks claims (below).
- What the user decided is fact and constraint. Anything unsettled becomes an `Unknown: …` line.
- Never invent the why. When the input gives no reason for the work (e.g., a bare title), Problem is exactly `Unknown: why this is wanted.` When a reason is strongly implied, write it as `Assumption: …`.
- Epistemic rules: known fact → state it plainly; existing decision → a constraint; evidence, including an unchecked claim about current code → link it, or summarize it with its source, worded to check; a choice reversing an unchecked claim → conditional on it; a decided mechanism working whatever the code does → unconditional; reasonable option → `Suggested: …`; unknown → `Unknown: …`; assumption → `Assumption: …`; missing detail that doesn't block the work → omit it.
- Check claims about current code. When the input says what the code does now (a load order, an ignored flag) and that code is in the working directory, read only the files the claim names. Confirmed → a fact marked `(checked)`; a choice reversing it is unconditional. No longer true → drop that choice; one Evidence line says so. Can't tell, or no code → unchecked. Add nothing else you read: no new files, names, or approach.
- Never invent evidence, reproduction steps, metrics, requirements, edge cases, or names.
- Link a prior session's document (design spec, notes); never copy it.
- Write first. Stop to ask only when the answer would change which artifact this is or what it is for (e.g., a "fix" that may be a new feature). Every other gap is an `Unknown:` line.
- One invocation, one artifact, except a brief's children and an offered ADR.

## Choose the smallest sufficient artifact

| Artifact | Use when |
|---|---|
| tiny-task | obvious, reversible, low-risk |
| issue (default) | a normal independently executable change |
| bug | behavior differs from an established expectation |
| investigation | the primary output is learning or a decision |
| project-brief | work that still needs shaping, where several issues share a problem, appetite, or shape |
| adr | a consequential, hard-to-reverse technical decision |

A tiny task is a title and completion condition, no headings:

```markdown
# <Concrete verb + object>

Done when <observable condition>.
```

Never expand a tiny task into an issue to satisfy a template. Never compress a consequential decision into a one-line task.

Detail is proportional to the cost of being wrong:

- Reversible and local → very short.
- Cross-cutting or uncertain → an issue or a project brief.
- Hard-to-reverse API, data, security, or architecture → a deeper issue or brief, and offer an ADR.

Read only the chosen artifact's file and files it names: `issue.md`, `bug.md`, `investigation.md`, `project-brief.md`, or `adr.md`. Use its headings, in order; render a heading only if it has content (an `Unknown:` line counts).

## Writing rules

- The title starts with a concrete verb or an observable behavior.
- Write as a strong staff engineer, not a consultant: direct, active voice, the team's own nouns, sentences under 25 words.
- Problem before solution: state what's wrong and for whom.
- A solution in the request or title is a proposal, however phrased ("enable Y in the config", "probably make a helper"). Write the problem it serves and leave the solution out entirely, not parked in Decisions, References, `Suggested:`, or `Unknown:` lines ("add Redis caching" → slow account history). When the proposal bundles changes in separate places, give each its own Acceptance bullet for the user-visible result it alone delivers. It is decided only when a discovery session settled it, a constraint requires it, or the user calls it non-negotiable.
- When a requested mechanism exposes keys, credentials, or access, or deletes data, record what you can't settle as `Unknown:` and bound it with a checkable limit.
- Write acceptance as plain, checkable bullets unique to this change; Given/When/Then only for confusing state.
- Never write: a repeat of the title, an executive summary, generic background, "Requirements" that restate Acceptance, a forced "As a user…", or rollout, analytics, security, or observability sections unless the work requires one.
- No estimates; appetite only when it shapes the solution.
- Implementation detail appears only when an architecture decision exists, compatibility, security, compliance, or a repo convention requires it, prior investigation resolved it, or it avoids a known rabbit hole. Mark it required or suggested. Never prescribe undecided classes, files, schemas, libraries, or algorithms.

## Scope

- One coherent outcome per item. Small means a vertical slice, not a layer: never split into DB, API, UI, or tests tasks.
- Split when independent outcomes can ship or validate separately, unrelated concerns are joined, acceptance describes several distinct workflows, or pieces differ materially in risk or ownership.
- Don't split when splitting creates artificial dependencies or destroys useful context.
- Unshaped work whose outcomes could ship separately is one project brief, never one oversized issue or parentless siblings; a proposed mechanism doesn't shape it.

## Cut the writing, never the decisions

1. Copy decided identifiers verbatim (commands, flags, file paths, CLI syntax, config keys, schema and table names, marker strings) and decided shapes ("one process"), in the input's own words; compress by deleting, never by paraphrasing (`which gopls`, never "look for the installed binary").
2. Put costly evidence nothing links to in **Evidence**, compact, with source and date, worded as things to recheck; otherwise link it.
3. Keep a chosen test approach as one Decision line ("tests replay a recorded HTTP fixture"); cut test lists and generic gates.
4. Use a project brief only for work that still needs shaping; when upstream settled the approach and the user wants one piece, write one issue with Decisions, even if large.
5. Apply word targets to prose only; never trim a decision (one line: the choice, not how it plays out) or unlinked evidence to meet them. In every section, cut narrative, brainstorm logs, rejected options outside ADRs, step-by-step flows, error tables, doc-update, files-to-touch, test and gate lists, even if settled, repetition, and counts that go stale.

## Compression pass and final lint

Run this internally before showing anything. It deletes; it never rewords a decided identifier and never removes a decided choice or unlinked evidence.

Remove repeated intent, generic benefits, inferred implementation, Definition-of-Done items, requested extras with no stated purpose (cut them; don't turn them into `Unknown:` lines), obvious acceptance criteria, speculative edge cases, empty headings, background available via a link, and prose that doesn't change a decision.

Final lint:

- Can a teammate explain why this matters after one read?
- Is the outcome observable?
- Is done testable without guessing the implementation?
- Do the bounds stop the likeliest scope creep?
- Is team discretion preserved where nothing was decided?
- One coherent slice?
- Did I invent anything?
- Did I drop or reword any decision, decided identifier, or unlinked evidence?
- Can any sentence or heading go without losing meaning? — if yes, remove it.

## Filing

Before filing, follow `filing.md`: find the tracker, show the artifact and destination, and wait for approval unless context skips it.
A brief files alone; children wait until the user accepts its shape.
