# Resolve paths relative to this helper file (not relative to the test file)
_helper_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
load "${_helper_dir}/bats-support/load"
load "${_helper_dir}/bats-assert/load"

# Resolve the repo root relative to this helper file
REPO_ROOT="$(cd "${_helper_dir}/../.." && pwd)"

common_setup() {
  # Ensure DOTFILES is defined so platform.sh can source correctly
  export DOTFILES="$REPO_ROOT"

  # Source shared lib (order matters: _shared first)
  . "$REPO_ROOT/lib/_shared.sh"
  . "$REPO_ROOT/lib/commands.sh"
  # Export REPO_ROOT and all _dotfiles_* functions for use in bash -c subshells
  export REPO_ROOT
  export -f is_macos is_linux
  while IFS= read -r _fn; do
    export -f "$_fn" 2>/dev/null || true
  done < <(declare -F | awk '{print $3}' | grep '^_dotfiles_')
}
