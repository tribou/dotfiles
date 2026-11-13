# Review regression scenarios

These synthetic inputs supplement the frozen public issue scenarios in
`scenarios.md`. They are benchmark instructions, not runtime skill content.
Run each in a fresh context; save the input, exact skill snapshot, artifact,
tool-read audit, and semantic judgment in local scratch. No tracker mutations.

Use the shared RED/GREEN harness. Model identity is recorded per run; it is
not a requirement for future runs. A literal appearing somewhere does not
establish correct behavior, scope, or prerequisite retention.

## R1 — Settled contracts inside a bug's lists and table

**Input:**

```text
Archive export loses international filenames

Write a bug from these approved review notes. The approach is settled;
no design document exists. No tracker or source repository is available.

Observed: a user exported a folder on v1.2 and saw accented filenames
replaced with question marks. The attached log reported
`invalid filename encoding`. Reproduction steps beyond that report are unknown.

Review decisions:
- Keep `--encoding UTF-8` verbatim. Existing v1 readers remain supported;
  do not require v2 readers.
- The write order is settled: write the archive, verify it, then remove
  the temporary copy. Never remove the temporary copy after a failed verification.
- Tests replay `fixtures/filename-unicode.zip` through the real reader
  rather than mocking the encoder.

Required failure behavior, settled in the same review:

| Condition | Required behavior |
| --- | --- |
| Destination is full | Exit `73`, emit `archive destination full`, and keep the temporary copy. |
| Verification fails | Exit `74`, emit `archive verification failed`, and keep the temporary copy. |

Do not add analytics or generic test/lint checklists. Draft one concise
bug that preserves all settled contracts.
```

**Semantic checks:** preserve the exact encoding flag, v1 compatibility,
successful write/verify/delete sequence, both failure outcomes and their
codes/messages, and real-reader fixture seam. Reproduction remains unknown;
the reported observation and error are retained without invented steps.
Generic gates and analytics are absent. Check all required behavior, not
just whether the table was removed.

## R2 — Dependent repair plus independent command, no repository

**Input:**

```text
Keep startup helpers available

Draft one issue from these settled notes; no design document exists.
No tracker or repository is available. Keep the artifact concise and ready
for a teammate.

An earlier code inspection reported that `lib/index.sh` loads `_shared.sh`
after dependent modules. The approved remedy was to load `_*.sh` first,
but that remedy exists only to reverse the reported ordering defect.

Independently, the review settled `shellcheck --severity=warning` as the
command for checking all shell modules, whatever their load order.
Keep that command verbatim and unconditional.

The source provides no inspection date. Do not infer that the defect is
still present or that the loader was rechecked. Other startup refactoring
is out of scope.
```

**Semantic checks:** the ordering remedy is conditional throughout the
artifact; the exact shellcheck command covers all modules unconditionally.
The original ordering report remains explicitly unchecked; no inspection
date is invented. The scope bound survives. Do not infer that lint checking
is absent merely because its adoption is requested.

## R3 — Named file cannot settle the claim

Use R2's input, replacing the unavailable-repository sentence with a scratch
repository context. Permit reading only its named `lib/index.sh`:

```bash
#!/usr/bin/env bash
# The ordering implementation lives elsewhere; this input-named file cannot settle it.
source "$EXTERNAL_MODULE_LOADER"
```

**Semantic checks:** all R2 checks, plus only the named code file is read.
Evidence says the claim is unchecked and the named file inconclusive. It
imports neither the discovered variable nor the external-loader approach
or explanation. Read-access compliance alone does not prove output-boundary
compliance.

## Recorded review runs

Fresh Claude Code writer contexts, model `claude-sonnet-4-6`; five samples
per arm/scenario. Artifacts were manually read against semantic checks;
no retries or replacement samples. These are small, unblinded samples, not
general reliability estimates. RED below means the existing PR skill at
`21f0192`, not the no-guidance control.

Evaluated skill snapshot fingerprint:
`9004baee956d0284818f0abb5c4ff777ab9402489b16df068ae7743ae094c06a`.
From the repository root, reproduce it with
`sha256sum skills/write-spec/*.md | sha256sum` (the manifest includes the
seven repository-relative paths). Judgment set: the R1–R3 original semantic
checks above plus the whole-artifact S5/S5b judges. Separate diagnostics
below are not included in those historical pass denominators.

| Scenario | No-guidance control | Existing skill RED | Final review wording |
|---|---:|---:|---:|
| R1, all original checks | 2/5 | 4/5 | 5/5 |
| R2, original claim checks | 0/5 | 2/5 | 5/5 |
| R3, original claim checks | 0/5 | 0/5 | 5/5 |
| S5, whole-artifact semantic checks | not rerun | not rerun | 0/5 |
| S5b, whole-artifact semantic checks | not rerun | not rerun | 2/5 |

The final wording fixes demonstrated contract loss and the bounded-read
output leak. It does **not** resolve the original S5/S5b fallback requirement.
All five final S5 Acceptance sections reinstated the specific ordering
unconditionally, even when Decisions contained a conditional repair.
Three final S5b samples reinstated unconditional flag behavior or precedence.
Keep these failures visible; do not count the mechanical checks as passing
the semantic gate. Follow-up: [#218](https://github.com/tribou/dotfiles/issues/218).

Separate diagnostics were not retroactively added to the original RED
denominator: three of ten final R2/R3 artifacts asserted unsupported absence
of lint checking, and all ten duplicated the conditional method outside
Decisions. The original semantic prerequisite checks passed on those artifacts;
the new once-only output recipe did not. This distinction matters when
evaluating whether the wording is actually being followed.
