# Bug

Use when behavior differs from an established expectation.

## Sections, in this order

- **Observed**: what happens, for whom, and where. Quote the exact error text verbatim. A cause found by code inspection goes here as one line with its source, worded to check ("`X` appears to pick `Y` without checking `Z` (code inspection; recheck)"); never as a Decision.
- **Evidence**: optional. Logs, traces, and findings nothing links to.
- **Expected**: the behavior that should happen, and the basis for expecting it (a prior item, a doc, earlier behavior).
- **Reproduction**: numbered steps known to trigger it. When not known: `Unknown.` Never invent steps, environments, or versions.
- **Acceptance**: 2–5 checkable bullets: the failure is gone, working behavior is unchanged, and any agreed failure mode. Not a test list.
- **Bounds**: scope limits and non-goals.
- **Decisions**: optional.
- **References**: related items.

Bounds, Decisions, and Evidence follow `issue.md`.

`Unknown: …` and `Assumption: …` lines go at the end, or inside the section they qualify.

## Rules

- The title names the observable failure, not the fix.
- Observed is a fact about what happened. It never prescribes the fix.
- When the request names the fix, write the failure it serves and leave the fix out.
- Do not guess a root cause the input did not state. An unconfirmed cause is an `Unknown: …` line.
- Per `issue.md`, a Decision is a choice, one line, under 25 words. Cut encoding flags, write order, version notes, test lists, and brainstorm logs, even when settled.
- Keep decided identifiers verbatim (commands, env vars, paths, protocol names); delete around them, never paraphrase.

## Skeleton

```markdown
# <The failure, as observed>

## Observed
<What happens, where, for whom.> `<exact error text>`
<One line of code-inspection cause, with its source.>

## Expected
<What should happen.>

## Reproduction
1. <Known step.>

## Acceptance
- <The failure no longer occurs.>
- <Working behavior is unchanged.>

## Bounds
- No <likeliest scope creep>.

## Decisions
- <A choice settled upstream.>

## References
- <link>
```
