# Issue

## Sections, in this order

- **Problem**: what is wrong and for whom, with no solution. With no stated reason: `Unknown: why this is wanted.`
- **Evidence**: optional.
- **Outcome**: the observable state once this is done.
- **Acceptance**: 2–5 checkable bullets unique to this change.
- **Bounds**: scope limits and non-goals.
- **Decisions**: optional.
- **References**: links to related items or design documents.

`Unknown: …` and `Assumption: …` lines go at the end, or inside the section they qualify.

## Bounds, Evidence, and Decisions

**Bounds**: scope limits and non-goals that stop the likeliest scope creep, never implementation choices.

**Evidence**: costly findings the builder needs that nothing links to (research results, data locations, schemas, field maps), compact. Give each its source and date, worded to recheck; with a link, link instead.

**Decisions**, named exactly that:

- Only implementation choices settled upstream (a discovery session, a required constraint, or the user calling it decided); a bare request or title settles nothing.
- One sentence per decision, under 25 words: the choice, not how to carry it out, even if settled upstream. Add a "because" only when non-obvious and likely to be undone.
- A decision is a choice ("do X", "put Y in Z"), never a claim about the current code ("the loader is broken", "X runs last"). Claims go stale: put them in Problem or Evidence with their source, worded to check, not obey.
- A choice whose point is reversing a claimed state of the current code, even one settled in a linked issue, opens with that claim as its condition: "if the token still expires early, fix the TTL first". A decided mechanism (a command, flag, or check) working whatever the code does stays unconditional and verbatim, even if it cures a claimed defect.
- A suggested approach is not a decision: omit it, or end the item with one `Suggested: …` line.
- A hard-to-reverse settled detail goes in an offered ADR, not here.

## Default targets

- About 100–250 words of prose.
- At most 5 prose headings.
- 2–5 acceptance criteria.

The targets apply to Problem, Outcome, Acceptance, and Bounds only; never trim Decisions or Evidence to meet them.

Bounds and References should often disappear.

## Skeleton

```markdown
# <Concrete verb + observable outcome>

## Problem
<What is wrong, and for whom.>

## Evidence
- <Finding> (source, date; recheck).

## Outcome
<The observable state once this is done.>

## Acceptance
- <A checkable behavior unique to this change.>
- <Another one.>

## Bounds
- No <likeliest scope creep>.

## Decisions
- <A choice settled upstream.>

## References
- <link>

Unknown: <an open question that does not block starting>.
```
