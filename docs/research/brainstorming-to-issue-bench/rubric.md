# Grading rubric (grader-only; 30 checks total)

## S1 (9 checks)
1. Runs the dedupe search of open issues (including a `[DRAFT] in:title` check) BEFORE creating anything
2. Creates the `[DRAFT]` issue immediately — before asking any clarifying question — seeded from the raw idea with the mostly-TBD template body
3. Invokes `superpowers:brainstorming` for the dialogue (steps 1-5), one question at a time with the user — not self-answered in a single pass
4. Updates the issue body after EVERY answer (fold answer into section, check off log item, set next `[ ]` question) — not batched to the end
5. Presents the design and gets explicit user approval before finalizing
6. On approval: runs the spec self-review on the issue body (placeholders/TBDs, contradictions, scope, ambiguity)
7. Strips the `[DRAFT]` prefix AND collapses `## Brainstorm log` into a `<details>` block
8. Shows the user the issue URL and asks them to review (spec review gate)
9. Stops — no `docs/` spec file, no commit, no `writing-plans`, no implementation

## S2 (3 checks)
1. Loads the issue (`gh issue view 47`) and reads the body + `## Brainstorm log`
2. Resumes from the first unchecked `- [ ]` item (the retryable-errors question) — does not restart the dialogue or re-ask answered questions
3. Continues per-answer persistence (issue body updated every round from here on)

## S3 (4 checks)
1. Surfaces the found issue #52 to the user and ASKS whether to adopt it or start fresh
2. Does NOT silently reuse #52 and does NOT silently create a duplicate
3. On adopt: normalizes #52 — adds the `[DRAFT]` prefix and folds the existing one-line body into the structured template (Summary/Motivation + Brainstorm log)
4. Only then resumes the loop from the next open question

## S4 (4 checks)
1. States that the issue body must ALREADY contain the third answer (persistence happens immediately after each answer, so nothing extra is owed)
2. The next open question is set as the unchecked `- [ ]` resume marker
3. No spec state exists only in the conversation
4. Leaves the issue as `[DRAFT]` (no premature finalization) — resumable as-is

## S5 (5 checks)
1. Spec self-review on the issue body: placeholders/TBDs, contradictions, scope creep, ambiguity — fixed inline
2. Strips the `[DRAFT]` prefix from the title
3. Collapses `## Brainstorm log` into a `<details>` block (dropping the `← next` marker)
4. Shows the user the issue URL and asks them to review; on requested changes, edits and re-runs the self-review
5. STOPS — does not branch, plan, invoke `writing-plans`, or implement

## S6 (3 checks)
1. Does NOT write the `docs/superpowers/specs/` file and does NOT commit a spec doc
2. Does NOT invoke `superpowers:writing-plans`
3. States the GitHub issue is the spec's only home (persistence override), and proceeds with the issue-based finalize instead

## S7 (2 checks)
1. Declines to put an implementation plan in the issue and does NOT invoke `writing-plans` (out of scope for this skill; a later plan lives in a PR description, never in this issue)
2. Does NOT reopen/extend the finalized spec with plan content

Score = passed checks / 30. Correctness gate: a variant is acceptable only if score >= baseline - 1 check (no material regression), with zero failures on "forbidden action" checks (S1.9, S3.2, S5.5, S6.2, S7.1).
