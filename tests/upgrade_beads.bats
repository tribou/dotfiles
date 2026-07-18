setup() {
  load 'test_helper/common_setup'
  common_setup
}

# Regression: `just upgrade` runs `ansible-playbook --tags upgrade`, so any task
# not tagged `upgrade` is silently skipped. upgrade.yml's "Pull latest beads
# issues" task (tagged `upgrade`) guards on `bd_bin.rc == 0`, but `bd_bin` is
# only registered by beads.yml's "Detect beads CLI" task, which was tagged
# only `beads`. Under `--tags upgrade`, beads.yml never runs, so `bd_bin` is
# undefined and the `when` clause fails with "'bd_bin' is undefined".
@test "role: beads hydration tasks run under the upgrade tag so bd_bin is defined" {
  block="$(awk '/name: Include beads hydration/,/^$/' "$REPO_ROOT/roles/dotfiles/tasks/main.yml")"
  echo "$block" | grep -q 'beads.yml'
  echo "$block" | grep -qE 'tags:.*\bupgrade\b'
}
