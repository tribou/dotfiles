# write-spec scenarios (RED/GREEN)

Scenario IDs `S1`-`S14` (plus the held-out `S5b`) and their checks for `skills/write-spec`. Later work cites scenarios by ID. This file is not part of the skill's runtime instructions.

## Shared harness

A run is one fresh `general-purpose` Agent with `model: "sonnet"`, no repo access beyond the stated skill directory. Scratch outputs go to `$SCRATCH/<arm>/<ID>.md` where `$SCRATCH` is the session scratchpad and `<arm>` is `red` or `green`. `$OUT` in every check is that output file.

- RED prompt: `You are asked to write a work item. Output only the final artifact as markdown, as you would file it. No tracker or repo is available. Input:\n<scenario input>`
- GREEN prompt: the RED prompt preceded by `Follow the skill at <absolute path>/skills/write-spec/SKILL.md; read it and any file it points to. Do not read anything else.`
- Inputs that name an issue come from the frozen snapshot `inputs/<N>.json` next to this file (`gh issue view <N> --json title,body`, captured 2026-10-14 and identical to the inputs of the PR #216 runs), never a live fetch. Render one as `jq -r '"Title: " + .title + "\n\nBody:\n" + .body' inputs/<N>.json` and paste it verbatim.
- Inputs fetched from issues are saved to files in `$SCRATCH/in`; the agent is told to read its input file and write its artifact to `$SCRATCH/<arm>/<ID>.md`. Both arms use identical inputs and instructions.
- Run each check as a shell one-liner with `OUT` set, for example `OUT=$SCRATCH/red/S1.md; ! grep -qi 'localstorage' $OUT`. A check passes when the command exits 0. A `Judge:` line is evaluated by reading the output.
- Size guards on the skill: `SKILL.md` at most 1350 words (raised from 1300 in the PR #216 review fixes), each other file in `skills/write-spec/` at most 450 (`wc -w`).
- RED runs only S1-S8, S10, S11, and S12 (each of its four inputs). S9, S13, and S14 need the skill's own file and filing rules, so they run only in GREEN. S5b is a held-out GREEN check of the claim rule; it has no RED arm.

---

## S1 - Paper's localStorage request

**Input:**

> We need to add localStorage to the search page so users don't lose their filters. Store all of the filters every time they change and reload them when they come back. Probably make a hook for it. Add unit tests, e2e tests, analytics, docs, error handling, and make sure it works everywhere.

**Checks:**

```bash
! grep -qi 'localstorage' $OUT
! grep -qi 'hook' $OUT
! grep -qiE 'analytics|unit test|e2e' $OUT
grep -q '^## Problem' $OUT
grep -q '^Unknown:' $OUT
```

Judge: the title's first word is a verb.

## S2 - Tiny task (#134)

**Input:**

> remove the old docker-machine functions from commands.sh, docker-machine was archived in 2021

**Checks:**

```bash
[ $(wc -w < $OUT) -le 45 ]
! grep -q '^## ' $OUT
grep -q 'docker-machine' $OUT
grep -q 'commands.sh' $OUT
```

## S3 - Title only, no stated reason (#141)

**Input:** the title of #141 only, no body: `jq -r .title inputs/141.json`

**Checks:**

```bash
grep -q 'Unknown: why this is wanted' $OUT
```

Judge: no unlabeled statement of a reason, benefit, or user pain.

## S4 - Solution baked into the request (#162)

**Input:**

> enable ForwardAgent in the mac ssh config and add a stable SSH_AUTH_SOCK symlink on linux so tmux survives reconnects

**Checks:**

```bash
! grep -qi 'ForwardAgent' $OUT   # unless under Decisions as user-decided
grep -qE 'Unknown:.*(trusted|host)' $OUT
grep -q '^## Acceptance' $OUT
awk '/^## Acceptance/{f=1;next}/^## /{f=0}f' $OUT | grep -iE 'agent|key' | grep -viE 'tmux|reconnect' | grep -q .
```

The last check asserts an Acceptance bullet for agent access on its own, apart from the tmux-after-reconnect bullet.

Judge: the `Unknown:` line concerns which hosts are trusted or need agent access. Both needs survive as Outcome or Acceptance: a plain `ssh` (no `-A`) gets the Mac's agent on the Linux host, and tmux panes keep it after a reconnect. A tmux-only item fails.

## S5 - Stale current-state claim (#42)

**Input:** `inputs/42.json`

**Checks:**

```bash
! awk '/^## Decisions/{f=1;next}/^## /{f=0}f' $OUT | grep -qi '10th'
grep -q '_shared.sh' $OUT
```

Judge: the claim sits in Problem or Evidence with its source (#153) and is worded as something to check; any ordering fix is conditional ("if ...").

## S5b - Held-out claim plus decided mechanism (invented; no wording of it appears in the skill)

**Input:** this text verbatim.

```text
Title: Let the CLI pick its profile from the environment

Body:
The config loader (`src/config/load.ts`) ignores the `--profile` flag, so `app --profile staging` still reads the prod settings. Checked last sprint on v2.3.

From the platform sync we decided to read the profile from `$APP_PROFILE` rather than add more flag parsing. The loader should also fail with `profile file not found: config/<profile>.yaml` when that file is missing. Once the flag works, `--profile` should win over `$APP_PROFILE`.

Staging deploys keep reading prod credentials, which is why this matters.
```

**Checks:**

```bash
grep -qF '$APP_PROFILE' $OUT
grep -qF 'profile file not found: config/<profile>.yaml' $OUT
! grep -iE '^- if' $OUT | grep -qiE 'from .?\$APP_PROFILE|rather than'
! awk '/^## Decisions/{f=1;next}/^## /{f=0}f' $OUT | grep -qi 'ignores'
```

Judge: the `$APP_PROFILE` choice and the missing-file error are unconditional Decisions; "ignores the `--profile` flag" sits in Problem or Evidence with its source (last sprint, v2.3) and is worded to recheck; any choice whose point is making `--profile` work (including its precedence over `$APP_PROFILE`) is conditional ("if the loader still ignores `--profile` ...").

## S6 - Post-brainstorm compression (#211)

**Input:** `inputs/211.json`

**Checks:**

```bash
grep -qF "alias qq='_dotfiles_qq #'" $OUT
grep -q 'DOTFILES_QQ_TIMEOUT' $OUT
grep -q 'lib/ai.sh' $OUT
grep -q '_dotfiles_ai_\*' $OUT
grep -q 'DOTFILES_AI_' $OUT
grep -q '^## Decisions' $OUT
[ $(wc -w < $OUT) -le 750 ]
```

Judge: about 350 words is ideal; cuts per the #211 Cut list (error table, runtime-flow walkthrough, refactor file list, test list, brainstorm narrative).

## S7 - Bug (#202)

**Input:** `inputs/202.json`

**Checks:**

```bash
grep -qF "Can't open display: (null)" $OUT
grep -q 'xclip' $OUT
grep -q 'OSC 52' $OUT
! grep -qi 'base64' $OUT
```

Heading order check: the headings Observed, Expected, Reproduction, Acceptance appear in that order.

```bash
grep -n '^## ' $OUT | grep -oE 'Observed|Expected|Reproduction|Acceptance' | tr '\n' ' ' | grep -q 'Observed Expected Reproduction Acceptance'
```

## S8 - Investigation (#170 raw idea)

**Input:**

> Should we start using the new GitHub stacked PRs for issues that span past the 65k character limits? Pressure test whether this is a good idea and recommend.

**Checks:**

```bash
grep -n '^## ' $OUT | grep -oE 'Question|Why now|Timebox|Deliverable' | tr '\n' ',' | grep -q 'Question,Why now,Timebox,Deliverable,'
grep -A1 '^## Timebox' $OUT | grep -q 'Unknown'
```

Judge: Deliverable is learning or a recommendation, not "implement stacked PRs".

## S9 - ADR (#170 decision)

**Input:** `inputs/170.json`, plus the instruction "record the decision". Run in a scratch git repo: `REPO=$SCRATCH/repos/S9`, created with `git init` and an untracked `README.md`, no commits, no `docs/`. The prompt replaces "No tracker or repo is available." with "No tracker is available. Your working directory is the git repository at `$REPO`. Nobody is available to answer questions." and asks the agent to save everything it says to the user to `$SCRATCH/<arm>/S9-reply.md`. `$OUT` is the ADR file the run writes.

**Checks:**

```bash
[ $(ls $REPO/docs/adr/*.md 2>/dev/null | wc -l) -eq 1 ] && OUT=$(ls $REPO/docs/adr/*.md)
[ -z "$(git -C $REPO rev-list --all 2>/dev/null)" ]
! git -C $REPO status --porcelain | grep -q '^A'
grep -q '^Status:' $OUT
grep -n '^## ' $OUT | grep -oE 'Context|Decision|Consequences|Alternatives' | tr '\n' ',' | grep -q 'Context,Decision,Consequences,Alternatives,'
grep -qF '## Execution order' $OUT
grep -qi 'general availability' $OUT
```

Judge: the ADR obeys `adr.md`'s cut list (no requirement numbering, no command lists, no triage narrative) and is about 200 words.

The first line asserts the run wrote exactly one `docs/adr/<slug>.md`; the next two assert no commit and nothing staged.

## S10 - Project brief from an unshaped idea (#192)

**Input:** the title plus the `## Summary` and `## Motivation / Context` sections only of #192: everything before the body's third `## ` heading (`## Architecture / Ownership`). Both arms slice the same way:

```bash
jq -r '"Title: " + .title + "\n\nBody:\n" + .body' inputs/192.json | awk '/^## /{n++} n<=2' > $SCRATCH/in/S10.txt
```

**Checks:**

```bash
grep -n '^## ' $OUT | grep -oE 'Problem|Appetite|Outcome|Approach|Risks|No-gos' | tr '\n' ',' | grep -q 'Problem,Appetite,Outcome,Approach,Risks,No-gos,'
grep -A1 '^## Appetite' $OUT | grep -q 'Unknown'
```

Judge: the run stops after the brief and offers 3-5 vertical children, none a layer (DB/API/UI/tests).

## S11 - Settled spec stays one issue (#192)

**Input:** the full `inputs/192.json` (the settled spec).

**Checks:**

```bash
grep -q '^## Decisions' $OUT
! grep -q '^## Appetite' $OUT
```

Judge: one issue, not a brief.

## S12 - Identifiers and evidence kept verbatim (#187, #181, #180, #154)

**Input:** four separate runs, one per body: `inputs/187.json`, then `inputs/181.json`, `inputs/180.json`, and `inputs/154.json`. Each run has its own `$OUT` (`S12-187.md`, `S12-181.md`, `S12-180.md`, `S12-154.md`).

**Checks:**

```bash
# #187
grep -qF 'which gopls' $OUT
# #181
grep -qF 'issue:N' $OUT
grep -qF 'pr:M' $OUT
grep -qF 'stubbed `gh`' $OUT
# #180
grep -qF '~/.local/share/opencode/opencode.db' $OUT
grep -qF '~/.gemini/antigravity-cli/conversations/<uuid>.db' $OUT
grep -q '^## Evidence' $OUT
grep -qiE 'single|one (executable )?(TypeScript )?script' $OUT
# #154
grep -qF 'just upgrade' $OUT
grep -qi 'zoxide' $OUT
```

## S13 - Filing behaviors

**Input:** six sub-cases: (a) an interactive issue request with a GitHub remote described in context; (b) a request needing independent outcomes plus "just file it"; (c) any request with no tracker described; (d) an ADR request; (e) an interactive ADR request in a repo with no tracker; (f) a non-interactive issue request with two trackers (a GitHub remote and a Linear connection) and no instruction naming one.

Each sub-case's context and request is a file in `$SCRATCH/in` (`S13a.txt`–`S13f.txt`; `S13b.txt` is a GitHub-remote context, "write this up. Just file it.", then `S10.txt`; `S13e.txt` and `S13f.txt` reuse the requests of `S13d.txt` and `S13a.txt`). The agent has no tracker tools: it writes each tracker command it would run now as a line `ACTION: <command>`, and saves its whole reply to the user to `$OUT`. (d) runs in a scratch git repo (`REPO=$SCRATCH/repos/S13d`, set up as for S9) and states that nobody is available to answer. (e) runs in its own scratch repo (`REPO=$SCRATCH/repos/S13e`) and saves only the first turn's reply.

```bash
# (a)
! grep -qE '^ACTION:.*(create|new)' $OUT
# (b)
[ $(grep -cE '^ACTION: *[a-z]+ +(issue +)?create\b' $OUT) -eq 1 ]
# (c)
! grep -q '^ACTION:' $OUT
# (d)
[ $(ls $REPO/docs/adr/*.md 2>/dev/null | wc -l) -eq 1 ]
grep -qi 'uncommitted' $OUT
[ -z "$(git -C $REPO rev-list --all 2>/dev/null)" ]
! git -C $REPO status --porcelain | grep -q '^A'
# (e)
[ $(ls $REPO/docs/adr/*.md 2>/dev/null | wc -l) -eq 0 ]
# (f)
! grep -q '^ACTION:' $OUT
```

**Checks (read the run's output and tool calls):**

- (a) The output shows the artifact plus its destination and asks for approval; it runs no create command.
- (b) It files one parent brief; it derives and files no children.
- (c) The final output is the markdown, with no approval prompt.
- (d) It writes the file, says it is uncommitted, and runs no `git add`, `commit`, or `push`.
- (e) It shows the ADR and its destination path and asks for approval; it writes no file yet.
- (f) The final output is the markdown; it neither picks a tracker nor waits on a question.

## S14 - Skill-selection micro-test

**Input:** list the repo's skills with their descriptions (`grep -h '^description:' skills/*/SKILL.md .agents/skills/*/SKILL.md`, deduplicated by skill name, since `.agents/skills/` includes symlinks to `skills/`), then give six prompts, one at a time: "file an issue for X", "write up a bug for Y", "draft an ADR for Z", "spike ticket for W", "write a project brief for V", "brainstorm this feature with me".

**Checks:**

- `write-spec` is chosen for the first five prompts.
- `write-spec` is not chosen for the last ("brainstorm this feature with me"); `brainstorming` or `brainstorming-to-issue` are both acceptable.

Judge: 3 reps each; the reps must converge on the same choice.
