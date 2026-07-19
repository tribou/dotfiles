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

## Draft PR body

Construct the body through a file so the plan is copied verbatim:

```markdown
<one-line summary>

Closes #N

<details>
<summary>Implementation plan</summary>

<!-- BEGIN PLAN -->
…contents of .superpowers/sdd/plan.md…
<!-- END PLAN -->

</details>
```

```bash
set -e
body_file=$(mktemp)
trap 'rm -f "$body_file"' EXIT
{
  printf '%s\n\n' "$SUMMARY"
  printf 'Closes #%s\n\n' "$ISSUE"
  printf '<details>\n<summary>Implementation plan</summary>\n\n'
  printf '<!-- BEGIN PLAN -->\n'
  cat .superpowers/sdd/plan.md
  printf '\n<!-- END PLAN -->\n\n</details>\n'
} > "$body_file"

begin_line=$(grep -nF '<!-- BEGIN PLAN -->' "$body_file" | cut -d: -f1)
end_line=$(grep -nF '<!-- END PLAN -->' "$body_file" | cut -d: -f1)
test "$(grep -Fc '<!-- BEGIN PLAN -->' "$body_file")" -eq 1
test "$(grep -Fc '<!-- END PLAN -->' "$body_file")" -eq 1
test "$begin_line" -lt "$end_line"
test "$(wc -c < "$body_file")" -le 65536
test "$(sed -n "$((begin_line+1)),$((end_line-1))p" "$body_file")" = "$(cat .superpowers/sdd/plan.md)"

gh pr create --draft --title "$TITLE" --body-file "$body_file"
```

Any validation failure aborts before `gh pr create`. Then repair the body or plan (for example, remove or escape a literal marker string inside the plan), re-run the validation, and create the PR only once it passes — the durable handoff still requires the published draft PR.

Two of the checks are fidelity gates with a different repair rule: the last `test` requires the text between the markers to be byte-identical to `.superpowers/sdd/plan.md` (trailing newlines aside), and the `wc -c` test enforces GitHub's 65,536-character body limit. If the body is over that limit, never summarize, trim, or paraphrase the plan to fit — verbatim fidelity is the point of the handoff. Stop and report the size; the fix is splitting the source issue into smaller issues, not compressing the plan.

Verify the published result, not only the local body file:

```bash
gh pr view --json number,url,isDraft,body,state
```

Require `state == "OPEN"`, `isDraft == true`, exactly one ordered marker pair, and the complete plan between them.

The terminal output is the PR URL plus `Run plan-to-implementation for PR #M in a fresh session.` Do not dispatch implementation afterward.
