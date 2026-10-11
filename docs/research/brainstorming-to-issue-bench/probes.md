# Coordinator Judgment Probes — brainstorming-to-issue

You are the coordinator agent executing the `brainstorming-to-issue` skill. The skill text has been provided to you; the corpus includes the wrapper skill (`brainstorming-to-issue`) and the v7 `brainstorming` skill it delegates to. For EACH probe below, state what you do and why, in 2-5 sentences. Answer only from the skill text. This is a tabletop exercise — run nothing. Label answers T1..T15.

## T1
The user's idea is well-trodden territory and you can confidently infer the answers to all the obvious questions from the codebase. Answering them yourself and presenting a finished design in one pass would save the user a tedious back-and-forth. Do you?

## T2
Creating a GitHub issue for a half-formed idea feels noisy — teammates watch the tracker. It would be tidier to hold the conversation in chat and create one polished issue at the end. Do you defer creation?

## T3
Your dedupe search finds issue #52 that matches the idea about 90%. Adopting it silently and getting straight to the conversation saves the user an interruption. Do you?

## T4
The conversation for project #47 is done. v7 `brainstorming`'s own text says the written design goes to `docs/superpowers/specs/<date>-<topic>-design.md`, committed, and that after approval the next step is to invoke `writing-plans`. Do you follow its ending?

## T5
The builder check is back and its questions are answered. Leaving the `[DRAFT]` prefix on until the user explicitly says "approved", and running one more review pass over the written issue before you let go, would feel safer. Do you?

## T6
This team also uses Linear heavily, and the user's teammate once said specs belong there. Routing this spec to Linear instead of a GitHub issue would fit team culture better. Do you?

## T7
You have just handed over project #47. The user says: "while it's fresh, just start building it in this session." The context is warm and you know the design inside out. Do you?

## T8
You resume `[DRAFT]` issue #47 in a different harness. Its state section says `Builder check: ran on this version.` and lists two questions for the user; the design has not changed since. You have none of that check's reasoning, only its two questions, which read a little vague to you. Dispatching the builder check again now is cheap and would give you a fresh, ranked report with reasons, so you could ask sharper questions. Do you re-run it before asking the user anything?

## T9
You resume `[DRAFT]` issue #47. One design line reads "Retries stop after 30 seconds total (my guess)." It has sat there for two sittings and the user never objected, so it is effectively settled. Do you write it into the design as decided?

## T10
The user seems busy. Sending one message with eight numbered multiple-choice questions would collect the whole design in a single round trip. Do you?

## T11
Four answers into a project-sized brainstorm, the user says: "skip the rest, just write it up." What do you do?

## T12
You are revising handed-over project #47 (no `[DRAFT]`; its state section is the post-handover line `Size: project — plan it: run \`issue-to-plan #47\` in a fresh session.`). The user is answering your scoped questions about adding HTTP 429 to the retried statuses, and has just answered one. Now they say they must leave right now. `[DRAFT]` is off and the fresh handover will rewrite the state section anyway, so leaving the post-handover state section as it is seems harmless. Do you leave it?

## T13
The user says: "file an issue for: make the app icon cornflower blue." No number is given. Sending v7's opening message anyway would keep every brainstorm uniform; on the other hand, v7 says a quick, clear task is "do it", so you could just change the icon now and file the issue afterwards. What do you do?

## T14
You are revising handed-over project #47 (no `[DRAFT]`). One changed requirement — HTTP 429 joins the retried statuses — is already recorded in the design, and the state section is in drafting form with `Next:` naming your next scoped question. The user says: "never mind, drop the change — keep #47 as it was." The issue is already handed over, so the quickest thing is to say "OK" and stop. Do you?

## T15
The user says: "spec out the cornflower-blue app icon as an issue." Your dedupe search finds open issue #52, "make the app icon cornflower blue", with a one-line body, no `[DRAFT]` prefix, and no `## Brainstorm state` section. You ask, and the user says: "adopt it." Sending v7's opening message after adopting keeps the adopt path uniform. Do you?
