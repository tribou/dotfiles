# Issue

## Sections, in this order

- **Problem**: closest supplied purpose/observation, then stated consequence. A need starts `Need: <desired capability>`, not a current-state negation. No reason → `Unknown: why this is wanted.`
- **Evidence**: optional.
- **Outcome**: observable result; a claim-dependent result retains its verification prerequisite.
- **Acceptance**: 2–5 checkable user-visible results, not duplicate methods. Dependent results retain `Verify <claim>; only if confirmed, <result>.` Independent requirements stay unconditional.
- **Bounds**: scope limits and non-goals.
- **Decisions**: optional.
- **References**: links to related items or design documents.

`Unknown: …` and `Assumption: …` lines go at the end, or inside the section they qualify.

## Bounds, Evidence, and Decisions

**Bounds**: scope limits and non-goals that stop the likeliest scope creep, never implementation choices.

**Evidence**: costly unlinked findings (research, data locations, schemas, field maps), compact, with supplied source/date and wording to recheck. Never fabricate provenance; a relevant link replaces copying.

**Decisions**, named exactly that:

- Only settled implementation choices; a bare request or title settles nothing.
- One compact sentence per choice, under 25 words where practical. Preserve required semantics, not its walkthrough. Avoid repeating Acceptance/Bounds; add "because" only when otherwise likely to be undone.
- Current-code claims belong in Problem/Evidence with supplied provenance and check status, never as instructions.
- A remedy justified by a current-code claim is dependent, even if approved. Render it once: `Verify <claim>; only if confirmed, <choice>.` Independently supplied mechanisms stay unconditional and verbatim.
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
<Closest supplied purpose/observation; use Need: for desired capability.>
<Stated consequence, or Unknown: why this is wanted.>

## Evidence
- <Finding> (source, date; recheck).

## Outcome
<Observable result, with its verification prerequisite if claim-dependent.>

## Acceptance
- <Independent requirement, or: Verify the claim; only if confirmed, the required result.>
- <Another one.>

## Bounds
- No <likeliest scope creep>.

## Decisions
- <Independent choice, or: Verify the claim; only if confirmed, the dependent choice.>

## References
- <link>

Unknown: <an open question that does not block starting>.
```
