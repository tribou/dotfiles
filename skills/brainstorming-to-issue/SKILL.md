---
name: brainstorming-to-issue
description: Use when brainstorming a feature or change whose spec should land in a GitHub issue instead of a docs/ file — the issue becomes the durable spec and implementation happens separately later. Triggers include "brainstorm this into an issue", "spec it out as a GitHub issue", "file an issue for this feature", "capture the spec in an issue".
---

# Brainstorming Into a GitHub Issue

## Overview

Reuse the full `superpowers:brainstorming` dialogue, but persist the approved spec as a **GitHub issue** instead of a `docs/` file. The issue IS the spec — the durable "what/why" contract. This skill ends the moment the issue exists; implementation is a separate, later concern.

**Core principle:** brainstorming's *dialogue* is medium-agnostic and reused unchanged. Only its *persistence* (steps 6-9) is overridden.

## When to Use

- You want a spec captured somewhere trackable and linkable, not buried in `docs/`.
- Building will happen later or by someone/something else — the issue is the handoff.

**When NOT to use:** you're about to implement immediately in this same session with no need for a durable spec artifact (use `superpowers:brainstorming` directly), or the spec belongs in a versioned design doc.

## The Process

**REQUIRED SUB-SKILL:** Run `superpowers:brainstorming` for the dialogue — steps 1-5 exactly as written: explore context, clarifying questions **one at a time**, propose 2-3 approaches, present the design in sections, get **user approval**. Do NOT collapse this into a single self-answered pass; the one-question-at-a-time HIL loop is the point.

Then **DIVERT** — do not follow brainstorming's own steps 6-9.

<HARD-OVERRIDE>
`superpowers:brainstorming` ends by writing `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`, committing it, and invoking `writing-plans`. When using THIS skill you do NONE of that:

- Do NOT write a spec file under `docs/`.
- Do NOT commit a spec doc.
- Do NOT invoke `writing-plans`. There is no plan step here.

The spec's only home is the GitHub issue.
</HARD-OVERRIDE>

## After Design Approval: Create the Issue

1. **Spec self-review** (from brainstorming, applied to the issue body): scan for placeholders/TBDs, internal contradictions, scope creep, and ambiguous requirements. Fix inline.
2. **Create the issue** from inside the repo so `gh` infers the target repo from the git remote — do NOT hardcode `--repo`. Title uses the repo's commit-message convention (e.g. conventional commits: `feat(scope): ...`). Add `--label`/`--assignee`/`--milestone` only if the repo actually uses them; omit otherwise.

```bash
gh issue create --title "<type(scope): concise summary>" --body "$(cat <<'EOF'
## Summary
<1-3 sentences: what and why>

## Motivation / Context
<the problem, any existing overlap, why now>

## Requirements
- <bulleted, testable requirements>

## Non-goals
- <explicit YAGNI exclusions>

## Testing
<how it will be verified>

## Open decisions
<anything left for the builder, or "none">
EOF
)"
```

3. **Show the user the issue URL** and ask them to review it. If they request changes, edit with `gh issue edit <n> --body ...` and re-run the self-review. This is the spec review gate — keep it.
4. **STOP.** The issue is the handoff. Do not branch, plan, or implement.

## Issue Backend: `gh`, Not Beads

This skill deliberately uses **GitHub issues (`gh`)**, overriding this repo's default of tracking work in beads (`bd`). Do not route the spec to `bd create` and do not hesitate — the whole purpose of this skill is a GitHub-issue spec. (If a caller genuinely wants beads instead, they want a different skill, not this one.)

## Downstream (out of scope — do not do it here)

Implementation happens later. When it does, any implementation **plan is optional, scope-gated, and lives in the PR description** — never in `docs/`, never in this issue. This skill does not produce or persist a plan.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Following brainstorming to a `docs/` file + commit | Divert per HARD-OVERRIDE; the issue is the only artifact |
| Invoking `writing-plans` | No plan step — stop at the issue |
| Self-answering all clarifying questions in one pass | Run the real one-question-at-a-time dialogue with the user |
| Ad-hoc issue structure that differs every run | Use the template above |
| `bd create` instead of `gh issue create` | This skill is GitHub-issue-first by design |
| Hardcoding `--repo owner/name` | Run from the repo; let `gh` infer from the remote |

## Red Flags — STOP

- About to write anything under `docs/superpowers/specs/`
- About to invoke `writing-plans`
- About to run `bd create` for the spec
- Presenting a design you never actually asked the user about

All of these mean: divert back to `gh issue create` with real HIL approval first.
