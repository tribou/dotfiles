# Issue Lifecycle: Templates & `gh` Recipes

Exact commands for the draft lifecycle in `SKILL.md`. Run all `gh` commands **from inside the repo** so `gh` infers the target from the git remote — never hardcode `--repo`.

## Body Template (the living spec)

While a draft is in progress the body looks like this. Sections firm up over time; unknowns stay marked `TBD`. The `## Brainstorm log` is visible and carries the resume state.

```markdown
## Summary
<1-3 sentences: what and why — TBD until known>

## Motivation / Context
<the problem, existing overlap, why now — TBD until known>

## Requirements
- <testable requirements as they're decided>
- TBD: <open requirement>

## Non-goals
- <explicit YAGNI exclusions>

## Testing
<how it will be verified — TBD until known>

## Open decisions
<anything still undecided, or "none">

## Brainstorm log
- [x] Q: <question>? A: <answer>
- [ ] Q: <next question>?   ← next
```

Title while drafting: `[DRAFT] <type(scope): concise summary>` using the repo's commit-message convention (e.g. conventional commits).

## Entry Recipes

### Resume / adopt a given issue number

```bash
gh issue view 47 --json number,title,body
```

Read the body and the `## Brainstorm log`. Find the first unchecked `- [ ]` item — that's where you resume.

If the issue lacks the `[DRAFT]` prefix or the structured body (e.g. a placeholder you logged manually), normalize it: add the prefix and fold any existing free-text body into `## Summary` / `## Motivation`, then add a `## Brainstorm log`.

```bash
gh issue edit 47 --title "[DRAFT] <type(scope): summary>"
gh issue edit 47 --body-file /path/to/normalized-body.md
```

### Dedupe search (no number given)

Search open issues by keywords from the idea before creating anything:

```bash
gh issue list --state open --search "<keywords>"
# also check existing drafts specifically:
gh issue list --search "[DRAFT] in:title"
```

If a plausible placeholder/draft matches, **show it to the user and ask** whether to adopt `#N` or start fresh. Never silently reuse.

### Create the draft immediately (no match)

Do this before asking questions, seeded from the raw idea:

```bash
gh issue create --title "[DRAFT] <type(scope): concise summary>" --body "$(cat <<'EOF'
## Summary
TBD

## Motivation / Context
<the raw idea in the user's words>

## Requirements
- TBD

## Non-goals
- TBD

## Testing
TBD

## Open decisions
TBD

## Brainstorm log
- [ ] Q: <first clarifying question>?   ← next
EOF
)"
```

Capture the returned issue number/URL — every subsequent round edits this issue.

## Per-Answer Update (every round)

After each answer, rewrite the body: fold the answer into the relevant spec section, check off the log item, and set the next `[ ]` question. Editing the whole body is the reliable path — assemble the new body and pass it via `--body-file`:

```bash
gh issue edit 47 --body-file /path/to/updated-body.md
```

(Use the scratchpad directory for the temp body file.) Do this **every round** — a hard interruption after any answer must leave the issue current.

## Finalize → Ready

On final approval:

1. Self-review the body (placeholders, contradictions, scope, ambiguity) and fix inline.
2. Collapse the log into a `<details>` block and drop the `← next` marker:

   ```markdown
   <details>
   <summary>Brainstorm log</summary>

   - [x] Q: <question>? A: <answer>
   - [x] Q: <question>? A: <answer>

   </details>
   ```

3. Strip the `[DRAFT]` prefix and push the finalized body:

   ```bash
   gh issue edit 47 --title "<type(scope): summary>" --body-file /path/to/final-body.md
   ```

4. Show the user the issue URL for the review gate. On requested changes, edit and re-review.
5. STOP — no branch, no plan, no `writing-plans`.

## Guardrails

- No `--repo` hardcoding — run from the repo.
- Add `--label`/`--assignee`/`--milestone` only if the repo actually uses them.
- Never write under `docs/` and never invoke `writing-plans`.
