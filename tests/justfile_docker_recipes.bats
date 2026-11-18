# covers: justfile
setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "justfile: no recipe references Ansible" {
  ! grep -qiE 'ansible|playbook' "$REPO_ROOT/justfile"
}

@test "justfile: test resolves git-common-dir and bind-mounts it read-only" {
  block="$(sed -n '/^test:/,/^[^[:space:]]/p' "$REPO_ROOT/justfile")"
  echo "$block" | grep -q 'git rev-parse --path-format=absolute --git-common-dir'
  echo "$block" | grep -q -- '-v "${git_common_dir}:${git_common_dir}:ro"'
}

@test "justfile: dev resolves git-common-dir and bind-mounts it read-only" {
  block="$(sed -n '/^dev:/,/^[^[:space:]]/p' "$REPO_ROOT/justfile")"
  echo "$block" | grep -q 'git rev-parse --path-format=absolute --git-common-dir'
  echo "$block" | grep -q -- '-v "${git_common_dir}:${git_common_dir}:ro"'
}

@test "justfile: has test-clean recipe that clears .ci-cache and runs cold with every tool" {
  block="$(sed -n '/^test-clean:/,/^[^[:space:]]/p' "$REPO_ROOT/justfile")"
  echo "$block" | grep -q 'rm -rf .ci-cache'
  echo "$block" | grep -q 'MISE_DISABLE_TOOLS=""'
  echo "$block" | grep -q -- '-v "${git_common_dir}:${git_common_dir}:ro"'
}

@test "justfile: test-unit runs bats in parallel only when GNU parallel is available" {
  block="$(sed -n '/^test-unit/,/^[^[:space:]]/p' "$REPO_ROOT/justfile")"
  echo "$block" | grep -q 'parallel --version'
  echo "$block" | grep -q 'GNU parallel'
  echo "$block" | grep -q -- '--jobs'
  echo "$block" | grep -q 'DOTFILES_TEST_JOBS'
}

@test "justfile: default picker matches recipe names, not descriptions" {
  block="$(sed -n '/^default:/,/^[^[:space:]]/p' "$REPO_ROOT/justfile")"
  echo "$block" | grep -q -- 'fzf .*--nth=1'
}

@test "justfile: _own-ci-cache chowns the container's .ci-cache to the host user" {
  block="$(sed -n '/^_own-ci-cache:/,/^[^[:space:]]/p' "$REPO_ROOT/justfile")"
  echo "$block" | grep -q 'docker compose run --rm -T ci chown -R "$(id -u):$(id -g)" /dotfiles/.ci-cache'
}

@test "justfile: test and test-clean hand .ci-cache back to the host user on exit" {
  for recipe in test test-clean; do
    block="$(sed -n "/^${recipe}:/,/^[^[:space:]]/p" "$REPO_ROOT/justfile")"
    echo "$block" | grep -q "trap .*_own-ci-cache.* EXIT"
  done
}
