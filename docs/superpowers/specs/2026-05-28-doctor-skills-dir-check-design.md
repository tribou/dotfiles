# doctor.sh skills-dir check

*Update `just doctor` to match the per-skill symlinking behavior in `bootstrap.sh`.*

## Problem

`bootstrap.sh`'s `linkSkillsDir` (lines 35–68) no longer creates a whole-directory
symlink for skills. Instead, for each of three targets it:

1. Migrates any old whole-dir symlink to a real **directory**.
2. Creates a per-skill symlink inside it: `<target>/<skill-name>` → `$DOTFILES/skills/<skill-name>`.
3. Prunes stale symlinks (skills removed from dotfiles).

The three targets are:

- `~/.claude/skills`
- `~/.config/opencode/skills`
- `~/.gemini/config/skills`

`scripts/doctor.sh` still checks a single entry `"~/.claude/skills~skills"` in
`check_symlinks`, expecting `~/.claude/skills` to itself be a whole-directory
symlink → `$DOTFILES/skills`. This is doubly wrong:

- It reports a **false failure** on `~/.claude/skills` (now a directory, not a symlink).
- It does not check the opencode or gemini targets at all.

## Approach

Add a dedicated `check_skills_dirs()` function (mirroring the existing
`check_symlinks` / `check_tools` one-function-per-check-type convention) and remove
the stale skills entry from `check_symlinks`. Granularity is **per-target-dir**:
verify each of the three dirs without enumerating every individual skill.

A new function is preferred over overloading `check_symlinks` with a
"directory-of-symlinks" entry type, which would mix two validation models in one
loop and make parsing branchier and harder to test.

## Design

### `check_skills_dirs()` — new function

- **Input:** accepts target dirs as args (for testing); defaults to the three real
  targets listed above.
- **Per-dir pass criteria:**
  1. Path exists and is a **directory**. A plain symlink fails with
     `run: ./bootstrap.sh` (catches the un-migrated old whole-dir-symlink layout).
  2. Every symlink inside the dir resolves to an existing directory under
     `$DOTFILES/skills/`. Any broken or foreign-pointing link fails the dir.
- **Output:** one `✓`/`✗` line per dir under a `Skills:` header, using the same
  `pass` / `fail` helpers and `run: ./bootstrap.sh` remediation as the rest of the
  script.
- **Empty-but-valid dir:** passes (no broken links). An edge case bootstrap won't
  normally produce.
- **Return:** non-zero if any dir failed, matching `check_symlinks` / `check_tools`.

### `check_symlinks()` change

- Remove the `"~/.claude/skills~skills"` entry from the default list (14 → 13 entries).

### `main()` wiring

- Run `check_skills_dirs` alongside `check_symlinks` and `check_tools`, counting its
  `✓`/`✗` output lines the same way.
- Update `total_checks`: **13 symlinks + 3 skills + 7 tools = 23**.

## Testing

Per CLAUDE.md rule 4, write failing tests first.

New tests in `tests/doctor.bats`:

- `check_skills_dirs` passes for a dir of valid skill symlinks.
- `check_skills_dirs` fails when a target is still a whole-dir symlink (old layout).
- `check_skills_dirs` fails on a broken/stale skill symlink.

Updated tests:

- Replace the `"~/.claude/skills~skills"` entry in the "all checks pass" test with
  setup for the three skills dirs.
- Update summary assertions from `21` to `23` in both the pass and fail tests.
