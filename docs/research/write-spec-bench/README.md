# write-spec bench

Scenarios, frozen inputs, and scripts for testing `skills/write-spec`. [scenarios.md](scenarios.md) holds each scenario's input and mechanical checks; the scripts read it, so a check lives in one place.

## Run, score, review

```bash
B=docs/research/write-spec-bench; OUT=$SCRATCH/run1
bash $B/run.sh -n 3 green $OUT S1 S4 S5b      # 3 fresh runs each of the working-tree skill
bash $B/score.sh $OUT                         # mechanical checks -> $OUT/results.tsv + summary
bash $B/fidelity.sh check $OUT                # must-survive key check -> <stem>.fid.json
bash $B/review.sh $OUT run1 green             # $OUT/review/index.html + data/run.json
```

Publish `$OUT/review/index.html` as an artifact with `data/run.json` as its data file and the `db` capability. The page groups cases by artifact type and shows each output beside its failed checks, lost must-keep items, hedged claims, and claims the input does not support. Verdicts and notes are stored in the artifact's `verdicts` collection, and key edits in `keys`, for Claude to read back.

- **Arms:** `red` (no skill), `green` (working tree), `skill@REV` (the skill at a git revision, for the RED arm of a change).
- **Repeat runs** keep existing outputs, so rerunning the same command fills in only missing or failed runs.
- **Billing:** runs use the claude.ai login, not an exported `ANTHROPIC_API_KEY`, unless `WRITE_SPEC_BENCH_API_KEY=1`.

## Frozen RED baseline

`baseline/red/` holds 3 no-skill runs of every RED scenario, and `baseline/skill-1fee233/` the 3 S5r-stale runs of the pre-claim-check skill (`claude-sonnet-5-5`, 2026-10-17). The no-skill arm does not change when the skill does, so reuse these instead of rerunning RED: `cp -r baseline/red $OUT/` before `score.sh $OUT`. Rerun RED only for a new scenario, or when the model changes.

## How a run works

Each run is one headless `claude -p --safe-mode --no-session-persistence` session with no settings, hooks, or memory. The skill's `SKILL.md` and every reference file are inlined into the system prompt, so the cached prefix is shared across runs and no tool calls are spent reading the skill. Scenarios without a repo get no tools. S5r and S9 get a fresh fixture repo per run (`build-fixtures.sh`) with file tools only, and their tool calls are saved as `<stem>.tools`. S13 and S14 still need frozen inputs and run as subagents by hand.

A plain run costs about 9k tokens, almost all of it the cached skill prefix; a repo run about 40-60k. A `general-purpose` subagent run costs about 50k, and its transcript lands in the coordinator's context.

## Must-survive keys

`keys/<name>.json` lists, for one input, up to 15 items a coding agent would need from it, ranked by how much losing each would change what gets built. An item's `need` is `must` or `may`, and an identifier item has an `exact` string checked by fixed-string search. `fidelity.sh draft` writes a key with `status: "draft"`; the human reviewer approves or edits it on the review page's Keys view before its results count. The check is one model call per output and reports each item as present, hedged, missing, or contradicted, plus unsupported additions.

Keys cover the items most likely to change the plan, not every detail. The issue-to-plan equivalence run (original vs rewrite, graded blind) still covers the long tail, at milestones only.
