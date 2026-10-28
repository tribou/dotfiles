# tests/integration/nvim_python_provider.bats
setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'
  STUB_BIN="$(mktemp -d)"
  # A python3 first on PATH that can't import pynvim, like brew's python3
  # right after a minor version upgrade. -S skips site-packages entirely,
  # hiding both --user and system-wide (Dockerfile) pynvim installs.
  printf '#!/bin/sh\nexec %s -S "$@"\n' "$(command -v python3)" > "$STUB_BIN/python3"
  chmod +x "$STUB_BIN/python3"
}

teardown() {
  rm -rf "$STUB_BIN"
}

@test "python3 provider loads when the first python3 on PATH lacks pynvim" {
  # A failed host load only echoes an error (try/catch can't see it), so
  # check py3eval's result instead
  PATH="$STUB_BIN:$PATH" run nvim --headless \
    -c 'if py3eval("1+1") != 2 | cquit | endif' -c 'qa!'
  assert_success
}
