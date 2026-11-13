# covers: docker-compose.yml .github/workflows/ubuntu-tests.yml
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

@test "docker-compose: skips only the rust toolchain by default (MISE_DISABLE_TOOLS)" {
  awk '/^  ci:/,/^  dev:/' "$REPO_ROOT/docker-compose.yml" | grep -qF 'MISE_DISABLE_TOOLS: ${MISE_DISABLE_TOOLS-rust}'
  ! grep -qF 'DOTFILES_ANSIBLE_EXTRA_ARGS' "$REPO_ROOT/docker-compose.yml" "$REPO_ROOT/.github/workflows/ubuntu-tests.yml"
}

@test "ci-workflow: caches full .ci-cache directory with actions/cache" {
  run grep -E 'path:\s*\.ci-cache$' "$REPO_ROOT/.github/workflows/ubuntu-tests.yml"
  assert_success
}

@test "docker-compose: ci converges twice, requires a clean second run, then goss and integration checks" {
  local compose="$REPO_ROOT/docker-compose.yml"
  local ci_block
  ci_block="$(awk '/^  ci:/,/^  dev:/' "$compose")"
  [ "$(grep -cF './bootstrap.sh' <<< "$ci_block")" -eq 2 ]
  grep -qF './bootstrap.sh | tee /tmp/first-converge.log' <<< "$ci_block"
  grep -qF './bootstrap.sh | tee /tmp/second-converge.log' <<< "$ci_block"
  grep -qF '! grep -Eq "$$DOTFILES_CHANGE_PATTERN" /tmp/second-converge.log' <<< "$ci_block"
  grep -qF 'mise -C /dotfiles bootstrap status --missing' <<< "$ci_block"
  grep -qF 'DOTFILES=/dotfiles goss validate --format tap' "$compose"
  grep -qF './tests/test_helper/bats-core/bin/bats tests/integration/' "$compose"
}

@test "docker-compose: change pattern catches every kind of converge change" {
  local pattern
  pattern="$(awk -F"'" '/DOTFILES_CHANGE_PATTERN:/ {print $2}' "$REPO_ROOT/docker-compose.yml")"
  [ -n "$pattern" ]
  for line in 'changed: generated ~/.ssh/id_rsa' 'mise files: created symlink ~/.zshrc -> /dotfiles/zshrc' \
      'mise repos: applied ~/.tmux/plugins/tpm' 'mise node@26.1.0 [1/3] install' 'mise brew: Installing lynx'; do
    echo "$line" | grep -Eq "$pattern" || fail "pattern misses: $line"
  done
  for line in 'mise files: all files are applied' 'mise all tools are installed'; do
    ! echo "$line" | grep -Eq "$pattern" || fail "pattern flags a no-op: $line"
  done
}

@test "docker-compose: dev uses the mise-first bootstrap" {
  local dev_block
  dev_block="$(awk '/^  dev:/,0' "$REPO_ROOT/docker-compose.yml")"
  grep -qF './bootstrap.sh && bash' <<< "$dev_block"
}

@test "docker-compose: caches the Linux Homebrew prefix mise pours brew packages into" {
  grep -qE '\./\.ci-cache/linuxbrew:/home/linuxbrew/\.linuxbrew' "$REPO_ROOT/docker-compose.yml"
}

@test "docker-compose and CI forward GITHUB_TOKEN so mise installs avoid anonymous rate limits" {
  awk '/^  ci:/,/^  dev:/' "$REPO_ROOT/docker-compose.yml" | grep -qE 'GITHUB_TOKEN: \$\{GITHUB_TOKEN:-\}'
  awk '/name: Run Docker environment tests/,/run: just test/' "$REPO_ROOT/.github/workflows/ubuntu-tests.yml" \
    | grep -qF 'GITHUB_TOKEN: ${{ github.token }}'
}
