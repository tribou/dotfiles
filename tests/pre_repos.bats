# covers: scripts/bootstrap/pre_repos.sh mise.toml tmux/tmux-conf
setup() {
  load 'test_helper/common_setup'
  common_setup
  export HOME="$BATS_TEST_TMPDIR/home"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
  PLUGINS="$HOME/.tmux/plugins"
  TPM="$PLUGINS/tpm"
  mkdir -p "$PLUGINS"
  make_clone "$TPM" https://github.com/tmux-plugins/tpm
  SCRIPT="$REPO_ROOT/scripts/bootstrap/pre_repos.sh"
}

# make_clone DIR ORIGIN: a clean one-commit Git checkout with that origin.
make_clone() {
  git init -q "$1"
  git -C "$1" commit -q --allow-empty -m init
  git -C "$1" remote add origin "$2"
}

# stray NAME SLUG: what TPM leaves in its own checkout when
# TMUX_PLUGIN_MANAGER_PATH is unset (the May 2026 regression).
stray() {
  make_clone "$TPM/$1" "https://git::@github.com/$2"
}

@test "pre_repos: removes a stray plugin clone from ~/.tmux/plugins/tpm when ~/.tmux/plugins has it" {
  stray tmux-sensible tmux-plugins/tmux-sensible
  make_clone "$PLUGINS/tmux-sensible" https://git::@github.com/tmux-plugins/tmux-sensible
  run "$SCRIPT"
  assert_success
  [ ! -e "$TPM/tmux-sensible" ]
  [ -d "$PLUGINS/tmux-sensible/.git" ]
  [ -z "$(git -C "$TPM" status --porcelain)" ]
  assert_output --partial 'changed: removed stray ~/.tmux/plugins/tpm/tmux-sensible'
}

@test "pre_repos: moves a stray plugin clone into ~/.tmux/plugins when it is the only copy" {
  stray tmux-mem-cpu-load thewtex/tmux-mem-cpu-load
  run "$SCRIPT"
  assert_success
  [ ! -e "$TPM/tmux-mem-cpu-load" ]
  [ "$(git -C "$PLUGINS/tmux-mem-cpu-load" remote get-url origin)" = https://git::@github.com/thewtex/tmux-mem-cpu-load ]
  assert_output --partial 'changed: moved stray ~/.tmux/plugins/tpm/tmux-mem-cpu-load to ~/.tmux/plugins/tmux-mem-cpu-load'
}

@test "pre_repos: leaves anything it cannot prove is TPM debris" {
  printf 'edit\n' > "$TPM/README.md"                                          # an edit to tpm itself
  stray tmux-unlisted someone/tmux-unlisted                                    # not in tmux-conf
  make_clone "$TPM/tmux-yank" https://github.com/tmux-plugins/tmux-yank        # not cloned by TPM
  stray tmux-open tmux-plugins/tmux-open && printf 'x\n' > "$TPM/tmux-open/mine" # has its own changes
  mkdir "$TPM/tmux-copycat"                                                    # not a clone
  run "$SCRIPT"
  assert_success
  for path in README.md tmux-unlisted tmux-yank tmux-open/mine tmux-copycat; do
    [ -e "$TPM/$path" ] || fail "removed $path"
  done
  assert_output ''
}

@test "pre_repos: does nothing without a tpm checkout" {
  rm -rf "$TPM"
  run "$SCRIPT"
  assert_success
  assert_output ''
}

@test "pre_repos: --dry-run reports without changing anything" {
  stray tmux-sensible tmux-plugins/tmux-sensible
  stray tmux-yank tmux-plugins/tmux-yank
  make_clone "$PLUGINS/tmux-sensible" https://git::@github.com/tmux-plugins/tmux-sensible
  run "$SCRIPT" --dry-run
  assert_success
  assert_output --partial 'would remove stray ~/.tmux/plugins/tpm/tmux-sensible'
  assert_output --partial 'would move stray ~/.tmux/plugins/tpm/tmux-yank to ~/.tmux/plugins/tmux-yank'
  [ -d "$TPM/tmux-sensible" ] && [ -d "$TPM/tmux-yank" ] && [ ! -e "$PLUGINS/tmux-yank" ]
}

@test "pre_repos: second run reports no changes" {
  stray tmux-sensible tmux-plugins/tmux-sensible
  stray tmux-yank tmux-plugins/tmux-yank
  make_clone "$PLUGINS/tmux-sensible" https://git::@github.com/tmux-plugins/tmux-sensible
  run "$SCRIPT"
  assert_success
  run "$SCRIPT"
  assert_success
  assert_output ''
}

@test "mise.toml wires the pre-repos hook to pre_repos.sh" {
  awk '/^\[bootstrap.hooks.pre-repos\]/,/^$/' "$REPO_ROOT/mise.toml" | grep -qF '{{ config_root }}/scripts/bootstrap/pre_repos.sh'
}
