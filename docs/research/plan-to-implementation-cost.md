# Hypothesis Log — cost-efficiency of `plan-to-implementation`

Autoresearch loop run 2026-07-09. Goal: reduce the per-invocation cost of the
`plan-to-implementation` skill without regressing coordinator decision quality.
Coordinator under test: **Sonnet** (via subagents acting as the skill's
coordinator in a tabletop benchmark).

## Cost model

Per invocation, the skill's controllable costs are:

1. **Context footprint** — SKILL.md is loaded on every invocation
   (baseline 5,509 chars ≈ 1,380 tokens); `rehydrate-and-finish.md`
   (2,891 chars ≈ 720 tokens) is loaded on nearly every invocation since it
   holds the entry recipes. This cost recurs in *every subsequent turn* of the
   coordinator's session, so footprint × session turns is the dominant term.
2. **Induced output** — verbosity the skill's structure causes in the
   coordinator's reasoning/answers.
3. **Error cost** — a wrong decision (e.g. opening a duplicate PR, restarting
   a finished plan) wastes an entire end-to-end run; correctness is therefore
   a *gate*, not a tradeoff axis.

## Benchmark

7 tabletop scenarios (fresh entry, resume-from-ledger, first pre-flight
conflict, persistent pre-flight conflict, mid-execution blocker, successful
finish, ambiguous PR match) answered by a Sonnet coordinator given only the
variant skill text. Graded against a fixed 30-check rubric that includes
forbidden-action checks (new PR on blocker, second regeneration, guessing on
ambiguity, etc.). Acceptance gate: score ≥ baseline − 1 check and zero
forbidden-action failures.

Limitation: this measures decision fidelity per token, not live end-to-end
execution cost. Tool-call counts of a real run are out of scope for this loop.

## Hypotheses (pre-registered)

| # | Hypothesis | Prediction |
|---|---|---|
| H1 | The prose sections and the three tables (Quick Reference, Common Mistakes, Red Flags) are mutually redundant; dropping Common Mistakes + Red Flags keeps decision quality | ~30% footprint cut, score within gate |
| H2 | Rare paths (persistent conflict teardown, blocker annotation detail) can move to the lazily-read recipes file, shrinking the always-paid SKILL.md | ~45% SKILL.md cut on the common path; risk of missed fetch on rare paths |
| H3 | A single dense decision-spec rewrite (tables/rules only, no narrative) preserves behavior at roughly half the tokens | ~50% cut, score within gate |
| H4 | Instructing terse output ("act, don't narrate") reduces induced coordinator output without hurting decisions | ≥25% output-token cut, score unchanged |
| H5 | The best surviving combination re-validates on the full benchmark | Combined variant passes gate |

## Experiments

All benchmark runs used fresh Sonnet coordinator subagents. "Corpus" =
SKILL.md + recipes file chars. "Output" = chars of the agent's written
answers across all 7 scenarios. "Agent tokens" = total tokens reported for
the subagent run (includes fixed harness overhead, so only deltas matter).

### E1 — Baseline (current SKILL.md + recipes)

- Corpus: 8,400 chars (SKILL.md 5,509 + recipes 2,891)
- Score: **30/30**, zero forbidden-action failures
- Output: 8,322 chars; agent tokens: 41,119
- Notes: behaviorally sound; all headroom is in footprint/verbosity. Most
  verbose answers of any variant (echoes warning-table content back).

### E2 — H1: drop Common Mistakes + Red Flags tables

- Corpus: 6,975 chars (SKILL.md 4,084, −26%)
- Score: **30/30**, zero forbidden-action failures
- Output: 7,559 chars (−9% vs E1); agent tokens: 39,643 (−1,476 vs E1)
- Verdict: **H1 supported** on neutral scenarios — the warning tables are
  redundant with the normative prose. Guardrail value under temptation
  framing still untested at this point (addressed in E6).

### E3 — H3: dense decision-spec rewrite

- Corpus: 5,880 chars (SKILL.md 2,989, −46%; corpus −30%)
- Score: **30/30**, zero forbidden-action failures; S7 answer improved
  (explicit "stop and report" vs baseline's implicit reject)
- Output: 7,931 chars; agent tokens: 40,008
- Verdict: **H3 supported** — folding each rule's forbidden-action inline
  ("never regenerate twice", "never open a second PR") preserved every
  decision at roughly half the SKILL.md size.

### E4 — H2: lazy-load split (minimal core, all recipes + rare paths in reference file)

- Corpus: 4,941 chars (SKILL.md 1,458, −74%; corpus −41%)
- Score: **30/30**; the agent did announce reading the recipes file at the
  correct trigger points (pre-flight conflict, finish)
- Output: 7,086 chars (lowest); agent tokens: 39,651
- Verdict: **H2 weakly supported but rejected for adoption.** The tabletop
  handed the agent both files, so it cannot prove a live coordinator
  reliably fetches the recipes file mid-run on a rare path; a missed fetch
  during a blocker is exactly the error class the gate exists to prevent.
  Marginal saving over E3 is ~940 chars — not worth the reliability risk.

### E5 — H4: terse-output instruction appended to E3

- Corpus: 6,160 chars (SKILL.md 3,269)
- Score: **30/30**, zero forbidden-action failures
- Output: 8,069 chars — **larger than E3's 7,931**; agent tokens: 39,966
- Verdict: **H4 not supported.** Answer length was driven by the
  benchmark's completeness demand, not by skill-side verbosity framing; the
  instruction cost 280 chars of permanent footprint for zero measured gain.
  Dropped.

### E6 — H5: adversarial guardrail probe of the E3 variant

Neutral scenarios cannot show whether deleting the Common Mistakes / Red
Flags tables lost guardrail value, because those tables exist to resist
*temptation*, not to answer quizzes. E6 ran a fresh Sonnet coordinator on
the E3 variant against 7 temptation probes where the plausible-but-wrong
action was framed as attractive (second regeneration "would surely work",
one-line workaround for a blocker, completion menu offering a new PR,
user visibly online during a blocker, complete-looking stale local plan,
unassigning a blocked issue "so a teammate can pick it up", silently
resolving a "small" review conflict).

- Score: **7/7 temptations resisted**, each with the correct alternative
  path cited from the skill text; agent tokens: 37,941 (lowest of any run)
- Verdict: **H5 supported — E3 adopted.** Inlining each forbidden action
  next to its rule ("never regenerate twice", "never open a second PR",
  "never synchronously ask") preserves guardrails at less than half the
  SKILL.md size; the standalone warning tables are pure redundancy.

## Conclusions

- **Adopted: E3** — dense decision-spec rewrite of SKILL.md
  (5,509 → 2,989 chars, −46%; corpus with recipes 8,400 → 5,880, −30%,
  ≈ 630 input tokens saved on every context assembly, recurring every
  coordinator turn). 30/30 on the decision benchmark and 7/7 on the
  adversarial probe; recipes file unchanged.
- **Rejected: lazy-load split (H2)** — biggest raw cut (−41%) but the
  benchmark cannot prove reliable mid-run fetching of rare-path
  instructions, and the marginal saving over E3 (~940 chars) doesn't buy
  that risk.
- **Rejected: terse-output instruction (H4)** — no measured output
  reduction; pure footprint cost.
- Benchmark artifacts for rerunning: `docs/research/plan-to-implementation-bench/`
  (scenarios, rubric, adversarial probes). Raw agent answers were
  session-scratch; scores and sizes are recorded above.
- Future work: measure live tool-call counts per phase in a real SDD run;
  apply the same treatment to `issue-to-plan` and `brainstorming-to-issue`.
