# Rehydrate and Finish Recipes

Run commands inside the repository so `gh` infers the remote.

## Resolve the draft PR

For a PR number, inspect it directly:

```bash
gh pr view <M> --json number,url,state,isDraft,headRefName,closingIssuesReferences
```

For an issue number, list open PRs and select the single draft whose `closingIssuesReferences` includes that issue. Do not select by title similarity. Confirm the selection by plan comment, not description: exactly one comment on that PR contains `<!-- BEGIN PLAN -->` — zero or multiple marker-bearing comments: stop and report.

## Resolve the worktree

Read `headRefName` from the PR. First search `git worktree list --porcelain` for exactly `refs/heads/<headRefName>`:

```bash
head_ref=$(gh pr view <M> --json headRefName --jq .headRefName)
git worktree list --porcelain | awk -v ref="refs/heads/$head_ref" '
  $1 == "worktree" { path = substr($0, 10) }
  $1 == "branch" && $2 == ref { print path }
'
```

- Exactly one match: enter that path. This is the worktree Phase A left behind.
- More than one match: stop; worktree state is ambiguous.
- No match: use `superpowers:using-git-worktrees` directory selection, native-tool preference, ignore checks, setup, and baseline verification to create an isolated worktree for the **existing PR branch**, not a new feature branch. With the git fallback, run `git fetch origin <headRefName>`, then use `git worktree add <path> <headRefName>` when the local branch exists, or `git worktree add -b <headRefName> <path> origin/<headRefName>` otherwise.

Inside the resolved path, run `gh pr checkout <M>` and verify `git branch --show-current` equals `headRefName`. This works both on the original machine and on a fresh machine without guessing a worktree path.

## Locate the plan comment

One lookup resolves both the comment's id and its body; every later step reuses it. Three properties are load-bearing — dropping any one of them breaks rehydration on a healthy PR:

- `--paginate`: the plan comment is posted at PR creation, so it is the *oldest* comment and the first to fall off page 1 once the PR collects 30 comments.
- Slurp before counting: with `--paginate` alone `--jq` runs once per page, so a per-page `length == 1` guard passes on two different pages and yields two comments. Stream objects with `--jq '.[]'`, then `jq -s` them into one array.
- `select(.user.login == $author)`: the marker is ordinary text, so a reviewer's quote-reply contains it too. Without the author filter a quoted plan counts as a second plan comment and blocks a healthy PR.

```bash
set -euo pipefail
pr=<M>
author=$(gh pr view "$pr" --json author --jq .author.login)

plan_comments=$(gh api --paginate "repos/{owner}/{repo}/issues/$pr/comments" --jq '.[]' \
  | jq -s --arg author "$author" \
      '[.[] | select(.user.login == $author and (.body | contains("<!-- BEGIN PLAN -->")))]')

count=$(printf '%s' "$plan_comments" | jq 'length')
test "$count" -eq 1 || { echo "STOP: $count plan comments on PR $pr (need exactly 1)"; exit 1; }

comment_id=$(printf '%s' "$plan_comments" | jq -r '.[0].id')
```

Report the count, not just the failure: `0` means the plan comment is missing or was deleted, `2+` means a stale revision is still marked. They need different human fixes, so never collapse them into one message.

## Extract the plan

Mechanically validate and extract exactly one ordered marker pair from that comment:

```bash
body_file=.superpowers/sdd/plan-comment.md
mkdir -p .superpowers/sdd
git check-ignore -q .superpowers/sdd/plan.md || printf '*\n' > .superpowers/sdd/.gitignore
printf '%s' "$plan_comments" | jq -r '.[0].body' > "$body_file"
awk '
  $0 == "<!-- BEGIN PLAN -->" { if (++begin != 1) exit 2; capture = 1; next }
  $0 == "<!-- END PLAN -->" { if (!capture || ++end != 1) exit 3; capture = 0; next }
  capture { print }
  END { if (begin != 1 || end != 1 || capture) exit 4 }
' "$body_file" > .superpowers/sdd/plan.md
test -s .superpowers/sdd/plan.md
```

Write only the bytes between those markers to `.superpowers/sdd/plan.md`. Preserve an existing `.superpowers/sdd/progress.md`; it is the crash-recovery ledger.

## Update the existing PR

- **Plan regeneration:** rewrite the same comment in place by its numeric comment ID — never post a second plan comment, never rely on `gh pr comment --edit-last` (it is positional and edits the wrong comment once anyone else comments). `$comment_id` is already resolved by the lookup above. Rebuild the validated comment file per `plan-and-publish.md`, then PATCH and re-verify:

  ```bash
  gh api "repos/{owner}/{repo}/issues/comments/$comment_id" -X PATCH -F body=@"$comment_file"
  ```

  Exit 0 means the API accepted a write, not that the durable plan now matches the plan you are about to execute. Re-run the lookup and require all three: the count is still `1`, `.[0].id` still equals `$comment_id` (proving an edit, not an accidental second comment), and the plan re-extracted through the awk validator is byte-identical to `.superpowers/sdd/plan.md`. Only then re-run pre-flight review.

- **Mid-run blocker:** prepend the blocked section to the PR description while preserving the summary and `Closes #N`; the plan comment is separate and untouched. Read, prepend, write back — never `gh pr edit <M> --body '<new section>'`, because `--body` **replaces** the description. Dropping `Closes #N` removes the PR from `closingIssuesReferences`, which is the only remaining link from the issue to this PR; a later fresh entry then resolves zero PRs, and matching by title is forbidden, so the branch is stranded.

  ```bash
  set -euo pipefail
  old=.superpowers/sdd/pr-description-old.md
  new=.superpowers/sdd/pr-description-new.md

  gh pr view "$pr" --json body --jq .body > "$old"
  test -s "$old"

  {
    printf '## ⚠️ Blocked — needs human decision\n\n'
    printf -- '- **Task:** %s\n' "$TASK"
    printf -- '- **Reason / finding:** %s\n' "$REASON"
    printf -- '- **Conflicting plan text:** %s\n' "$CONFLICT"
    printf -- '- **Decision needed:** %s\n\n' "$DECISION"
    printf -- '- **Progress:** %s\n' "$PROGRESS"
    printf -- '- **Test status:** %s\n\n' "$TEST_STATUS"
    printf -- '---\n\n'
    cat "$old"
  } > "$new"

  gh pr edit "$pr" --body-file "$new"

  gh pr view "$pr" --json body,isDraft,closingIssuesReferences --jq '
    if (.body | contains("Closes #")) and .isDraft and (.closingIssuesReferences | length > 0)
    then "ok" else error("blocker edit dropped Closes #N, the draft state, or the issue link") end'
  ```

- **Successful finish:** push, then `gh pr ready <M>`.
- **Persistent pre-flight conflict:** `gh pr close <M> --delete-branch`, then reset the issue state.

Never call `gh pr create` from this skill.
