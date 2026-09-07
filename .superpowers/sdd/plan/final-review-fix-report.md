# Final Review Fix Report

Date: 2026-09-07
Branch: `feat-180-agent-usage-audit`
Issue: #180

## Fixes Applied

- agy protobuf parsing now rejects truncated varints, length-delimited fields,
  and fixed-width fields; usage rows must contain fields #3, #9, and #10 before
  the self-check can pass.
- ccusage entries and all recursive children now require a non-empty session id
  and finite, nonnegative primary usage fields. Invalid payloads fall back to
  the built-in adapter.
- opencode now walks all descendants through `parent_id` with a visited set,
  preserving child itemization and preventing cycles from inflating totals.
- Claude usage rows validate finite, nonnegative numeric values and unusable
  rows are dropped without corrupting normalized token totals.
- `AGENT_USAGE_AUDIT_HARNESS` is validated against the harness allowlist using
  an `unknown` value before dispatch.
- Unexpected probe errors preserve the detected harness and session id in the
  unavailable fallback record.
- Regression fixtures cover malformed/truncated agy rows, malformed Claude
  usage, invalid harness overrides, nested/cyclic opencode descendants,
  ccusage shape failures, and error-path metadata preservation.

## Verification

### Focused Bats Tests

Command:

```text
just test-unit tests/agent_usage_audit.bats
```

Output:

```text
1..36
ok 1 agent-usage-audit: script is executable
ok 2 probe: unknown harness yields an unavailable record, never fabricated numbers
ok 3 probe: record carries schema, stage and an ISO-8601 UTC timestamp
ok 4 probe: --session overrides environment detection
ok 5 probe: rejects an unknown stage
ok 6 probe: invalid harness override falls back to the unknown harness
ok 7 detect_harness: CLAUDECODE marker selects the claude-code harness
ok 8 detect_harness: OPENCODE marker selects the opencode harness
ok 9 detect_harness: AGY marker selects the agy harness
ok 10 claude-code adapter: dedups repeated streaming rows by (message id, request id)
ok 11 claude-code adapter: subagent usage rolls up and is itemized in children
ok 12 claude-code adapter: a missing transcript is unavailable, not zero-filled truth
ok 13 claude-code adapter: unreadable transcript is unavailable
ok 14 claude-code adapter: transcript with no assistant turns is unavailable
ok 15 claude-code adapter: malformed usage rows are dropped without corrupting totals
ok 16 probe: unexpected errors preserve detected harness and session context
ok 17 opencode adapter: reads the session row and rolls up its child sessions
ok 18 opencode adapter: rolls up nested descendants and stops on parent cycles
ok 19 opencode adapter: preserves a zero parent-plus-child cost
ok 20 opencode adapter: a session id absent from the database is unavailable
ok 21 opencode adapter: a missing database file is unavailable
ok 22 opencode adapter: an unreadable database is unavailable
ok 23 agy adapter: sums only rows whose stored total verifies
ok 24 agy adapter: a row failing the #3 == #9 + #10 self-check is dropped, not guessed
ok 25 agy adapter: a missing conversation database is unavailable
ok 26 agy adapter: a conversation where every row fails verification is unavailable
ok 27 agy adapter: malformed and truncated protobuf rows are dropped
ok 28 probe order: ccusage wins over the built-in adapter when it is installed
ok 29 probe order: a failing ccusage falls back to the built-in adapter
ok 30 probe order: AGENT_USAGE_AUDIT_DISABLE_CCUSAGE skips ccusage entirely
ok 31 probe order: malformed ccusage token fields fall back to the built-in adapter
ok 32 probe order: ccusage entries missing usage fall back to the built-in adapter
ok 33 probe order: ccusage children missing identity or usage fall back to the built-in adapter
ok 34 probe order: malformed ccusage children fall back to the built-in adapter
ok 35 probe order: a non-array ccusage sessions field falls back to the built-in adapter
ok 36 probe order: a timed-out ccusage falls back to the built-in adapter
```

Exit status: `0`

### Bash Syntax Check

Command:

```text
source lib/commands.sh && bashcheck tests/agent_usage_audit.bats
```

Output:

```text
==> tests/agent_usage_audit.bats

All files passed
```

Exit status: `0`

### Bun Build

Command:

```text
bun build --target=bun --outdir "$(mktemp -d)" skills/agent-usage-audit/scripts/agent-usage-audit
```

Output:

```text
Bundled 1 module in 130ms

  agent-usage-audit.js         178 bytes  (entry point)
  agent-usage-audit-hndyznkh.  25.49 KB   (asset)
```

Exit status: `0`

### Diff Check

Command:

```text
```

Output: silent.

Exit status: `0`

### Full Unit Suite

Command:

```text
just test-unit
```

Output summary:

```text
1..309
```

All 309 tests passed. The command emitted pre-existing Bats `BW02` warnings
about `run` flags in unrelated test files.

Exit status: `0`

### Docker Suite

Command attempts:

```text
just test
```

Attempt 1 output after 300 seconds:

```text
docker compose run --rm -T ci
 Container feat-180-agent-usage-audit-ci-run-4dc5e06be29b Creating
 Container feat-180-agent-usage-audit-ci-run-4dc5e06be29b Created
error: recipe `test` was terminated on line 7 by signal 15
```

Attempt 2 output after 600 seconds:

```text
docker compose run --rm -T ci
 Container feat-180-agent-usage-audit-ci-run-b20e613b6293 Creating
 Container feat-180-agent-usage-audit-ci-run-b20e613b6293 Created
error: recipe `test` was terminated on line 7 by signal 15
```

No Docker test assertion output was produced before either timeout. The
container was no longer running after each terminated attempt.

## Concerns

- The Docker-backed `just test` suite could not complete in the available
  environment because `docker compose run --rm -T ci` exceeded both 5-minute
  and 10-minute timeouts. Focused and full non-Docker tests passed.
