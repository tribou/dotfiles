setup() {
  load 'test_helper/common_setup'
  common_setup
}

# Regression: `just upgrade` runs the brew-installed ansible, and the play's
# `brew upgrade` (upgrade_all) would upgrade ansible + its python runtime while
# that very interpreter is running. Ansible lazily imports its module-result
# deserialization profile AFTER a module completes, so replacing those files
# mid-run crashes with:
#   Module result deserialization failed: Unknown profile name 'module_legacy_m2c'.
# The upgrade recipe must protect ansible and its python by pinning them for the
# duration of the play, then upgrade them afterward in a separate process where
# self-replacement is harmless. The python formula is derived from
# `brew deps ansible` so it survives a future python major bump (python@3.15+).
@test "justfile: upgrade pins ansible+python for the play, then upgrades them afterward" {
  # Extract the upgrade recipe body: from its header to the next unindented line.
  block="$(sed -n '/^upgrade \*args:/,/^[^[:space:]]/p' "$REPO_ROOT/justfile")"
  [ -n "$block" ]

  # ansible is part of the protected set that gets pinned.
  echo "$block" | grep -Eq '\bansible\b'
  # Pins the protected set before the play (protects the running runtime).
  echo "$block" | grep -q 'brew pin'
  # Derives the python runtime formula from ansible's deps (not hardcoded).
  echo "$block" | grep -q 'brew deps ansible'
  # Upgrades the protected set in a separate process after the play.
  echo "$block" | grep -q 'brew upgrade'

  pin_line="$(echo "$block" | grep -n 'brew pin' | head -1 | cut -d: -f1)"
  play_line="$(echo "$block" | grep -n 'ansible-playbook' | head -1 | cut -d: -f1)"
  upg_line="$(echo "$block" | grep -n 'brew upgrade' | head -1 | cut -d: -f1)"

  [ -n "$pin_line" ] && [ -n "$play_line" ] && [ -n "$upg_line" ]
  # pin must come before the play, and the ansible upgrade must come after it.
  [ "$pin_line" -lt "$play_line" ]
  [ "$play_line" -lt "$upg_line" ]
}
