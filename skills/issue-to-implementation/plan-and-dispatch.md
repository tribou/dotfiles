# Plan & Dispatch: `gh` / scratch / PR Recipes

Exact commands for `SKILL.md`. Run all `gh` commands **from inside the repo** so `gh` infers the target from the git remote — never hardcode `--repo`.

## Link the issue

```bash
gh issue view <N> --json number,title,body,state
```

- If `title` starts with `[DRAFT]`, STOP — route to `brainstorming-to-issue`; the spec isn't finalized.
- Otherwise claim it and mark it in-progress by adding the `in-progress` label:

```bash
gh issue edit <N> --add-label "in-progress"
```

Keep the number — the PR body ends with `Closes #<N>`.

## Plan home (scratch, not docs/)

The plan is ephemeral **how**. It lives beside SDD's own scratch and is never committed. Write it **inside the execution worktree** (the one `superpowers:using-git-worktrees` sets up for SDD) so each run has its own copy and concurrent runs never collide on the path.

```bash
mkdir -p .superpowers/sdd

# Ensure the plan path is ignored WITHOUT touching the tracked root .gitignore.
# Match SDD's own convention: a nested ignore that covers the scratch dir.
git check-ignore -q .superpowers/sdd/plan.md || printf '*\n' > .superpowers/sdd/.gitignore

# writing-plans writes the plan HERE, not under docs/:
#   .superpowers/sdd/plan.md
```

Do **not** append `.superpowers/` to the repo's root `.gitignore` — that edits a tracked file. Checking the *directory* (`git check-ignore .superpowers/`) misreports it as un-ignored even when the nested rule already covers `plan.md`; always check the file path.

This is the `PLAN_FILE` you hand to subagent-driven-development:

```bash
# (SDD runs this itself — shown so the path contract is explicit)
scripts/task-brief .superpowers/sdd/plan.md 1
```

`git clean -fdx` destroys `.superpowers/` — that's fine; the plan's durable copy is the PR description (below). Recover an interrupted run from `.superpowers/sdd/plan.md` + `.superpowers/sdd/progress.md` while they exist.

## PR body carries the plan (durable how)

`superpowers:finishing-a-development-branch` opens the PR at the end of SDD. Its description MUST contain the plan and close the issue:

```bash
gh pr create --title "<type(scope): summary>" --body "$(cat <<'EOF'
<one-line summary>

Closes #<N>

<details>
<summary>Implementation plan</summary>

<!-- paste the contents of .superpowers/sdd/plan.md here -->

</details>
EOF
)"
```

The plan lives in exactly two temporary/durable places: `.superpowers/sdd/plan.md` (scratch, during the run) and the PR description (durable, after). It never lands under `docs/` and never on the issue.

## Guardrails

- No `--repo` hardcoding — run from the repo.
- Never `git add`/`commit` the plan file or `.superpowers/`.
- Never write the plan under `docs/superpowers/plans/`.
- No human "which execution approach?" prompt — auto-select subagent-driven-development.
- No human "what would you like to do?" prompt at the finish — auto-select "Push and create a Pull Request" (option 2 in a normal repo, option 1 on detached HEAD).
