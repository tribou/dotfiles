load 'bats-support/load'
load 'bats-assert/load'

# Resolve the repo root relative to this helper file
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"

common_setup() {
  # Source shared lib (order matters: _shared first)
  . "$REPO_ROOT/lib/_shared.sh"
  . "$REPO_ROOT/lib/commands.sh"
}
