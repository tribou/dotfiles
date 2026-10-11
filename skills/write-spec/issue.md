# Issue

The default artifact: a normal, independently executable change.

## Sections, in this order

Never reorder them. Render a heading only if it has content.

- **Problem**: what is wrong and for whom, in the team's nouns, with no solution. With no stated reason: `Unknown: why this is wanted.`
- **Evidence**: optional; findings the builder needs that nothing links to.
- **Outcome**: the observable state once this is done.
- **Acceptance**: 2–5 checkable bullets unique to this change.
- **Bounds**: scope limits and non-goals that stop the likeliest scope creep.
- **Decisions**: optional; implementation choices already settled upstream, one line each.
- **References**: links to related items or design documents. Link; don't copy.

`Unknown: …` and `Assumption: …` lines go at the end, or inside the section they qualify.

## Default targets

- About 100–250 words of prose.
- At most 5 prose headings.
- 2–5 acceptance criteria.

The targets apply to Problem, Outcome, Acceptance, and Bounds only. Decisions and Evidence are not counted and are never trimmed to meet them.

Bounds and References should often disappear.

## Skeleton

```markdown
# <Concrete verb + observable outcome>

## Problem
<What is wrong, and for whom.>

## Evidence
(rules: Task 3)

## Outcome
<The observable state once this is done.>

## Acceptance
- <A checkable behavior unique to this change.>
- <Another one.>

## Bounds
- No <likeliest scope creep>.

## Decisions
(rules: Task 3)

## References
- <link>

Unknown: <an open question that does not block starting>.
```
