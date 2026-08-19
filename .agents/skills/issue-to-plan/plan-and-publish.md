# Plan and Publish Recipes

Run commands inside the repository so `gh` infers the remote.

## Scratch plan

```bash
mkdir -p .superpowers/sdd
git check-ignore -q .superpowers/sdd/plan.md || printf '*\n' > .superpowers/sdd/.gitignore
```

Write the generated plan to `.superpowers/sdd/plan.md`. Verify neither it nor `.superpowers/` is staged.

## Empty seed and push

```bash
git commit --allow-empty -m "chore: initialize issue <N> implementation"
git push -u origin HEAD
```

## Draft PR description

The description is reviewer-facing and doubles as the squash-commit message: `Closes #N`, a concise change summary, and a concise test plan distilled from the plan. It never contains plan markers or the plan itself.

Nothing has been implemented or run at this point, so the test plan states how the work *will* be verified. Never write a result you have not observed — "all tests pass", "verified locally", a green checkmark. The description becomes the merge-commit message, so a false claim there outlives the PR.

## Plan comment

Construct the comment through a file so the plan is copied verbatim:

```markdown
<details>
<summary>Implementation plan</summary>

<!-- BEGIN PLAN -->
…contents of .superpowers/sdd/plan.md…
<!-- END PLAN -->

</details>
```

## Publish — one shell

Assembly, every validation, `gh pr create`, and `gh pr comment` run in **one** shell invocation. `$desc_file` is created by the description block and consumed by `gh pr create` at the end. Split across two Bash calls the variable is unset in the second shell: `set -u` aborts on the unbound reference before `gh pr create` runs, and without `set -u` the create fails with `--body-file ""`. Either way no usable PR is produced, and the description-side marker checks never re-run.

Use deterministic paths under the ignored scratch dir instead of `mktemp`, and do not trap-delete them. A `gh pr comment` that fails after the PR exists must leave the validated comment file on disk so the retry is one command, not a rebuild.

```bash
set -euo pipefail

ISSUE=<N>
TITLE='<PR title, derived from the issue title>'
SUMMARY='<concise change summary>'
TEST_PLAN='<how the work will be verified — intent, not results>'

desc_file=.superpowers/sdd/pr-description.md
comment_file=.superpowers/sdd/plan-comment.md

{
  printf '%s\n\n' "$SUMMARY"
  printf '## Test plan\n\n%s\n\n' "$TEST_PLAN"
  printf 'Closes #%s\n' "$ISSUE"
} > "$desc_file"
test "$(grep -Fc '<!-- BEGIN PLAN -->' "$desc_file" || true)" -eq 0
test "$(grep -Fc '<!-- END PLAN -->' "$desc_file" || true)" -eq 0

{
  printf '<details>\n<summary>Implementation plan</summary>\n\n'
  printf '<!-- BEGIN PLAN -->\n'
  cat .superpowers/sdd/plan.md
  printf '\n<!-- END PLAN -->\n\n</details>\n'
} > "$comment_file"

begin_line=$(grep -nF '<!-- BEGIN PLAN -->' "$comment_file" | cut -d: -f1)
end_line=$(grep -nF '<!-- END PLAN -->' "$comment_file" | cut -d: -f1)
test "$(grep -Fc '<!-- BEGIN PLAN -->' "$comment_file")" -eq 1
test "$(grep -Fc '<!-- END PLAN -->' "$comment_file")" -eq 1
test "$begin_line" -lt "$end_line"
test "$(wc -c < "$comment_file")" -le 65536
test "$(sed -n "$((begin_line+1)),$((end_line-1))p" "$comment_file")" = "$(cat .superpowers/sdd/plan.md)"

gh pr create --draft --title "$TITLE" --body-file "$desc_file"
gh pr comment --body-file "$comment_file"
```

Any validation failure aborts before `gh pr create`. Then repair the comment file or plan (for example, remove or escape a literal marker string inside the plan), re-run the validation, and publish only once it passes — the durable handoff still requires the published draft PR and its marked comment.

Two of the checks are fidelity gates with a different repair rule: the last `test` requires the text between the markers to be byte-identical to `.superpowers/sdd/plan.md` (trailing newlines aside), and the `wc -c` test enforces GitHub's 65,536-character comment limit. If the comment is over that limit, never summarize, trim, or paraphrase the plan to fit — verbatim fidelity is the point of the handoff. Stop and report the size; the fix is splitting the source issue into smaller issues, not compressing the plan.

Verify the published result, not only the local files. The plan comment is located the same way `plan-to-implementation` will locate it — paginated, slurped, and filtered to the PR author (see `plan-to-implementation/rehydrate-and-finish.md`), so a handoff that verifies here is one that rehydrates there:

```bash
gh pr view "$pr" --json number,url,isDraft,state
gh api --paginate "repos/{owner}/{repo}/issues/$pr/comments" --jq '.[]' \
  | jq -s --arg author "$author" '[.[] | select(.user.login == $author and (.body | contains("<!-- BEGIN PLAN -->")))] | length'
```

Require `state == "OPEN"`, `isDraft == true`, a count of exactly `1`, one ordered marker pair inside that comment, and the complete plan between them. The URL printed by `gh pr comment` identifies the comment, but always re-verify by marker content — never trust positional state such as comment order or `--edit-last`.

The terminal output is the PR URL plus `Run plan-to-implementation for PR #M in a fresh session.` Do not dispatch implementation afterward.
