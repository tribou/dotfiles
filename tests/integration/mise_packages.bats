@test "mise brew manager installs formulae without Homebrew" {
  ! command -v brew
  [ -x /home/linuxbrew/.linuxbrew/bin/git ]
  [ -x /home/linuxbrew/.linuxbrew/bin/bash ]
  mise bootstrap packages status --missing
}

@test "canonical formula prefix is available after shell startup" {
  run bash -lc 'command -v git && command -v bash'
  [ "$status" -eq 0 ]
  [[ "$output" == *"/home/linuxbrew/.linuxbrew/bin/"* ]]
}
