# tests/integration/nvim_health.bats
setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'
}

@test "nvim checkhealth exits without errors" {
  run nvim --headless -c "checkhealth" -c "qall" 2>&1
  refute_output --partial "ERROR"
}

@test "nvim starts without E-code errors in messages" {
  run nvim --headless -c "messages" -c "qall" 2>&1
  refute_output --regexp "E[0-9]+:"
}

@test "vim-plug is installed" {
  [ -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ] || \
  [ -f "$HOME/.vim/autoload/plug.vim" ]
}

@test "nvim plugins directory exists and is populated" {
  local plugdir="$HOME/.local/share/nvim/plugged"
  [ -d "$plugdir" ] && [ "$(ls -A "$plugdir")" ]
}

@test "CopilotChat plugin is installed" {
  run find "$HOME/.local/share/nvim" -name "CopilotChat.nvim" -type d
  assert_output --partial "CopilotChat"
}

@test "CoC extensions directory exists" {
  [ -d "$HOME/.config/coc/extensions/node_modules" ]
}

@test "nvim PlugStatus shows no errors" {
  run nvim --headless -c "PlugStatus" -c "qall" 2>&1
  refute_output --partial "Error"
}
