setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "docker-compose: mounts persistent ci-cache volumes for mise, tmux, go, and coc" {
  run grep -E '\./\.ci-cache/nvim:/root/\.local/share/nvim' "$REPO_ROOT/docker-compose.yml"
  assert_success
  run grep -E '\./\.ci-cache/mise:/root/\.local/share/mise' "$REPO_ROOT/docker-compose.yml"
  assert_success
  run grep -E '\./\.ci-cache/mise-cache:/root/\.cache/mise' "$REPO_ROOT/docker-compose.yml"
  assert_success
  run grep -E '\./\.ci-cache/tmux:/root/\.tmux/plugins' "$REPO_ROOT/docker-compose.yml"
  assert_success
  run grep -E '\./\.ci-cache/go:/root/dev/go' "$REPO_ROOT/docker-compose.yml"
  assert_success
  run grep -E '\./\.ci-cache/coc:/root/\.config/coc' "$REPO_ROOT/docker-compose.yml"
  assert_success
}

@test "docker-compose: sets default DOTFILES_ANSIBLE_EXTRA_ARGS to skip brew and rust" {
  run grep -E 'DOTFILES_ANSIBLE_EXTRA_ARGS.*--skip-tags brew,rust' "$REPO_ROOT/docker-compose.yml"
  assert_success
}

@test "ci-workflow: aligns DOTFILES_ANSIBLE_EXTRA_ARGS with compose default" {
  run grep -E 'DOTFILES_ANSIBLE_EXTRA_ARGS:\s*"--skip-tags brew,rust"' "$REPO_ROOT/.github/workflows/ubuntu-tests.yml"
  assert_success
}

@test "ci-workflow: caches full .ci-cache directory with actions/cache" {
  run grep -E 'path:\s*\.ci-cache$' "$REPO_ROOT/.github/workflows/ubuntu-tests.yml"
  assert_success
}

@test "docker-compose: ci converges twice before goss and integration checks" {
  local compose="$REPO_ROOT/docker-compose.yml"
  local ci_block
  ci_block="$(awk '/^  ci:/,/^  dev:/' "$compose")"
  [ "$(grep -cF './bootstrap.sh' <<< "$ci_block")" -eq 2 ]
  grep -qF './bootstrap.sh $${DOTFILES_ANSIBLE_EXTRA_ARGS:-} | tee /tmp/first-converge.log' <<< "$ci_block"
  grep -qF './bootstrap.sh $${DOTFILES_ANSIBLE_EXTRA_ARGS:-} | tee /tmp/second-converge.log' <<< "$ci_block"
  grep -qF "! grep -Eq 'changed=[1-9][0-9]*' /tmp/second-converge.log" "$compose"
  grep -qF 'DOTFILES=/dotfiles goss validate --format tap' "$compose"
  grep -qF './tests/test_helper/bats-core/bin/bats tests/integration/' "$compose"
}

@test "docker-compose: dev uses the mise-first bootstrap boundary" {
  local compose="$REPO_ROOT/docker-compose.yml"
  local dev_block
  dev_block="$(awk '/^  dev:/,0' "$compose")"
  grep -qF './bootstrap.sh $${DOTFILES_ANSIBLE_EXTRA_ARGS:-} && bash' <<< "$dev_block"
  ! grep -qF 'ansible-playbook -i localhost' <<< "$dev_block"
}
