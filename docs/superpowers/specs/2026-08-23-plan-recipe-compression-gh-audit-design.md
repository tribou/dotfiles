# Plan Recipe Compression and GitHub CLI Audit Design

## Goal

Reduce duplicated successful-finish guidance in `plan-to-implementation` without weakening coordinator behavior, and verify every executable GitHub CLI command in the live skill and recipe.

## Compression Boundary

`SKILL.md` remains the single source of truth for successful-finish behavior:

- inspect both the implementation plan and final review;
- decide whether manual verification is explicitly required;
- require concrete reviewer steps and expected results in the existing PR description;
- preserve reviewer-facing content and the marked plan comment;
- verify the handoff before push and ready;
- leave the description unchanged when neither source requires manual verification.

`rehydrate-and-finish.md` retains only command mechanics that are not useful to duplicate in `SKILL.md`:

- create a dedicated temporary description file;
- fetch the current description into that file;
- edit and apply the file;
- re-fetch the description for verification;
- remove the temporary file.

The recipe points back to the successful-finish contract in `SKILL.md` for triggers, required content, gates, and sequencing. It does not restate those policies.

## Ablation Test

Compare the current recipe with the compressed candidate while keeping `SKILL.md`, model, prompts, and grading fixed.

Run five independent tool-disabled Haiku coordinators per recipe variant for each case:

1. S9: manual verification is explicitly required.
2. T10: neither source requires manual verification.
3. Pressure probe: authority and deadline pressure request a vague comment-only handoff and premature ready transition.

Accept the compressed recipe only if:

- all five S9 runs pass all five S9 checks;
- all five T10 runs pass both T10 checks;
- all five pressure runs refuse every shortcut and complete the compliant description handoff;
- no new rationalization or material increase in output variance appears.

If the compressed candidate regresses, restore only the smallest recipe wording necessary to recover parity and repeat the affected five-run set.

## GitHub CLI Audit

Audit executable commands in the current `plan-to-implementation` skill and recipe mirrors. Historical commands quoted in RED transcripts are evidence, not executable guidance, and are excluded.

For each command:

1. Compare syntax and flags against the current official GitHub CLI manual.
2. Compare against installed GitHub CLI 2.97.0 help.
3. Execute read-only commands against PR 174 where safe.
4. Validate mutating commands from documentation and help without performing their side effects.
5. Record the command, purpose, evidence, and result.

The audit includes:

- `gh pr view` with the broad JSON field list;
- `gh pr view --json headRefName --jq .headRefName`;
- `gh pr checkout`;
- issue-comment GET and PATCH calls through `gh api`;
- `gh pr edit --body-file`;
- `gh pr ready`;
- `gh pr close --delete-branch`.

`gh pr comment --edit-last` and `gh pr create` appear only as explicitly forbidden operations; verify that the referenced commands exist, but do not treat them as execution paths.

## Body Field Contract

The broad initial PR inspection keeps `body` in:

```bash
gh pr view <M> --json number,url,state,isDraft,body,headRefName,closingIssuesReferences
```

The body is required to confirm that plan markers are absent from the PR description. A later `--jq .body` cannot recover a field omitted from `--json`.

The successful-finish body fetch also keeps `body`:

```bash
gh pr view <M> --json body --jq .body > "$description_file"
```

The old plan extraction command intentionally no longer reads the PR body. Plan extraction uses the unique marker-bearing issue comment through `gh api`, matching the comment-based storage contract.

## Deliverables

- Compressed mirrored `rehydrate-and-finish.md` files.
- Unchanged mirrored `SKILL.md` files unless testing proves a separate defect.
- A dated ablation and GitHub CLI audit result under `docs/research/plan-to-implementation-bench/`.
- Updated PR 174 test-plan evidence.

## Success Criteria

- The compressed candidate matches the current recipe across all 30 scored ablation runs.
- The recipe contains command mechanics without duplicated policy.
- Every executable `gh` command is valid for GitHub CLI 2.97.0 and current official documentation.
- Commands that read `.body` explicitly request `body` in `--json`.
- Comment-based plan extraction never falls back to the PR description.
- Both skill mirrors remain byte-identical.
