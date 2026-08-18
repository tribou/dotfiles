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

```bash
set -e
desc_file=$(mktemp)
{
  printf '%s\n\n' "$SUMMARY"
  printf '## Test plan\n\n%s\n\n' "$TEST_PLAN"
  printf 'Closes #%s\n' "$ISSUE"
} > "$desc_file"
test "$(grep -Fc '<!-- BEGIN PLAN -->' "$desc_file")" -eq 0
test "$(grep -Fc '<!-- END PLAN -->' "$desc_file")" -eq 0
```

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

```bash
set -e
comment_file=$(mktemp)
trap 'rm -f "$comment_file"' EXIT
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

Verify the published result, not only the local files:

```bash
gh pr view --json number,url,isDraft,state,comments
```

Require `state == "OPEN"`, `isDraft == true`, exactly one comment whose body contains `<!-- BEGIN PLAN -->`, one ordered marker pair inside it, and the complete plan between them. The URL printed by `gh pr comment` identifies the comment, but always re-verify by marker content — never trust positional state such as comment order or `--edit-last`.

The terminal output is the PR URL plus `Run plan-to-implementation for PR #M in a fresh session.` Do not dispatch implementation afterward.
