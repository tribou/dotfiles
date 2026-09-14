setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "dockerignore: ignores .worktrees, .claude, and .ci-cache" {
  run grep -E '^\.worktrees' "$REPO_ROOT/.dockerignore"
  assert_success
  run grep -E '^\.claude' "$REPO_ROOT/.dockerignore"
  assert_success
  run grep -E '^\.ci-cache' "$REPO_ROOT/.dockerignore"
  assert_success
}

@test "dockerfile: configures safe.directory *" {
  run grep -E 'git config --system --add safe\.directory "\*"' "$REPO_ROOT/Dockerfile"
  assert_success
}

@test "docker-compose: configures GIT_CONFIG_PARAMETERS safe.directory=*" {
  run grep -E "GIT_CONFIG_PARAMETERS:.*safe\.directory=\*" "$REPO_ROOT/docker-compose.yml"
  assert_success
}

@test "dockerfile: pre-installs build prerequisites for sub-45s inner loop" {
  run grep -E 'build-essential' "$REPO_ROOT/Dockerfile"
  assert_success
  run grep -E 'zlib1g-dev' "$REPO_ROOT/Dockerfile"
  assert_success
  run grep -E 'xdg-utils' "$REPO_ROOT/Dockerfile"
  assert_success
  run grep -E 'bash-completion' "$REPO_ROOT/Dockerfile"
  assert_success
}

@test "dockerfile: leaves product tools to mise" {
  local dockerfile="$REPO_ROOT/Dockerfile"
  ! grep -qF 'https://mise.run' "$dockerfile"
  ! grep -qF 'ansible-core' "$dockerfile"
  ! grep -qF 'setup_24.x' "$dockerfile"
  ! grep -qF 'nvim-linux' "$dockerfile"
  ! grep -qF 'pip3 install' "$dockerfile"
  ! grep -qF 'apt-get install -y nodejs' "$dockerfile"
  grep -qF 'COPY . .' "$dockerfile"
}
