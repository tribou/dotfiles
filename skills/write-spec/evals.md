# write-spec scenarios (RED/GREEN)

Scenario IDs `S1`-`S14` and their checks. Later work cites scenarios by ID. This file is not part of the skill's runtime instructions.

## Shared harness

A run is one fresh `general-purpose` Agent with `model: "sonnet"`, no repo access beyond the stated skill directory. Scratch outputs go to `$SCRATCH/<arm>/<ID>.md` where `$SCRATCH` is the session scratchpad and `<arm>` is `red` or `green`. `$OUT` in every check is that output file.

- RED prompt: `You are asked to write a work item. Output only the final artifact as markdown, as you would file it. No tracker or repo is available. Input:\n<scenario input>`
- GREEN prompt: the RED prompt preceded by `Follow the skill at <absolute path>/skills/write-spec/SKILL.md; read it and any file it points to. Do not read anything else.`
- Inputs that name an issue are fetched with `gh issue view <N> --json title,body -q ...` and pasted verbatim.
- Inputs fetched from issues are saved to files in `$SCRATCH/in`; the agent is told to read its input file and write its artifact to `$SCRATCH/<arm>/<ID>.md`. Both arms use identical inputs and instructions.
- Run each check as a shell one-liner with `OUT` set, for example `OUT=$SCRATCH/red/S1.md; ! grep -qi 'localstorage' $OUT`. A check passes when the command exits 0. A `Judge:` line is evaluated by reading the output.
- RED runs only S1-S8, S10, S11, and S12 (each of its four inputs). S9, S13, and S14 need the skill's own file and filing rules, so they run only in GREEN.

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

**Input:** the title of #141 only, no body: `gh issue view 141 --json title -q .title`

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
```

Judge: the `Unknown:` line concerns which hosts are trusted or need agent access.

## S5 - Stale current-state claim (#42)

**Input:** `gh issue view 42 --json title,body`

**Checks:**

```bash
! awk '/^## Decisions/{f=1;next}/^## /{f=0}f' $OUT | grep -qi '10th'
grep -q '_shared.sh' $OUT
```

Judge: the claim sits in Problem or Evidence with its source (#153) and is worded as something to check; any ordering fix is conditional ("if ...").

## S6 - Post-brainstorm compression (#211)

**Input:** `gh issue view 211 --json title,body`

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

**Input:** `gh issue view 202 --json title,body`

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

**Input:** `gh issue view 170 --json title,body`, plus the instruction "record the decision". Run in a scratch git repo: `REPO=$SCRATCH/repos/S9`, created with `git init` and an untracked `README.md`, no commits, no `docs/`. The prompt replaces "No tracker or repo is available." with "No tracker is available. Your working directory is the git repository at `$REPO`. Nobody is available to answer questions." and asks the agent to save everything it says to the user to `$SCRATCH/<arm>/S9-reply.md`. `$OUT` is the ADR file the run writes.

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
gh issue view 192 --json title,body -q '"Title: " + .title + "\n\nBody:\n" + .body' | awk '/^## /{n++} n<=2' > $SCRATCH/in/S10.txt
```

**Checks:**

```bash
grep -n '^## ' $OUT | grep -oE 'Problem|Appetite|Outcome|Approach|Risks|No-gos' | tr '\n' ',' | grep -q 'Problem,Appetite,Outcome,Approach,Risks,No-gos,'
grep -A1 '^## Appetite' $OUT | grep -q 'Unknown'
```

Judge: the run stops after the brief and offers 3-5 vertical children, none a layer (DB/API/UI/tests).

## S11 - Settled spec stays one issue (#192)

**Input:** the full `gh issue view 192 --json title,body` (the settled spec).

**Checks:**

```bash
grep -q '^## Decisions' $OUT
! grep -q '^## Appetite' $OUT
```

Judge: one issue, not a brief.

## S12 - Identifiers and evidence kept verbatim (#187, #181, #180, #154)

**Input:** four separate runs, one per body: `gh issue view 187 --json title,body`, then the same for #181, #180, and #154. Each run has its own `$OUT` (`S12-187.md`, `S12-181.md`, `S12-180.md`, `S12-154.md`).

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
# #154
grep -qF 'just upgrade' $OUT
grep -qi 'zoxide' $OUT
```

## S13 - Filing behaviors

**Input:** four sub-cases: (a) an interactive issue request with a GitHub remote described in context; (b) a request needing independent outcomes plus "just file it"; (c) any request with no tracker described; (d) an ADR request.

Each sub-case's context and request is a file in `$SCRATCH/in` (`S13a.txt`–`S13d.txt`; `S13b.txt` is a GitHub-remote context, "write this up. Just file it.", then `S10.txt`). The agent has no tracker tools: it writes each tracker command it would run now as a line `ACTION: <command>`, and saves its whole reply to the user to `$OUT`. (d) runs in a scratch git repo (`REPO=$SCRATCH/repos/S13d`, set up as for S9) and states that nobody is available to answer.

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
```

**Checks (read the run's output and tool calls):**

- (a) The output shows the artifact plus its destination and asks for approval; it runs no create command.
- (b) It files one parent brief; it derives and files no children.
- (c) The final output is the markdown, with no approval prompt.
- (d) It writes the file, says it is uncommitted, and runs no `git add`, `commit`, or `push`.

## S14 - Skill-selection micro-test

**Input:** list the repo's skills with their descriptions (`grep -h '^description:' skills/*/SKILL.md .agents/skills/*/SKILL.md`, deduplicated by skill name, since `.agents/skills/` includes symlinks to `skills/`), then give six prompts, one at a time: "file an issue for X", "write up a bug for Y", "draft an ADR for Z", "spike ticket for W", "write a project brief for V", "brainstorm this feature with me".

**Checks:**

- `write-spec` is chosen for the first five prompts.
- `write-spec` is not chosen for the last ("brainstorm this feature with me"); `brainstorming` or `brainstorming-to-issue` are both acceptable.

Judge: 3 reps each; the reps must converge on the same choice.
