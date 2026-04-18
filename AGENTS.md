*Non-interactive shell safety flags — everything else lives in CLAUDE.md*

# Agents

When using shell commands via agents, always prioritize non-interactive flags (like `npm init -y` or `apt-get install -y` or `yes | command`).
Do not run commands that expect a pager (`git diff` or `git log` might need `--no-pager`).
Never run commands that open interactive editors like `vi` or `nano` without configuring them to be non-interactive.
