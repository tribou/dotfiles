# Project brief

Use for work that still needs shaping, where several issues share a problem, appetite, or shape. When upstream already settled the approach and the user wants one piece, write one issue with Decisions instead.

## Sections, in this order

- **Problem**: supplied purpose or observation and its stated consequence, with sources. A desired capability starts `Need:` rather than an invented current defect.
- **Appetite**: how much time the work is worth. When not given: `Unknown.` Never invent one.
- **Outcome**: the observable state once all of it ships.
- **Approach**: deliberately rough, a few sentences. It absorbs decided detail (named tools, backends, ordering) a clause each; no steps, requirements, or file lists.
- **Risks**: rabbit holes and hard-to-reverse effects, each with its mitigation when known.
- **No-gos**: what is explicitly out.

`Unknown: …` and `Assumption: …` lines go at the end, or inside the section they qualify.

## Rules

- Shape before slices: no child issues, phases, or task lists inside the brief.
- Cut migration sequences, requirement lists, test lists, and doc-update lists.
- About 220 words. Keep decided identifiers verbatim.

## Children

- After the brief, stop. End with an offer to derive the child issues, one proposed title per line.
- Each child is a vertical slice that delivers an observable outcome on its own. Never split by layer (DB, API, UI, tests).
- Derive children only after the user accepts the brief's shape, or a calling workflow says it is accepted. "Just file it" or a non-interactive run never accepts the shape: file the brief and stop.
- Once accepted, draft every child as an issue (`issue.md`) and show them for one batch approval; file them linked to the parent (`filing.md`).

## Skeleton

```markdown
# <Verb + the outcome>

## Problem
<Supplied purpose/observation and stated consequence, with sources; Need: for desired capability.>

## Appetite
Unknown.

## Outcome
<The observable state once it all ships.>

## Approach
<The rough shape, with decided detail.>

## Risks
- <Risk>. <Mitigation.>

## No-gos
- <Out of scope.>
```

Then, outside the brief:

```markdown
Shape accepted? I can derive these child issues:
- <Vertical slice title>
- <Vertical slice title>
```
