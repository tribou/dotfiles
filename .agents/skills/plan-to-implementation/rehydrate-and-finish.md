# Rehydrate and Finish Recipes

Run commands inside the repository so `gh` infers the remote.

## Resolve the draft PR

For a PR number, inspect it directly:

```bash
gh pr view <M> --json number,url,state,isDraft,body,headRefName,closingIssuesReferences
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
- No match: use `superpowers:using-git-worktrees` directory selection, native-tool preference, ignore checks, setup, and baseline verification to create an isolated worktree for the **existing PR branch**, not a new feature branch — no consent prompt; the worktree preference is already declared as always-isolate. With the git fallback, run `git fetch origin <headRefName>`, then use `git worktree add <path> <headRefName>` when the local branch exists, or `git worktree add -b <headRefName> <path> origin/<headRefName>` otherwise.

Inside the resolved path, run `gh pr checkout <M>` and verify `git branch --show-current` equals `headRefName`. This works both on the original machine and on a fresh machine without guessing a worktree path.

## Extract the plan

Fetch the marker-bearing comment's body and mechanically validate/extract exactly one ordered marker pair. PRs are issues, so conversation comments come from the issues API:

```bash
body_file=$(mktemp)
trap 'rm -f "$body_file"' EXIT
gh api repos/{owner}/{repo}/issues/<M>/comments --paginate --slurp |
  jq -r '[.[][] | select(.body | contains("<!-- BEGIN PLAN -->"))] | if length == 1 then .[0].body else empty end' > "$body_file"
test -s "$body_file"
mkdir -p .superpowers/sdd
git check-ignore -q .superpowers/sdd/plan.md || printf '*\n' > .superpowers/sdd/.gitignore
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

- Plan regeneration: rewrite the same comment in place by its numeric comment ID — never post a second plan comment, never rely on `gh pr comment --edit-last` (it is positional and edits the wrong comment once anyone else comments). Rebuild the validated comment file per `plan-and-publish.md`, then:

  ```bash
  comment_id=$(gh api repos/{owner}/{repo}/issues/<M>/comments --paginate --slurp |
    jq -r '[.[][] | select(.body | contains("<!-- BEGIN PLAN -->"))] | if length == 1 then .[0].id else empty end')
  test -n "$comment_id"
  gh api repos/{owner}/{repo}/issues/comments/"$comment_id" -X PATCH -F body=@"$comment_file"
  ```

- Mid-run blocker: prepend the blocked section to the PR description while preserving the summary and `Closes #N`; the plan comment is separate and untouched.
- Successful finish: inspect both `.superpowers/sdd/plan.md` and the final review result and state each result separately. Follow the trigger, required content, gates, and sequencing in `SKILL.md`. When its step 4 requires a description update:
  1. Create `description_file=$(mktemp)`, fetch the existing description with `gh pr view <M> --json body --jq .body > "$description_file"`, edit that file, and apply it with `gh pr edit <M> --body-file "$description_file"`.
  2. Re-fetch with `gh pr view <M> --json body --jq .body`, verify the result against the `SKILL.md` contract, then remove the temporary file with `rm -f "$description_file"`.
- Persistent pre-flight conflict: `gh pr close <M> --delete-branch`, then reset the issue state.

Never call `gh pr create` from this skill.
