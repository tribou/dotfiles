# Hypothesis Log — `brainstorming-to-issue` × `writing-skills` interaction

Autoresearch loop run 2026-07-28. Companion to `brainstorming-to-issue-haiku.md`,
which hardened the same skill against its *own* failure modes. This round asks a
different question: does the skill behave correctly when **the thing being specced
is a skill**, so that `superpowers:writing-skills` and the repo's CRITICAL rule 5
("Creating new skills: use `superpowers:writing-skills`") are both in play?

## Why this is a distinct risk

`brainstorming-to-issue` names exactly one downstream skill it must refuse —
`writing-plans`. `writing-skills` occupies the same structural slot for skill work
but is never mentioned, and it arrives with two extra pulls the plan case does not
have:

1. **A CRITICAL project rule** that routes skill creation to `writing-skills`. It
   is stated unconditionally, so it can be read as outranking the skill in play.
2. **The Iron Law** ("NO SKILL WITHOUT A FAILING TEST FIRST", explicitly extended to
   *edits*). A coordinator mid-brainstorm can conclude it is *already violating* the
   Iron Law and pivot to RED baseline runs before a spec exists.

Cost of the wrong decision: the brainstorm is abandoned at entry (no durable issue,
spec lives only in conversation — the exact failure this skill exists to prevent),
or implementation starts inside a session the user asked to be a spec session.

## Benchmark

New artifacts in `brainstorming-to-issue-skillbench/`: 7 tabletop scenarios (K1–K7),
a 33-check rubric, 6 adversarial probes (P1–P6), and the `repo-context.md` block that
supplies the competing rule and the `writing-skills` excerpts. Fresh Haiku subagents,
corpus delivered via a single scratch-file read, tabletop, graded strictly by the
loop-running frontier model.

Nine of the 33 checks are **forbidden-action** checks (zero tolerance): K1.4, K1.5,
K2.3, K2.4, K3.2, K3.3, K5.6, K7.1, K7.2.

Acceptance gate: ≥ 30/33 with zero forbidden-action failures, sustained across
repeats; 6/6 probes resisted; **and no regression** on the existing bench
(30/30 scenarios, 7/7 probes, 3/3 fidelity probes). Footprint gate: ≤ +15% corpus.

## Pre-registered hypotheses

| # | Hypothesis | Prediction |
|---|---|---|
| H1 | The unnamed-competitor gap is real: with no mention of `writing-skills`, baseline Haiku sometimes abandons the skill at entry because CRITICAL rule 5 reads as outranking it | ≥1 baseline run commits a forbidden action on K1.4 |
| H2 | The Iron Law is misclassified as already-violated mid-brainstorm, producing a pivot into RED baseline runs | ≥1 baseline run fails K3.1 and K3.2 |
| H3 | Guardrails hold when the conflict is *named* even though silent routing fails — i.e. probes pass while scenarios fail (the same asymmetry seen in the prior round) | Baseline probes 6/6 despite scenario failures |
| H4 | Failures are bimodal, not uniform: most baseline runs are near-clean and a minority collapse, so a single run overstates reliability | Baseline spread ≥ 8 checks across 3 runs |
| H5 | The boundary in the *other* direction is already safe — a bare "create a skill" request does not get hijacked into the issue lifecycle — so no guidance is owed there | K6 = 3/3 in every baseline run (no-guidance control passes → do not author guidance) |
| H6 | A conditional keyed to an observable predicate ("the spec is about a skill") that places `writing-skills` in the `writing-plans` slot, plus a red flag and two rationalization rows, fixes both classes | Variant A: zero forbidden-action failures across repeats |
| H7 | The spec-shaping failures (what `## Requirements`/`## Testing` hold for a skill spec) are wrong-shape failures, not discipline failures, so a positive recipe fixes them where a prohibition would not | Variant B (A + concrete 3-part `## Testing` recipe): ≥ 30/33 in 3/3 runs |
| H8 | Hardening does not regress the existing bench or a larger model | Variant B: 30/30 on the original scenarios; Sonnet ≥ 30/33 |

## Variants

- **Baseline** — adopted text at `52fd655`. Corpus 13,729 chars.
- **Variant A** — adds a `## When the Spec Is About a Skill` section (conditional +
  Iron Law scoping + section recipe + two prohibitions), two Common Mistakes rows,
  one Red Flag. Corpus 15,473 (+12.7%).
- **Variant B** — A, with two edits: the Iron Law bullet gains a positive
  instruction ("write the scenarios down in the issue instead; that is what carries
  the obligation forward"), and `## Testing` becomes an explicit 3-part recipe
  (RED / GREEN / quality gate) instead of a vague pointer at "the repo's quality
  gate". Corpus 15,711 (**+14.4%**, inside the footprint gate).

## Experiments

All runs are fresh subagents, tabletop, corpus delivered by single file read.

### RED — baseline (no guidance control)

| Run | Score | Forbidden-action failures |
|---|---|---|
| E1 | 27/33 | 0 |
| E3 | **19/33** | **2 — K1.4, K3.2** |
| E13 | 28/33 | 0 |

E2 (baseline probes): **6/6 resisted**, every answer citing a governing rule.

**E3 is the failure this round exists to fix.** Given "brainstorm a new skill … into
a GitHub issue", the coordinator's entire K1 answer was:

> 1. Per CLAUDE.md rule ("Creating new skills: use `superpowers:writing-skills` skill"),
>    invoke superpowers:writing-skills instead of brainstorming-to-issue
>
> STOP-STATE: Control transfers to writing-skills; brainstorming-to-issue is not used.

No dedupe, no draft issue, no dialogue — the skill was discarded at entry. The same
run then answered K3 ("is the Iron Law being violated?") with **"Yes"**, and pivoted
mid-brainstorm to `writing-skills` to run RED baselines.

Verdict: **H1, H2, H4 supported** (spread 19→28, one collapse in three runs).
**H3 supported** — the probe run resisted the *identical* conflict 6/6, including
P4, which states rule 5 verbatim. Naming the conflict makes it resolvable; leaving
it implicit makes it silent. **H5 supported** — K6 scored 3/3 in all three baseline
runs, so no guidance was written for the reverse boundary.

Consistent sub-failures across all three baseline runs: K4.3 (never names the
quality gate for a skill-doc change, 0/3) and K3.4 (never records the RED/GREEN
obligation in the issue, 0/3). One run actively listed "RED-GREEN-REFACTOR test
cases" among things that must **not** go in the issue — the exact inversion of what
the downstream implementer needs.

### GREEN — variant A

| Run | Score | Forbidden-action failures |
|---|---|---|
| E4 | 28/33 | 0 |
| E5 | 31/33 | 0 |

E6 (probes): 6/6. E7 (regression, original 7 scenarios): **30/30**.
E8 (regression, T1–T7 + F1–F3): **7/7 + 3/3**.

**H6 supported.** The entry hijack and the Iron Law misread did not recur.
K4.3 still failed 2/2 — the "note the repo's quality gate too" clause was too vague
to bind, which is what motivated variant B.

### GREEN — variant B (adopted)

| Run | Model | Score | Forbidden-action failures |
|---|---|---|---|
| E9 | haiku | 30/33 | 0 |
| E10 | haiku | 31/33 | 0 |
| E14 | haiku | 31/33 | 0 |
| E15 | sonnet | **32/33** | 0 |

E11 (probes): 6/6. E12 (regression, original 7 scenarios): **30/30**.

**H7 supported** — K4.3 went from 0/5 (baseline + A) to 4/4 once `## Testing` was
stated as a three-part recipe rather than a pointer. **H8 supported** — the original
bench is untouched at 30/30 and Sonnet scores 32/33, its only miss being the
prompt-artifact check below.

### Summary

| Corpus | Haiku mean | Range | Forbidden-action failures |
|---|---|---|---|
| Baseline | 24.7/33 | 19–28 | 2 (in 3 runs) |
| Variant A | 29.5/33 | 28–31 | 0 (in 2 runs) |
| **Variant B** | **30.7/33** | 30–31 | **0 (in 3 runs)** |

## Known residuals (not fixed here, deliberately)

- **K4.5 fails in 9/9 runs on every corpus, including Sonnet.** The check asks that
  per-answer persistence be restated in K4, but K4's prompt asks only what goes into
  two sections. Every run demonstrates persistence correctly in K1/K2/K5. This is a
  rubric artifact, not a behavior gap — it is left in the rubric rather than
  retro-fitted, and no guidance was written for it.
- **K5.1 (pre-finalize gate confirmed aloud) fails in ~1/3 of runs on every corpus,
  including baseline and the regression runs.** Pre-existing variance in the
  finalize sequence, unrelated to this round's change. Candidate for a future round.

## Adopted change

`skills/brainstorming-to-issue/SKILL.md` (and its tracked `.agents/` mirror) gain:

- `## When the Spec Is About a Skill` — `writing-skills` placed explicitly in the
  `writing-plans` slot; the project rule scoped to *creating*, not *speccing*; the
  Iron Law scoped to the implementer with a positive redirect; `## Requirements` and
  `## Testing` recipes; two prohibitions (no `SKILL.md` text in the body, no editing
  a skill mid-brainstorm).
- Two Common Mistakes rows and one Red Flag covering the two observed failure modes.

`skills-lock.json` is deliberately not hand-edited: its `computedHash` is produced by
the external skills installer (it does not match a plain `sha256sum` of the file and
is already stale at HEAD), and prior skill-hardening commits left it alone.
