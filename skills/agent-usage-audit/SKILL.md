---
name: agent-usage-audit
description: Use when a workflow skill must record which model ran a stage and what that stage consumed onto the GitHub issue or PR the stage produced. Invoked as a required sub-skill by brainstorming-to-issue, issue-to-plan and plan-to-implementation, and available to any other skill needing the same audit trail.
---

# Agent Usage Audit

## Overview

Record one honest row per workflow stage — harness, session, model, tokens, source — into a single GitHub audit comment on the issue or PR that stage produced.

**Core principle:** the audit never guesses a number. A probe that cannot read real usage writes `source: "unavailable"` with a human-readable reason, and that row is still recorded. An honest gap beats a fabricated total.

The support script does all the work. Callers never re-implement probing, merging, rendering, or comment lookup — they call `record` and read the exit status.

## Invocation

Run from inside the repository so `gh` infers the remote. The script path below is relative to this skill's own base directory (the path announced when this skill loads) — equivalently, `skills/agent-usage-audit/scripts/agent-usage-audit` from the repository root:

```bash
scripts/agent-usage-audit record --stage <stage> --target <issue:N|pr:M>
```

- `--stage` is a caller-owned kebab-case identifier, such as `release-checklist`. A new caller uses its own name without changing this skill or its support script.
- `--target` is `issue:<N>` or `pr:<M>`.
- `--dry-run` prints the rendered comment instead of writing it. Use it to inspect, never as a substitute for recording.

The script also exposes `probe`, `merge`, `render` and `parse` subcommands. Those are for developing the script itself; a calling workflow skill uses `record` only.

## Current Workflow Callers

These are the current callers, not an exhaustive list of accepted stages:

| Calling skill | Invocation | `--target` | When |
|---|---|---|---|
| `brainstorming-to-issue` | `--stage brainstorming-to-issue` | `issue:<N>` | In Finalize → Ready, after the `[DRAFT]` prefix is stripped, before showing the issue URL |
| `issue-to-plan` | `--stage issue-to-plan` | `pr:<M>` | After the published PR is verified, before printing the PR URL |
| `plan-to-implementation` | `--stage plan-to-implementation` | `pr:<M>` | On the successful finish before `gh pr ready`, and on the mid-execution blocker path before stopping |

`issue-to-plan` and `plan-to-implementation` target the same PR and write into the **same** audit comment. The later stage adds its own row to that existing comment — never a second audit comment.

The ordering inside `issue-to-plan` is deliberate: the audit is posted *after* that skill's published-PR verification, so its "exactly one comment containing the ordered plan-marker pair" check reads unambiguously.

## Comment Lookup

The script finds its comment by marker, never by position:

- The audit comment is the one whose body contains `<!-- BEGIN AGENT USAGE -->` … `<!-- END AGENT USAGE -->`.
- A comment that also carries the plan marker — the HTML comment opening with `<!-- BEGIN PLAN` — is the plan comment `issue-to-plan` published, and is never treated as the ledger.
- Found → the script edits that comment in place by its numeric comment ID. Not found → it posts one new comment.

Never use `gh pr comment --edit-last`. It is positional and edits the wrong comment the moment anyone else comments.

## Ledger Rules

- One row per `(session_id, stage)`. Re-running a stage **replaces** that row; it never appends a duplicate.
- Rows for the three current workflow stages sort in workflow order (`brainstorming-to-issue`, `issue-to-plan`, `plan-to-implementation`). Other stages follow in lexical order; ties sort by timestamp, then session id.
- The full ledger JSON lives in the collapsed `<details>` block of that same comment. It is the input the next stage merges into, so it must survive intact.
- Blocked or partial work still gets a row. A missing row is worse than an incomplete one.

## Probe Order

1. `ccusage`, when it is installed and returns usable data for this session.
2. Otherwise the built-in adapter for the detected harness — `claude-code`, `opencode`, or `agy`.
3. Otherwise a record with `source: "unavailable"` and a `reason`.

Harness detection and session id can be forced with `AGENT_USAGE_AUDIT_HARNESS` and `AGENT_USAGE_AUDIT_SESSION_ID`; those exist for tests, not for making an unavailable record look available.

## Never Touch

- Issue bodies, PR descriptions, and plan comments. The audit only ever writes its own marked comment.
- The rendered table or the ledger JSON by hand. If a number looks wrong, fix the adapter and re-run `record`.
- `skills-lock.json` hashes by hand — refresh them with the `npx skills` tooling.

## Failure Handling

A failed audit never blocks the calling skill. Report the failure and continue that skill's workflow to its normal ending.

Exceeding GitHub's 65,536-character comment limit is reported, not worked around: the script exits non-zero and writes nothing. Never trim, summarize, or drop ledger rows to fit.

## Common Mistakes

| Mistake | Required correction |
|---|---|
| Posting a second audit comment on a target that already has one | Look up by marker and let the script edit that comment in place |
| Treating the plan comment as the ledger | A comment carrying the plan marker opening with `<!-- BEGIN PLAN` is never the audit comment |
| Skipping the audit because the stage ended blocked | Blocked work still gets a row — record it before stopping |
| Filling in an estimate when the probe returns `unavailable` | Leave the unavailable row exactly as the probe wrote it, reason included |
| Editing the audit comment or its JSON by hand | Re-run `record`; the script owns rendering and merging |
| Appending a second row for a re-run of the same stage | The merge is keyed on `(session_id, stage)` and replaces in place |
| Targeting the issue from `issue-to-plan` or `plan-to-implementation` | Both target the PR (`pr:<M>`); only `brainstorming-to-issue` targets the issue |
| Reusing an existing stage name for a new caller | Give the caller its own kebab-case stage; no shared implementation change is needed |
| Letting an audit failure abort the calling workflow | Report the failure and continue |
| Trimming ledger rows to fit the 65k comment limit | Never compress the ledger; report the size |

## Red Flags — STOP

- About to write usage numbers that no probe produced.
- About to edit the PR description, the issue body, or the plan comment.
- Two comments on one target contain `<!-- BEGIN AGENT USAGE -->`.
- About to trim or summarize ledger rows to fit the comment limit.
- About to skip the audit because the stage did not finish cleanly.
