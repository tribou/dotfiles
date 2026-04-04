# Agent Directory Design

## Goal

Move the agent-user feature into a dedicated top-level `agent/` directory so agent-only files are structurally isolated from globally sourced shell libraries.

## Design

- `agent/overrides.sh` holds the agent-only git identity and prompt overrides.
- `agent/setup-user.sh` holds the Linux-only setup flow for creating and configuring the `agent` user.
- `lib/index.sh` returns to a generic contract: source every `lib/*.sh` file except `lib/index.sh`.
- Agent shell startup continues to work by symlinking `~agent/.agent_overrides.sh` to `agent/overrides.sh`.

## Why

The previous layout put `lib/agent_overrides.sh` beside globally sourced libraries. That forced `lib/index.sh` to carry a one-off exclusion, and the bug happened when that boundary was violated. A dedicated `agent/` directory makes the purpose explicit and removes the need for filename-based exceptions.
