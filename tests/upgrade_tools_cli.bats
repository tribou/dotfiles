setup() {
  load 'test_helper/common_setup'
  common_setup
}

# Regression: `just upgrade` runs `ansible-playbook --tags upgrade`, so any task
# not tagged `upgrade` is silently skipped. tools_cli.yml's "Upgrade claude CLI"
# and "Upgrade opencode CLI" tasks were only reachable via the `claude_opencode`
# tag, so `just upgrade` never ran them despite exiting 0.
@test "role: CLI agent tools (claude/opencode) upgrade tasks run under the upgrade tag" {
  block="$(awk '/name: Include CLI agent tools/,/^$/' "$REPO_ROOT/roles/dotfiles/tasks/main.yml")"
  echo "$block" | grep -q 'tools_cli.yml'
  echo "$block" | grep -qE 'tags:.*\bupgrade\b'
}
