setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "commit: ticket present builds TICKET: <summary> and commits" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() {
      if [ \"\$1\" = \"add\" ] && [ \"\$2\" = \"-A\" ]; then return 0; fi
      if [ \"\$1\" = \"diff\" ] && [ \"\$2\" = \"--cached\" ] && [ \"\$3\" = \"--quiet\" ]; then return 1; fi
      if [ \"\$1\" = \"branch\" ] && [ \"\$2\" = \"--show-current\" ]; then echo 'feature/ABC-123-b'; return 0; fi
      if [ \"\$1\" = \"commit\" ] && [ \"\$2\" = \"-m\" ]; then echo \"git_commit_message:\$3\"; return 0; fi
    }
    _dotfiles_commit_generate_message() { echo 'silence brew prompt'; }
    _dotfiles_git_log_commit() { echo 'git_log_commit'; }
    _dotfiles_git_status() { echo 'git_status'; }
    commit
  "
  assert_success
  assert_output --partial "git_commit_message:ABC-123: silence brew prompt"
  assert_output --partial "git_log_commit"
  assert_output --partial "git_status"
}

@test "commit: no ticket uses the generated message verbatim" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() {
      if [ \"\$1\" = \"add\" ] && [ \"\$2\" = \"-A\" ]; then return 0; fi
      if [ \"\$1\" = \"diff\" ] && [ \"\$2\" = \"--cached\" ] && [ \"\$3\" = \"--quiet\" ]; then return 1; fi
      if [ \"\$1\" = \"branch\" ] && [ \"\$2\" = \"--show-current\" ]; then echo 'main'; return 0; fi
      if [ \"\$1\" = \"commit\" ] && [ \"\$2\" = \"-m\" ]; then echo \"git_commit_message:\$3\"; return 0; fi
    }
    _dotfiles_commit_generate_message() { echo 'fix(bootstrap): silence brew prompt'; }
    _dotfiles_git_log_commit() { echo 'git_log_commit'; }
    _dotfiles_git_status() { echo 'git_status'; }
    commit
  "
  assert_success
  assert_output --partial "git_commit_message:fix(bootstrap): silence brew prompt"
  refute_output --partial "git_commit_message:ABC"
}

@test "commit: nothing staged prints message and skips commit" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() {
      if [ \"\$1\" = \"add\" ] && [ \"\$2\" = \"-A\" ]; then return 0; fi
      if [ \"\$1\" = \"diff\" ] && [ \"\$2\" = \"--cached\" ] && [ \"\$3\" = \"--quiet\" ]; then return 0; fi
      echo \"git_unexpected_call:\$*\"
      return 0
    }
    _dotfiles_commit_generate_message() { echo 'should-not-be-called'; }
    commit
  "
  assert_success
  assert_output "nothing to commit"
  refute_output --partial "should-not-be-called"
  refute_output --partial "git_unexpected_call"
}

@test "commit: falls back to c when message generation fails" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() {
      if [ \"\$1\" = \"add\" ] && [ \"\$2\" = \"-A\" ]; then return 0; fi
      if [ \"\$1\" = \"diff\" ] && [ \"\$2\" = \"--cached\" ] && [ \"\$3\" = \"--quiet\" ]; then return 1; fi
      if [ \"\$1\" = \"branch\" ] && [ \"\$2\" = \"--show-current\" ]; then echo 'main'; return 0; fi
      echo \"git_commit_message:unexpected\"
      return 0
    }
    _dotfiles_commit_generate_message() { return 1; }
    c() { echo 'c_invoked'; }
    commit
  "
  assert_success
  assert_output --partial "claude unavailable, falling back to manual commit"
  assert_output --partial "c_invoked"
  refute_output --partial "git_commit_message"
}

@test "commit: mid-merge delegates to c instead of generating an AI message" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    tmpdir=\$(mktemp -d)
    mkdir -p \"\$tmpdir/.git\"
    touch \"\$tmpdir/.git/MERGE_HEAD\"
    cd \"\$tmpdir\" || exit 1
    git() { echo \"git_unexpected_call:\$*\"; return 0; }
    _dotfiles_commit_generate_message() { echo 'should-not-be-called'; }
    c() { echo 'c_invoked'; }
    commit
    rm -rf \"\$tmpdir\"
  "
  assert_success
  assert_output --partial "c_invoked"
  refute_output --partial "should-not-be-called"
  refute_output --partial "git_unexpected_call"
}

@test "commit: falls back to c with no forwarded args when message generation fails" {
  run bash -c "
    . '$REPO_ROOT/lib/_shared.sh'
    . '$REPO_ROOT/lib/commands.sh'
    git() {
      if [ \"\$1\" = \"add\" ] && [ \"\$2\" = \"-A\" ]; then return 0; fi
      if [ \"\$1\" = \"diff\" ] && [ \"\$2\" = \"--cached\" ] && [ \"\$3\" = \"--quiet\" ]; then return 1; fi
      if [ \"\$1\" = \"branch\" ] && [ \"\$2\" = \"--show-current\" ]; then echo 'main'; return 0; fi
      echo \"git_commit_message:unexpected\"
      return 0
    }
    _dotfiles_commit_generate_message() { return 1; }
    c() { echo \"c_invoked_with_argc:\$#\"; }
    commit ignored-arg
  "
  assert_success
  assert_output --partial "c_invoked_with_argc:0"
}

@test "commit: removes the old non-AI alias" {
  run grep -F "alias commit=" "$REPO_ROOT/lib/commands.sh"
  assert_failure
}
