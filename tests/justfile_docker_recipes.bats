setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "justfile: test-unit runs ansible-playbook --syntax-check with ANSIBLE_CONFIG" {
  block="$(sed -n '/^test-unit/,/^[^[:space:]]/p' "$REPO_ROOT/justfile")"
  echo "$block" | grep -q 'ansible-playbook --syntax-check playbook.yml'
  echo "$block" | grep -q 'ANSIBLE_CONFIG='
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

@test "justfile: has test-clean recipe that clears .ci-cache and runs full test without skip-tags" {
  block="$(sed -n '/^test-clean:/,/^[^[:space:]]/p' "$REPO_ROOT/justfile")"
  echo "$block" | grep -q 'rm -rf .ci-cache'
  echo "$block" | grep -q 'DOTFILES_ANSIBLE_EXTRA_ARGS=""'
  echo "$block" | grep -q -- '-v "${git_common_dir}:${git_common_dir}:ro"'
}
