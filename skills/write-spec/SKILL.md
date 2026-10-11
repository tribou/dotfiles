---
name: write-spec
description: Use when asked to write, draft, or file a work item (an issue, ticket, bug report, spike, project brief, or ADR), whether the input is a rough idea, a specific request, or the results of a discovery session already held. Triggers include "file an issue for…", "write up a bug for…", "open a ticket", "spike ticket for…", "write a project brief", "draft an ADR".
---

# Write Spec

> Give the team enough context to understand the problem, enough bounds to make good trade-offs, and enough checkable criteria to know when it's done, then leave room for the team to solve it.

Good work items are contextual, bounded, testable, small, and negotiable. You are a strict editor: write the minimum durable context needed for the next good decision. Spare context-window capacity is never a reason to write more.

## Input and what you may claim

- Input is whatever is in context: a rough idea, a specific request, or the output of a discovery session. Do not read the codebase or interview the user to ground content. The only repo reading is finding the tracker (`filing.md`).
- What the user said or decided is fact and constraint. Anything unsettled becomes an `Unknown: …` line.
- Never invent the why. When the input gives no reason for the work (for example, a bare title), Problem is exactly `Unknown: why this is wanted.` When a reason is strongly implied, write it as `Assumption: …`.
- Epistemic rules:
  - Known fact → state it plainly.
  - Existing decision → state it as a constraint.
  - Evidence → link it, or summarize it with its source.
  - Reasonable option → label it as an option.
  - Unknown → `Unknown: …`.
  - Assumption → `Assumption: …`.
  - Missing detail that doesn't block the work → omit it.
- Never invent evidence, reproduction steps, metrics, requirements, edge cases, names, or the reason for the work to make the item look complete.
- When a prior session produced a document (design spec, notes), link to it instead of copying it.
- Write first. Stop to ask only when the answer would change which artifact this is or what it is for (for example, a "fix" that may really be a new feature). Every other gap is an `Unknown:` line.
- One invocation produces one artifact. The only exceptions are a project brief's children and an offered ADR.

## Choose the smallest sufficient artifact

| Artifact | Use when |
|---|---|
| tiny-task | obvious, reversible, low-risk |
| issue (default) | a normal independently executable change |
| bug | behavior differs from an established expectation |
| investigation | the primary output is learning or a decision |
| project-brief | work that still needs shaping, where several issues share a problem, appetite, or shape |
| adr | a consequential, hard-to-reverse technical decision |

A tiny task is a title and a completion condition, with no headings:

```markdown
# <Concrete verb + object>

Done when <observable condition>.
```

Never expand a tiny task into an issue to satisfy a template. Never compress a consequential decision into a one-line task.

Detail is proportional to the cost of being wrong:

- Reversible and local → very short.
- Cross-cutting or uncertain → an issue or a project brief.
- Hard-to-reverse API, data, security, or architecture → a deeper brief, plus an offered ADR. Write the primary artifact, say an ADR is warranted, and offer to write it. Never produce both silently.

Read only the chosen artifact's reference file. Use its headings in its order; render a heading only if it has content.

- issue → `issue.md`
- bug → `bug.md`
- investigation → `investigation.md`
- project-brief → `project-brief.md`
- adr → `adr.md`

## Writing rules

- The title starts with a concrete verb or an observable behavior.
- Keep sentences under about 25 words where practical. Use direct, active voice and the team's own nouns.
- Problem before solution: state what's wrong and for whom. Keep the how negotiable unless it is already decided.
- A solution in the request is a proposal, not a decision, however firmly it is phrased ("store it in X", "enable Y in the config", "probably make a helper for it"). Write the problem it serves and leave the solution out entirely, not parked in References or an `Unknown:` line ("add Redis caching" → slow account history). It is decided only when the input says so: a discovery session settled it, a constraint requires it, or the user calls it non-negotiable.
- When the change carries an obvious risk (for example, security exposure), bound it with a checkable limit and mark what you can't settle `Unknown:`.
- Write acceptance as plain, checkable bullets covering what is unique to this change. Use Given/When/Then only when state is genuinely confusing.
- Voice: a strong staff engineer writing for teammates, not a consultant. Use "As a user…" only when the persona adds information.
- Never write: a repeat of the title, an executive summary, generic background, "Requirements" that restate Acceptance, Definition-of-Done items (tests pass, lint, CI, docs, review), a forced "As a user…", exhaustive edge cases, or rollout, analytics, security, or observability sections unless the work materially requires one.
- Keep estimates out of prose. Add appetite only when it shapes the solution.
- Implementation detail appears only when an architecture decision exists, compatibility, security, compliance, or a repo convention requires it, prior investigation resolved it, or it avoids a known rabbit hole. Mark each as a required constraint or a suggested approach. Never prescribe classes, files, schemas, components, libraries, or algorithms that were not already decided.

## Scope

- One coherent outcome per item. Small means a vertical slice, not a layer: never split into DB, API, UI, or tests tasks.
- Split when independent outcomes can ship or validate separately, unrelated concerns are joined, acceptance describes several distinct workflows, or pieces differ materially in risk or ownership.
- Don't split when splitting creates artificial dependencies or destroys useful context. Parts that depend on each other stay in one item.
- A request that needs splitting into independent outcomes becomes one project brief, never a set of parentless sibling issues.

## Cut the writing, never the decisions

Compress by deleting, never by paraphrasing. Decisions, decided identifiers, and unlinked evidence survive every cut.

## Compression pass and final lint

Run this internally before showing anything. The user sees only the edited artifact.

Remove repeated intent, generic benefits, inferred implementation, Definition-of-Done items, requested extras with no stated purpose (cut them; don't turn them into `Unknown:` lines), obvious acceptance criteria, speculative edge cases, empty headings, background available via a link, and prose that doesn't change a decision. Never reword a decided identifier. Never remove a decision or unlinked evidence.

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

Finding the tracker, approval before filing, and how each artifact lands: `filing.md`. With no tracker, the markdown artifact is the final output.
