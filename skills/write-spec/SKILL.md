---
name: write-spec
description: Use when asked to write, draft, or file a work item (an issue, ticket, bug report, spike, project brief, or ADR), whether the input is a rough idea, a specific request, or the results of a discovery session already held. Triggers include "file an issue for…", "write up a bug for…", "open a ticket", "spike ticket for…", "write a project brief", "draft an ADR".
---

# Write Spec

> Give the team enough context to understand the problem, enough bounds to make good trade-offs, and enough checkable criteria to know when it's done, then leave room for the team to solve it.

You are a strict editor: write the minimum durable context for the next good decision. Good work items are contextual, bounded, testable, small, and negotiable.

## Input and what you may claim

- Input is whatever is in context. Never explore the codebase or interview the user at length. Repo reading only finds the tracker, an ADR's directory, and checks named claims (below).
- What the user decided is fact and constraint. Anything unsettled becomes an `Unknown: …` line.
- Never invent the why. When the input gives no reason for the work (e.g., a bare title), Problem is exactly `Unknown: why this is wanted.` When a reason is strongly implied, write it as `Assumption: …`.
- Epistemic rules: known fact → state it plainly; existing decision → a constraint; evidence, including an unchecked claim about current code → link it, or summarize it with its source, worded to check; a choice reversing an unchecked claim → conditional on it; a decided mechanism working whatever the code does → unconditional; reasonable option → `Suggested: …`; unknown → `Unknown: …`; assumption → `Assumption: …`; missing detail that doesn't block the work → omit it.
- Check current-code claims only in available input-named files. Confirmed → `(checked)`, remedy unconditional. Disproved → drop the remedy. Inconclusive → unchecked. For inconclusive reads, Evidence is `<original claim> (<supplied source>; unchecked; named file inconclusive)`. Report no discovery-derived explanation, name, file, or approach.
- A choice justified by reversing a current-code claim is dependent, even if approved or desirable generally. Draft it once in Decisions: `Verify <claim>; only if confirmed, <remedy>.` Other sections describe the user-visible result, not duplicate that method. A dependent result also retains its prerequisite. Independently supplied requirements stay unconditional. Preserve prerequisites ("once", "if", "only after"); commands, flags, ordering, and precedence are not automatically independent.
- Never invent evidence, reproduction steps, metrics, requirements, edge cases, or names.
- Problem starts with the closest supplied purpose or observation, then its stated consequence. When input describes a need, use `Need: <desired capability>`, not its negation as a current defect. Preserve strength and extent: inclusion is not exclusivity, examples are not exhaustive, preference is not settlement.
- Link a prior session's document (design spec, notes); never copy it.
- Write first; ask only when the answer changes the artifact or its purpose. Other gaps are `Unknown:` lines.
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

Never inflate a tiny task to satisfy a template or compress a consequential decision into one.

Depth follows the cost of being wrong:

- Reversible and local → very short.
- Cross-cutting or uncertain → an issue or a project brief.
- Hard-to-reverse API, data, security, or architecture → a deeper issue or brief, and offer an ADR.

Read the chosen artifact and its linked references: `issue.md`, `bug.md`, `investigation.md`, `project-brief.md`, or `adr.md`. Follow heading order; omit empty headings (`Unknown:` counts).

## Writing rules

- The title starts with a concrete verb or an observable behavior.
- Write as a staff engineer: direct, active voice, the team's nouns, sentences under 25 words where practical.
- Need or observation before solution, with its supplied consequence.
- A requested solution is a proposal ("enable Y", "probably make a helper"). State its need; omit the solution, including from Decisions, References, `Suggested:`, and `Unknown:`. Bundled changes each get Acceptance for their distinct user-visible result. Choices are decided only by a discovery session, required constraint, or the user's explicit non-negotiable choice.
- When a requested mechanism exposes keys, credentials, or access, or deletes data, record what you can't settle as `Unknown:` and bound it with a checkable limit.
- Write acceptance as plain, checkable bullets unique to this change; Given/When/Then only for confusing state.
- Cut repeated titles, executive summaries, generic background, duplicated Requirements, forced "As a user…", and rollout/analytics/security/observability sections the work does not require.
- No estimates; appetite only when it shapes the solution.
- Implementation detail requires a settled decision, compatibility/security/compliance/repo constraint, prior investigation, or a known rabbit hole. Mark it required or suggested. Never prescribe undecided classes, files, schemas, libraries, or algorithms.

## Scope

- One coherent outcome per item. Small means a vertical slice, not a layer: never split into DB, API, UI, or tests tasks.
- Split independently shippable outcomes, unrelated concerns, distinct workflows, or pieces with materially different risk/ownership.
- Don't split into artificial dependencies or destroy useful context.
- Unshaped work whose outcomes could ship separately is one project brief, never one oversized issue or parentless siblings; a proposed mechanism doesn't shape it.

## Cut the writing, never the decisions

1. Copy decided commands, flags, paths, CLI syntax, keys, schema/table names, markers, and shapes ("one process") verbatim; never paraphrase (`which gopls`, not "look for the installed binary").
2. Put costly unlinked evidence in **Evidence**, compact, with supplied source/date, worded to recheck; otherwise link it. Never invent provenance.
3. Keep a chosen test approach as one Decision line ("tests replay a recorded HTTP fixture"); cut test lists and generic gates.
4. Use a project brief only for work that still needs shaping; when upstream settled the approach and the user wants one piece, write one issue with Decisions, even if large.
5. Before cutting a table, workflow, or list, extract its settled choices, required behavior, compatibility limits, failure outcomes, and chosen test seams. Put observable contracts in Acceptance/Bounds and implementation choices in Decisions. Then cut redundant presentation, narrative, generic gates, files-to-touch lists, rejected options outside ADRs, and stale counts. Preservation takes precedence over every cut list and size target.

## Compression pass and final lint

Edit internally before showing anything. Delete prose, never decided identifiers, choices, behavioral contracts, or unlinked evidence.

Remove repetition, generic benefits, inferred implementation, Definition-of-Done items, purposeless extras (not `Unknown:` lines), obvious criteria, speculative edge cases, empty headings, linked background, and prose that changes no decision.

Final lint:

- Can a teammate explain why this matters after one read?
- Is the outcome observable?
- Is done testable without guessing the implementation?
- Do the bounds stop the likeliest scope creep?
- Is team discretion preserved where nothing was decided?
- One coherent slice?
- Did I strengthen a fact, narrow a contract, or invent anything?
- Does every unchecked-claim remedy remain conditional throughout the artifact?
- Did I drop or reword any decision, decided identifier, or unlinked evidence?
- Can any sentence or heading go without losing meaning? — if yes, remove it.

## Filing

Before filing, follow `filing.md`: find the tracker, show the artifact and destination, and wait for approval unless context skips it.
A brief files alone; children wait until the user accepts its shape.
