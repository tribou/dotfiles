# covers: lib/cloud.sh
setup() {
  load 'test_helper/common_setup'
  common_setup
  STUB_BIN="$(mktemp -d)"
  export AWS_LOG="$STUB_BIN/aws.log"
  # aws: profile list, an identity without SSO (forces a login), and a login that logs its args
  cat > "$STUB_BIN/aws" <<'EOF'
#!/usr/bin/env bash
case "$1 $2" in
  "configure list-profiles") echo "dev" ;;
  "sts get-caller-identity") echo '{"Arn": "arn:aws:iam::1:user/x"}' ;;
  "sso login") echo "$*" >> "$AWS_LOG" ;;
esac
EOF
  cat > "$STUB_BIN/fzf" <<'EOF'
#!/usr/bin/env bash
cat
EOF
  chmod +x "$STUB_BIN/aws" "$STUB_BIN/fzf"
  export PATH="$STUB_BIN:$PATH"
  unset SSH_CONNECTION SSH_TTY AWS_SSO_NO_BROWSER DISPLAY WAYLAND_DISPLAY
}

teardown() {
  rm -rf "$STUB_BIN"
}

@test "aws-profile: logs in with the default browser flow locally" {
  is_linux && export DISPLAY=:0
  run aws-profile
  assert_success
  run cat "$AWS_LOG"
  assert_output "sso login"
}

@test "aws-profile: uses device code login without a browser over SSH" {
  export SSH_CONNECTION="1.2.3.4 5 6.7.8.9 22"
  run aws-profile
  assert_success
  run cat "$AWS_LOG"
  assert_output "sso login --use-device-code --no-browser"
}

@test "aws-profile: AWS_SSO_NO_BROWSER=1 forces device code login" {
  is_linux && export DISPLAY=:0
  export AWS_SSO_NO_BROWSER=1
  run aws-profile
  assert_success
  run cat "$AWS_LOG"
  assert_output "sso login --use-device-code --no-browser"
}

@test "aws-profile: AWS_SSO_NO_BROWSER=0 keeps the browser flow over SSH" {
  export SSH_CONNECTION="1.2.3.4 5 6.7.8.9 22"
  export AWS_SSO_NO_BROWSER=0
  run aws-profile
  assert_success
  run cat "$AWS_LOG"
  assert_output "sso login"
}

@test "sso: passes the session and uses device code login over SSH" {
  export SSH_TTY=/dev/pts/0
  run sso
  assert_success
  run cat "$AWS_LOG"
  assert_output "sso login --sso-session tribou --use-device-code --no-browser"
}
