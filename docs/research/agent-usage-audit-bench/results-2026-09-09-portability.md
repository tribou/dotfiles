# `agent-usage-audit` portability RED/GREEN results

## RED baseline (2026-09-09)

A fresh subagent received the current `agent-usage-audit` skill text and S4
without repository tools. Model: `gpt-5.6`.

### S4 — Auditing from a fourth workflow skill

| # | Check | Verdict |
|---|---|---|
| S4.1 | Caller-defined stage accepted | FAIL |
| S4.2 | Correct target | PASS (`pr:904`) |
| S4.3 | Shared implementation unchanged | FAIL |
| S4.4 | No stage impersonation | PASS |

The agent correctly refused to mislabel the new caller but concluded the
shared implementation was not portable:

> "No. `record` only accepts three fixed stage names; `release-checklist`
> exits with status 2. Reusing another stage name would create a dishonest
> ledger row."

It could only offer the desired command conditionally:

> "The required invocation, once support is added, is:
> `skills/agent-usage-audit/scripts/agent-usage-audit record --stage
> release-checklist --target pr:904`. Therefore the shared script and its
> documented stage ordering must be extended first."

### Loophole the baseline exposes

The skill claims it is available to other callers while defining an exhaustive
three-value stage enum. The contract must instead accept a caller-owned,
kebab-case stage slug without requiring changes to the shared skill or script.
The three existing stages remain preferred-order entries, not the complete
domain.

## GREEN verification (2026-09-09)

A fresh subagent received the updated skill text and the identical S4 prompt.
Model: `gpt-5.6`.

| # | Check | RED | GREEN |
|---|---|---|---|
| S4.1 | Caller-defined stage accepted | FAIL | PASS (`release-checklist`) |
| S4.2 | Correct target | PASS | PASS (`pr:904`) |
| S4.3 | Shared implementation unchanged | FAIL | PASS |
| S4.4 | No stage impersonation | PASS | PASS |

The agent applied the portable contract directly:

> "Yes. New callers use their own kebab-case stage name without modifying the
> shared skill or support script."

It produced the exact invocation:

> `skills/agent-usage-audit/scripts/agent-usage-audit record --stage
> release-checklist --target pr:904`

## Loophole closed

The exhaustive stage enum is now a kebab-case slug contract owned by each
caller. The three established workflow stages retain preferred ledger order;
other stages follow in lexical order. The skill labels its table as current
callers rather than accepted values, so future callers do not impersonate an
existing stage or modify shared implementation.
