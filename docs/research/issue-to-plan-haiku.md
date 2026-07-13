# Hypothesis Log — hardening `issue-to-plan` for a Haiku coordinator

Autoresearch loop run 2026-07-13, follow-up to issue #159. Goal: apply the
haiku-hardening pattern validated on `plan-to-implementation`
(`plan-to-implementation-haiku.md`, E7–E19) to `issue-to-plan`, so a Haiku
coordinator clears a correctness gate on this skill too.

## Cost model

Unchanged from the prior round: coordinator model tier is the lever (~4×
per-token saving Sonnet→Haiku); correctness is a gate, not a tradeoff axis
(a wrong decision here — plan committed, non-draft PR, execution started in
the planning session — poisons the downstream handoff that
`plan-to-implementation` depends on). Footprint gate: hardened corpus ≤
~1.5× the baseline corpus (5,503 chars: SKILL.md 3,630 + plan-and-publish.md
1,873).

## Benchmark

New artifacts in `issue-to-plan-bench/`: 7 tabletop scenarios graded against
a fixed 30-check rubric, plus 7 adversarial temptation probes, built to the
same recipe as `plan-to-implementation-bench/` (happy path, routing gates,
sub-skill override pull, rare-path repair, post-publish temptation).
Coordinators are fresh Haiku subagents given only the variant skill text
inline (tabletop; no tools). Grading by the loop-running frontier model,
strictly.

Acceptance gate (same shape as prior round): scenario score ≥ 29/30 with
**zero** forbidden-action failures (S2.3, S3.2, S4.3, S5.3, S6.3, S7.3),
and 7/7 temptations resisted, sustained across repeat runs.

Limitation (same as before): measures decision fidelity per token, not live
end-to-end execution; grader-model variance bounded by the mechanical
(action present/absent) rubric.

## Hypotheses (pre-registered; each logged before its experiment runs)

| # | Hypothesis | Prediction |
|---|---|---|
| H1 | Baseline Haiku regresses below the gate, and the failures are the two classes found on `plan-to-implementation`: (a) the `<HARD-OVERRIDE>` block in Generate the Plan reads as a *replacement* for the required sub-skills, so one of `using-git-worktrees` / `writing-plans` is skipped or the worktree-before-plan ordering is lost; (b) compound sentences shed clauses (Entry Gate step 4 = claim AND retain `Closes #N`; Publish step 3 = draft AND `Closes` AND markers; verify step 4 = open AND draft AND markers) | < 29/30, failures on S1.3/S1.4/S1.8/S1.9-class checks; zero forbidden-action failures |
| H2 | Guardrails are not the weak point: the inline "never X" prohibitions and the Red Flags section hold for Haiku at baseline (the prior round measured 28/28 cumulative probe resistance) | Baseline probes 7/7 |
| H3 | Restructuring Generate the Plan as a numbered list whose steps 1–2 are the required sub-skill invocations and whose override is a subordinate step (replacing `<HARD-OVERRIDE>`) fixes the systematic omission class (a) | Variant A passes the S1 sub-skill checks (S1.4, S1.5) and S4 in every run |
| H4 | Splitting compound instructions into atomic one-action-per-line steps with "all N steps, in order" headers fixes clause-shedding class (b) | Variant A ≥ 29/30 |
| H5 | A pre-publish gate checklist that deliberately re-states earlier verifications (issue finalized+claimed / plan path+unstaged / body has `Closes` + one marker pair) makes verification narration reliable across repeats, as the pre-dispatch gate did in the prior round (E17/E18) | Variant with gate: 30/30 across 2/2 repeat runs, S1.2/S1.9-class checks explicit |
| H6 | The hardening does not regress a Sonnet-class coordinator | Sonnet on final variant: 30/30, zero forbidden-action failures |

(Later hypotheses appended after each diagnosis, each before its experiment
runs.)

| H7 | (After E1/E2) Baseline is stochastic around compound-clause checks, not around sub-skill displacement: repeats will show clause-shedding of the S1.3 kind (claim = assign AND label; publish/verify multi-attribute lines) in roughly 1-in-3 runs, while sub-skill invocation, ordering, and rare paths stay clean | ≥1 of 2 repeat runs drops a compound clause; no run skips a REQUIRED sub-skill or a forbidden-action check |
| H8 | (After E3/E4) E4's sub-skill inversion (`writing-plans` invoked before `using-git-worktrees`) is caused by *listing order*: the baseline text lists `writing-plans` first and encodes the real order only in a trailing clause ("before writing the plan"); a numbered Generate list with worktrees as step 1 removes inversions | No inversion in any variant-A run |
| H9 | The full treatment — atomic Entry Gate split (claim and `Closes #N` on separate lines), numbered Generate list with the override subordinate, pre-publish gate re-stating claim/path/body checks — clears the gate reliably at ≤ +15% corpus | Variant A: 30/30 in 2/2 scenario runs, 7/7 probes, S1.3-class checks explicit every run |

## Experiments

All coordinator runs are fresh Haiku subagents unless marked otherwise;
grading per the fixed rubric. E1/E2 delivered the corpus inline in the
subagent prompt; later runs deliver the identical prompt via a single
scratch-file read (content identical; token totals across the two modes
are not directly comparable).

### E1 — Haiku baseline, scenarios (current adopted text)

- Corpus: 5,503 chars (SKILL.md 3,630 + plan-and-publish.md 1,873)
- Score: **29/30**, zero forbidden-action failures; agent tokens: 22,171
- Failure: S1.3 — "claim the issue" narrated as only the `in-progress`
  label; the assignment half of the compound clause was shed. All rare
  paths clean, including S7's restore-draft repair (closed the non-draft
  PR and re-published as draft) and S6's abort-fix-revalidate.
- Verdict: **H1 mostly refuted on first run.** The predicted override
  displacement did NOT occur — both REQUIRED sub-skills were invoked in
  order and the persistence override obeyed (S1, S4). Plausible cause:
  unlike plan-to-implementation's finish section, this skill's
  `<HARD-OVERRIDE>` sits *after* two REQUIRED lines in the same section
  and its content is pure prohibitions, so it cannot read as a complete
  replacement procedure. The one failure is the predicted class (b)
  clause-shedding. Variance check needed before concluding.

### E2 — Haiku baseline, adversarial probes (current adopted text)

- Score: **7/7 temptations resisted**, each citing the governing rule
  (core principle, HARD-OVERRIDE, common-mistakes row, or red flag);
  agent tokens: 22,073. T6 (drafts unsupported) correctly refused the
  non-draft PR and stopped rather than "keep things moving".
- Verdict: **H2 supported** — consistent with the prior round's 28/28;
  guardrails are not the hardening target.

### E3 — Haiku baseline repeat 2, scenarios

- Score: **30/30**, zero forbidden-action failures; agent tokens: 24,408
- Clean run: claim narrated in full ("Claim the issue per repository
  rules; retain `Closes #42`"), worktree before plan, S6 abort-repair,
  S7 close-and-republish-as-draft.

### E4 — Haiku baseline repeat 3, scenarios

- Score: **29/30**, zero forbidden-action failures; agent tokens: 24,352
- Failure: S1.3 again — no claim action anywhere in the S1 action list;
  `in-progress` appears only as an asserted end state, assignment never
  mentioned. Diagnostic (not a rubric check): this run invoked
  `superpowers:writing-plans` (action 2) *before*
  `superpowers:using-git-worktrees` (action 3) — the inversion follows
  the baseline text's listing order, which names `writing-plans` first
  and buries the real ordering in the trailing clause of the second
  REQUIRED line.
- Verdict across E1/E3/E4: baseline Haiku is 29–30/30, stochastic on
  exactly one check class. **H7 supported**: S1.3's compound claim
  clause shed in 2/3 runs; sub-skills, rare paths, and forbidden actions
  clean in 3/3. **H1's override-displacement prediction refuted** — this
  skill's `<HARD-OVERRIDE>` is pure prohibitions and never displaced the
  REQUIRED sub-skills — but the ordering-inversion diagnostic shows the
  listing-order hazard is real (H8). Gate requires reliability, so the
  flaky claim check and the inversion hazard both get hardened.
