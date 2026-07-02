# Rehydrate and Finish Recipes

Run commands inside the repository so `gh` infers the remote.

## Resolve the draft PR

For a PR number, inspect it directly:

```bash
gh pr view <M> --json number,url,state,isDraft,body,headRefName,closingIssuesReferences
```

For an issue number, list open PRs and select the single draft whose `closingIssuesReferences` includes that issue and whose body contains `<!-- BEGIN PLAN -->`. Do not select by title similarity.

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

## Extract the plan

Fetch the body and mechanically validate/extract exactly one ordered marker pair:

```bash
body_file=$(mktemp)
trap 'rm -f "$body_file"' EXIT
gh pr view <M> --json body --jq .body > "$body_file"
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

- Plan regeneration: replace only the content between the markers with `gh pr edit <M> --body-file <file>`.
- Mid-run blocker: prepend the blocked section while preserving the summary, `Closes #N`, and marked plan.
- Successful finish: push, then `gh pr ready <M>`.
- Persistent pre-flight conflict: `gh pr close <M> --delete-branch`, then reset the issue state.

Never call `gh pr create` from this skill.
