# Issue Lifecycle: `gh` Recipes & Body Shapes

Run every `gh` command from inside the repo so `gh` infers the target from the git remote — never `--repo`. Write body files in the scratchpad directory.

## Recipes

```bash
# dedupe (no number given) — both searches
gh issue list --state open --search "<keywords>"
gh issue list --search "[DRAFT] in:title"

# create (before the first question)
gh issue create --title "[DRAFT] <type(scope): summary>" --body-file <scratch>/body.md

# load / fetch the current body (with comments on resume)
gh issue view N --comments
gh issue view N --json title,body --jq .body > <scratch>/body.md

# rewrite after every reply: edit <scratch>/body.md, then
gh issue edit N --body-file <scratch>/body.md

# title changes ([DRAFT] on; stripped at handover)
gh issue edit N --title "<type(scope): summary>"

# revision: an open draft PR with a plan for #N
gh pr list --state open --draft --search "N"
```

Title: `[DRAFT] <type(scope): summary>` in the repo's commit convention.

## Body shapes

**Project** — v7's written design, in sections:

```markdown
## Intent and why
## Goals, non-goals, anti-goals
## Constraints
## How — the parts the user decided
## Left to the builder

## Brainstorm state
```

**Quick task / small change** — a short description, no required sections, then `## Brainstorm state`.

A new draft starts from the raw idea, every section empty or one line, with `Size: not sized yet`.

## `## Brainstorm state` — always the last section

While drafting:

```markdown
## Brainstorm state
Size: <not sized yet | quick task | small change | project>
Next: <exactly what is waiting on the user: a question (verbatim), a playback check (which part), the builder check's questions (verbatim, numbered), or a handover step>
<zero or more remember lines, only when true:>
Opted out of questions.
Visual companion declined.
Split: <#A (1 of N), #B (2 of N), …> — this issue is <k> of N.
Builder check: ran on this version. Questions for the user: <numbered, verbatim — removed once answered>
```

After handover (no `[DRAFT]`) there is no `Next:` line. Keep a `Split:` line. A revision in progress uses the drafting form (with `Next:`) until its fresh handover.

Project:

```markdown
## Brainstorm state
Size: project — plan it: run `issue-to-plan #N` in a fresh session.
```

Quick task / small change:

```markdown
## Brainstorm state
Size: <quick task | small change> — build it through the normal workflow, no plan:
1. Claim the issue: assign yourself and add the `in-progress` label.
2. Test-driven development.
3. Verification before completion.
4. Open a PR that closes #N.
5. No plan, no subagent-driven development.
6. If it grows: stop, update `Size:` here, and send it back through `brainstorming-to-issue #N`.
```

## Old-format conversion

Old drafts end in `## Brainstorm log` (`- [x] Q: … A: …` items, `← next` marker). On resume:
1. Confirm every `[x]` answer is in the design sections; add any that is missing, unchanged.
2. The first unchecked `[ ]` item becomes `Next:`.
3. Delete the log and add the state section.

A finalized issue from before this change with a collapsed `<details>` log keeps that log until its first revision, which converts it the same way.
