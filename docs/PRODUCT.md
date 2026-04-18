*What are we building and why? — user story, requirements, success criteria, and business domain context helpful for understanding **why** features are built the way they are*

# Product

## What is this?

A personal dotfiles repository that bootstraps developer environments quickly, predictably, and reproducibly. It captures years of accumulated CLI workflow preferences, tool configurations, and shell functions into a single installable package.

## User Story

As a developer setting up a new machine (or helping someone else set up theirs), I want to run a single command (`./bootstrap.sh`) and have my complete development environment ready — with all my preferred tools, aliases, key bindings, tmux layouts, editor plugins, and AI agent user configured — so I can be productive immediately without manual configuration.

## Core Requirements

- **Single-command bootstrap**: `./bootstrap.sh -i` sets up a fully working environment from scratch
- **Idempotent**: Running bootstrap repeatedly must not break anything
- **Fast shell startup**: Lib scripts and NVM loading are optimized to minimize prompt latency
- **Fuzzy-first UX**: Common tasks (branch checkout, npm scripts, AWS profiles) use fzf for interactive selection when no args are provided
- **Tmux-integrated**: Shell commands and project layouts are tmux-aware
- **AI-ready**: Includes an isolated `agent/` user account for LLM agent sessions with sandboxed git identity and shell profile
- **Tested**: Infrastructure and shell functions are validated via Docker + goss + bats-core

## Success Criteria

- `./bootstrap.sh` runs on a fresh macOS machine without errors
- `just test` passes inside Docker, validating the full environment
- Shell startup time remains fast (NVM loads with `--no-use`; plugins are lazy-loaded)
- Ticket-number-prefixed commits, fuzzy branch checkout, and tmux layouts all work out of the box
- The `agent` user account is correctly isolated from the primary user's identity

## Primary Platform

macOS (Darwin) is the primary target. Linux is supported for Docker and CI environments. Platform-specific code uses Darwin checks to guard macOS-only behavior.

## Non-Goals

- This is not a framework for others to use — it is a personal configuration
- It does not try to be minimal; it includes the full preferred stack for the owner's workflows
- It does not manage application installation beyond what `brew` and `mise` provide (no full package manager)
